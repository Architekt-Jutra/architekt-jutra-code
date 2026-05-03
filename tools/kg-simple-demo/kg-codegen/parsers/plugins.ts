// Plugin parser: manifests + plugin-side TypeScript.
//
// Extracts:
//   - Plugin (one per plugins/<id>/manifest.json)
//   - Manifest (one per manifest)
//   - ExtensionPoint (one per extensionPoints[] entry, except product.list.filters)
//   - FilterDefinition (one per product.list.filters entry)
//   - PluginPage (one per <Route> in plugins/<id>/src/main.tsx)
//   - DomainConcept (one per exported interface/type in plugins/<id>/src/domain.ts)
//   - API (one per plugin; kind=backend-route if pages/api/* exists, else sdk-host-bridge)
//
// Edges:
//   - Plugin DECLARES Manifest
//   - Manifest DECLARES ExtensionPoint / FilterDefinition
//   - Plugin EXPOSES ExtensionPoint
//   - Plugin CONTAINS PluginPage / API
//   - Plugin DEFINES DomainConcept
//   - ExtensionPoint IMPLEMENTED_BY PluginPage   (when EP.path matches a Route path)
import fs from 'node:fs';
import path from 'node:path';
import fg from 'fast-glob';
import ts from 'typescript';
import type { CypherEdge, CypherNode, Graph } from '../types.ts';
import { slug } from '../types.ts';

interface ManifestExtensionPoint {
  type: string;
  label?: string;
  icon?: string;
  path?: string;
  priority?: number;
  filterKey?: string;
  filterType?: 'boolean' | 'string' | 'number';
}

interface PluginManifest {
  name: string;
  version?: string;
  url?: string;
  description?: string;
  extensionPoints?: ManifestExtensionPoint[];
}

const SCOPE_BY_TYPE: Record<string, string> = {
  'menu.main':            'global',
  'product.detail.tabs':  'product',
  'product.detail.info':  'product',
  'product.list.filters': 'product-list',
};

