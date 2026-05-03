// CLI orchestrator. Parses src/ + plugins/, merges with overrides.yaml,
// validates against ontology, and writes a timestamped seed cypher file.
//
// Usage:
//   npx tsx index.ts                               # uses defaults below
//   npx tsx index.ts --root ../..                  # explicit project root
//   npx tsx index.ts --out-dir ../../generated     # output directory
//   npx tsx index.ts --check                       # validate only (no write)
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';
import { emitCypher } from './emitter.ts';
import { loadOntology, validate } from './validator.ts';
import { loadOverrides } from './overrides.ts';
import { parseJava } from './parsers/java.ts';
import { parseFrontend } from './parsers/frontend.ts';
import { parsePlugins } from './parsers/plugins.ts';
import { empty, mergeGraph } from './types.ts';

interface CliArgs {
  root: string;
  ontologyJson: string;
  overridesYaml: string;
  outDir: string;
  outName?: string;
  check: boolean;
}

function parseArgs(argv: string[]): CliArgs {
  const here = path.dirname(url.fileURLToPath(import.meta.url));
  const defaultRoot = path.resolve(here, '..', '..');
  const args: CliArgs = {
    root:          defaultRoot,
    ontologyJson:  '',
    overridesYaml: path.join(here, 'overrides.yaml'),
    outDir:        '',
    check:         false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]!;
    const next = () => argv[++i];
    switch (a) {
      case '--root':       args.root          = path.resolve(next()!); break;
      case '--ontology':   args.ontologyJson  = path.resolve(next()!); break;
      case '--overrides':  args.overridesYaml = path.resolve(next()!); break;
      case '--out-dir':    args.outDir        = path.resolve(next()!); break;
      case '--out':        args.outName       = next()!; break;
      case '--check':      args.check         = true; break;
      case '-h':
      case '--help':
        printHelp(); process.exit(0);
      default:
        console.error(`unknown argument: ${a}`); process.exit(2);
    }
  }
  if (!args.ontologyJson) args.ontologyJson = path.join(args.root, 'aj-kg-ontology.json');
  if (!args.outDir)       args.outDir = args.root;
  return args;
}

function printHelp(): void {
  console.log(`aj-kg-codegen — generate instance seed cypher from src/ + plugins/

Options:
  --root <dir>        project root (default: parent of tools/kg-codegen)
  --ontology <file>   path to aj-kg-ontology.json (default: <root>/aj-kg-ontology.json)
  --overrides <file>  path to overrides.yaml (default: alongside this script)
  --out-dir <dir>     where to write the seed (default: <root>)
  --out <name>        explicit filename (default: aj-kg-seed.<timestamp>.cypher)
  --check             parse + validate but do not write
  -h, --help          show this help`);
}

function timestamp(d = new Date()): string {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}`
    + `-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  console.log(`kg-codegen: root=${args.root}`);

  const javaSrc     = path.join(args.root, 'src', 'main', 'java');
  const frontendDir = path.join(args.root, 'src', 'main', 'frontend');
  const pluginsDir  = path.join(args.root, 'plugins');

  if (!fs.existsSync(javaSrc))     throw new Error(`Java source missing: ${javaSrc}`);
  if (!fs.existsSync(frontendDir)) throw new Error(`Frontend missing: ${frontendDir}`);
  if (!fs.existsSync(pluginsDir))  throw new Error(`Plugins dir missing: ${pluginsDir}`);

  const javaGraph     = await parseJava(javaSrc);
  const frontendGraph = await parseFrontend(frontendDir);
  const pluginsGraph  = await parsePlugins(pluginsDir);

  const parsed = empty();
  mergeGraph(parsed, javaGraph);
  mergeGraph(parsed, frontendGraph);
  mergeGraph(parsed, pluginsGraph);

  const overrides = loadOverrides(args.overridesYaml, parsed);
  const final = empty();
  mergeGraph(final, parsed);
  mergeGraph(final, overrides);

  // Validation
  const ontology = loadOntology(args.ontologyJson);
  const report   = validate(final, ontology);

  for (const w of report.warnings) console.warn(`warn: ${w}`);
  for (const e of report.errors)   console.error(`error: ${e}`);

  console.log(`kg-codegen: ${final.nodes.length} nodes, ${final.edges.length} edges`);
  console.log(`            (parsed=${parsed.nodes.length} nodes / ${parsed.edges.length} edges,`
            + ` overrides=${overrides.nodes.length} nodes / ${overrides.edges.length} edges)`);
  if (report.errors.length > 0) {
    console.error(`kg-codegen: ${report.errors.length} ontology violation(s) — failing.`);
    process.exit(1);
  }

  if (args.check) {
    console.log(`kg-codegen: --check passed`);
    return;
  }

  const filename = args.outName ?? `aj-kg-seed.${timestamp()}.cypher`;
  const outFile = path.join(args.outDir, filename);
  const cypher = emitCypher(final, [
    `AJ Platform — Knowledge Graph Instance Seed (auto-generated)`,
    `Generated at ${new Date().toISOString()}`,
    `Source: ${path.relative(args.root, javaSrc)} + ${path.relative(args.root, frontendDir)} + ${path.relative(args.root, pluginsDir)}`,
    `Overrides: ${path.relative(args.root, args.overridesYaml)}`,
    `Ontology:  ${path.relative(args.root, args.ontologyJson)}`,
  ]);
  fs.writeFileSync(outFile, cypher);
  console.log(`kg-codegen: wrote ${path.relative(process.cwd(), outFile)}`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
