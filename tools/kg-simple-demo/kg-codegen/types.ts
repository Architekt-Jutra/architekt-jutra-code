// Shared types + label mapping + small helpers used across the codegen.

export type PropVal = string | number | boolean | string[] | null;

export interface CypherNode {
  label: string;
  id: string;
  properties: Record<string, PropVal | undefined>;
}

export interface CypherEdge {
  type: string;
  sourceLabel: string;
  sourceId: string;
  targetLabel: string;
  targetId: string;
}

export interface Graph {
  nodes: CypherNode[];
  edges: CypherEdge[];
}

export const empty = (): Graph => ({ nodes: [], edges: [] });

// Merge `from` into `into`. For overlapping (label, id) nodes, properties
// merge with `from` taking precedence (overrides win over parsed defaults).
export function mergeGraph(into: Graph, from: Graph): void {
  for (const n of from.nodes) {
    const existing = into.nodes.find(x => x.label === n.label && x.id === n.id);
    if (existing) Object.assign(existing.properties, n.properties);
    else into.nodes.push({ ...n, properties: { ...n.properties } });
  }
  for (const e of from.edges) {
    const exists = into.edges.some(x =>
      x.type === e.type &&
      x.sourceLabel === e.sourceLabel && x.sourceId === e.sourceId &&
      x.targetLabel === e.targetLabel && x.targetId === e.targetId);
    if (!exists) into.edges.push(e);
  }
}

// Bridge between ontology concept ids (snake_case) and instance Neo4j labels.
export const CONCEPT_TO_LABEL: Record<string, string> = {
  system: 'System',
  actor: 'Actor',
  host: 'Host',
  frontend: 'Frontend',
  backend: 'Backend',
  core: 'Core',
  plugin_engine: 'PluginEngine',
  module: 'Module',
  entity: 'Entity',
  repository: 'Repository',
  action: 'Action',
  api_endpoints: 'APIEndpoints',
  core_page: 'CorePage',
  plugin_shell: 'PluginShell',
  plugin: 'Plugin',
  manifest: 'Manifest',
  extension_point: 'ExtensionPoint',
  filter_definition: 'FilterDefinition',
  plugin_page: 'PluginPage',
  plugin_entity: 'PluginEntity',
  extended_entity: 'ExtendedEntity',
  storage_strategy: 'StorageStrategy',
  entity_binding: 'EntityBinding',
  iframe_isolation: 'IframeIsolation',
  host_bridge: 'HostBridge',
  plugin_sdk: 'PluginSDK',
  domain_concept: 'DomainConcept',
  feature: 'Feature',
  api: 'API',
  external_system: 'ExternalSystem',
};

// Insert hyphens at camelCase boundaries, lowercase, collapse runs of non-alnum.
export function slug(s: string): string {
  return s
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/([A-Z]+)([A-Z][a-z])/g, '$1-$2')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .toLowerCase();
}
