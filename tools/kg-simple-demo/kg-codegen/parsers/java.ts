// Java backend parser (Spring Boot conventions, regex-based).
//
// Extracts:
//   - Entity nodes from @Entity / @Table classes
//   - Repository nodes from JpaRepository<T,...> interfaces and Db*QueryService classes
//   - Action nodes from public methods of @Service classes (kind=query if @Transactional(readOnly=true) else command)
//   - APIEndpoints nodes from controller methods annotated with @GetMapping/@PostMapping/...
//   - Module nodes from package layout under pl.devstyle.aj.*
//
// Edges:
//   - Module CONTAINS Entity / Repository / Action / APIEndpoints (by package)
//   - Entity PERSISTED_BY Repository (Repository<Entity> generic + Db<Entity>QueryService convention)
//   - Entity EXPOSED_BY APIEndpoints (controller-name → entity convention, with overrides)
//   - Action OPERATES_ON Entity (service-name convention; falls back to its first injected repo)
//   - Action EXPOSED_BY APIEndpoints (controller method body delegates to service.method)
import fs from 'node:fs';
import fg from 'fast-glob';
import type { CypherEdge, CypherNode, Graph } from '../types.ts';
import { slug } from '../types.ts';

const HTTP_ANNOTS: Record<string, string> = {
  GetMapping: 'GET',
  PostMapping: 'POST',
  PutMapping: 'PUT',
  PatchMapping: 'PATCH',
  DeleteMapping: 'DELETE',
};

// Controller class -> primary entity class. Handles cases where the controller
// name does not equal the entity name (PluginController -> PluginDescriptor,
// PluginDataController -> Product).
const CONTROLLER_TO_ENTITY: Record<string, string> = {
  Category: 'Category',
  Product: 'Product',
  Plugin: 'PluginDescriptor',
  PluginData: 'Product',
  PluginObject: 'PluginObject',
};

interface MethodInfo {
  name: string;
  isReadOnly?: boolean;
  httpMethod?: string;
  uriSuffix?: string;
  body?: string;
}

interface ClassInfo {
  filePath: string;
  packageName: string;
  className: string;
  fqcn: string;
  isEntity: boolean;
  tableName?: string;
  isService: boolean;
  isRestController: boolean;
  isRepoInterface: boolean;
  repoEntity?: string;
  classBaseUri?: string;
  methods: MethodInfo[];
  injectedFields: { type: string; name: string }[];
}

export async function parseJava(srcRoot: string): Promise<Graph> {
  const files = await fg(['**/*.java'], { cwd: srcRoot, absolute: true });
  const classes: ClassInfo[] = [];
  for (const f of files) {
    const c = readClass(f);
    if (c) classes.push(c);
  }
  return buildGraph(classes);
}

function readClass(file: string): ClassInfo | null {
  const text = fs.readFileSync(file, 'utf8');
  const pkg = text.match(/^\s*package\s+([\w.]+)\s*;/m);
  if (!pkg) return null;

  // First class/interface declaration (top-level only).
  const decl = text.match(/(?:^|\n)(?:public\s+)?(class|interface)\s+(\w+)/);
  if (!decl) return null;
  const isInterface = decl[1] === 'interface';
  const className = decl[2]!;
  const packageName = pkg[1]!;

  const c: ClassInfo = {
    filePath: file,
    packageName,
    className,
    fqcn: `${packageName}.${className}`,
    isEntity: /@Entity\b/.test(text),
    tableName: text.match(/@Table\s*\(\s*name\s*=\s*"([^"]+)"/)?.[1],
    isService: /@Service\b/.test(text),
    isRestController: /@RestController\b/.test(text),
    isRepoInterface: false,
    methods: [],
    injectedFields: [],
  };

  // Class-level @RequestMapping (search header before the class declaration).
  if (c.isRestController) {
    const head = text.slice(0, decl.index ?? 0);
    c.classBaseUri = head.match(/@RequestMapping\s*\(\s*"([^"]+)"\s*\)/)?.[1];
  }

  // JpaRepository extension.
  if (isInterface) {
    const ext = text.match(/extends\s+JpaRepository\s*<\s*(\w+)\s*,/);
    if (ext) {
      c.isRepoInterface = true;
      c.repoEntity = ext[1];
    }
  }

  // Constructor-injected fields (private final XxxService xxxService).
  for (const m of text.matchAll(/private\s+final\s+(\w+)\s+(\w+)\s*;/g)) {
    c.injectedFields.push({ type: m[1]!, name: m[2]! });
  }

  if (c.isService || c.isRestController) c.methods = extractMethods(text);

  return c;
}

