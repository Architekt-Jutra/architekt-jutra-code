#!/usr/bin/env node
// Validates plugins under plugins/* against the host contract.
// Usage: node .claude/skills/plugin-doctor/check.mjs [plugin-id ...]

import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { join, basename } from "node:path";

const ROOT = process.cwd();
const PLUGINS_DIR = join(ROOT, "plugins");
const HOST = process.env.AJ_HOST ?? "http://localhost:8080";
const ID_RE = /^[a-zA-Z0-9_-]+$/;
const NO_ROUTE_TYPES = new Set(["product.list.filters"]);
const KNOWN_TYPES = new Set([
  "menu.main",
  "product.detail.tabs",
  "product.detail.info",
  "product.list.filters",
]);

const findings = [];
const add = (plugin, level, check, detail) =>
  findings.push({ plugin, level, check, detail });

const read = (p) => readFileSync(p, "utf8");

function pluginDirs() {
  const wanted = process.argv.slice(2);
  return readdirSync(PLUGINS_DIR)
    .filter((n) => statSync(join(PLUGINS_DIR, n)).isDirectory())
    .filter((n) => existsSync(join(PLUGINS_DIR, n, "manifest.json")))
    .filter((n) => wanted.length === 0 || wanted.includes(n));
}

/** Collect every `path="..."` in the router file. */
function routePaths(mainSrc) {
  return [...mainSrc.matchAll(/<Route\s[^>]*path=["']([^"']+)["']/g)].map((m) => m[1]);
}

function walk(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });
}

