---
name: research-gatherer
description: Lightweight research workflow that collects and cross-verifies information from multiple sources without synthesizing into a report. Produces raw findings with summary and cross-source verification. Reuses research-planner and information-gatherer subagents.
argument-hint: "[question] [--yolo] [--type=TYPE]"
---

# Research Gatherer

Collect and verify information from multiple sources. Stops after gathering and merge — no synthesis

## Initialization

**BEFORE executing any phase, you MUST complete these steps:**

### Step 1: Load Framework Patterns

**Read NOW using the Read tool:**
1. `../orchestrator-framework/references/orchestrator-patterns.md` - Delegation rules, interactive mode, state schema

### Step 2: Initialize Workflow

1. **Create Task Items**: Use `TaskCreate` for all 3 phases (see Phase Configuration), then set dependencies with `TaskUpdate addBlockedBy`
2. **Create Task Directory**: `.maister/tasks/research/YYYY-MM-DD-task-name/`
3. **Initialize State**: Create `orchestrator-state.yml`

**Output**:
```
Research Gatherer Started

Task: [research question]
Mode: [Interactive/YOLO]
Directory: [task-path]

Starting Phase 1: Initialize...
```

---

## When to Use

Use when:
- Need raw findings from multiple sources without synthesis
- Want to collect data for manual analysis
- Building a research corpus for later use
- Need cross-source verification but not a polished report

**For full research with synthesis and report**: Use `research-orchestrator` instead.

---

## Local References

| File | When to Use | Purpose |
|------|-------------|---------|
| `references/research-methodologies.md` | Phase 2 | Research type classification, methodology selection, gathering strategies |

---

## Phase Configuration

| Phase | content | activeForm | Agent/Skill |
|-------|---------|------------|-------------|
| 1 | "Initialize research" | "Initializing research" | Direct |
| 2 | "Plan and gather" | "Planning and gathering" | research-planner + information-gatherer (xN) |
| 3 | "Merge and verify" | "Merging and verifying findings" | Direct |

---

## Research Types

| Type | Keywords | Focus | Requires Web Research |
|------|----------|-------|----------------------|
| **Internal** | "how does our system", "what are requirements", "what problems exist", "what do users say", "what's in the codebase" | Codebase, docs, tickets, transcripts | No |
| **External** | "best practices", "industry standards", "competitors", "how others do it", "state of the art" | Web, frameworks, standards, competitor analysis | **Yes** |
| **Mixed** | Combination of above, or broad questions spanning internal and external | Both internal evidence and external context | **Yes** |

### Classification Rules

**CRITICAL — External research triggers**: If the question mentions ANY of these, type MUST be `mixed` (not `internal`):
- Competitors, competition, market, industry, "similar features", "how others do it"
- Named external products or companies (e.g., "Birdeye", "Yext")
- "Best practices", "industry standards", "state of the art"
- Comparison with external solutions
- Pricing, market positioning, feature parity

**Why**: Only `mixed` and `external` types trigger web research via `information-gatherer` agents with `WebSearch`/`WebFetch`. Classifying as `internal` when the question asks about competitors means no web agent is launched, and competitor analysis is fabricated from training data instead of researched from current sources.

**Self-check after classification**:
1. Re-read the research question
2. Ask: "Does answering this FULLY require information from outside the organization?"
3. If yes → type MUST be `mixed` or `external`
4. Ask: "Does answering this require ANY internal sources?"
5. If yes and type is `external` → change to `mixed`
6. If the question has BOTH local aspects (transcript, codebase) AND external aspects (competitors, market) → type is `mixed`

---

## Anti-Patterns

