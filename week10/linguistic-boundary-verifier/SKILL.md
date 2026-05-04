---
name: linguistic-boundary-verifier
description: Verifies linguistic boundaries between bounded contexts by analyzing language.md files. Each language.md declares context role, relationships, and integration points — no separate context-map needed. Detects typical language leakage patterns (strings, events, API calls), proposes type-specific fixes (generalization, ACL, dependency inversion), and interactively validates with user. For single-module PRs, checks whether new concepts fit the module's linguistic space. Strictly read-only.
argument-hint: "[module names to check, or 'all', or module name --pr for single-module new concept check]"
---

# Linguistic Boundary Verifier

Analyze bounded context boundaries to ensure ubiquitous language remains properly isolated and flows only in permitted directions. When violations are found, propose **type-specific fixes** and validate interactively with the user.

**Output goal**: A boundary report with detected violations, proposed fixes (generalization for strings, ACL for events, dependency inversion for API calls), and language.md update suggestions. The report is a review artifact — the skill never modifies code.

**DDD nomenclature is optional.** The skill uses DDD terms (OHS, ACL, Customer-Supplier, upstream/downstream) as defaults because they have well-defined language flow rules. But if your team uses different names — "provider/consumer", "library/client", "core/plugin" — that works too. What matters is that each integration point in language.md declares direction and translation expectations.

## When to Use

**Two modes of operation:**

1. **Cross-module boundary check** — provide 2+ module names (or "all"). The skill analyzes relationships between those modules, finds language leaking across boundaries, and proposes fixes.
2. **Single-module PR check** — provide one module name with `--pr`. The skill diffs the PR, extracts new concepts, and checks whether they fit the module's linguistic space — catching terms from downstream that break generalizations.

**Use this skill when:**
- Architectural review of changes touching multiple bounded contexts
- Architectural review of changes in a single module — validate new concepts
- Before major refactoring across module boundaries
- As periodic architecture health check (quarterly)
- After adding new modules or changing relationships in language.md

## When NOT to Use — Fit Test

### The core question

> *"Do I have modules with language.md files that describe the module's purpose and declare integration points with other modules?"*

