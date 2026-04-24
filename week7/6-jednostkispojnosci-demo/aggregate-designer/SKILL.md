---
name: maister:aggregate-designer
description: Interactive wizard for designing consistency units (aggregates). Guides the designer step-by-step through command extraction, pairwise conflict analysis, boundary decisions, and locking strategy. Invoke when the user asks about designing aggregates, consistency units, "projektowanie agregatów", "jednostki spójności", "jakie komendy się blokują", "granica agregatu", "współbieżna walka o zasoby", "rywalizacja o zasoby", "concurrent resource contention", or similar.
argument-hint: "[domain description or list of commands/requirements]"
---

# Aggregate Designer — Interactive Wizard

Design consistency units (aggregates) through a guided conversation. At each phase this skill asks targeted questions and waits for your answers before moving forward.

An aggregate is a **locking unit** — not an OOP pattern. Its only job is to lock what must be locked and leave everything else free to run in parallel.

**Scope**: this wizard produces a **model** — command boundaries, invariants, locking strategy, data scope. Implementation details (persistence, testing, paradigm choice) are optional extensions offered at the end.

---

## Phase 0: Input

Acquire the domain context.

- If an argument was provided, use it directly and proceed to Phase 1.
- If no argument, scan the conversation for a relevant domain description. If found, present a 2–3 sentence summary of what you understood and ask for confirmation before proceeding.
- If nothing is available, ask:

```
AskUserQuestion:
  "Describe the domain — what operations change state, what rules should never be broken,
   and who (or what) triggers these operations? A rough list of commands is enough to start."
```

Do not proceed past Phase 0 until you have at least a rough description.

---

## Phase 1: Fit Check

Before extracting commands, verify this is actually a resource contention problem — not CRUD or a read-only transformation.

**The core test** (apply silently first, then surface the result):
> *"Can the data checked to decide 'is this operation allowed?' be changed by another concurrent request at the exact same moment?"*

If the answer is clearly **no** (rules only check input data, single-user process, or the system only records outcomes decided elsewhere), present:

```
⚠️ This looks like a CRUD or validation problem, not resource contention.
No aggregate is needed here. Consider:
- DB unique constraints for uniqueness rules
- Application-layer validation for input rules
- `maister:problem-class-classifier` if the problem class is unclear

Do you want to continue anyway, or would you like to reclassify first?
```

If the answer is **yes** or **uncertain**, proceed to Phase 2.

Use `AskUserQuestion` only if the fit is genuinely ambiguous (e.g., unclear whether single-user or multi-user access):

```
AskUserQuestion:
  "Can multiple users (or the same user from parallel requests) trigger these operations
   simultaneously on the same data?"
  Options:
    "Yes — multiple concurrent actors on the same resource"
    "No — single user or strictly sequential process"
    "Unsure — it depends on the operation"
```

---

## Phase 2: Extract Commands

From the domain description, extract all commands — operations that **change state**.

Present the list clearly:

```
I identified the following commands:

1. [command name] — [what state it changes]
2. [command name] — [what state it changes]
...

Are these complete? Should I add, rename, or remove any?
Respond with corrections or say "looks good" to continue.
```

Wait for confirmation. Do not proceed until the command list is agreed upon.

**Help the user distinguish:**
- **Command** → changes state, goes through the rules guard → candidate for the aggregate
- **Fact / event** → records something that happened externally (human decided, external system acted) → does not need guarding, does not belong in the aggregate
- **Query** → reads state, no change → stays outside the aggregate entirely

If something on the list is clearly a fact or a query, flag it:
```
Note: "[X]" looks like a fact/event rather than a command — it records what happened
rather than requesting permission for something to happen. I'll set it aside unless you disagree.
```

---

## Phase 3: Pairwise Conflict Analysis

For every pair of commands (including each command with itself), determine whether simultaneous execution could violate an invariant.

Present a conflict matrix:

```
| Command A        | Command B        | Conflict? | Why                                       |
|------------------|------------------|-----------|-------------------------------------------|
| block slot       | block slot       | YES       | Two actors could both pass the "is free" check |
| block slot       | disable resource | YES       | Block wouldn't see the disable in progress |
| release slot     | define slot      | NO*       | Different data, no shared invariant       |
| ...              | ...              | ...       | ...                                       |
```

Mark `NO*` when commands are independent but may still end up in the same unit by transitivity (see note below).

Then ask:

