// Host frontend parser.
// Extracts CorePage nodes from src/main/frontend/src/router.tsx using the TS AST.
//
// We only emit core pages that are bound to a real component (skip <Navigate>
// redirects and the dynamic plugin route /plugins/:pluginId/* which is the
// generic plugin shell entry, not a host-owned page).
import fs from 'node:fs';
import path from 'node:path';
import ts from 'typescript';
import type { CypherNode, Graph } from '../types.ts';
import { slug } from '../types.ts';

interface RouteEntry { path: string; component: string }

const SKIP_COMPONENTS = new Set(['Navigate', 'Outlet', 'PluginPageRoute']);

export async function parseFrontend(frontendRoot: string): Promise<Graph> {
  const routerFile = path.join(frontendRoot, 'src', 'router.tsx');
  if (!fs.existsSync(routerFile)) return { nodes: [], edges: [] };

  const routes = readRouterRoutes(routerFile).filter(r => !SKIP_COMPONENTS.has(r.component));

  // Group routes that share the same component into a single CorePage. This
  // collapses /products/new + /products/:id/edit (both ProductFormPage) into
  // one node, with the route property recording every path it answers to.
  const byComponent = new Map<string, string[]>();
  for (const r of routes) {
    if (!byComponent.has(r.component)) byComponent.set(r.component, []);
    byComponent.get(r.component)!.push(r.path);
  }

  const nodes: CypherNode[] = [];
  for (const [component, paths] of byComponent) {
    const id = `page-${slug(component.replace(/Page$/, ''))}`;
    nodes.push({ label: 'CorePage', id, properties: {
      name: humanize(component.replace(/Page$/, '')),
      route: paths.map(p => '/' + p.replace(/^\/+/, '')).join(' | '),
      component,
    }});
  }

  return { nodes, edges: [] };
}

function readRouterRoutes(file: string): RouteEntry[] {
  const text = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
  const out: RouteEntry[] = [];

  function visit(node: ts.Node) {
    // createBrowserRouter accepts an array of route objects. Collect those.
    if (ts.isObjectLiteralExpression(node)) {
      let pathProp: string | undefined;
      let elementType: string | undefined;
      let isIndex = false;
      for (const prop of node.properties) {
        if (!ts.isPropertyAssignment(prop) || !ts.isIdentifier(prop.name)) continue;
        const k = prop.name.text;
        if (k === 'path' && ts.isStringLiteral(prop.initializer)) pathProp = prop.initializer.text;
        if (k === 'index' && prop.initializer.kind === ts.SyntaxKind.TrueKeyword) isIndex = true;
        if (k === 'element') {
          // element: <ComponentName ... />
          const init = prop.initializer;
          if (ts.isJsxSelfClosingElement(init)) elementType = init.tagName.getText();
          else if (ts.isJsxElement(init)) elementType = init.openingElement.tagName.getText();
        }
      }
      if (elementType && (pathProp || isIndex)) {
        out.push({ path: pathProp ?? '', component: elementType });
      }
    }
    ts.forEachChild(node, visit);
  }
  visit(sf);
  return out;
}

function humanize(s: string): string {
  return s.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/^./, c => c.toUpperCase()).trim() || s;
}