export async function parsePlugins(pluginsRoot: string): Promise<Graph> {
  const manifests = await fg(['*/manifest.json'], { cwd: pluginsRoot, absolute: true });
  const nodes: CypherNode[] = [];
  const edges: CypherEdge[] = [];

  for (const mfPath of manifests) {
    const pluginDir = path.dirname(mfPath);
    const pluginId = path.basename(pluginDir);
    let manifest: PluginManifest;
    try {
      manifest = JSON.parse(fs.readFileSync(mfPath, 'utf8')) as PluginManifest;
    } catch (err) {
      console.warn(`plugins: skipping ${mfPath} — invalid JSON: ${(err as Error).message}`);
      continue;
    }

    const pluginNodeId = `plugin-${slug(pluginId)}`;
    const manifestNodeId = `manifest-${slug(pluginId)}`;
    const apiNodeId = `api-${slug(pluginId)}`;

    nodes.push({ label: 'Plugin', id: pluginNodeId, properties: {
      pluginId,
      name: manifest.name ?? pluginId,
      version: manifest.version ?? null,
      url: manifest.url ?? null,
      description: manifest.description ?? null,
      enabled: true,
      path: `plugins/${pluginId}`,
    }});

    nodes.push({ label: 'Manifest', id: manifestNodeId, properties: {
      name: manifest.name ?? pluginId,
      version: manifest.version ?? null,
      url: manifest.url ?? null,
      description: manifest.description ?? null,
      extensionPoints: (manifest.extensionPoints ?? []).map(ep => ep.type),
    }});
    edges.push(edge('DECLARES', 'Plugin', pluginNodeId, 'Manifest', manifestNodeId));

    // API node — backend-route if pages/api/* exists, otherwise sdk-host-bridge.
    const backendRoutes = await fg(['src/pages/api/**/*.{ts,tsx}'], { cwd: pluginDir, absolute: true });
    const apiKind = backendRoutes.length > 0 ? 'backend-route' : 'sdk-host-bridge';
    const apiNode: CypherNode = { label: 'API', id: apiNodeId, properties: {
      name: `${manifest.name ?? pluginId} Plugin API`,
      kind: apiKind,
    }};
    if (backendRoutes.length > 0) {
      apiNode.properties.path = path.relative(path.resolve(pluginDir, '..', '..'), backendRoutes[0]!);
    }
    nodes.push(apiNode);
    edges.push(edge('CONTAINS', 'Plugin', pluginNodeId, 'API', apiNodeId));

    // Extension points + filter definitions.
    const epsForPlugin: Array<{ ep: ManifestExtensionPoint; nodeId: string }> = [];
    for (const ep of manifest.extensionPoints ?? []) {
      if (ep.type === 'product.list.filters') {
        const fid = `filter-${slug(pluginId)}-${slug(ep.filterKey ?? ep.label ?? 'filter')}`;
        nodes.push({ label: 'FilterDefinition', id: fid, properties: {
          filterKey: ep.filterKey ?? null,
          filterType: ep.filterType ?? null,
          label: ep.label ?? null,
          priority: ep.priority ?? null,
        }});
        edges.push(edge('DECLARES', 'Manifest', manifestNodeId, 'FilterDefinition', fid));
        continue;
      }
      const epId = `ep-${slug(pluginId)}-${slug(ep.type)}-${slug(ep.label ?? ep.path ?? 'ep')}`;
      nodes.push({ label: 'ExtensionPoint', id: epId, properties: {
        type: ep.type,
        label: ep.label ?? null,
        icon: ep.icon ?? null,
        path: ep.path ?? null,
        priority: ep.priority ?? null,
        scope: SCOPE_BY_TYPE[ep.type] ?? null,
        rendering: 'plugin-iframe',
      }});
      edges.push(edge('DECLARES', 'Manifest', manifestNodeId, 'ExtensionPoint', epId));
      edges.push(edge('EXPOSES', 'Plugin', pluginNodeId, 'ExtensionPoint', epId));
      epsForPlugin.push({ ep, nodeId: epId });
    }

    // Plugin pages: explicit React Router routes (main.tsx) AND/OR
    // Next.js-style file-based routes under src/pages/. Plugins typically
    // use one or the other; we collect both and dedupe by route path.
    const routes = await collectPluginRoutes(pluginDir);
    const pagesByPath = new Map<string, { id: string; component: string }>();
    for (const r of routes) {
      const ppId = `pp-${slug(pluginId)}-${slug(r.component)}`;
      const matchEp = epsForPlugin.find(({ ep }) => ep.path === r.path);
      nodes.push({ label: 'PluginPage', id: ppId, properties: {
        name: r.component,
        route: r.path,
        component: r.component,
        extensionPoint: matchEp?.ep.type ?? null,
      }});
      edges.push(edge('CONTAINS', 'Plugin', pluginNodeId, 'PluginPage', ppId));
      pagesByPath.set(r.path, { id: ppId, component: r.component });
    }

    // ExtensionPoint IMPLEMENTED_BY PluginPage (only iframe-rendered ones).
    for (const { ep, nodeId } of epsForPlugin) {
      if (!ep.path) continue;
      const page = pagesByPath.get(ep.path);
      if (page) edges.push(edge('IMPLEMENTED_BY', 'ExtensionPoint', nodeId, 'PluginPage', page.id));
    }

    // Domain concepts from src/domain.ts.
    const domainFile = path.join(pluginDir, 'src', 'domain.ts');
    if (fs.existsSync(domainFile)) {
      for (const typeName of readExportedTypeNames(domainFile)) {
        const dcId = `dc-${slug(pluginId)}-${slug(typeName)}`;
        nodes.push({ label: 'DomainConcept', id: dcId, properties: { name: typeName } });
        edges.push(edge('DEFINES', 'Plugin', pluginNodeId, 'DomainConcept', dcId));
      }
    }
  }

  return { nodes, edges };
}