```
AskUserQuestion:
  "Does this conflict analysis look correct?
   Are there any conflicts I missed, or any I marked incorrectly?"
  Options:
    "Looks correct"
    "I want to adjust one or more cells"
    "There are additional commands we haven't covered"
```

**Three rules to surface in the analysis (present as notes below the matrix):**

> **Self-conflict**: A command can conflict with itself — e.g., two users simultaneously adding the same resource both "see" it as absent.

> **Parameter-dependent conflict**: A command may conflict with itself only for certain parameters — e.g., blocking different time slots doesn't conflict; blocking the same slot does. This is a hint that the unit could be partitioned.

> **⚠️ Time-range conflict trap**: When conflict depends on **overlapping time ranges** (reservations, bookings, schedules), the naive aggregate "per resource" (e.g., per room) is too wide — it forces two reservations for non-overlapping times to compete for the same lock even though they can never violate the same invariant. Detect this when commands use time ranges as parameters and the invariant is "no overlap within a range."
>
> When detected, surface this explicitly and walk through the decision:
>
> ```
> ⚠️ Time-range conflict detected.
>
> "Reserve 10:00–10:30" and "Reserve 14:00–15:00" on the same room don't actually
> conflict — they can't violate the "no overlap" rule. But the current aggregate
> boundary (per room) would lock them against each other.
>
> How problematic this is depends on concurrency volume:
> ```
>
> ```
> AskUserQuestion:
>   "Two reservations for non-overlapping times on the same resource are currently
>    locked together. How much concurrent traffic do you expect?"
>   Options:
>     "Low — a few per minute. An occasional optimistic locking retry is fine."
>     "Moderate — retries are acceptable but I want to minimize them."
>     "High — hundreds per second, retries are costly, I need real parallelism."
> ```
>
> **Decision tree based on answer:**
>
> - **Low volume**: Keep the aggregate per resource. Optimistic locking with 1–2 background retries handles the rare collision. Simple, no slot granularity to define. Flag this as a conscious trade-off in the model: *"Non-overlapping time ranges may occasionally retry under optimistic locking. Accepted at current volume."*
>
> - **Moderate volume**: Same as low, but note that if retries become frequent, the design should be revisited. Add to Open Design Decisions.
>
> - **High volume**: The aggregate-per-resource model becomes a bottleneck. Surface two alternatives:
>
>   1. **Aggregate per slot**: Each time slot (e.g., "10:00–10:30, Room X") is its own aggregate instance. Pro: true parallelism for non-overlapping times. Con: requires defining slot granularity upfront (30 min? 1 hour? flexible?), creates many small aggregate instances.
>      ```
>      AskUserQuestion:
>        "If we partition by time slot — what is the natural slot granularity?"
>        Options:
>          "Fixed slots (e.g., 30-min or 1-hour blocks)"
>          "Flexible / arbitrary time ranges — no natural slot boundary"
>          "I'm not sure — help me decide"
>      ```
>      If **flexible/arbitrary ranges**: slot-per-aggregate doesn't work cleanly because ranges overlap unpredictably. Move to option 2.
>
>   2. **Database-level range constraint**: Some databases (notably PostgreSQL with range types and exclusion constraints, e.g., `EXCLUDE USING gist (room_id WITH =, time_range WITH &&)`) can enforce "no overlap" atomically without loading an aggregate at all. The invariant moves from application code to a DB constraint. Pro: the database handles the concurrency problem natively, no aggregate needed for this specific rule. Con: the invariant is no longer visible in the domain model — it lives in the schema.
>      ```
>      Note: If your invariant is purely "no overlapping time ranges for the same resource"
>      and there are no additional business rules that depend on the current set of bookings,
>      a database exclusion constraint may be simpler and more performant than an aggregate.
>      The aggregate adds value only when the decision logic is richer than "no overlap."
>      ```
>
> Document the chosen approach in the final model under Locking Strategy or Open Design Decisions.

> **Transitivity**: If A conflicts with B and B conflicts with C, then A–B–C belong in the same unit even if A and C don't directly conflict.

Wait for the user to confirm or correct before moving to Phase 4.

---

## Phase 4: Business Process Sequencing Probe

Some conflicts that appear in Phase 3 may be **eliminated by the business process** — if one command always happens in a completely separate session or time window from another, the concurrent window doesn't actually exist.

For each `YES` pair, ask whether this conflict is realistic:

