# Opik — Claude Code observability

[Opik](https://www.comet.com/docs/opik/) (by Comet) is the mirror that
workshop participants look into while they chat with Claude. We use the
**[opik-claude-code-plugin](https://github.com/comet-ml/opik-claude-code-plugin)**
to capture sessions — not raw OpenTelemetry. Reason: the plugin uses
Claude Code hooks, so it sees the **un-redacted** payloads (real prompts,
real tool names, real tool arguments — including the Cypher query sent to
the Neo4j MCP). The OTLP route exports anonymized spans where MCP arguments
are dropped; useless for the workshop.

Each conversation turn becomes one Opik trace. Each tool call becomes a
span underneath. Subagents nest as child spans. Both the user prompt and
the full tool input/output are visible in the UI.

## Bring Opik up

From the parent `kg-claude-demo/` folder:

```bash
make opik-up
```

This clones https://github.com/comet-ml/opik into `.opik/` (gitignored)
and runs the upstream `./opik.sh`. First run downloads ~2 GB of images.
Subsequent runs are seconds.

UI: http://localhost:5173 — log in with the credentials shown on the
login page (the bundled deployment seeds an `admin@aj.local / admin123`
user).

## Install the plugin in Claude Code

Inside a Claude Code session:

```
/plugin marketplace add comet-ml/opik-claude-code-plugin
/plugin install opik
```

Restart `claude` after install — hooks only attach at session start.

## Point the plugin at the local Opik

The plugin reads `~/.opik.config` (a plain INI file). Easiest way:

```bash
cat > ~/.opik.config <<'EOF'
[opik]
url_override = http://localhost:5173/api
workspace = default
EOF
```

If you prefer the official path, `uvx --from opik opik configure`
writes the same file interactively (no global Python install — `uv`
runs it in an isolated env). The heredoc above just skips the
intermediate tool.

(Optional) Tag traces from this workshop so they don't mix with
anything else:

```bash
export OPIK_CC_PROJECT="aj-kb-demo"
```

## Turn tracing on for the demo project

In Claude, from the worktree root:

```
/opik:trace-claude-code start
```

This writes `.claude/.opik-tracing-enabled` so tracing is scoped to this
project only. Use `--global` if you want it everywhere.

```
/opik:trace-claude-code status      # confirm it's on
/opik:trace-claude-code stop        # turn off without uninstalling
```

After `start` you must restart `claude` for hooks to load.

## Bonus: query Opik from inside Claude

The plugin doc also lists an `opik` MCP server (`opik-mcp` via `npx`) so
Claude can answer questions like "how many tool calls did the last turn
make?" by calling Opik's API directly. We've pre-configured it in
`../mcp/.mcp.json`. After restarting Claude, run `/mcp` and trust both
servers (`neo4j-aj-kb` for the knowledge graph, `opik` for trace
introspection).

## Workshop flow

1. Open Opik (http://localhost:5173) in a browser tab.
2. In Claude, disable `neo4j-aj-kb` via `/mcp`.
3. Ask Q3 from `../questions/README.md` ("If I rename `Product`, what
   breaks?").
4. Watch the trace land in Opik — you'll see Claude grepping/reading
   files, with the actual file names visible on each span.
5. Re-enable `neo4j-aj-kb`. Ask Q3 again.
6. Compare. The KG-enabled run should have one or two
   `mcp__neo4j-aj-kb__read_neo4j_cypher` spans with the actual Cypher
   query visible — instead of a dozen Read/Grep spans.

## Caveats

- The plugin auto-truncates very long fields. Set
  `OPIK_CC_TRUNCATE_FIELDS=false` if you want full payloads at the cost
  of larger traces.
- `/opik:trace-claude-code start` writes a marker file, not env vars.
  Hooks only re-read this on session start, so always restart Claude
  after toggling.
- `make opik-up` and the plugin install are independent steps — the
  Opik backend can be running without the plugin, and vice versa.
- **Tested 2026-04-29**: full Opik stack came up cleanly on macOS /
  Docker 29.4.1. Plugin install path verified end-to-end is the
  participant's responsibility on first dry-run.
