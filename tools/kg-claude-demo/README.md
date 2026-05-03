# Knowledge Graph + Claude Code — interactive workshop

A self-contained demo for workshop participants. The point: **let people
feel** how a domain knowledge graph changes the way an agent like Claude
Code reasons about a codebase. No benchmark — just a piaskownica.

The aj product (this repo) is described in a Neo4j knowledge graph that
follows the ontology in
[`../../<your-ontology-image>`](../../). Participants ask Claude Code
questions, toggle the Neo4j MCP on and off, and watch traces in Opik.

> **Codex is out of scope here** — that's a separate ticket. This demo is
> Claude-only.

---

## What you get

```
knowledge-base/kg-claude-demo/
├── compose.yml          # Neo4j + auto-seed loader
├── Makefile             # make up / down / reset / opik-up
├── seed/
│   ├── 01_ontology.cypher    # ontology classes + constraints
│   └── 02_instances.cypher   # the actual aj knowledge
├── mcp/
│   ├── .mcp.json             # mcp-neo4j-cypher + opik MCP servers
│   └── README.md             # how to enable / toggle / verify
├── opik/
│   └── README.md             # how to run Opik + install the
│                             # opik-claude-code-plugin
└── questions/
    └── README.md             # 12 progressive questions for participants
```

---

## Prerequisites

- Docker (Desktop) — for Neo4j + Opik containers.
- `make` — comes with macOS / Linux out of the box.
- `uv` (`brew install uv`) — Claude uses `uvx` to launch the Neo4j MCP.
- `npx` / Node 18+ — Claude uses `npx` to launch the Opik MCP.
- Claude Code CLI in your `PATH`.

No Python install needed — the `~/.opik.config` file is plain INI; you
can create it by hand (shown below) or use the Opik CLI in an isolated
env via `uvx --from opik opik configure` if you prefer the official
interactive flow.

---

## First-time setup (~10 min, once per machine)

```bash
cd knowledge-base/kg-claude-demo

# 1. Neo4j + Opik in one go
make all-up
# Neo4j browser:  http://localhost:7474   user: neo4j   pass: aj-knowledge
# Opik UI:        http://localhost:5173

# 2. Tell the opik-claude-code-plugin where Opik lives
#    (Plain INI — no Python needed. The opik CLI would write the same file.)
cat > ~/.opik.config <<'EOF'
[opik]
url_override = http://localhost:5173/api
workspace = default
EOF

# 3. Start Claude in the folder with the MCP config
cd mcp && claude
```

Inside Claude — install the tracing plugin (once):

```
/plugin marketplace add comet-ml/opik-claude-code-plugin
/plugin install opik
/opik:trace-claude-code start
```

Exit Claude (`/exit`) and restart it — **plugin hooks attach only at
session start**, so the first session after `install` won't trace yet.

Done. After this initial pass, daily startup is two commands.

---

## Daily startup (~10 s)

```bash
cd knowledge-base/kg-claude-demo
make all-up                 # Neo4j + Opik (no-op if already running)
cd mcp && claude            # MCP servers + plugin auto-attach
```

In Claude:

```
/mcp                        # confirm 'neo4j-aj-kb' and 'opik' are connected
```

Then jump into [`questions/README.md`](./questions/README.md).

---

## Smoke test (~2 min — confirms everything's wired)

After daily startup, in Claude:

```
> Use the Neo4j tool to return the schema of the knowledge graph.
```

You should see ~22 labels (System, Host, Plugin, Module, Entity, ...)
and ~17 relationship types.

Open Opik → project `Default Project` → newest trace. Click the
`claude_code.tool` span with `tool_name = mcp__neo4j-aj-kb__get_neo4j_schema` —
the input panel should show the actual MCP arguments and the output
panel should show the schema Neo4j returned.

If both checks pass, you're good to run the workshop.

---

## Full validation (~15 min — first dry-run of the workshop)

A longer end-to-end procedure for confirming the demo works after a
fresh setup or significant changes. Each step has a pass criterion;
stop at the first one that fails and check the troubleshooting section.

1. **Clean slate** — `make down && make opik-down`. `docker ps` should
   show no `kb-neo4j` and no `opik-opik-*` containers.
2. **Neo4j seed** — `make up`. In Neo4j browser, `MATCH (n) RETURN count(n)`
   returns ~120 nodes; `MATCH ()-[r]->() RETURN count(r)` returns ~240.
3. **Opik UI** — `make opik-up && make opik-verify`. Both lines say
   `HTTP 200`. http://localhost:5173 loads.
4. **Plugin tracing on** — `cd mcp && claude` → `/opik:trace-claude-code status`
   says `enabled (project)`. File `.claude/.opik-tracing-enabled` exists.