**NEVER do any of the following. These are the most common workflow violations.**

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Writing findings files directly instead of launching information-gatherer agents | Bypasses systematic gathering, misses sources, no citations | Launch `information-gatherer` subagents via Task tool |
| Skipping research-planner and deciding categories yourself | Planner detects external research needs, actors, layers — you will miss them | Always invoke `research-planner` via Task tool in Phase 2A |
| Classifying as `requirements` when question mentions competitors/market | No web research agent will be launched, competitor data fabricated from memory | Classify as `mixed` — triggers external gathering category |
| "Sources are just local files, no need for subagents" | Even with 2 local files, the planner may detect need for external research you didn't anticipate | Always delegate. Planner analyzes the QUESTION, not just the sources you already know about |
| Skipping `-> Pause` in interactive mode | User loses ability to review classification, scope, and gathered data before next phase | MUST use `AskUserQuestion` at every `-> Pause` marker |
| Proceeding to Phase 3 without verifying Phase 2 artifacts exist | Merge will produce empty/hallucinated summary | Check: `research-plan.md`, `sources.md`, and at least one `findings/*.md` file must exist |

---

## Workflow Phases

### Phase 1: Initialize

**Purpose**: Parse question, classify type, define scope
**Execute**: Direct
**Output**: `planning/research-brief.md`, `orchestrator-state.yml`

1. Parse research question (from command or prompt user)
2. Classify research type (auto-detect from keywords or use `--type` flag)
3. **SELF-CHECK classification** (mandatory):
   - Re-read the question: does it mention competitors, market, external products, industry, or anything requiring web research?
   - If YES and type is not `mixed` or `literature` → **change type to `mixed`**
   - Log: "Classification self-check: [question aspect] requires external research → type set to mixed"
4. Determine scope (included, excluded, constraints)
5. Define success criteria
6. Create research brief → `planning/research-brief.md`
7. Create directories: `planning/`, `analysis/findings/`
8. Update state: set `research_context.research_type`, `research_question`, `scope`

---

-> Pause

**Interactive**: AskUserQuestion - "Research initialized. Continue to planning and gathering?"
**YOLO**: "-> Continuing to Phase 2..."

---

### Phase 2: Plan and Gather

**Purpose**: Plan methodology, identify sources, gather from all sources in parallel
**Execute**: research-planner + N x information-gatherer (parallel)
**Output**: `planning/research-plan.md`, `planning/sources.md`, `analysis/findings/*.md`

#### Step A: Plan (Subagent) — MANDATORY DELEGATION

**Read `references/research-methodologies.md` NOW using the Read tool**

**INVOKE NOW**: Use Task tool with `subagent_type: research-planner`

**NEVER skip this step.** Do NOT decide categories, methodology, or sources yourself. The research-planner analyzes the QUESTION and detects needs you may miss (e.g., external web research for competitor analysis, actors, information layers). Even if sources seem obvious, the planner's analysis is required.

**Context to pass**: task_path, research_brief_path, research_type, research_question, scope

**After planner completes**:
1. Read `planning/research-plan.md` — verify it exists and has a Gathering Strategy section
2. Read `planning/sources.md` — verify it exists
3. Update state: `research_context.methodology`, `sources`, `gathering_strategy`
4. If files missing → retry (max 2 attempts per Auto-Recovery table)

#### Step B: Gather (Parallel Subagents) — MANDATORY DELEGATION

**NEVER write findings files yourself.** Information-gatherer agents do the gathering — they have specialized tools (WebSearch, WebFetch for external; Glob, Grep, Read for codebase) and follow systematic evidence-based collection with citations.

**Determine gatherer count and categories**:
1. Read `planning/research-plan.md` for **Gathering Strategy** section
2. If gathering strategy found: use specified categories and count (cap at 8 max)
3. If no gathering strategy: fall back to default 4 categories (codebase, documentation, configuration, external)

**CRITICAL: Launch all N agents in ONE message for parallel execution.**

Each agent gets:
- `subagent_type: information-gatherer-lite`
- `source_category=[category_id]`
- Path to `research-plan.md` and `sources.md`
- Instruction: filter sources.md to YOUR category only
- Output to: `analysis/findings/[prefix]-*.md`

**For local-source agents only** (categories reading transcripts, meeting notes, interviews, internal docs): include the following instruction in the agent prompt:

