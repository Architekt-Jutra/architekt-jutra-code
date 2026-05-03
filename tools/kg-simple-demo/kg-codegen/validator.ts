import fs from 'node:fs';
import { CONCEPT_TO_LABEL, type Graph } from './types.ts';

interface OntologyJSON {
  nodes: { id: string; label: string }[];
  relationships: { source: string; target: string; type: string }[];
}

export interface OntologyIndex {
  knownLabels: Set<string>;
  allowedEdges: Set<string>;
}

const k = (s: string, t: string, r: string) => `${s}|${t}|${r}`;

export function loadOntology(file: string): OntologyIndex {
  const raw = JSON.parse(fs.readFileSync(file, 'utf8')) as OntologyJSON;
  const knownLabels = new Set<string>();
  for (const n of raw.nodes) {
    const L = CONCEPT_TO_LABEL[n.id];
    if (L) knownLabels.add(L);
  }
  const allowedEdges = new Set<string>();
  for (const r of raw.relationships) {
    const sl = CONCEPT_TO_LABEL[r.source];
    const tl = CONCEPT_TO_LABEL[r.target];
    if (sl && tl) allowedEdges.add(k(sl, tl, r.type));
  }
  return { knownLabels, allowedEdges };
}

export interface ValidationReport {
  errors: string[];
  warnings: string[];
}

export function validate(g: Graph, ont: OntologyIndex): ValidationReport {
  const errors: string[] = [];
  const warnings: string[] = [];

  for (const n of g.nodes) {
    if (!ont.knownLabels.has(n.label)) {
      warnings.push(`Node '${n.id}' uses label '${n.label}' not declared by ontology`);
    }
  }

  const idToLabel = new Map(g.nodes.map(n => [n.id, n.label]));
  for (const e of g.edges) {
    const actualSrc = idToLabel.get(e.sourceId);
    const actualTgt = idToLabel.get(e.targetId);
    if (!actualSrc) {
      errors.push(`Edge :${e.type} references unknown source '${e.sourceId}'`);
      continue;
    }
    if (!actualTgt) {
      errors.push(`Edge :${e.type} references unknown target '${e.targetId}'`);
      continue;
    }
    if (actualSrc !== e.sourceLabel) {
      errors.push(`Edge :${e.type} source label mismatch: declared ${e.sourceLabel}, actual ${actualSrc} for '${e.sourceId}'`);
      continue;
    }
    if (actualTgt !== e.targetLabel) {
      errors.push(`Edge :${e.type} target label mismatch: declared ${e.targetLabel}, actual ${actualTgt} for '${e.targetId}'`);
      continue;
    }
    if (!ont.allowedEdges.has(k(e.sourceLabel, e.targetLabel, e.type))) {
      errors.push(`Edge (${e.sourceLabel} '${e.sourceId}')-[:${e.type}]->(${e.targetLabel} '${e.targetId}') is not allowed by ontology`);
    }
  }

  return { errors, warnings };
}