If **yes** — verification can proceed. Each language.md contains everything needed: module description (what it does, whether it's a generalization), core terms, and integration points with other modules (relationship type, direction, imported/exported terms). No separate context-map file needed — the relationship graph is reconstructed from integration point sections across all language.md files.
If modules **don't have language.md** — the skill can't verify what isn't defined. First step: generate language.md drafts from code (separate agent available).
If the question is **"where should my boundaries be?"** — use `context-distiller` first to find boundaries. This skill checks whether existing boundaries are respected, not whether they're correct.

## Prerequisites

- Modules have `language.md` defining: module description (purpose, whether it's a generalization), core domain terms, operations, events, and **integration points** with other modules (relationship type like OHS/ACL/Customer-Supplier, direction, imported/exported terms)
- Access to module source code

## Core Principle

**Generalize behavior, not identity.** When a foreign term leaks into a module, the upstream should not know WHY something happens — only WHAT effect it has. This follows context-distiller's rule: test by effect in consumer context, not by cause at source.

---

## Phase 1: Discover & Parse

Read `language.md` files for specified modules (or all). Each language.md has a module description at the top (what it does, whether it's a generalization) and integration point sections declaring relationships with other modules. From these integration points, reconstruct the relationship graph. Build vocabulary inventory per context — core terms, operations, events, exports, imports, aliases.

**Internal vs Published vocabulary**: If a language.md has both `Core Terms` (internal) and `Published API` (exported) sections — consumers may only use terms from Published API. Using internal terms is a violation (correct direction, wrong vocabulary). If a language.md has only `Core Terms` without a separate Published section — all terms are available to consumers. The split is optional.

**Scoping**:
- 2+ modules -> analyze relationships BETWEEN those modules only
- 1 module -> analyze that module's relationships with all related contexts
- "all" -> analyze all relationships

**Output**: Summary table — contexts found, relationships identified, vocabulary sizes.

-> Proceed to Phase 2

---

## Phase 2: Detect Violations

For each relationship pair: take all terms from context A's vocabulary, grep for them in context B's code (class names, string literals, event handler annotations, API/service calls, column names, JSON keys). Classify findings. Read surrounding code (10 lines) to understand what the code DOES with the foreign term.

### Typical Violation Types

Not exhaustive — these are the most common patterns, not a closed taxonomy.

| Violation Type | How It Leaks | Fix Strategy |
|----------------|-------------|--------------|
| **String from foreign context** | `reason.equals("REMONT")` — literal text, invisible to architectural dependency tools (ArchUnit, deptrac, Nx, etc.) | **Generalize behavior**: replace specific reason with generic flag/property in upstream's language |
| **Event in foreign language** | `handle(UrlopZatwierdzony)` — physical data direction OK, linguistic direction reversed | **Reverse linguistic direction**: add ACL translating to subscriber's own language |
| **API call in wrong direction** | `facilityService.zablokujSale()` — specific calls specific instead of generic | **Specific adapts to generic**: call generic module's API in its language. Genericity heuristic: generic doesn't adapt to specific |

### Detection details

**String from foreign context**: Grep terms from other context's language.md in string literals, switch cases, map keys, enum names. Invisible to architectural dependency tools (ArchUnit, deptrac, Nx, etc.) — no package import, just a literal.

**Event in foreign language**: Find event handler/subscriber declarations (annotations, decorators, message consumer configs, event bus registrations — whatever pattern your stack uses). Check if event type is defined in another context's language.md. Key: physical data flow direction != linguistic direction. Data flows HR -> Resource (OK), but HR's language leaks INTO Resource's codebase (violation). Invisible to dependency analysis.

**API call in wrong direction**: Find direct method calls or HTTP client calls to services in other contexts. Check if call direction matches relationship direction declared in language.md files.

### NOT a Violation

Filter out before presenting:
- Primitive types (string, int, date) — universal
- Infrastructure vocabulary (HTTP, JSON, SQL) — not domain language
- Terms explicitly listed in Shared Kernel or Published Language
- OHS upstream expanding with generic terms (counters, timestamps) in its own namespace

### -> Pause: Present violations with diagram

**Draw an ASCII diagram showing the current architecture with all violations marked.** Show which modules are involved, where language leaks, where direction is wrong. Mark violations with ❌. This diagram is the FIRST thing the user sees — before the table.

Then present violations as table with: #, type, term/call, location, source context, what code does.

Ask: "Should I proceed with fix proposals? (Yes / Some are false positives / Add context)"

---

## Phase 3: Propose Fixes

For each confirmed violation, propose a fix matched to the violation type.

### Fix for Strings: Generalize the behavior

1. Read surrounding code — what does the if/switch DO?
2. Strip identity, keep effect: `reason.equals("REMONT") -> blockAdjacentSlots` becomes "some unavailabilities need safety buffer"
3. Propose generic property in upstream's language: `Unavailability.requiresSafetyBuffer: boolean`
4. Identify who sets (downstream) and who reads (upstream)
5. Check if multiple violations collapse to same generalization (good sign)

```
VIOLATION: reason.equals("REMONT") in Resource/ResourceService.java:47
  Behavior: Blocks adjacent time slots as safety buffer
  Fix: Unavailability.requiresSafetyBuffer: boolean
  Who sets: Facility (knows remont needs buffer)
  Who reads: Resource (blocks adjacent slots if true — doesn't know why)
  Collapses with: AWARIA also triggers adjacent blocking -> same flag
```

### Fix for Events: ACL translation OR reverse to command

Two possible fixes. The choice depends on one heuristic:

> **Does the publishing context know EXACTLY what should happen next?**
> - **Yes, it knows the next step** -> it should send a **command** in the receiver's language (or generic shared language). The publisher is orchestrating — it tells the receiver what to do.
> - **No, it just announces what happened and doesn't care what follows** -> the receiver subscribes to the **event** through an **ACL** that translates to receiver's own language. The publisher's process is done — whoever reacts, reacts.

**Fix A: ACL translation (publisher doesn't care what happens next)**

HR publishes `UrlopZatwierdzony` because from HR's perspective the process is complete — vacation is approved, done. HR doesn't know or care that Resource needs to mark unavailability. This is a genuine event: "something happened, I'm telling the world."

Fix: ACL at boundary translates to receiver's language.

```
VIOLATION: handle(UrlopZatwierdzony) in Resource/ResourceEventHandler.java:83
  Behavior: Creates unavailability when HR approves vacation
  Heuristic: HR doesn't know/care what Resource does -> event + ACL
  Fix: ACL at boundary:
    UrlopZatwierdzony -> ResourceUnavailabilityRequested(resourceId, timeSlot, PLANNED)
  Resource handler: handle(ResourceUnavailabilityRequested) — zero HR terms
```

**Fix B: Reverse to command (publisher knows exactly what should happen)**

But imagine a different case: Scheduling module knows that after scheduling a training, the room MUST be blocked. Scheduling knows the exact next step. It's not announcing "training scheduled, whoever cares" — it's orchestrating: "block this room for this slot."

Fix: Replace event subscription with a direct command in the receiver's (or shared) language.

```
VIOLATION: handle(TrainingScheduled) in Resource/ResourceEventHandler.java:91
  Behavior: Blocks room resource for scheduled training
  Heuristic: Scheduling knows EXACTLY what must happen (block room) -> command
  Fix: Scheduling sends command directly:
    resourceService.blockResource(resourceId, timeSlot, reason=SCHEDULED)
  No event subscription needed — Scheduling orchestrates the step
```

**Decision process**:
1. Identify foreign event being consumed
2. Ask: does the publisher know the exact next step, or is it just announcing?
3. If announcing -> ACL translation (Fix A)
4. If orchestrating -> reverse to command (Fix B)
5. Present both options to user with the heuristic — user decides based on domain knowledge

**Genericity heuristic** (applies to events AND API calls):

> **More generic modules don't adapt to more specific ones.** The specific adapts to the generic. 50 types of orders adapt to 1 invoicing API — not invoicing adapts to 50 order types.

Anti-pattern: "Ordering publishes `ZamowienieZlozone`, Invoicing subscribes." Invoicing is MORE generic than Ordering (it invoices orders, subscriptions, refunds, penalties...). If Invoicing subscribes to order events, it starts knowing about orders. Tomorrow about subscriptions. Next week about refunds. Invoicing becomes a patchwork of foreign handlers — the generic module is no longer generic.

Correct: Ordering (specific) calls `invoicingService.issueDocument(InvoiceRequest)` — adapting to Invoicing's generic language.

### Fix for API calls: First check — is the direction correct?

Before proposing any fix, ask: **is the DIRECTION of this call correct?**

**Step 1 — Determine direction correctness:**
- Generic → Specific: direction is **WRONG** — generic should not know about specific. Reverse it.
- Specific → Generic, correct vocabulary: **OK** — nothing to fix.
- Specific → Generic, wrong vocabulary: direction is **CORRECT** but uses internal/unpublished API. Fix vocabulary only.

**Step 2 — Fix depends on direction diagnosis:**

**3a. Direction is WRONG — generic calls specific (reverse it):**

```
VIOLATION: resourceService.getTrainerSchedule() calls Scheduling from Resource
  Direction check: Resource (generic) → Scheduling (specific) = WRONG ❌
  Problem: generic module calls specific — Resource knows about training schedules
  Fix: reverse dependency. Scheduling calls Resource, not the other way around.
    If Resource needs data: Scheduling pushes it via Resource's published API.
```

**3b. Direction is CORRECT but vocabulary is wrong (fix vocabulary only):**

```
VIOLATION: schedulingService calls resourceRepository.getSlots() in Scheduling
  Direction check: Scheduling (specific) → Resource (generic) = CORRECT ✅
  Problem: uses Resource's INTERNAL method (getSlots from repository)
           instead of PUBLISHED API (checkAvailability from language.md)
  Fix: switch to published API. Direction stays the same.
    resourceService.checkAvailability(resourceId, timeSlot)
  DO NOT propose "flip to events" — direction is already right, problem is vocabulary.
```

### Quality checks for all fixes

- Does it capture **behavior** without **identity**? (Good: `requiresSafetyBuffer`. Bad: `isRemont`)
- Could multiple downstream concepts map to it?
- Does it make sense as a term in upstream's own language?
- Is the proposed concept already partially present in upstream's language.md?

### Diagrams: BEFORE and AFTER per violation (or grouped)

For each violation (or group of related violations), generate two ASCII diagrams:

**BEFORE diagram** — show the current architecture with the violation visible:
- Which module contains the foreign term/event/call
- Arrows showing the wrong direction of language flow
- Mark with ❌ where the boundary is broken
- Show that standard tools (architectural dependency tools (ArchUnit, deptrac, Nx, etc.)) see no problem

**AFTER diagram** — show the proposed fix:
- Clean module with generic concepts only
- Correct direction of dependencies/language
- Mark with ✅
- Show where translation/adaptation happens

Diagrams should be concise (8-12 lines). Purpose: make the problem and fix visually obvious — a developer seeing the diagram immediately understands what's wrong and what the fix looks like, without reading the full explanation.

### -> Pause: Present fixes with diagrams

**ALWAYS draw diagrams when presenting violations and fixes to the user.** Every violation gets a BEFORE diagram (what's wrong) and every fix gets an AFTER diagram (proposed solution). This is not optional — visual representation is the primary way the user understands the problem. Text explanation accompanies the diagram, not the other way around.

Present each fix proposal with BEFORE/AFTER diagrams. Ask per violation:
"Does this make sense?
- **Yes**
- **No, upstream actually needs to know** (explain why — may indicate boundary is misplaced)
- **Different fix** (describe)"

If user says "upstream needs to know" -> flag as **boundary question**. Do not force fix. Note in report.

---

## Phase 4: Incorporate Feedback

- Confirmed fixes -> include in report
- User's alternative -> adopt
- "Upstream needs to know" -> flag as boundary question, recommend reviewing module boundaries
- False positives from Phase 2 -> remove

-> Proceed to Phase 5

---

## Phase 5: Generate Report

**Output**: `linguistic-boundary-report.md`

1. **Executive Summary** — boundary health, violation count by type, fix proposals status
2. **BEFORE/AFTER diagrams** — per violation (or grouped): ASCII diagram showing the problem and the proposed fix. Visual, immediate, no need to read code.
3. **Context Inventory** — contexts analyzed, language.md status, vocabulary sizes
3. **Relationship Map** — ASCII diagram with compliance status per relationship
4. **Violations with Fixes** — per violation: evidence, type, behavior, proposed fix, user decision, language.md update needed
5. **Recommendations** — prioritized: fixes to implement (before/after), language.md updates, boundary questions

---

## Single Module PR Check (--pr mode)

When PR changes only one module — no cross-boundary check. Instead, check new concepts.

1. **Diff the PR** — extract new class names, method names, string literals, event types
2. **Compare with language.md** — flag anything not in the vocabulary
3. **Classify each new term**:
   - **Consistent with module's language** — fits existing linguistic space (e.g., `MaintenanceWindow` in Resource). OK, suggest adding to language.md.
   - **Generic/infrastructure** — counters, timestamps, metadata (e.g., `retryCount`). OK, not a domain term.
   - **Term from downstream's language** — belongs to a downstream module per language.md relationships (e.g., `TrainerSchedule` in Resource — "Trainer" is HR's language). **Violation: breaks generalization.**
   - **Breaks existing generalization** — type-specific check in generic module (e.g., `if (resource instanceof Sala)` in Resource). **Violation: this belongs in Facility.**

**Sensitivity depends on module's role.** Not every module is equally fragile to new concepts:

- **Module is a generalization / serves many clients (e.g., Resource, PricingEngine, Invoicing)** — described in language.md as generic, has only consumers in its integration points, no outgoing dependencies. Every new concept matters. A new term that smells like a consumer's language is a real threat — it breaks the generalization. **High sensitivity.** This is where the skill adds the most value.
- **Module is a specific context / integrator / has 5+ dependencies (e.g., Scheduling, OrderFulfillment)** — already knows about many other modules by design (visible from integration points). A new concept from yet another dependency is probably fine — this module IS an integrator, it's supposed to know things. **Low sensitivity.** New terms are likely OK unless they leak INTO one of its upstreams.

Before flagging violations, read the module description at the top of language.md. If it describes a generalization that serves many clients — be strict. If it describes a specific context that integrates many modules — be lenient on new incoming terms, strict only on outgoing leakage.

**Key test for upstream/generic modules**: Does this term make sense without knowing about any specific downstream? If yes — OK. If only with knowledge of rooms/trainers/insurance — violation.

**Key test for downstream/integrator modules**: Does this term leak INTO an upstream module? If yes — violation. Does it add a new dependency from yet another upstream? Probably fine — flag but don't alarm.

### -> Pause: Present classification

"These 3 new terms look consistent with Resource's language. This 1 term ('TrainerSchedule') looks like it comes from HR — breaks Resource's generalization. Agree?"

---

## Relationship Direction Rules

The skill uses DDD relationship types (OHS, Customer-Supplier, ACL, Conformist, Shared Kernel) as defaults because they have well-defined language flow rules. **But this nomenclature is optional.** If your team uses different names — "provider/consumer", "library/client", "core/plugin", or anything else — that's fine. What matters is that each integration point in language.md declares:

1. **Direction**: who defines the language, who consumes it
2. **Translation expectation**: does the consumer use terms directly (conformist) or translate (ACL)?
3. **Shared terms**: which terms are explicitly agreed to cross the boundary

The skill reads whatever you put in the integration point section and applies the direction rules accordingly.

**Default direction rules (DDD nomenclature)**:

```
Provider -> Consumer (language flows from provider to consumer)

OHS:              Provider --API--> Consumer (consumer receives provider's language)
Customer-Supplier: Supplier ------> Customer (customer receives)
Conformist:       Provider ------> Consumer (consumer fully adopts)
ACL:              Provider --X--> [Translation] -> Consumer (blocked, translated)
Shared Kernel:    Module A <----> Module B (explicit shared terms only)
```

## Gotchas

- **architectural dependency tools (ArchUnit, deptrac, Nx, etc.) is necessary but insufficient** — catches type/import dependencies, misses strings and event language
- **Physical data direction != linguistic direction** — event flows HR->Resource (OK), HR language leaks INTO Resource (violation)
- **"Publish event, let downstream listen" is not enough** — without ACL, you trade API coupling for event language coupling (same problem, different channel)
- **Not every new term is a violation** — generic expansions in upstream's own namespace are fine (counters, flags, metadata)
- **15+ violations between two modules** may signal the boundary is wrong, not just the code