```
## Declarative Conclusions

When a speaker states a conclusion, judgment, or assessment as fact, tag it as a
**declarative conclusion** — a claim made by a person, not a verified truth.

### Analytical Impact Filter — APPLY FIRST

Only tag a statement as a declarative conclusion if it could **distort an analytical
finding** when taken at face value. Ask: "If I accept this claim uncritically, could
it lead me to a wrong conclusion in the research output?"

**Tag these** (analytically dangerous):
- "These are things done in isolation" — if wrong, architecture decisions based on it fail
- "Nobody likes the navigation" — if wrong, UX redesign priority is misallocated

**Do NOT tag these** (analytically harmless):
- "I wrote XYZ in five weekends" — someone boasting about their side project.
  Even if exaggerated, no analytical conclusion depends on the exact weekend count.
- Pure opinions about people's competence or character

**Rule of thumb**: If the claim is someone bragging, venting, or using hyperbole,
and your analytical findings would be identical regardless of whether the claim is
literally true, skip it. Reserve declarative conclusion tagging for claims that
**shape the research output** — problem classification, architecture decisions,
priority assessment, or scope determination.

### Tagging Process (for claims that pass the filter)

For each declarative conclusion found:
1. Quote the statement verbatim with speaker + timestamp
2. Tag it: `[DECLARATIVE: speaker_name]`
3. Search the surrounding context for **supporting reasons** the speaker gave
   (or that other participants confirmed). Quote those too.
4. If NO reasons are given — note: "Stated without justification in this source"

Collect all declarative conclusions in a dedicated `## Declarative Conclusions`
section at the end of your findings file, structured as:

| # | Claim | Speaker | Timestamp | Supporting Reasons (quoted) | Unsupported? |
|---|-------|---------|-----------|----------------------------|--------------|


IMPORTANT: If you draw your own conclusions based on a declarative conclusion,
your derived conclusion inherits the uncertainty of its source. Mark it:
`[DERIVED FROM DECLARATIVE #N — confidence ceiling: same as source verdict]`
A logical derivation from an uncertain premise remains uncertain.
```

Wait for ALL agents to complete before continuing.

**Post-gather validation**: Check that at least one findings file exists per launched agent. If an agent produced no files, log it as a gap.

---

-> Pause

**Interactive**: AskUserQuestion - "All sources gathered. Continue to merge and verification?"
**YOLO**: "-> Continuing to Phase 3..."

---

### Phase 3: Merge and Verify

**Purpose**: Consolidate findings from all categories, cross-verify between sources, produce per-actor tailored output
**Execute**: Direct
**Output**: `analysis/findings/00-summary.md`, `analysis/findings/98-rejected.md`, `analysis/findings/99-verification.md`, `analysis/findings/97-actor-map.md` (if actors exist)

#### Step A: Generate Summary (`00-summary.md`)

1. List all files in `analysis/findings/`
2. Read all category-specific findings files
3. Create unified summary:
   - Research question (from brief)
   - Sources investigated per category (with counts)
   - Key findings per category
   - Gaps and uncertainties

#### Step B: Generate Cross-Source Verification (`99-verification.md`)

1. Cross-reference findings across categories
2. Compare findings between source types (e.g., code vs docs, internal vs external)
3. Identify contradictions
4. Assess confidence levels (High / Medium / Low) per finding
5. Document missing information
6. **Consolidate Declarative Conclusions** (see below)

**Declarative Conclusions section in `99-verification.md`**:

Collect all `## Declarative Conclusions` tables from local-source findings files. **Apply the analytical impact filter again** during consolidation — gatherers may have over-tagged. Drop any conclusion where the analytical finding would be identical regardless of whether the claim is literally true (boasting, venting, hyperbole that doesn't change the research output). Only consolidate conclusions that could distort a finding if accepted uncritically.

Produce a consolidated section:

```markdown
## Declarative Conclusions

Claims stated as fact by participants. These are assessments, not verified truths.
Each is evaluated for supporting evidence found across all gathered sources.

| # | Claim | Speaker | Supporting Evidence | Corroborated By | Verdict |
|---|-------|---------|--------------------|--------------------|---------|
| 1 | "..." | Name | [quoted reasons from transcript or external validation] | [other sources that confirm/deny] | Supported / Partially supported / Unsupported / Contradicted |
```

**Verdict rules**:
- **Supported**: Speaker gave reasons AND at least one other source (external research, another speaker, or data) corroborates
- **Partially supported**: Speaker gave reasons but no independent corroboration, OR corroboration exists but speaker gave no reasons
- **Unsupported**: No reasons given by speaker AND no corroboration found
- **Contradicted**: Evidence from other sources directly contradicts the claim

**Uncertainty inheritance rule**: Any conclusion YOU derive from a declarative conclusion is itself uncertain — it inherits (at minimum) the uncertainty of its source. If a speaker claims "the codebase is beyond saving" (Partially supported) and you conclude "therefore a full rewrite is needed", your conclusion is AT BEST Partially supported, regardless of how logical the derivation seems. Chain multiple declarative conclusions and uncertainty compounds. Flag derived conclusions explicitly: `[DERIVED FROM DECLARATIVE #N]` with inherited confidence ceiling.

#### Step B2: Consolidate Rejections (`98-rejected.md`)

**Purpose**: Give the user a single view of all information that was seen but consciously excluded, with justification and re-inclusion criteria.

**Process**:
1. Read `## Rejected Information` sections from ALL findings files
2. Deduplicate (same information flagged by multiple gatherers)
3. Group by rejection reason category:
   - **Out of scope (different module/component)** — information about a different area than targeted
   - **Out of scope (different information layer)** — e.g., implementation details when scope is big picture
   - **Solution not problem** — recommendation/solution when goal is problem identification
   - **Insufficient evidence** — signal from a single unverifiable source
4. For each rejected item, preserve the "Re-include if" column from the gatherer

**Output structure**:
```markdown
# Rejected Information

Research question: [from brief]
Scope: [in-scope / out-of-scope from research-plan.md]

## Out of Scope (Different Module/Component)

| # | Information | Source | Why Rejected | Re-include If |
|---|------------|--------|-------------|---------------|
| 1 | Moduł rabatowy: SLA spadło do 90% | Transkrypcja 12.03, Tomek | Different module (rabatowy, not zamówień) | Scope expanded to cross-module dependencies |

## Out of Scope (Solution Not Problem)

| # | Information | Source | Why Rejected | Re-include If |
|---|------------|--------|-------------|---------------|
| 1 | "Powinniśmy przejść na event sourcing" | ADR-007 | Recommendation — goal is problem identification | Scope includes solution evaluation |

## Summary
- Total findings collected: [N]
- Total rejected: [M]
- Rejection rate: [M/N+M %]
```

**If no rejections across all gatherers**: Create file with note: "No potentially relevant information was rejected. All encountered information fell clearly within or outside the research scope."

---

#### Step C: Generate Actor Map (`97-actor-map.md`) — Conditional

**Skip if**: `planning/research-plan.md` has no Actors section.

**Purpose**: Consolidate actor relevance tags from all findings into a single per-actor document. Each actor gets a tailored view of the most important findings, written in their language.

**Process**:
1. Read the Actors table from `planning/research-plan.md` (actor name, optimizes for, information needs, presentation style)
2. Read `## Actor Relevance` sections from ALL findings files
3. For each actor:
   - Collect all High and Medium relevance findings across all gatherer outputs
   - Rank by relevance (High first, then Medium)
   - Select top 5-7 findings per actor (avoid information overload)
   - Write the key takeaway in the actor's presentation style (business language for PO, technical for tech lead, modeling for domain expert, onboarding-friendly for new team)
4. Produce the consolidated file