// Collect plugin routes from both kinds of conventions used here:
//   1. Explicit React Router routes inside src/main.tsx (warehouse, box-size).
//   2. Next.js file-based routes under src/pages/*.tsx (ai-description).
// Excludes Next.js API handlers, _document, _app.
async function collectPluginRoutes(pluginDir: string): Promise<Array<{ path: string; component: string }>> {
  const routes: Array<{ path: string; component: string }> = [];
  routes.push(...await readRoutes(path.join(pluginDir, 'src', 'main.tsx')));
  const seen = new Set(routes.map(r => r.path));

  const pageFiles = await fg(['src/pages/*.tsx'], { cwd: pluginDir, absolute: true });
  for (const f of pageFiles) {
    const base = path.basename(f, '.tsx');
    if (base.startsWith('_') || base === 'api') continue;
    const routePath = '/' + base;
    if (seen.has(routePath)) continue;
    const component = readDefaultExportName(f) ?? base;
    routes.push({ path: routePath, component });
  }

  return routes;
}

function readDefaultExportName(file: string): string | undefined {
  const text = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
  for (const stmt of sf.statements) {
    if (ts.isFunctionDeclaration(stmt)) {
      const isDefault = (stmt.modifiers ?? []).some(m => m.kind === ts.SyntaxKind.DefaultKeyword);
      if (isDefault && stmt.name) return stmt.name.text;
    }
    if (ts.isExportAssignment(stmt) && ts.isIdentifier(stmt.expression)) {
      return stmt.expression.text;
    }
  }
  return undefined;
}

// Parse <Route path="..." element={<Component/>}/> from main.tsx using TS AST.
async function readRoutes(file: string): Promise<Array<{ path: string; component: string }>> {
  if (!fs.existsSync(file)) return [];
  const text = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);

  const out: Array<{ path: string; component: string }> = [];
  function visit(node: ts.Node) {
    if (ts.isJsxSelfClosingElement(node) || ts.isJsxOpeningElement(node)) {
      const tagName = node.tagName.getText();
      if (tagName === 'Route') {
        let routePath: string | undefined;
        let component: string | undefined;
        for (const attr of node.attributes.properties) {
          if (!ts.isJsxAttribute(attr) || !ts.isIdentifier(attr.name)) continue;
          const n = attr.name.text;
          if (n === 'path' && attr.initializer && ts.isStringLiteral(attr.initializer)) {
            routePath = attr.initializer.text;
          }
          if (n === 'element' && attr.initializer && ts.isJsxExpression(attr.initializer)) {
            const ex = attr.initializer.expression;
            if (ex && (ts.isJsxSelfClosingElement(ex) || ts.isJsxOpeningElement(ex))) {
              component = ex.tagName.getText();
            } else if (ex && ts.isJsxElement(ex)) {
              component = ex.openingElement.tagName.getText();
            }
          }
        }
        if (routePath !== undefined && component) out.push({ path: routePath, component });
      }
    }
    ts.forEachChild(node, visit);
  }
  visit(sf);
  return out;
}

// Exported interface / type alias names from a TS file.
function readExportedTypeNames(file: string): string[] {
  const text = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS);
  const names: string[] = [];
  for (const stmt of sf.statements) {
    const isExported = (stmt.modifiers ?? []).some(m => m.kind === ts.SyntaxKind.ExportKeyword);
    if (!isExported) continue;
    if (ts.isInterfaceDeclaration(stmt)) names.push(stmt.name.text);
    else if (ts.isTypeAliasDeclaration(stmt)) names.push(stmt.name.text);
  }
  return names;
}

function edge(type: string, sl: string, sid: string, tl: string, tid: string): CypherEdge {
  return { type, sourceLabel: sl, sourceId: sid, targetLabel: tl, targetId: tid };
}
