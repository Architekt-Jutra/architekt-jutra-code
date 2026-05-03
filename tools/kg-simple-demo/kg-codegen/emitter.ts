import type { CypherEdge, CypherNode, Graph, PropVal } from './types.ts';

function escStr(s: string): string {
  return "'" + s
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\n/g, '\\n') + "'";
}

function val(v: PropVal): string {
  if (v === null) return 'null';
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  if (typeof v === 'number') return Number.isFinite(v) ? String(v) : 'null';
  if (Array.isArray(v)) return '[' + v.map(escStr).join(', ') + ']';
  return escStr(v);
}

function emitNode(n: CypherNode): string {
  const entries = Object.entries(n.properties)
    .filter(([, v]) => v !== undefined) as [string, PropVal][];
  if (entries.length === 0) return `MERGE (n:${n.label} {id: ${escStr(n.id)}});`;
  const sets = entries.map(([k, v]) => `n.${k} = ${val(v)}`).join(',\n    ');
  return `MERGE (n:${n.label} {id: ${escStr(n.id)}})\nSET ${sets};`;
}

function emitEdge(e: CypherEdge): string {
  return `MATCH (s:${e.sourceLabel} {id:${escStr(e.sourceId)}}), `
       + `(t:${e.targetLabel} {id:${escStr(e.targetId)}}) `
       + `MERGE (s)-[:${e.type}]->(t);`;
}

export function emitCypher(g: Graph, header: string[]): string {
  const labels = [...new Set(g.nodes.map(n => n.label))].sort();
  const constraints = labels.map(L =>
    `CREATE CONSTRAINT inst_${L.toLowerCase()}_id IF NOT EXISTS `
    + `FOR (n:${L}) REQUIRE n.id IS UNIQUE;`
  );

  const nodeLines: string[] = [];
  for (const L of labels) {
    nodeLines.push('', `// --- ${L} ---`);
    const xs = g.nodes.filter(n => n.label === L).sort((a, b) => a.id.localeCompare(b.id));
    for (const x of xs) nodeLines.push(emitNode(x));
  }

  const edgeLines = [...g.edges]
    .sort((a, b) =>
      a.type.localeCompare(b.type)
      || a.sourceId.localeCompare(b.sourceId)
      || a.targetId.localeCompare(b.targetId))
    .map(emitEdge);

  return [
    '// =============================================================================',
    ...header.map(h => `// ${h}`),
    '// =============================================================================',
    '',
    '// CONSTRAINTS',
    ...constraints,
    '',
    '// NODES',
    ...nodeLines,
    '',
    '// EDGES',
    ...edgeLines,
    '',
  ].join('\n');
}