**Output structure**:
```markdown
# Actor Map: Research Findings by Stakeholder

## How to Use This Document
Each section presents the same research findings tailored to a specific stakeholder's
perspective, priorities, and language. Share the relevant section with each person.

---

### [Actor Name] ([Role])

**Optimizes for**: [from research plan]
**Presentation style**: [from research plan]

| # | Finding | Source | Why It Matters (to them) |
|---|---------|--------|--------------------------|
| 1 | [finding title] | [category/file] | [key takeaway in their language] |
| 2 | ... | ... | ... |

**Recommended actions** (optional, 1-3 items):
- [action framed for this actor's priorities]
```

**Key rules**:
- **Different actors see different findings** — a PO may see competitor gaps while a tech lead sees API constraints. Don't just repeat the same list for everyone.
- **Language must genuinely differ** — "We're losing deals to Birdeye" vs "Integration layer needs anti-corruption layer for DataShake API" vs "This is a pure CRUD context, no complex modeling needed"
- **If an actor has zero High/Medium findings** — include a brief note: "No high-priority findings for this actor in this research cycle."

**Declarative conclusions in actor map**:

After the findings table for each actor, add a `**Declarative conclusions relevant to this actor**` subsection. For each conclusion that matters to this actor:

```markdown
**Declarative conclusions relevant to this actor**:
- "[claim]" (Speaker) — **[Verdict]**. [1-sentence why this matters to this actor specifically]
```

Only include conclusions relevant to the actor's domain. A PO sees claims about product quality or market positioning. A tech lead sees claims about codebase state or complexity. An architect sees claims about domain structure or module boundaries. Don't repeat all conclusions for every actor.

---

**Workflow complete.** Present summary to user:
```
Research gathering complete.

Findings: [N] files across [M] categories
Summary: analysis/findings/00-summary.md
Rejected: analysis/findings/98-rejected.md
Verification: analysis/findings/99-verification.md
Actor Map: analysis/findings/97-actor-map.md (if actors detected)

Key findings:
- [top 3-5 findings from summary]

Confidence: [overall assessment]
Contradictions: [count or "none"]
Rejected: [N] items excluded with justification (review 98-rejected.md)
Declarative conclusions: [N] claims tagged ([supported/partially/unsupported counts])
Actors: [N] stakeholder perspectives mapped
```

---

## Domain Context (State Extensions)

```yaml
workflow_type: research-gather
research_context:
  research_type: "internal" | "external" | "mixed"
  research_question: "[user's question]"
  scope:
    included: []
    excluded: []
    constraints: []
  methodology: []
  sources: []
  gathering_strategy:
    categories: []
    count: 4
    source: "planner" | "default"
```

---

## Task Structure

```
.maister/tasks/research/YYYY-MM-DD-name/
├── orchestrator-state.yml
├── planning/
│   ├── research-brief.md        # Phase 1
│   ├── research-plan.md         # Phase 2, Step A
│   └── sources.md               # Phase 2, Step A
└── analysis/
    └── findings/
        ├── 00-summary.md        # Phase 3, Step A
        ├── 97-actor-map.md      # Phase 3, Step C (if actors detected)
        ├── 98-rejected.md       # Phase 3, Step B2 (rejected information)
        ├── 99-verification.md   # Phase 3, Step B
        ├── codebase-*.md        # Phase 2, Step B
        ├── docs-*.md            # Phase 2, Step B
        ├── config-*.md          # Phase 2, Step B
        ├── external-*.md        # Phase 2, Step B
        └── [custom]-*.md        # Phase 2, Step B (dynamic categories)
```

---

## Auto-Recovery

| Phase | Max Attempts | Strategy |
|-------|--------------|----------|
| 1 | 1 | Prompt user for clarification if question unclear |
| 2 (Plan) | 2 | Expand search patterns, use fallback mixed methodology |
| 2 (Gather) | 3 | Retry failed agents only, continue with successful categories |
| 3 | 2 | Merge available findings, note missing categories |

---

## Command Integration

Invoked via:
- `/research-gather [question] [--yolo] [--type=TYPE]`

Task directory: `.maister/tasks/research/YYYY-MM-DD-task-name/`