```
AskUserQuestion (one question per suspicious pair, up to 4 per call):

  "[Command A] and [Command B] conflict in theory. In practice:
   does the business process ensure they can never happen simultaneously?
   (e.g., definition always happens first, allocation always happens later, in separate sessions)"

  Options:
    "They can genuinely happen simultaneously — keep the conflict"
    "Business process separates them — conflict window is effectively zero"
    "Unsure"
```

Document the outcome for each pair. Conflicts eliminated by process sequencing are noted as:
```
[Command A] × [Command B]: Theoretical conflict, eliminated by business process.
Placed in same unit pragmatically for simplicity — not required for safety.
```

---

## Phase 5: Frequency and Volume Probe

The locking scope determines throughput. Before finalizing boundaries, understand how often commands fire.

```
AskUserQuestion:
  "How many of these commands are expected per second / minute at peak?"
  Options:
    "Low volume — a few per minute at most"
    "Moderate — tens to hundreds per minute"
    "High — hundreds per second or unpredictable spikes"
    "I don't know yet"

AskUserQuestion:
  "Do different commands spike at different times, or do they all peak together?"
  Options:
    "Different times — spikes are unlikely to overlap"
    "Same time — heavy concurrent load on all commands simultaneously"
    "Unknown"

AskUserQuestion:
  "Are commands naturally partitioned by instance?
   (e.g., 'command X always concerns one specific project/user/resource,
    so different instances never compete with each other')"
  Options:
    "Yes — each unit instance is independent, no cross-instance contention"
    "Sometimes — some commands cross instances, others don't"
    "No — commands can compete across instances"
```

Use the answers to guide locking recommendations and to flag any pragmatic inclusions as potentially risky under high load.

---

## Phase 6: Data Scope per Command

For each command that passed through the conflict analysis, determine the **minimum data needed to make the decision**.

Present your inference and ask for corrections:

```
For each command that enforces an invariant, I inferred the following minimum data:

| Command        | Data needed to decide             | Why                                    |
|----------------|-----------------------------------|----------------------------------------|
| block slot     | list of existing blocks (IDs + time ranges) | check for overlap |
| disable        | current enabled/disabled status   | idempotency check                      |
| ...            | ...                               | ...                                    |

Does this look right? Is there data I'm missing, or data listed here that isn't actually needed?
```

Wait for confirmation. Then note any collection smells:

> **Collection note**: If a command only needs to check *whether* something exists (not its details), a list of IDs is sufficient — you don't need full objects. Full-object collections widen the locking scope unnecessarily.

After confirmation, present the **aggregate candidate**:

```
Based on commands and minimum data, the consistency unit candidate contains:

Fields:
- [field] → required by [command] for [invariant]
- [field] → required by [command] for [invariant]
- ...
```

---

## Phase 7: Boundary Decision — Inclusions and Exclusions

Before finalizing, surface any candidates that are **not required by a rule** but might be convenient to include.

For each candidate, ask explicitly:

```
AskUserQuestion:
  "[Data X / Command Y] is not needed to enforce any invariant.
   Should it be included in this consistency unit?
   Including it means every command will lock against it, even commands that don't use it."
  Options:
    "Include it — the convenience or query value is worth the extra locking"
    "Exclude it — keep it separate, use eventual consistency or a separate read model"
    "Include it, but I accept it's a pragmatic choice (not required by rules)"
```

Also offer the **process aggregate option** when applicable:

If a rule checks data that cannot realistically change during the check (e.g., configuration that changes once a week, a setting changed only by a single admin), surface this:

```
Note: The rule "[X]" checks [data Y], which is only changed by [a tightly controlled process].
If that process genuinely cannot run concurrently with this command, this check can live
in the application service — no DB lock needed, no aggregate expansion required.

Does [data Y] ever change concurrently with this command in practice?
  Options:
    "No — the check can stay in the application service"
    "Theoretically yes — keep it in the aggregate to be safe"
    "Unsure — let's keep it in the aggregate for now"
```

---

## Phase 8: Locking Strategy

Based on the volume profile (Phase 5) and the conflict structure, recommend a locking strategy. Present the recommendation and ask for confirmation:

```
AskUserQuestion:
  "Based on the volume profile and conflict structure, I recommend [optimistic / pessimistic] locking.
   [Explain why in one sentence.]
   Does this fit your system's requirements?"
  Options:
    "Yes — proceed with this recommendation"
    "No — I need pessimistic locking (high contention, no retries acceptable)"
    "No — I need eventual consistency (distributed system or high-availability requirement)"
```

