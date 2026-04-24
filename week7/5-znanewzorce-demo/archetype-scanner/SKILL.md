---
name: archetype-scanner
description: Scan domain requirements against all known archetypes in parallel. Launches one agent per archetype (accounting, pricing, party — extensible), collects fit/no-fit results, then merges into a single summary. Produces fit/ directory with individual archetype results and a combined report.
argument-hint: "[domain requirements or feature description]"
---

# Archetype Scanner

Run all known archetype mappers against a single set of domain requirements **in parallel**. Each archetype agent independently performs its fit test and — if the archetype fits — produces a full mapping. A merge agent then consolidates everything into one document.

**Output goal**: A single directory (`fit/`) containing individual archetype results (only for archetypes that fit) and a merged summary showing which archetypes matched, which didn't, and how domain concepts distribute across matched archetypes.

## When to Use

- Early domain modeling — "which archetypes apply to these requirements?"
- Requirements review — systematically check for known patterns
- Training / workshops — demonstrate archetype recognition on real requirements
- Before detailed modeling — narrow down which archetype mapper to dive deeper into

## When NOT to Use

- You already know which single archetype to apply → use that mapper directly
- Requirements are too vague for any archetype to assess (no concrete operations described)

---

## Archetype Registry

Each entry maps to an existing `*-archetype-mapper` skill. To add a new archetype, add a row here.

| ID | Skill Name | One-line fit question |
|----|-----------|----------------------|
| `accounting` | `accounting-archetype-mapper` | "Can I ask 'how much X does S have?' and get a number with transaction history?" |
| `pricing` | `pricing-archetype-mapper` | "Is there a computed price/rate that depends on context, time, or components?" |

**Extending**: Add a new row to this table. The workflow below iterates over all rows. No other changes needed — the parallel launch in Step 2 picks up every entry in the registry.

---

## Workflow

### Step 0: Get Requirements

- If provided as argument, use directly.
- If not, scan conversation for domain context. If found, summarize in 2–3 sentences and confirm.
- Only if nothing available, ask:
  > "Describe the domain — what entities exist, what operations change state, what values are tracked?"

Store the requirements text — it will be passed verbatim to every archetype agent.

---

### Step 1: Create Output Directory

Create directory structure:

```
fit/
├── accounting.md      # (only if fit)
├── pricing.md         # (only if fit)
├── party.md           # (only if fit)
└── summary.md         # always — merged result
```

If invoked within an orchestrator with a `task_path`, place `fit/` under `{task_path}/analysis/fit/`. Otherwise create `fit/` in the current working directory.

---

### Step 2: Launch Archetype Agents in Parallel

For **every entry** in the Archetype Registry, launch one agent. All agents launch in a **single message** for parallel execution.

Each agent:
- **Tool**: Agent tool with `subagent_type` matching the skill name from the registry
- **Prompt structure**:

```
Apply the [archetype name] archetype to the following domain requirements.

## Requirements

[paste full requirements text]

## Instructions

1. Run your fit test first.
2. If the archetype does NOT fit — return ONLY:
   ---
   archetype: [id]
   fit: false
   reason: [1-2 sentence reason]
   ---
   Do not produce a mapping. Stop here.

3. If the archetype FITS — run your full mapping workflow.
   - Ask clarifying questions via AskUserQuestion as normal.
   - Produce your complete output.
   - Prepend this header to your output:
   ---
   archetype: [id]
   fit: true
   ---

4. Write your output to: [fit_directory]/[archetype_id].md
```

**Wait for ALL agents to complete before continuing.**

---

### Step 3: Collect Results

After all agents complete:

1. Read each `fit/[id].md` file that exists
2. For agents that returned `fit: false` — note the archetype and reason
3. For agents that returned `fit: true` — note the archetype and read the full mapping

Build a results table:

| Archetype | Fit? | Key Reason / Mapped Value |
|-----------|------|---------------------------|
| accounting | Yes/No | [1-line summary] |
| pricing | Yes/No | [1-line summary] |
| party | Yes/No | [1-line summary] |

---

### Step 4: Merge — Launch Summary Agent

Delegate summary generation to a merge agent. Use the Agent tool (general-purpose):

```
You are a domain modeling summary agent. Merge archetype scan results into a single report.

## Scan Results

### Archetypes That Fit
[For each: paste archetype ID + full mapping output]

### Archetypes That Did Not Fit
[For each: archetype ID + reason]

## Requirements (original)
[paste requirements]

## Your Task

Write `summary.md` to [fit_directory]/summary.md with this structure:

# Archetype Scan: [domain name]

## Quick View

| Archetype | Fit | Core Reason |
|-----------|-----|-------------|
| ... | ✅ / ❌ | ... |

## Matched Archetypes

For each archetype that fit:
### [Archetype Name] ✅
- **What matched**: 1-2 sentences on what domain aspect this archetype covers
- **Domain value / key entity**: the central concept identified by this archetype
- **Key decisions surfaced**: list 3-5 most important clarifying questions and answers

## Domain Concept Distribution

A single table showing where EVERY significant domain concept landed:

| Domain Concept | Archetype(s) | Role in Archetype | Unmapped? |
|----------------|-------------|-------------------|-----------|
| [concept] | accounting | Account / Transaction / ... | |
| [concept] | party | Role / Relation / ... | |
| [concept] | — | — | ⚠️ Yes |

This table must include:
- Concepts mapped by exactly one archetype
- Concepts mapped by multiple archetypes (show all — this reveals overlap worth discussing)
- Concepts NOT mapped by any archetype (these need separate modeling decisions)

## Overlaps

If any domain concept appears in multiple archetypes, describe the overlap and what it means:
- Is it the same concept seen from different angles? (normal — e.g., "Customer" in party + accounting)
- Is it a conflict that needs resolution? (rare but important)

## Gaps — Not Covered by Any Archetype

List domain concepts that no archetype claimed. For each:
- What it is
- Why no archetype covers it (state machine? workflow? integration? pure CRUD?)
- Suggested next step (e.g., "consider problem-class-classifier", "model directly", "needs custom archetype")

## Archetype Rejection Reasons

For each archetype that did NOT fit, one line explaining why. This helps future readers understand what was considered and ruled out.
```

---

### Step 5: Present Results

```
Archetype scan complete.

Matched: [list of ✅ archetypes]
No fit:  [list of ❌ archetypes]

Results:
[For each matched archetype]
  - fit/[id].md — full mapping

Summary: fit/summary.md

Key findings:
- [top 2-3 insights from the summary — overlaps, gaps, surprises]
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Agent times out | Use results from completed agents; note incomplete scan in summary |
| All archetypes return no-fit | Summary still generated — focuses on gaps section and suggests next steps |
| Agent produces no output file | Treat as no-fit with reason "agent produced no output" |

---

## Integration

This skill can be invoked:
- Standalone: `/archetype-scanner [requirements]`
- From development-orchestrator: as an optional analysis step
- From workshops/training: to demonstrate parallel archetype recognition
