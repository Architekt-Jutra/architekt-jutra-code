---
name: plugin-doctor
description: Diagnose plugins in the aj platform — validates manifest, extension points, ports, routes, SDK imports, and registration against the running host. Use when a plugin doesn't appear in the UI, a tab or sidebar entry is blank, a filter does nothing, after editing a manifest, or when the user asks to check/validate/debug plugins.
---

# Plugin Doctor

Validates every plugin under `plugins/` against the host contract in `plugins/CLAUDE.md`.

## Run it

```bash
node .claude/skills/plugin-doctor/check.mjs              # all plugins
node .claude/skills/plugin-doctor/check.mjs warehouse    # one plugin
```

Exits 1 if anything FAILs. Override the host with `AJ_HOST=http://host:port`.

## What it checks

| Check | Catches |
|---|---|
| `manifest` | invalid JSON, id not matching `^[a-zA-Z0-9_-]+$`, blank name, non-http url |
| `extension-point` | unknown type, missing path, `product.list.filters` missing `filterKey`/`filterType` or wrongly declaring a path, `menu.main` with no icon |
| `port` | manifest url and `vite.config.ts` disagreeing, `strictPort` off, two plugins on one port |
| `routes` | a manifest path with no `<Route>`, a `<Route>` matching no extension point |
| `sdk` | wrong relative import depth, a local `sdk.ts` copy |
| `registered` | plugin not registered, disabled, or host copy differing from `manifest.json` |
| `dev-server` | nothing listening on the plugin's port |

`registered` and `dev-server` report SKIP rather than FAIL when the host or dev server isn't running — those are environment facts, not defects.

## Reading the output

**`routes`** — the most common cause of a blank tab or 404 iframe. The manifest `path` and the `<Route path>` in `src/main.tsx` must match exactly.

**`registered` — "registered manifest differs"** — the single most common confusion. The host stores its own copy of the manifest at registration time. Editing `manifest.json` changes nothing until you re-register:

```bash
curl -sS -X PUT http://localhost:8080/api/plugins/<id>/manifest \
  -H "Content-Type: application/json" -d @plugins/<id>/manifest.json
```

**`sdk` — wrong import depth** — `plugins/CLAUDE.md` documents `../../sdk`, which is only correct from `src/`. Files in `src/pages/` need `../../../sdk`. This breaks `tsc -b`, not the browser, so a working dev server does not mean it's fine.

**`port`** — `strictPort: true` turns a collision into a startup crash rather than a silent port change. If the manifest url and vite port disagree, the host loads an iframe pointing at nothing.

## After fixing

Re-run the script. If you changed a manifest, re-register before re-running or the `registered` check will still report drift. Report which findings you fixed and which you left, with the reason.
