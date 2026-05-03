import fs from 'node:fs';
import YAML from 'yaml';
import type { CypherNode, CypherEdge, Graph, PropVal } from './types.ts';

interface OverrideFile {
  nodes?: Array<{
    label: string;
    id: string;
    properties?: Record<string, PropVal>;
  }>;
  edges?: Array<{
    type: string;
    from: { label: string; id: string };
    to:   { label: string; id: string };
  }>;
}

// Loads an overrides YAML and applies it on top of `parsed`. Wildcard ids
// ('*') in edges are expanded across every parsed node of that label.
export function loadOverrides(file: string, parsed: Graph): Graph {
  if (!fs.existsSync(file)) return { nodes: [], edges: [] };
  const data = YAML.parse(fs.readFileSync(file, 'utf8')) as OverrideFile;

  const nodes: CypherNode[] = (data.nodes ?? []).map(n => ({
    label: n.label,
    id: n.id,
    properties: { ...(n.properties ?? {}) },
  }));

  const edges: CypherEdge[] = [];
  const allIds = new Set([
    ...parsed.nodes.map(n => `${n.label}|${n.id}`),
    ...nodes.map(n => `${n.label}|${n.id}`),
  ]);

  for (const e of data.edges ?? []) {
    const sources = e.from.id === '*'
      ? [...parsed.nodes, ...nodes].filter(n => n.label === e.from.label).map(n => n.id)
      : [e.from.id];
    const targets = e.to.id === '*'
      ? [...parsed.nodes, ...nodes].filter(n => n.label === e.to.label).map(n => n.id)
      : [e.to.id];
    for (const sid of sources) {
      for (const tid of targets) {
        if (sid === tid && e.from.label === e.to.label) continue;
        edges.push({
          type: e.type,
          sourceLabel: e.from.label, sourceId: sid,
          targetLabel: e.to.label,   targetId: tid,
        });
      }
    }
    // Sanity: warn when explicit (non-wildcard) edges name a node nobody declared.
    if (e.from.id !== '*' && !allIds.has(`${e.from.label}|${e.from.id}`)) {
      console.warn(`overrides: edge :${e.type} references unknown ${e.from.label} '${e.from.id}'`);
    }
    if (e.to.id !== '*' && !allIds.has(`${e.to.label}|${e.to.id}`)) {
      console.warn(`overrides: edge :${e.type} references unknown ${e.to.label} '${e.to.id}'`);
    }
  }

  return { nodes, edges };
}