5. **MCP connected** — `/mcp` shows `neo4j-aj-kb` and `opik` both
   `connected`.
6. **First trace with visible Cypher** — ask: *"Use the Neo4j knowledge
   graph: list every REST endpoint in the aj backend and the permission
   required to call it."* In Opik, the newest trace contains a span
   `mcp__neo4j-aj-kb__read_neo4j_cypher` whose Input panel shows the
   actual Cypher query and Output panel shows the rows.
7. **With/without contrast** — `/mcp` → disable `neo4j-aj-kb` → ask
   *"If I rename the `Product` entity to `Item`, what breaks?"*. In Opik
   the trace has many `Grep` / `Read` spans. Re-enable `neo4j-aj-kb`,
   ask the same question. The new trace should be much shorter, with
   one or two `mcp__neo4j-aj-kb__read_neo4j_cypher` spans instead.
8. **Self-introspection** — *"Use the opik tool to list the last 5
   traces in the Default Project, with their span counts."* — Claude
   calls the `opik` MCP and returns a list. Confirms the second MCP
   server works.
9. **All 12 questions** — walk through `questions/README.md` Q1–Q12.
   For each: confirm Claude calls the Neo4j MCP, then run the hint
   Cypher in Neo4j Browser and confirm answers match.

If 1–7 pass, the demo is ready. 8–9 are nice-to-haves and can be done
during the workshop itself.

---

## How the workshop is supposed to feel

Two windows side by side:

| Left window | Right window |
| ----------- | ------------ |
| Claude Code talking to the participant | Opik trace view, auto-refreshing |

For each question:

1. Toggle the MCP **off** in Claude (`/mcp`). Ask the question.
2. Watch the trace in Opik — count tool calls, see token cost.
3. Toggle the MCP **on**. Ask the same question.
4. Compare. The KG-enabled trace is shorter, cheaper, and the answer is
   sharper because Claude can ask the graph instead of grepping.

That's the whole point. Participants leave with a felt sense of
"this is what a knowledge graph does for an agent" — the second case
in the training (the bug-analysis benchmark) covers the quantitative side.

---

## Common operations

| Command          | Effect                                   |
| ---------------- | ---------------------------------------- |
| `make up`        | Start Neo4j and load seed.               |
| `make reseed`    | Re-run Cypher seeds (no data wipe).      |
| `make reset`     | Wipe Neo4j volume and reload seed.       |
| `make down`      | Stop Neo4j, keep data.                   |
| `make opik-up`   | Clone (if needed) and start Opik.        |
| `make opik-down` | Stop Opik.                               |
| `make all-up`    | Neo4j + Opik in one go.                  |
| `make status`    | Show container status for both stacks.   |

---

## Customizing for a different product

The seed is intentionally hand-written so it's transparent and easy to
diff. To adapt to a different codebase:

1. Keep `seed/01_ontology.cypher` mostly as-is — the ontology is generic
   enough for any plugin/microkernel app.
2. Rewrite `seed/02_instances.cypher` with `MERGE` statements for that
   product's modules, entities, repositories, controllers, endpoints,
   plugins, and pages.
3. Update the questions in `questions/README.md` to use the new entity
   names.

If the codebase is large, the seed becomes the long-term artifact — keep
it next to the code and update it like any other piece of documentation.

---

## What's intentionally NOT here

- **Auto-extraction from code.** Hand-written Cypher is faster to read,
  faster to fix, and shows the participants what the graph contains.
- **Nasde / benchmark harness.** Different ticket, different demo case.
- **Codex / other agents.** Same — separate ticket.
- **Production-grade auth on Neo4j or Opik.** It's localhost-only.

---

## Troubleshooting

**`make up` hangs at "neo4j-seed"** — wait. The seed runner only starts
once Neo4j passes its healthcheck (~30s on a cold start).

**Claude says `neo4j-aj-kb` is `failed`** — check that `uvx` is on your
PATH (`which uvx`) and that Neo4j is reachable (`docker ps | grep neo4j`).

**Opik trace doesn't show up** — confirm three things, in order:
1. `opik-claude-code-plugin` is installed (`/plugin` in Claude lists it).
2. `/opik:trace-claude-code status` says enabled for this project.
3. You restarted `claude` after the most recent toggle — hooks load at
   session start, not live.
Also: `~/.opik.config` must point at `http://localhost:5173/api`.

**Port already in use** — Neo4j uses 7474/7687, Opik uses 5173/8080/3306/
6379/8123. Edit `compose.yml` (Neo4j) or `.opik/deployment/docker-compose/.env`
(Opik) to remap.