**Decision logic** (apply silently, show reasoning):

| Contention level | Conflict consequence              | Recommendation            |
|-----------------|-----------------------------------|---------------------------|
| Low             | Retry is acceptable               | Optimistic (version field) |
| High or spiky   | Must queue, no retries acceptable | Pessimistic (`SELECT FOR UPDATE`) |
| Distributed / HA | Short inconsistency window OK    | Compensating (Saga / Outbox) |
| Safety-critical  | Any inconsistency is dangerous   | Pessimistic + process controls outside the system |

**Immediate vs eventual consistency**:
- **Immediate**: one transaction covers the entire invariant check. Simpler, but all participating objects lock together.
- **Eventual**: split into two transactions; a short inconsistency window exists; a compensating mechanism must detect and repair violations. Higher scalability, harder to implement correctly.

For each invariant that spans multiple objects, explicitly ask:

```
AskUserQuestion:
  "Invariant '[X]' spans [Object A] and [Object B]. Two options:
   (1) Immediate consistency — lock both in one transaction. Simpler, but widens locking scope.
   (2) Eventual consistency — two separate transactions; a short window where the rule could be violated.
   Which is acceptable here?"
  Options:
    "Immediate consistency — the rule must never be violated, even briefly"
    "Eventual consistency — a short window is acceptable; I'll add compensation"
    "Unsure — tell me more about the tradeoffs"
```

---

## Phase 9: Final Model

Produce the complete aggregate model with two parts: a **boundary diagram** and a **detailed model**.

### Part 1: Boundary Diagram

Draw an ASCII diagram that shows at a glance which commands are **inside** the aggregate boundary (locked together) and which are **outside** (free to run independently). Inside the boundary box, list the invariant(s) the aggregate protects.

Rules for the diagram:
- One box per aggregate (if composite analysis produced multiple aggregates, draw one box per aggregate)
- Commands inside the box are listed with a `→` prefix
- Invariants are listed below a `───` separator inside the box, prefixed with `⚡`
- Commands outside are listed to the right with a `○` prefix and a short reason why they're excluded
- If an outside command **reads** data from the aggregate, draw a dashed arrow `╌╌>` from it to the box
- If multiple aggregates exist, show arrows between boxes only where cross-aggregate communication occurs

Example (adapt to the actual domain):

```
┌─────────────────────────────────────────────┐
│          Room Availability [per room]        │
│                                              │
│  → Reserve slot                              │
│  → Cancel reservation                        │
│  → Block room                                │
│  ─────────────────────────────────────────── │
│  ⚡ Slot must be free before reservation     │
│  ⚡ Block must not overlap active bookings   │
│                                              │
│  Locking: optimistic (version field)         │
└─────────────────────────────────────────────┘
        ╌╌╌╌╌╌╌╌╌╌╌╌╌>
                        ○ Update room description   — no invariant depends on it
                        ○ Add comment to reservation — no shared rule, read-only reference
```

After the diagram, ask:

```
AskUserQuestion:
  "Does this boundary diagram look right — are the right commands inside the box?"
  Options:
    "Yes — the boundary is correct"
    "Move a command in or out — I want to adjust"
    "I think there should be more than one aggregate"
```

Wait for confirmation before producing Part 2.

### Part 2: Detailed Model

```markdown
## Consistency Unit: [Name]

**Root**: [Root entity — single entry point; all commands go through it]

### Commands and Invariants

| Command         | Invariant enforced                             | Data needed to decide       |
|-----------------|------------------------------------------------|-----------------------------|
| [command]       | [the condition that must hold atomically]      | [minimum fields required]   |
| ...             | ...                                            | ...                         |

### Fields

| Field           | Type / Shape      | Required by            |
|-----------------|-------------------|------------------------|
| [field]         | [e.g. list of IDs] | [command(s) that use it] |
| ...             | ...               | ...                     |

### Excluded Intentionally

| Item            | Reason                                                              |
|-----------------|---------------------------------------------------------------------|
| [data / command] | No invariant depends on it; including it widens locking scope     |
| [data / command] | Process sequencing eliminates concurrent window                   |
| [data / command] | Moved to application service (no lock needed in practice)         |

### Locking Strategy

**Type**: Optimistic / Pessimistic / Compensating
**Rationale**: [one sentence]

### Consistency Model

**Immediate**: [which invariants are checked atomically]
**Eventual** (if any): [which invariants accept a short inconsistency window + compensation approach]

### Open Design Decisions

- [Any decision not resolved — requires business input before implementation]
```

