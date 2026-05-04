---
name: maister:problem-classifier
description: Classify business requirements into one of 4 modeling problem classes (CRUD, Transformation & Presentation, Integration, Resource Contention). Runs a signal scan, asks targeted clarifying questions, and recommends an implementation approach with rationale. NOT an archetype — invoke when the user asks about modeling problem classes, "jaka klasa problemu", "jak to sklasyfikować modelarsko", "problem class", or similar. For archetypes (accounting, pricing), use the *-archetype-mapper skills instead.
argument-hint: "[business requirements or feature description]"
---

# Modelling Problem Class Classifier

**This is a problem class classifier, not an archetype.** Use it when the question is *"which modeling class does this belong to?"* — not when the question is *"map this to an archetype"*.

| User intent | Correct skill |
|-------------|---------------|
| "Jaka klasa problemu?", "Jak to sklasyfikować modelarsko?", "Which modeling class?" | **this skill** |
| "Zamodeluj jako archetyp księgowy", "Map to accounting archetype" | `accounting-archetype-mapper` |
| "Zamodeluj cennik jako archetyp", "Pricing archetype" | `pricing-archetype-mapper` |

Given a business requirement, identify which of the 4 modeling problem classes best describes it, ask targeted clarifying questions to resolve ambiguity, and suggest an implementation approach aligned with the class.