function checkManifest(id, dir) {
  let manifest;
  try {
    manifest = JSON.parse(read(join(dir, "manifest.json")));
  } catch (e) {
    add(id, "FAIL", "manifest", `not valid JSON: ${e.message}`);
    return null;
  }

  if (!ID_RE.test(id)) add(id, "FAIL", "manifest", `plugin id must match ${ID_RE}`);
  if (!manifest.name?.trim()) add(id, "FAIL", "manifest", "name is required and non-blank");
  if (!/^https?:\/\//.test(manifest.url ?? ""))
    add(id, "FAIL", "manifest", `url must be http(s), got ${JSON.stringify(manifest.url)}`);

  const points = manifest.extensionPoints ?? [];
  if (points.length === 0) add(id, "WARN", "manifest", "no extension points — plugin is invisible in the host");

  for (const ep of points) {
    if (!KNOWN_TYPES.has(ep.type)) {
      add(id, "FAIL", "extension-point", `unknown type "${ep.type}"`);
      continue;
    }
    if (!ep.label?.trim()) add(id, "WARN", "extension-point", `${ep.type} has no label`);

    if (NO_ROUTE_TYPES.has(ep.type)) {
      if (ep.path) add(id, "WARN", "extension-point", `${ep.type} declares path "${ep.path}" — host renders this natively, path is ignored`);
      if (!ep.filterKey) add(id, "FAIL", "extension-point", `${ep.type} requires filterKey`);
      if (!["boolean", "string", "number"].includes(ep.filterType))
        add(id, "FAIL", "extension-point", `${ep.type} filterType must be boolean|string|number, got ${JSON.stringify(ep.filterType)}`);
    } else if (!ep.path) {
      add(id, "FAIL", "extension-point", `${ep.type} requires a path`);
    }

    if (ep.type === "menu.main" && !ep.icon)
      add(id, "WARN", "extension-point", "menu.main has no icon — sidebar falls back to 'plug'");
  }

  return manifest;
}

function checkPort(id, dir, manifest) {
  const cfgPath = join(dir, "vite.config.ts");
  if (!existsSync(cfgPath)) {
    add(id, "FAIL", "port", "vite.config.ts missing");
    return null;
  }
  const cfg = read(cfgPath);
  const cfgPort = cfg.match(/port:\s*(\d+)/)?.[1];
  const urlPort = manifest?.url?.match(/:(\d+)/)?.[1];

  if (!cfgPort) add(id, "FAIL", "port", "no port in vite.config.ts");
  if (!/strictPort:\s*true/.test(cfg))
    add(id, "WARN", "port", "strictPort not true — vite may silently move to another port and break the manifest url");
  if (cfgPort && urlPort && cfgPort !== urlPort)
    add(id, "FAIL", "port", `vite.config.ts uses ${cfgPort} but manifest url uses ${urlPort}`);

  return cfgPort ?? null;
}

function checkRoutes(id, dir, manifest) {
  const mainPath = join(dir, "src", "main.tsx");
  if (!existsSync(mainPath)) {
    add(id, "FAIL", "routes", "src/main.tsx missing");
    return;
  }
  const routes = routePaths(read(mainPath));
  const needed = (manifest?.extensionPoints ?? [])
    .filter((ep) => !NO_ROUTE_TYPES.has(ep.type) && ep.path)
    .map((ep) => ep.path);

  for (const p of needed)
    if (!routes.includes(p))
      add(id, "FAIL", "routes", `manifest path "${p}" has no matching <Route> in main.tsx`);

  for (const r of routes)
    if (!needed.includes(r))
      add(id, "WARN", "routes", `<Route path="${r}"> matches no extension point — dead route`);
}

function checkImports(id, dir) {
  if (existsSync(join(dir, "src", "sdk.ts")) || existsSync(join(dir, "sdk.ts")))
    add(id, "FAIL", "sdk", "local sdk.ts copy — import from the shared plugins/sdk.ts instead");

  for (const file of walk(join(dir, "src"))) {
    if (!/\.tsx?$/.test(file)) continue;
    const src = read(file);
    const depth = file.includes(`${join("src", "pages")}`) ? "../../../sdk" : "../../sdk";
    for (const m of src.matchAll(/from\s+["'](\.\.[^"']*sdk)["']/g)) {
      if (m[1] !== depth)
        add(id, "FAIL", "sdk", `${basename(file)}: imports "${m[1]}", should be "${depth}" — fails tsc, not the browser`);
    }
  }
}

async function checkRegistration(id, manifest) {
  let res;
  try {
    res = await fetch(`${HOST}/api/plugins/${id}`, { signal: AbortSignal.timeout(2000) });
  } catch {
    add(id, "SKIP", "registered", `host unreachable at ${HOST} — start it to check registration`);
    return;
  }
  if (res.status === 404) {
    add(id, "FAIL", "registered", `not registered — PUT ${HOST}/api/plugins/${id}/manifest`);
    return;
  }
  if (!res.ok) {
    add(id, "WARN", "registered", `host returned ${res.status}`);
    return;
  }

  const live = await res.json();
  if (live.enabled === false) add(id, "WARN", "registered", "registered but disabled");

  const onDisk = JSON.stringify(manifest?.extensionPoints ?? []);
  const onHost = JSON.stringify(live.manifest?.extensionPoints ?? live.extensionPoints ?? []);
  if (onDisk !== onHost)
    add(id, "FAIL", "registered", "registered manifest differs from manifest.json — re-register it");
}

async function checkDevServer(id, port) {
  if (!port) return;
  try {
    await fetch(`http://localhost:${port}/`, { signal: AbortSignal.timeout(1000) });
  } catch {
    add(id, "SKIP", "dev-server", `nothing listening on :${port} — run npm run dev in the plugin`);
  }
}

const ids = pluginDirs();
if (ids.length === 0) {
  console.log("No plugins found under plugins/");
  process.exit(0);
}

const portOwners = new Map();

for (const id of ids) {
  const dir = join(PLUGINS_DIR, id);
  const manifest = checkManifest(id, dir);
  const port = checkPort(id, dir, manifest);
  checkRoutes(id, dir, manifest);
  checkImports(id, dir);
  await checkRegistration(id, manifest);
  await checkDevServer(id, port);

  if (port) {
    if (portOwners.has(port))
      add(id, "FAIL", "port", `port ${port} already used by ${portOwners.get(port)} — strictPort makes this a startup crash`);
    else portOwners.set(port, id);
  }
}

const rank = { FAIL: 0, WARN: 1, SKIP: 2 };
findings.sort((a, b) => rank[a.level] - rank[b.level] || a.plugin.localeCompare(b.plugin));

const counts = { FAIL: 0, WARN: 0, SKIP: 0 };
for (const f of findings) counts[f.level]++;

console.log(`Checked ${ids.length} plugin(s): ${ids.join(", ")}\n`);
if (findings.length === 0) {
  console.log("All checks passed.");
} else {
  for (const f of findings) console.log(`${f.level.padEnd(4)} ${f.plugin} [${f.check}] ${f.detail}`);
  console.log(`\n${counts.FAIL} failed, ${counts.WARN} warnings, ${counts.SKIP} skipped`);
}

process.exit(counts.FAIL > 0 ? 1 : 0);