function extractMethods(text: string): MethodInfo[] {
  const out: MethodInfo[] = [];
  const lines = text.split('\n');
  let annBuf: string[] = [];
  for (let i = 0; i < lines.length; i++) {
    const ln = lines[i]!.trim();
    if (ln.startsWith('@')) { annBuf.push(ln); continue; }
    if (ln === '' || ln.startsWith('//') || ln.startsWith('*') || ln.startsWith('/*')) continue;

    const head = ln.match(/^public\s+[\w<>?,\s\[\]]+?\s+(\w+)\s*\(/);
    if (head) {
      const name = head[1]!;
      const annText = annBuf.join('\n');
      const httpAnn = Object.keys(HTTP_ANNOTS).find(k => annText.includes(`@${k}`));
      let httpMethod: string | undefined;
      let uriSuffix: string | undefined;
      if (httpAnn) {
        httpMethod = HTTP_ANNOTS[httpAnn];
        const re = new RegExp(`@${httpAnn}\\s*(?:\\(\\s*(?:value\\s*=\\s*)?"([^"]*)"\\s*\\))?`);
        uriSuffix = annText.match(re)?.[1] ?? '';
      }
      const isReadOnly = /@Transactional\s*\(\s*readOnly\s*=\s*true\s*\)/.test(annText);

      // Capture method body until matching brace closes.
      const bodyLines: string[] = [lines[i]!];
      let depth = countChar(lines[i]!, '{') - countChar(lines[i]!, '}');
      let j = i + 1;
      while (j < lines.length && depth > 0) {
        bodyLines.push(lines[j]!);
        depth += countChar(lines[j]!, '{') - countChar(lines[j]!, '}');
        j++;
      }
      out.push({ name, isReadOnly, httpMethod, uriSuffix, body: bodyLines.join('\n') });
      annBuf = [];
    } else {
      annBuf = [];
    }
  }
  return out;
}

function countChar(s: string, ch: string): number {
  let n = 0;
  for (const c of s) if (c === ch) n++;
  return n;
}

// --- module assignment ---------------------------------------------------------

const MODULE_PACKAGES: Array<{ id: string; name: string; pkg: string }> = [
  { id: 'mod-category',    name: 'Category Module',    pkg: 'pl.devstyle.aj.category' },
  { id: 'mod-product',     name: 'Product Module',     pkg: 'pl.devstyle.aj.product' },
  { id: 'mod-plugin-core', name: 'Plugin Core Module', pkg: 'pl.devstyle.aj.core.plugin' },
  { id: 'mod-api',         name: 'API Surface Module', pkg: 'pl.devstyle.aj.api' },
];

function moduleFor(pkg: string): { id: string; name: string; pkg: string } | null {
  return MODULE_PACKAGES
    .filter(m => pkg === m.pkg || pkg.startsWith(m.pkg + '.'))
    .sort((a, b) => b.pkg.length - a.pkg.length)[0] ?? null;
}

// --- graph builder -------------------------------------------------------------

function buildGraph(classes: ClassInfo[]): Graph {
  const nodes: CypherNode[] = [];
  const edges: CypherEdge[] = [];

  // Always emit the four module nodes (so empty modules still appear).
  for (const m of MODULE_PACKAGES) {
    nodes.push({ label: 'Module', id: m.id, properties: { name: m.name, package: m.pkg } });
  }

  // Entities.
  const entityIdByClass = new Map<string, string>();
  for (const c of classes.filter(c => c.isEntity)) {
    const id = `entity-${slug(c.className)}`;
    nodes.push({ label: 'Entity', id, properties: {
      name: c.className, fqcn: c.fqcn, table: c.tableName ?? null,
    }});
    entityIdByClass.set(c.className, id);
    const m = moduleFor(c.packageName);
    if (m) edges.push(edge('CONTAINS', 'Module', m.id, 'Entity', id));
  }

  // Repositories: JpaRepository interfaces.
  const repoIdByClass = new Map<string, string>();
  const repoEntityByClass = new Map<string, string>();
  for (const c of classes.filter(c => c.isRepoInterface)) {
    const id = `repo-${slug(c.className.replace(/Repository$/, ''))}`;
    nodes.push({ label: 'Repository', id, properties: {
      name: c.className, fqcn: c.fqcn, kind: 'JpaRepository',
    }});
    repoIdByClass.set(c.className, id);
    if (c.repoEntity) repoEntityByClass.set(c.className, c.repoEntity);
    // Module CONTAINS Repository is intentionally NOT emitted — the ontology
    // does not declare that rule (the meaningful link is Entity PERSISTED_BY Repository).
    if (c.repoEntity && entityIdByClass.has(c.repoEntity)) {
      edges.push(edge('PERSISTED_BY', 'Entity', entityIdByClass.get(c.repoEntity)!, 'Repository', id));
    }
  }

  // Repositories: Db*QueryService classes (jOOQ).
  for (const c of classes.filter(c => /^Db.*QueryService$/.test(c.className) && c.isService)) {
    const id = `repo-${slug(c.className)}`;
    nodes.push({ label: 'Repository', id, properties: {
      name: c.className, fqcn: c.fqcn, kind: 'jOOQ DSLContext',
    }});
    repoIdByClass.set(c.className, id);
    // DbXxxQueryService -> Xxx entity, when present.
    const inferred = c.className.replace(/^Db/, '').replace(/QueryService$/, '');
    if (inferred && entityIdByClass.has(inferred)) {
      edges.push(edge('PERSISTED_BY', 'Entity', entityIdByClass.get(inferred)!, 'Repository', id));
    }
  }

  // Actions: public methods of @Service classes (excluding Db*QueryService — those are repositories).
  const actionByQName = new Map<string, string>(); // ServiceClass.method -> action id
  for (const c of classes.filter(c => c.isService && !/^Db.*QueryService$/.test(c.className))) {
    const m = moduleFor(c.packageName);
    const stripped = c.className.replace(/Service$/, '');

    // Primary entity for this service: name match first, then first injected repo's entity.
    let primaryEntity: string | undefined = entityIdByClass.has(stripped) ? stripped : undefined;
    if (!primaryEntity) {
      for (const f of c.injectedFields) {
        const e = repoEntityByClass.get(f.type);
        if (e && entityIdByClass.has(e)) { primaryEntity = e; break; }
      }
    }

    for (const meth of c.methods) {
      const id = `action-${slug(stripped)}-${meth.name.toLowerCase()}`;
      nodes.push({ label: 'Action', id, properties: {
        name: `${c.className}.${meth.name}`,
        kind: meth.isReadOnly ? 'query' : 'command',
      }});
      actionByQName.set(`${c.className}.${meth.name}`, id);
      if (m) edges.push(edge('CONTAINS', 'Module', m.id, 'Action', id));
      if (primaryEntity) {
        edges.push(edge('OPERATES_ON', 'Action', id, 'Entity', entityIdByClass.get(primaryEntity)!));
      }
    }
  }

  // API Endpoints + EXPOSED_BY edges from controllers.
  for (const c of classes.filter(c => c.isRestController)) {
    const m = moduleFor(c.packageName);
    const base = c.classBaseUri ?? '';
    const ctrlPrefix = c.className.replace(/Controller$/, '');
    const entityName = CONTROLLER_TO_ENTITY[ctrlPrefix];

    for (const meth of c.methods) {
      if (!meth.httpMethod) continue;
      const id = `api-${slug(ctrlPrefix)}-${meth.name.toLowerCase()}`;
      const uri = base + (meth.uriSuffix ?? '');
      nodes.push({ label: 'APIEndpoints', id, properties: {
        method: meth.httpMethod,
        uri,
        handler: `${c.className}.${meth.name}`,
      }});
      if (m) edges.push(edge('CONTAINS', 'Module', m.id, 'APIEndpoints', id));

      if (entityName && entityIdByClass.has(entityName)) {
        edges.push(edge('EXPOSED_BY', 'Entity', entityIdByClass.get(entityName)!, 'APIEndpoints', id));
      }

      // Action EXPOSED_BY APIEndpoints — by service.method call inside controller method body.
      if (meth.body) {
        // Look at all *Service.method( call sites in the body, take the first that matches a known action.
        for (const callMatch of meth.body.matchAll(/(\w+(?:Service|QueryService))\.(\w+)\s*\(/g)) {
          const qn = `${callMatch[1]}.${callMatch[2]}`;
          const aId = actionByQName.get(qn);
          if (aId) {
            edges.push(edge('EXPOSED_BY', 'Action', aId, 'APIEndpoints', id));
            break;
          }
        }
      }
    }
  }

  return { nodes, edges };
}

function edge(type: string, sl: string, sid: string, tl: string, tid: string): CypherEdge {
  return { type, sourceLabel: sl, sourceId: sid, targetLabel: tl, targetId: tid };
}