The 4 classes determine which building blocks *likely* belong in the solution. Using the wrong class leads to overengineering (adding layers that don't add value) or underengineering (missing concurrency protection or integration concerns).

**Scope of this skill**: classify and suggest — not prescribe. The implementation suggestions are starting points and trade-off hints, not decisions. The team decides how to implement. Architecture decisions depend on context (team size, performance requirements, existing conventions) that this skill doesn't have full visibility into.

## The 4 Problem Classes

### Class 1: CRUD ("Notebook")

**Essence**: Data stored and retrieved exactly as entered. Think of a notebook — write, read, change, erase. No business logic decides *whether* the operation is allowed based on system state, and saving does not trigger domain effects elsewhere.

**Strong signals:**
- Fields are purely descriptive: title, description, notes, content, metadata
- No condition based on *system state* can block the operation
- Saving/deleting does not affect what other operations are allowed
- No invariants, no concurrency concern

**CRUD can have a lot of validation** — and that's fine. CRUD can contain very complex validation logic: cross-field rules, format checks, business policy constraints, even sophisticated multi-step calculations. The key distinction: all this validation checks only the **input data being submitted right now**. None of the data being validated is simultaneously being changed by another concurrent operation. If someone else could change a value you're checking at the exact moment you're checking it, you've crossed into Resource Contention territory.

*Quick test*: "Are all the values I'm checking part of what the user submitted in this request, or could another user change them right now?" → If all values come from the current request → CRUD with heavy validation. If any value lives in the database and could be modified by a concurrent command → RC.

**Validation logic is not T&P** — complex cross-field validation can be *implemented* as a pure function pipeline (which is a T&P technique), but that doesn't change the *problem class* of the overall operation. If the operation saves data, it's CRUD. Labeling it T&P because the validation is a pure function is a category error: T&P means the operation produces no state change at all. A save that happens to validate its inputs first is still CRUD.

**Disguised CRUD** — the important variant: A single screen may contain a mix of CRUD fields (title, description) *and* domain-controlled fields (status, approval chain). These appear together in the UI but are two separate models. Correct approach: one CRUD controller for the descriptive fields, one domain model for the rule-governed fields. Coupling them forces domain logic into the CRUD layer every time the domain model evolves.

**Implementation suggestion**: Controller → Database. Adding service layers, domain objects, or hexagonal architecture is overengineering here. Refactoring to extract domain logic later is the simplest operation — don't pre-optimize.

**CRUD + domain boundary**: If the domain model's state should prevent CRUD edits, expose a `canEdit()` query from the domain model. If a CRUD edit should notify the domain model, send a signal with *what changed* (not a specific new state) and let the domain model decide what to do — keeping domain logic on the domain side.

---

### Class 2: Transformation & Presentation

**Essence**: The operation reads existing state and transforms it for display or consumption. It does not change system state. Because there is no state to protect, aggregates are inappropriate — use function pipelines that can be composed and tested independently.

**Strong signals:**
- Read-only — no writes, no state mutations
- Output is derived from data owned by other modules (calendar = projection of reservations, reports = projection of transactions)
- Result is a view, API response, dashboard, report, or search result
- From a business perspective: "we're just showing what happened elsewhere"

**Implementation suggestions** (choose based on load requirements):
1. **Façade / BFF** — queries source-of-truth models directly; simple, sufficient for most cases
2. **Materialized views** — if the database supports them
3. **Event-refreshed cache** — denormalized read model refreshed by domain events (State Transfer Events with TTL work well; no polling jobs needed — just embed TTL in the event and let cache self-expire)

**Key principle**: The read model is always derivable from source-of-truth modules. Treat it as something that can be deleted and rebuilt. Never use it as a source of truth for commands.

---

### Class 3: Integration

**Essence**: The operation involves coordination across bounded contexts or external systems. The modeling challenge is not the business rules within any single module, but the contracts, sequencing, and failure modes *between* modules.

**Strong signals:**
- Multiple systems, modules, or teams are mentioned
- Language of "notify X", "send to Y", "receive from Z", "depends on module X"
- Partial failure scenarios matter ("what if payment succeeds but inventory block fails?")
- Message ordering may have business consequences ("pay before ship")

**Key decisions to surface:**
- **Published Language vs point-to-point**: Can modules communicate through a shared event vocabulary (e.g., `ResourceAcquired { itemId, ownerId }`) that hides implementation details? Or do they couple directly to each other's models?
- **Orchestration vs choreography**: Does a coordinator (Process Manager / Saga) control the flow, or do modules react independently to events? Choreography risks a distributed monolith if bounded context models leak across event payloads.
- **Failure ordering**: In synchronous flows, call easiest-to-reverse services first. In async flows, model failure scenarios explicitly on the board.
- **Message routing**: When event B is the result of command A, which module receives B? Direct routing (B → downstream) reduces hops but creates coupling. Routing through the coordinator keeps coupling contained.

---

### Class 4: Resource Contention

**Essence**: The system must protect the answer to the question *"Can you do X?"* The answer depends on current state — and that state can be changed by other simultaneous commands. It doesn't have to be a physical resource. It can be an artificial construct: a counter, a status flag, a computed threshold, a slot in a schedule. What matters is that the check and the change must happen atomically, because between checking and committing, another command from another user (or the same user from a parallel request) might change the data you just checked.

**This is not always about "multiple users"** — a single user sending parallel requests to the same endpoint hits this problem just as hard. The issue is concurrent write access to shared mutable state, regardless of who's holding the connection.

**Strong signals (high confidence):**
- The answer to "can I do X?" depends on data in the database that another command could change right now
- Reservation/blocking language: "reserve", "block", "check availability", "lock"
- The same command can arrive simultaneously from multiple sources (users, jobs, API clients) and the outcome depends on who wins
- A previous operation's result affects whether this operation is permitted

**Weak signals (need concurrency probe):**
- Assignment language: "only one owner", "assigned to one campaign", "one editor at a time"
- These express a uniqueness rule but don't confirm concurrent race conditions — probe whether the data being checked can actually change during the check

**Key discriminator — the mutability test**: *"Can the data I'm checking to decide if this operation is allowed be changed by another request at the exact same moment?"*
- Yes → RC: the check and the write must be atomic → Aggregate
- No / all checked values come from the current request → CRUD with heavy validation; no aggregate needed

**Levels of state rules**:
- *Data invariants*: "balance cannot exceed limit" — checked against current numeric state
- *Chronological invariants*: "cannot start a cancelled project" — checked against event sequence (status machine)
- Both types may exist in the same aggregate

**Implementation suggestion**: Aggregate — load state, call domain method, enforce invariants, save. Apply Optimistic Locking for concurrent access detection. The aggregate is the transactional boundary; never span a transaction across multiple aggregates.

---

## Skill Workflow

### Step 0: Input Acquisition

- If argument provided: use it directly.
- If no argument: scan the conversation for a business requirement, feature description, or domain scenario. If found, use it.
- If nothing found: ask *"Describe the business requirement or feature you want to model. The more context you provide (who initiates the operation, what happens after it executes, who else is involved), the more accurate the classification."*

---

### Step 1: Pre-check Scan (silent — no output yet)

Scan the input for signals from each class. Build an initial hypothesis.

**If the input contains a UI mockup or screen description**, read it visually first using the UI signal table below, then continue with the text signal table.

#### UI mockup signals

A single screen almost always combines multiple backend classes — one screen ≠ one class. Read each interactive element separately.

| What you see on the screen | Candidate class | Note |
|---------------------------|----------------|------|
| Form with text inputs, dropdowns, no conditional locking | CRUD | Check if any field gates other operations |
| "Save" / "Edit" / "Delete" buttons, always enabled | CRUD | If conditionally enabled → RC signal |
| Table, chart, aggregated numbers, read-only data, filters without editing | T&P | |
| "Generate report", "Export", "Preview" buttons | T&P | |
| Availability indicator: counter ("3/10"), colour (green/red), "available/taken" badge | RC — High | |
| "Reserve", "Book", "Assign", "Block", "Claim" buttons | RC — High | |
| Button greyed out / conditionally enabled based on status | RC — state machine | Probe what state gates it |
| Lock icon, "someone is editing…" indicator | RC | |
| Status badge (Open / In progress / Closed) that controls what's possible | RC — state machine | |
| "Send to…", "Publish", "Submit to ERP/CRM", "Notify" buttons | Integration | |
| External system logo or sync-status indicator | Integration | |
| Calculated totals, VAT summaries, running balances shown as display-only | T&P | Derives from other data — not source of truth |

**Key question for every "Save" button on the mockup:**
- *"What happens to data other users are working with at the moment of click?"* → nothing changes for them → CRUD; blocks or changes their availability → RC
- *"Who else could be clicking something right now that changes what I see on this screen?"* → nobody → CRUD/T&P; someone could → RC

#### Text input signals

| What you see in the input | Candidate class | Confidence |
|---------------------------|----------------|------------|
| Add/Remove/Save X → X added/removed/saved; purely descriptive fields | CRUD | High |
| "Generate", "show", "display", "report", "dashboard", no state changes | T&P | High |
| Multiple systems/modules, "notify", "send to", "depends on module X" | Integration | High |
| Physical/temporal resource: "reserve room", "book slot", "reserve inventory unit" + concurrent actors realistic | Resource Contention | High |
| Assignment/ownership uniqueness: "only one owner", "assigned to one campaign", "only one editor" | Resource Contention | Signal only — probe concurrency before deciding |
| "Cannot if already", "check availability", "lock" — but no explicit concurrent actors | Resource Contention | Medium — ask concurrency question |
| Mix of descriptive fields AND rule-governed fields on the same screen/entity | Disguised CRUD → decomposition needed | — |
| Signals from 2+ classes in a single requirement | Composite → decomposition needed | — |

Determine: **primary candidate**, optionally a **secondary candidate**. Note the specific phrases or UI elements from the input that triggered each signal.

---

### Step 2: Targeted Clarifying Questions

Based on the hypothesis, ask the most discriminating questions. Use `AskUserQuestion`. Maximum 4 questions per call; use a second call if more are needed.

**Always match the user's language** (Polish or English) in question text and option labels.

---

#### UI mockup probes — use when input contains a screen or mockup description

Ask these before the universal discriminators when a UI is present. They surface backend class boundaries that the screen hides.

- *"When the user clicks Save/Submit on this form, does it change what any other user sees or can do in the system right now?"*
  - "No, it just stores their data" → CRUD
  - "Yes, it affects availability / status / quota for others" → RC signal

- *"For each button on this screen: is it always enabled, or does it depend on something?"*
  - Always enabled → CRUD or T&P
  - Enabled only in certain states → RC / state machine — ask what state gates it and who changes that state

- *"Is any data shown on this screen calculated or derived from data that lives elsewhere?"*
  - Yes, totals, balances, aggregations, calendar entries → T&P component — don't model it as source of truth

- *"Is there a button that sends data to another system or triggers a process outside this screen?"*
  - Yes → Integration component — ask about failure and ordering

- *"Who else in the system could be clicking something right now that would change the data shown on this screen?"*
  - Nobody / single controlled process → CRUD or T&P
  - Multiple users, same resource → RC — probe atomicity

**Reminder**: a single screen almost always maps to multiple backend classes. Decompose by interactive element, not by screen.

---

#### Universal discriminators — ask first regardless of hypothesis

**1. "Is the only effect of this operation that the change will be shown on screen?"**
- Yes → CRUD (if data is saved) or T&P (if data is only read and transformed)
- No, the change affects what the system allows other users to do → Resource Contention signal

**2. "Does this operation change system state, or does it only read and transform data?"**
- Only reads/transforms → T&P (no aggregates, use function pipeline)
- Changes state → continue to further probes

**3. "Does executing this operation involve other modules or external systems?"**
- Yes → Integration signal — surface contracts, failure scenarios, message ordering
- No → CRUD or Resource Contention

**4. "How many users can execute this operation simultaneously? Do they access the same object?"**
- Single actor or strictly sequential process → lean CRUD or application validation
- Multiple actors, same object, same time → Resource Contention signal — probe atomicity next

---

#### CRUD depth — Behaving & Becoming probes

Use when CRUD is candidate but you want to confirm there's no hidden domain logic.

**Behaving (who changes it, why, with what effect):**

- *"Who can change this data, and under what circumstances?"*
  - "Any user, at any time" → CRUD confirmed
  - "Only specific roles, or only when the object is in a certain state" → RC or state machine signal

- *"What is the effect of this change — what happens next in the system?"*
  - "The new value appears on screen, nothing else" → CRUD confirmed
  - "The change unlocks or blocks other operations" → RC signal

- *"Can the change be freely repeated or undone without any conditions?"*
  - "Yes, always, unconditionally" → CRUD confirmed
  - "Only in certain states, undoing has side effects" → RC or state machine

**Becoming (does the change transform the nature of the object):**

- *"Does any of these fields — once changed — make this object something different from a business perspective?"*
  - "No, it's just a description or a note" → CRUD confirmed
  - "Yes, e.g. changing a status opens or closes possibilities" → RC / state machine, extract from CRUD model

---

#### T&P depth — source-of-truth test

Use when T&P is candidate, to confirm the view is truly derivable.

- *"If we deleted this view/report and rebuilt it from scratch from source data — would we lose any information?"*
  - "No, everything can be reconstructed" → T&P confirmed; implement as Façade/BFF or read model
  - "Yes, some data lives only here" → this is a source of truth, not a T&P view; reclassify

- *"Does clicking anything in this view send a command to another module, or does it only display data?"*
  - "Only displays" → pure T&P
  - "Clicking sends a command" → the view is T&P, but the click initiates something else (CRUD or RC) — decompose

- *"Are you grouping or categorizing objects using labels, tags, folders, or categories?"*
  - "Yes, but the labels are only for display/filtering and don't affect any rules" → **presentation grouping** — model as string label or JSON document, NOT as a separate entity with relationships; this is a labeling problem, not domain modeling
  - "Yes, and category membership changes what the system allows you to do with the object" → RC or CRUD + RC

---

#### CRUD vs RC border — use when unclear which

*"Which of the following best describes this data?"*
- "It's a notebook — we store it for reference, none of these fields affect what the system allows." → CRUD
- "At least one field determines whether operations are permitted or how they behave." → Resource Contention
- "I have both types of fields on the same screen." → Decompose (Disguised CRUD)

---

#### Resource Contention depth

**Step A — probe data mutability** (the key RC question):

*"Can the data we're checking to decide 'can this operation be executed' change during the check itself — because someone else (or the same user from a parallel request) is simultaneously sending a different command?"*
- Yes → RC: the check must be atomic with the write → Aggregate
- No / "all checked values come from the submitted request" → CRUD with validation; no aggregate needed
- Unsure → probe with Step B

*Note: "two users" is just the most common example. One user sending two parallel requests (e.g. double-click, two browser tabs open) causes the exact same problem.*

**Step B — probe concurrency scope** (when Step A is unclear):

*"Is this operation available to multiple users simultaneously, or is it driven by a single tightly controlled process?"*
- Multiple simultaneous actors / open system → proceed to Step C
- Single controlled process → likely application validation or process policy; CRUD + unique constraint may suffice

**Step C — probe atomicity** (when concurrency is confirmed):

For each rule protecting the operation, stack them, then ask:

*"If we checked these rules at two separate moments rather than atomically, could something go wrong?"*

Make it concrete from the requirement: *"For example, if we checked 'is the resource not blocked' and 'is the resource not disabled' in separate steps — someone could disable the resource in between, and the blocking would go through. Would that be a problem?"*
- "Yes, that would be a problem" → rules must be checked atomically → Aggregate confirmed
- "No, one of those checks is enough" → probe if the rules are truly independent; may not need a full aggregate

---

#### Integration depth

*"Must all these operations succeed together, or can each complete independently?"*
- Must all succeed together → Saga / Process Manager needed; model failure scenarios explicitly
- Independent → simpler choreography may work

*"Does the order of these operations matter from a business perspective (e.g., payment before shipment)?"*
- Yes → orchestrator / coordinator needed; in synchronous flows call easiest-to-reverse services first

*"What happens when one of these remote operations doesn't respond? Does the business have a name for that situation?"*
- Named scenario → model it explicitly as an event; don't hide it in error handling

---

### Step 3: Classification

Synthesize pre-check signals and answers into a determination:

1. **Primary class** — dominant problem class
2. **Secondary class** — if the requirement genuinely spans 2 classes after decomposition
3. **Confidence**: High (3+ strong signals aligned) / Medium (1-2 signals, answers confirm) / Low (ambiguous, ask more)
4. **Key evidence** — cite 3-5 phrases from the input
5. **Decomposition needed?** — if composite, identify split points

---

### Step 4: Output

```markdown
## Classification: [CLASS NAME]

**Confidence**: High / Medium / Low

### Deduction trail
Record every analytical question asked during classification and the answer received. This is the reasoning path — it must be preserved so the architect reviewing the output can trace exactly how the skill arrived at its conclusion.

| # | Question asked | Answer | Signal / Implication |
|---|---------------|--------|---------------------|
| 1 | [exact question from Step 2] | [user's answer or "inferred from input"] | [what this confirmed or ruled out] |
| 2 | ... | ... | ... |

### Why this class
- [Quote from requirements] → [signal it triggered]
- [Quote from requirements] → [signal it triggered]
- [...]

### What NOT to do
[Most common implementation mistake for this class — e.g. "Don't add service layers and aggregates — this is CRUD."]

### Suggested approach
[1-3 concrete implementation hints for this class]

### Open questions before modeling
[Decisions that must be made before starting — or "None"]
```

If composite, add:

```markdown
---
## Suggested decomposition

This requirement spans multiple classes. Proposed split:

| Component | Class | Rationale |
|-----------|-------|-----------|
| [name A]  | CRUD / T&P / Integration / Resource Contention | [why] |
| [name B]  | ...   | ... |

Do not model them together in one class — it will force domain logic into the CRUD layer or vice versa.

## Component relationship diagram

[ASCII diagram showing how the components connect — data flow, command flow, read dependencies]
```

### Resource Contention — next step offer

**When the primary or any component classification is Resource Contention**, after delivering the output ask:

```
AskUserQuestion:
  "This is a Resource Contention problem — the system must protect shared mutable state
   under concurrent access. The next step is designing the consistency unit (aggregate):
   which commands must lock together, which can run in parallel, and where the boundary sits.

   Would you like to proceed with aggregate design?"
  Options:
    "Yes — start the aggregate design wizard now"
    "No — the classification is enough for now"
```

If the user selects "Yes — start the aggregate design wizard now", invoke `maister:aggregate-designer` passing the original domain description as the argument.

**When to draw the diagram**: always when decomposition has 2+ components. The diagram shows:
- Which component owns the source of truth (→ arrow = "reads from" or "sends command to")
- Which component is a read model derived from another
- Where the integration boundary sits (external system box)
- Which components share a transactional boundary (dashed box = same aggregate)

**Example patterns**:

Single-user form with domain status (CRUD + RC):
```
[CRUD Controller] --edited(what)--> [Status Machine / Aggregate]
[CRUD Controller] <--canEdit()------ [Status Machine / Aggregate]
```

Reservation with presentation data (RC + T&P):
```
[Reservation Aggregate] --ReservationConfirmed--> [App Layer]
[Room Read Model / T&P] <--query------------------ [App Layer]
                                                       |
                                              response to user
```

Policy computation + limit enforcement (T&P + RC):
```
[Policy Calculator / T&P] --returns X--> [App Layer]
                                              |
                                         passes X to
                                              |
                                     [Slot Aggregate / RC]
```

Calendar view + room booking (T&P + RC + Integration):
```
[Reservations Module / RC] --ReservationMade event--> [Calendar Read Model / T&P]
[External Notify / Integration] <--command------------ [Reservations Module / RC]
```

---

## Class Quick Reference

| | CRUD | T&P | Integration | Resource Contention |
|--|------|-----|-------------|---------------------|
| **Changes state?** | Yes (trivially) | No | Yes (via others) | Yes (with rules) |
| **Business rules?** | Heavy validation on inputs only | None | Ordering, failures | Invariants, atomicity |
| **Concurrency?** | N/A | N/A | Partial failures | Race on data |
| **Key building block** | Controller + DB | Function pipeline | Saga / Process Mgr | Aggregate |
| **Anti-pattern** | Adding layers | Treating as source of truth | Tight coupling | Using aggregate for CRUD |

---

## Edge Cases & Traps

**"The only effect is a change on screen"** — If the entire effect of an operation is visible only on screen and nothing else happens, you have CRUD (if saving) or T&P (if only reading and transforming). Even if it's a large change with many fields and a complex form — if the result is just displaying new data, it's still CRUD or T&P. Don't add aggregates just because the screen looks complicated.

**"We're grouping things into larger structures"** — Grouping, tagging, categorizing, labeling is almost always a **presentation problem**, not a domain problem. Don't create separate entities with relationships for categories whose membership doesn't affect any business rules. A string label or a JSON field on the CRUD object is enough. Creating a `Category` entity with `CategoryRepository`, `CategoryService`, and a many-to-many relationship is overengineering. Verification question: *"Does membership in this group/category change what the system allows you to do with the object?"* If no → string label. If yes → may be RC.

**"I have validation, so it's not CRUD"** — Format validation (required field, valid email) is not a domain rule. CRUD can have validation. The key question: can any rule block the operation based on *system state*, not just input correctness? If no → CRUD.

**"Complex cross-field validation means T&P"** — This is a category error. T&P means the operation produces no state change at all. A form with 20 cross-field rules that validates VAT numbers, checks currency consistency, and calculates totals — but then *saves the result* — is CRUD. The validation logic can be *implemented* as a pure function pipeline (which is a T&P technique), but that's an implementation detail, not a class change. Class = what the operation does to system state. If it saves → CRUD. Don't let implementation elegance fool you into reclassifying the problem.

**"The calendar is a domain model"** — A calendar is almost always a projection of state changes from other modules (planning, availability, reservations). Clicking a calendar control sends a command to the source of truth — the calendar itself stores nothing. It's T&P. Don't model a calendar as an aggregate. Verification question: *"If we deleted the calendar and rebuilt it from other modules' data — would we lose any data?"* If no → T&P.

**"We're pulling data from an external system to display it"** — This is T&P with an Integration element. The primary class is T&P (transform and display). The integration aspect is an implementation technique (read model with event-refreshed cache with TTL), not a separate problem class.

**"We have a stateful process"** — If a document's status is a state machine, but the descriptive fields (title, description) can always be edited — that's Disguised CRUD. Don't push descriptive fields through the state machine. Send a signal `edited` from the CRUD module with information about what changed (not what value it changed to) and let the state machine decide what to do — domain logic stays on the domain side.

**"Only one X can Y" is not always Resource Contention** — The phrase "only one owner", "only one active campaign", "only one editor at a time" is a strong heuristic signal, but not proof of RC. Ask the concurrency question: "Can two people simultaneously try to assign this resource?" If no — it's an application rule (unique constraint in DB, validation in controller), not an aggregate. If yes — RC confirmed. Most common mistake: modeling "only one task owner" as an aggregate when in practice the owner is changed by one administrator sequentially — a constraint is enough here.

**"Max 3 times — but not by us"** — A limit expressed in the requirement ("maximum 3 concurrent exports", "at most 5 simultaneous reservations") looks like a textbook RC signal. But before modeling an aggregate, ask: *"Does our system enforce this limit, or does it only receive the outcome of a decision made by an external system or a human?"* If the limit is checked and enforced by an external system, and our system only records the result (a notification, a callback, a status update) — there is no RC here. Our system is not the one deciding "can you do X?"; it is only being informed that it happened. **Sanity check**: *"If two users simultaneously attempt this operation right now — does our system block one of them, or does it just accept both requests and pass them on?"* If our system blocks → RC. If it passes through and something else (an external service, a human approval, a queue consumer) decides → at most Integration or CRUD. The most common mistake: modeling an aggregate for a limit that is never enforced by this system's code — the aggregate will never fire, and the aggregate's invariant will never be violated, because enforcement happens elsewhere.

**"The aggregate is getting too large"** — This signals that inside the aggregate there are two independent groups of invariants. Ask the domain expert: "Would checking these two groups of rules at different moments be a problem?" If no → possibly two aggregates, or CRUD + aggregate.

**"I don't know what to call it"** — If the domain expert can't name a failure situation or exception, either that situation isn't possible and doesn't need modeling, or the expert hasn't thought it through yet. If the business has a colloquial name for something ("that's a real mess"), that name should probably become an event in the model.

**"Policy says how many times you can reserve — that's also RC"** — The limit isn't always a constant baked into the aggregate. Sometimes limit X is computed by a complex calculation depending on many factors (resource resistance, contract parameters, season). In that case, split it: **(1) T&P — policy computation**: a function takes data and returns X (how many times allowed). **(2) RC — limit enforcement**: the aggregate receives a ready X and ensures the current counter doesn't exceed X under concurrent access. Don't push policy computation into the aggregate — it becomes hard to test and changing policy rules forces changes to the aggregate.

**"Presentation data inside an RC operation"** — A very common mix: within the same reservation operation you have data that (a) determines *whether* you can reserve (protected by RC) and data that (b) determines *what* you get as a result of the reservation, but doesn't affect whether the reservation is allowed. Example: room booking — *whether the room is free* is RC; *what equipment the room has* is presentation data returned in the response. Don't pull presentation data into the aggregate. The aggregate returns the command result (e.g. `ReservationConfirmed { roomId, from, to }`), and presentation data about the room is fetched by the application layer or a read model.

**Most common composite combinations:**
- Document edit screen with descriptive fields + rule-governed status → CRUD + Resource Contention
- Financial report based on data from multiple modules → T&P + Integration
- Order: inventory reservation + external payment / email notification → Resource Contention + Integration
- Tags / categories visible in filters → T&P (string labels, not entities)
- Calendar + room reservation → T&P (calendar view) + Resource Contention (reservation)
- Computing how many times you can block (X = complex policy) + enforcing the limit → T&P (computing X) + Resource Contention (enforcing counter vs X)
- Room equipment in reservation response → Resource Contention (reservation decision) + T&P (presentation data about the room in the response)