After presenting the model, ask:

```
AskUserQuestion:
  "Does this model look correct? Would you like to:"
  Options:
    "Finalize — the model is correct"
    "Adjust something — I want to change part of the model"
    "Continue to optional phases (persistence, testing strategy, implementation paradigm)"
```

---

## Optional Phases (offered after Phase 9)

Offer these only if the user requests them.

---

### Optional A — Locking Mechanics

Detail how to implement the chosen locking strategy:

**Optimistic**: Add a `version` field to the aggregate root. At save, check the version matches what was loaded — if not, throw and retry. Works well for low to medium contention.

**Pessimistic**: Use `SELECT FOR UPDATE` (or equivalent) when loading the aggregate. Other transactions queue until the lock is released. Use when retries are not acceptable or contention is reliably high.

**Compensating**: Allow both transactions to succeed; a background process detects conflicts (version mismatch, rule violation) and issues a reversal transaction. Requires Outbox pattern for reliable event delivery. Use in distributed systems or where high availability outweighs strict immediate consistency.

**Important**: object boundaries in code ≠ transaction boundaries. Two domain objects can share one transaction (widening the locking unit); conversely, one domain object can be split across two aggregates (each with its own transaction). The boundary follows the locking need, not the object identity.

---

### Optional B — Persistence Hints

**Ideal**: one table or document per aggregate instance. Load one row, check rules, save one row. This minimizes lock scope and eliminates most multi-table consistency issues.

**Collections inside the aggregate**:
- If only membership/existence is checked → serialize as a list of IDs in a JSON column (`jsonb`). No separate table needed.
- If full objects are needed → consider whether they are truly part of the aggregate or should be a separate read model.

**Avoid lazy loading**: loading parts of the aggregate at different points in time means different parts were observed at different instants. Under concurrent access, decisions are then based on a stale partial snapshot. Always load the aggregate eagerly in a single query.

**Write-skew with collections**: if two concurrent commands both make additive changes ("both think they can add"), the aggregate root's version must be bumped when any child collection changes — not just when the root's own fields change.

**Event Sourcing** (optional alternative): persist a log of events instead of current state; reconstruct state by replaying. Advantages: full audit trail, time-travel debugging, natural aggregate boundary. Cost: new mental model, snapshot management for long-lived aggregates. Worth considering only when auditability is a strong requirement for this specific aggregate.

---

### Optional C — Testing Strategy

**Unit-test the aggregate in isolation** (no database, no framework):
- **Arrange**: put the aggregate into a known state using prior commands or direct construction
- **Act**: send the command under test
- **Assert**: check the outcome — returned event, result flag, or thrown exception

**What to assert**:
- Primarily **output-based**: what did the aggregate return?
- Secondarily **indirect state-based**: query a stable, business-meaningful aspect of the aggregate's state (e.g., "which resources are still missing?") when the output alone doesn't reveal enough

**Derive test cases from the conflict matrix** (Phase 3): every `YES` cell in the matrix produces a test — two commands that conflict, sent in sequence to the same aggregate instance, must produce the expected outcome (second one rejected or both producing consistent state).

**Testing paradigm note**: aggregate tests are mostly output-based but implicitly verify state — asserting that a second add-of-the-same-resource fails proves the aggregate remembered the first. This is fine. Do not go out of your way to avoid state-based assertions when they're stable and meaningful.

---

## Key Principles (Reference)

**The one underlying principle**: do not widen the locking scope unless you must. Every other aggregate design heuristic is a consequence of this.

**Cohesion as a locking diagnostic**: if most fields are used by most commands, the unit is well-scoped. If some fields are only used by one command and that command doesn't conflict with others, those fields are candidates for extraction. Cohesion is a means to efficient locking — not a goal in itself.

**Process aggregate / application-level rule**: a rule that looks like it requires a lock may not need one if the data it checks is controlled by a separate, sequential process. Move the check to the application service when the concurrent window is genuinely zero by design — simpler, no lock needed.

**Real size metric**: an aggregate is too large when loading it requires excessive data, or when commands that don't conflict are forced to queue because they share a locking unit. Size is measured in data loaded and locked — not in lines of code.

**Aggregates are not mandatory**: if there is no real concurrency (single user, sequential process, external system decides), a DB unique constraint and application-level validation are enough. Not every business rule needs an aggregate.
