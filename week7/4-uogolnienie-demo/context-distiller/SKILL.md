---
name: maister:context-distiller
description: Distill bounded contexts by finding safe generalizations across domain concepts. Uses bidirectional linguistic analysis to detect where different things behave identically (generalization candidates) and where same-named things behave differently (context split candidates). Produces a context map with generalized and specific models.
argument-hint: "[domain description, event storming output, or list of concepts to analyze]"
---

# Context Distiller

Analyze a domain to find where different concepts can be safely generalized within a bounded context, and where that generalization must stop because context-specific processes break the abstraction.

**Output goal**: A distilled context map showing which concepts collapse into shared abstractions in which contexts, which remain specific, and where the boundaries between generalized and specific models lie. The map is a modeling artifact — not implementation.

## When to Use

**Two modes of operation:**

1. **Full domain distillation** — provide a full block of requirements, event storming output, or domain description. The skill analyzes all concepts at once, looking for generalizations and ambiguities across the entire domain.
2. **Single concept probe** — provide one specific concept from the requirements (e.g., "check if trainer can be generalized with something else"). The skill focuses on that one concept, searching where it behaves identically to other things and where it starts to differ. Particularly useful when you have a hunch that something "smells like a generalization" but don't want to distill the entire domain at once — you build the picture piece by piece, iteratively.

**Use this skill when:**
- Multiple domain concepts seem to share behavior but you're unsure if they can be unified
- Event storming revealed the same noun appearing in multiple contexts with different commands/events
- You suspect a "God class" is forming because concepts that look similar got merged prematurely
- You want to find reusable, generalized bounded contexts (e.g., availability, inventory, scheduling)
- You need to decide whether to split or merge contexts during strategic design
- You have a single concept and suspect it generalizes with others — use single concept probe mode

**Output is useful for:**
- Strategic design sessions — drawing context boundaries
- Identifying generic subdomains that become reusable capabilities
- Preventing both premature generalization (God Object) and premature splitting (unnecessary complexity)
- Input for archetype mappers — once you know what's generalized, you can map it to known archetypes

## When NOT to Use — Fit Test

### The core question

> *"Do I have two or more concepts that might be the same thing in some contexts but clearly different in others?"*

If **yes** — context distillation likely needed.
If the domain has **a single clear concept with no ambiguity** — you don't need distillation; model it directly.
If the question is **"how should I implement X?"** — this is a modeling skill, not an implementation skill. Use `problem-class-classifier` or an archetype mapper instead.

### Signal table

| Signal in requirements | Likely fit? |
|------------------------|-------------|
| Same word used differently by different people / in different processes | Yes — linguistic ambiguity, needs context split |
| Different words that seem to do the same thing in a given process | Yes — generalization candidate |
| "We have employees, machines, and rooms — all need to be scheduled" | Yes — potential shared abstraction |
| "Order means something different in sales vs manufacturing" | Yes — classic ambiguity |
| Single concept, single context, clear behavior | No — just model it |
| "Should I use microservices or monolith?" | No — this is deployment, not modeling |

### If the domain does not fit

Output:

```
## Context Distillation Assessment: Not Needed

The domain does not exhibit linguistic ambiguity or cross-context generalization opportunities because:

- [specific reason]
- Recommendation: [model directly / use archetype mapper X / ...]
```

Do NOT proceed with distillation. Stop here.

---

## Core Principles
a
These principles guide every step of the distillation. They were derived from iterative modeling practice and encode the reasoning patterns that prevent both premature generalization and premature splitting.

### Principle 1: Generalize behavior, not identity

The question is never "are these things the same?" (a room is not a trainer). The question is "do I do the same thing with them in this context?" If the answer is yes — they can share a model here.

### Principle 2: Boundaries appear where type-specific processes emerge

Generalization holds until one type needs a process that makes no sense for another. Vacation is a process for people. Technical maintenance is a process for equipment. These processes signal: "here the generalization ends, a specific context begins."

### Principle 3: Test by effect in context, not by cause

Shallow test: "Are the processes the same?" — vacation vs maintenance → different → split.
Deep test: "Is the effect the same in my context?" — both cause unavailability → same → generalize.

Always go deeper. If the effect in the consuming context is identical, the generalization still holds. The cause details belong in the source context, not here. The consuming context receives only the event: "resource X unavailable from-to."

### Principle 4: Generalizations live inside one bounded context, not globally

Never create a global "God Resource" that is everything everywhere. A generalization is local — `ReservableResource` exists only inside the scheduling context. In HR context, the same physical person is `Employee`. In maintenance context, the same physical machine is `ServiceableEquipment`. Same entity in reality, different models per context.

### Principle 5: Search by verbs, not nouns

"I reserve a room", "I reserve a trainer", "I reserve equipment" — same verb, same mechanics → generalization candidate. "I send a trainer on vacation" — different verb, different mechanics → separate context. Verbs reveal shared behavior; nouns hide it behind false differences.

### Principle 6: The generalized model must not know the specifics

`ReservableResource` knows it has a `type` field but knows nothing about certifications, maintenance schedules, or vacation policies. If the generalized context starts needing type-specific knowledge — the boundary is wrong or a new context is emerging. Generalization should delegate, not absorb.

---

## Distillation Workflow

### Step 0: Get Domain Input

- If provided as argument, use it directly.
- If not provided, scan the recent conversation for domain context (event storming output, entity lists, process descriptions). If found, use that.
- Only if no argument AND no context in session, ask:
  > "Describe the domain — what are the key concepts (nouns), what operations happen on them (verbs/commands), and are there situations where the same word means different things or different words seem to mean the same thing?"

**Detect mode from input:**
- If input is a full domain description (multiple concepts, processes, requirements) → **full domain distillation** — proceed with all steps analyzing the entire domain.
- If input focuses on a single concept (e.g., "can trainer be generalized?", "check if Room shares behavior with other things") → **single concept probe** — focus Steps 1-3 on that concept. Extract verbs acting on it, find other concepts with matching verbs, and run the bidirectional analysis centered on this concept. The output map may be narrower (fewer contexts), but the depth of analysis for that concept is the same.

**Ideal input includes:** Event storming output (commands + events), list of domain entities, process descriptions, or user stories. The richer the input, the better the distillation. For single concept probe mode, even a sentence like "I suspect trainers and rooms might be the same thing in some contexts" is enough to start.

---

### Step 1: Extract Nouns and Verbs

From the domain input, build two inventories:

**Noun inventory** — every significant domain concept:
- Entity names, actor names, resource names
- Note which processes/contexts each noun appears in

**Verb inventory** — every significant operation:
- Commands, actions, state changes
- Note which nouns each verb acts upon

This is raw material — no interpretation yet.

---

### Step 2: Bidirectional Linguistic Analysis

Apply two complementary analyses:

#### Analysis A: One word → multiple meanings (ambiguity detection)

For each noun that appears in multiple processes or is used by multiple actors, ask:

> "Does this word mean the same thing everywhere it appears?"

**Signals of ambiguity:**
- Different actors describe contradictory properties ("Document has one item" vs "Document has many items")
- Different data is needed in different contexts (Resource in Planning needs capability; Resource in Maintenance needs service schedule)
- Different commands apply in different contexts (you can "send on vacation" an employee but not a machine)

**Each ambiguity found → candidate for context split.** The same word needs different models in different contexts.

#### Analysis B: Multiple words → one meaning (generalization detection)

**Important: Be skeptical, even with a single concept.** If only one noun appears in a context but the verbs suggest the behavior is generic (e.g., "reserve X", "check availability of X"), treat it as a generalization candidate with cardinality 1. Ask: *"Is this really only about X, or does the same behavior apply to things not mentioned?"* Then propose additional concepts in Analysis C.

For groups of different nouns (or even a single noun with generic-looking verbs), ask:

> "In this specific context, do these different things behave identically?"

**Signals of generalization:**
- Same verbs apply: "reserve a room", "reserve a trainer", "reserve equipment"
- Same questions are asked: "is X available at time T?" for all of them
- Same events matter: "X became unavailable" regardless of what X is
- Substitution test passes: replacing one with another doesn't break the context's logic

**Each generalization found → candidate for shared abstraction within a bounded context.**

#### Analysis C: Proposed Additional Concepts (generalization expansion)

For each generalization detected in Analysis B, ask:

> "What other concepts — **not mentioned in the input** — could plausibly exhibit the same behavior and fall into this generalization?"

Think beyond the domain description. If the user described rooms, trainers, and equipment as reservable — what else in this type of business could be reservable? Parking spots? Interpreters? Vehicles?

**Rules:**
- Propose 2–4 additional concepts per generalization, not more.
- Each must pass the same verb/effect test as the original concepts.
- Mark each as **speculative** — these are hypotheses, not facts.
- The user confirms or rejects them in Step 3.

**Why this matters:** Domain experts often omit concepts they take for granted. By proposing candidates, you help them discover missing elements early — before the model solidifies.

Present findings to the user as a table before proceeding.

---

### Step 3: Ask Clarifying Questions

After presenting the linguistic analysis, ask about unresolved ambiguities and uncertain generalizations. Use `AskUserQuestion` (up to 4 questions per call).

Always include **"To zalezy / It depends"** as an explicit last option.

#### Types of questions to ask:

**For each ambiguity found (Analysis A):**
> "You use '[word]' in both [context A] and [context B]. In context A it seems to mean [interpretation A], in context B [interpretation B]. Are these genuinely different concepts that need separate models?"

**For each generalization candidate (Analysis B):**
> "In the context of [process], [noun A] and [noun B] seem to behave identically — both are [generalized verb]. Is there any situation in this context where you'd need to distinguish them?"

**The deep effect test (Principle 3):**
> "[Noun A] has [process X] and [Noun B] has [process Y] — these are clearly different. But in the context of [consuming process], is the effect the same? For example, does it matter *why* something is unavailable, or only *that* it is?"

**Boundary validation:**
> "If a new type of [generalized concept] appeared tomorrow (e.g., a new kind of resource), would it need its own processes, or would the existing generalized model cover it?"

---

### Step 4: Map Contexts and Generalizations

Based on the analysis and answers, produce the distillation map.

For each identified bounded context, determine:

1. **What concepts live here** — with their local names (which may differ from the global domain language)
2. **What's generalized** — which originally-different concepts collapsed into one abstraction here
3. **What's dropped** — which information from source concepts is irrelevant in this context (destylacja = removing what doesn't matter here)
4. **What commands/events operate here** — distilled to the context's vocabulary
5. **What the context's key question is** — the single question this model answers (e.g., "is resource X available at time T?")

**Apply the three generalization techniques from linguistic analysis:**

| Technique | What it does | Example |
|-----------|-------------|---------|
| **Uogolnienie** (generalization by dropping details) | Remove details irrelevant to this context, keep shared attributes | Invoice and Order → Document (only number + creation date matter in document workflow context) |
| **Wyabstrahowanie** (abstraction by finding new concept) | Create a concept that didn't exist in original vocabulary | Employee + Machine + Room → Resource (new word, captures shared essence: availability + capability) |
| **Zmiana reprezentacji** (representation change) | Same concept, different model structure per context | Project in Planning = timeline + milestones; Project in Budgeting = cost centers + allocations |

---


### Step 5: Decision Sanity Check

Before producing the final output, enumerate every boundary decision and verify each has a source:
- **(R)** — from requirements or event storming
- **(A)** — asked and answered in Step 3
- **(L)** — from linguistic analysis (Step 2)
- **(D)** — heurtistic validation (Step 5)
- **(X)** — assumed silently

**For every (X) decision:**
1. If low impact (naming, technical detail): mark as assumption in Notes.
2. If affects boundary placement or generalization scope: **stop and ask** using `AskUserQuestion`.

---

## Output Format

```markdown
# Context Distillation: [Domain Name]

## Linguistic Analysis Summary

### Ambiguities Detected (one word → multiple meanings)

| Word | Context A | Meaning A | Context B | Meaning B | Resolution |
|------|-----------|-----------|-----------|-----------|------------|
| [word] | [context] | [meaning] | [context] | [meaning] | Split into separate models |

### Generalizations Detected (multiple words → one meaning)

| Words | Context | Shared Behavior | Generalized As | Technique |
|-------|---------|----------------|---------------|-----------|
| [word1, word2, ...] | [context] | [what they share] | [new name] | Generalization / Abstraction / Representation change |

### Proposed Additional Concepts (not in input — speculative)

| Generalization | Proposed Concept | Why It Fits | Status |
|----------------|-----------------|-------------|--------|
| [generalized name] | [concept not mentioned by user] | [same verbs/effects apply] | Speculative — confirm with domain expert |

## Distilled Context Map

### [Context Name 1] (generalized)

**Key question**: "[the single question this context answers]"

**Generalized concepts**:
| Original Concepts | Generalized As | What's Kept | What's Dropped |
|-------------------|---------------|-------------|---------------|
| [originals] | [abstraction] | [relevant attrs] | [irrelevant details] |


**Boundaries — what this context does NOT know:**
- [explicitly excluded knowledge]

---

### [Context Name 2] (specific)

**Key question**: "[...]"

**Specific concepts**: [concepts that live only here]
**Type-specific processes**: [processes that break generalization]


[Repeat for each context]

---

## Generalization Safety Notes

**Boundaries that may shift over time:**
- [boundary + what could cause it to change]

**Generalizations that should be revisited if:**
- [condition that would break the generalization]

## Notes
[Key decisions, assumptions, open questions, recommended next steps (e.g., "apply accounting archetype to the ledger context")]
```

---

## Common Patterns & Pitfalls

### Pattern: The Effect Proxy

When specific contexts (HR, Maintenance) have different processes but their effect on a generalized context (Availability) is identical, the generalized context should consume only the effect — an `UnavailabilityPeriod` event — not the cause. The cause details (vacation type, maintenance reason) are irrelevant to availability and constitute context leakage if included.

### Pattern: Generalized Context as Capability

A well-distilled generalized context (Availability, Inventory, Scheduling) often becomes a reusable capability — a generic subdomain that can serve multiple core domains. This is a sign of good distillation. If a generalized context can only serve one core domain, question whether the generalization is real or forced.

### Pattern: Facade Over Premature Split

When you're unsure whether specific contexts (Employee, Device) should be fully independent or just facets of a larger context — cover them with a facade. Start with the generalized model for shared behavior, expose specifics through thin facades. The refactoring to full separation is straightforward when needed; premature separation creates integration complexity that's expensive to undo.

### Pitfall: Generalizing by Nouns Instead of Verbs

"Employee and Machine are both Resources" — this noun-based generalization is dangerous because it collapses identity. The correct analysis goes through verbs: "I schedule employees and machines the same way" → generalization in scheduling context only. "I train employees but service machines" → different contexts.

### Pitfall: Shallow Substitution Test

Testing "can I replace X with Y?" at the process level gives false negatives. Vacation ≠ maintenance → "can't generalize." But testing at the effect level: both produce unavailability → "can generalize in the consuming context." Always test at the effect level in the consuming context, not at the cause level in the source context.

### Pitfall: Context Leakage Through "Just One More Field"

The generalized model has a `type` field. Then someone adds `certification_required` for trainers. Then `max_weight_capacity` for equipment. Each addition is small, but the generalized model now knows about type-specific details. If the generalized context starts needing knowledge about what a type *is* rather than what it *does here* — the boundary has leaked.

### Pitfall: Premature Merging to Save Code

Two contexts look similar "right now" but have different rates of change, different stakeholders, or different regulatory requirements. Merging them saves code today but creates a costly ball of mud when they diverge. The distillation analysis should consider not just current similarity but expected divergence (driver: anti-requirements, regulations).

---

## Quality Checks

Before returning the distillation, verify:

- [ ] Every ambiguity from Step 2A has a resolution (context split or confirmed same meaning)
- [ ] Every generalization from Step 2B has a named abstraction and identified technique
- [ ] Each generalized context has a clear "key question" it answers
- [ ] Each generalized context explicitly lists what's dropped (not just what's kept)
- [ ] Each specific context lists type-specific processes that break generalization
- [ ] Cross-context communication shows what flows AND what's explicitly excluded
- [ ] Heuristics were applied and documented
- [ ] No silent (X) decisions remain on boundary-affecting questions
- [ ] The deep effect test (Principle 3) was applied to every rejected generalization
- [ ] Generalization Safety Notes document conditions under which boundaries may shift
- [ ] No generalized context "knows" type-specific details (Principle 6 check)

---

## Example

**Input:** "System zarządzania szkoleniami. Mamy sale, trenerów i sprzęt (np. aparat do nagrywania). Wszystko trzeba rezerwować na termin szkolenia. Trenerzy mają urlopy i chorobowe. Sprzęt ma przeglądy techniczne. Sale mają pojemność i lokalizację. Handlowcy blokują miejsca dla VIP-ów. Organizatorzy mogą warunkowo zwiększyć limit miejsc."

**Output:**

```markdown
# Context Distillation: Training Management

## Linguistic Analysis Summary

### Ambiguities Detected

| Word | Context A | Meaning A | Context B | Meaning B | Resolution |
|------|-----------|-----------|-----------|-----------|------------|
| Zasób (Resource) | Rezerwacje | Cokolwiek rezerwowalne na czas | HR / Serwis | Konkretny byt z wlasnymi procesami | Split: generalized in reservation, specific in HR/maintenance |
| Miejsce | Rezerwacja sali | Fizyczne miejsce w sali | Zapis uczestnika | Slot w limicie uczestnikow | Split: different models |

### Generalizations Detected

| Words | Context | Shared Behavior | Generalized As | Technique |
|-------|---------|----------------|---------------|-----------|
| Sala, Trener, Sprzet | Rezerwacje | Sprawdz dostepnosc + zablokuj na czas | ReservableResource | Abstraction (new concept) |
| Urlop, Przeglad techniczny, Awaria | Dostepnosc (effect) | Powoduja niedostepnosc zasobu w okresie | UnavailabilityPeriod | Generalization (drop cause, keep effect) |
| Blokada VIP, Rezerwacja | Zapis na szkolenie | Zajmuja slot w limicie | SlotClaim (with TTL for holds) | Generalization (drop reason, keep slot consumption) |

### Proposed Additional Concepts (not in input — speculative)

| Generalization | Proposed Concept | Why It Fits | Status |
|----------------|-----------------|-------------|--------|
| ReservableResource | Parking (miejsca parkingowe) | "Zarezerwuj parking na czas szkolenia" — same verb, same availability check | Speculative |
| ReservableResource | Tłumacz / Interpreter | "Zarezerwuj tłumacza na termin" — same block/unblock mechanics as trainer | Speculative |
| UnavailabilityPeriod | Remont sali | Sala zamknięta na remont — same effect as vacation/maintenance: unavailable from-to | Speculative |
| SlotClaim | Lista oczekujących (waitlist) | Zajmuje potencjalny slot z priorytetem — similar consumption pattern with TTL | Speculative |

## Distilled Context Map

### Availability (generalized)

**Key question**: "Is resource X available at time T?"

**Generalized concepts**:
| Original Concepts | Generalized As | What's Kept | What's Dropped |
|-------------------|---------------|-------------|---------------|
| Sala, Trener, Sprzet | Resource | resourceId, type | Pojemnosc, lokalizacja, certyfikacje, harmonogram przegladow |
| Urlop, Przeglad, Awaria | UnavailabilityPeriod | resourceId, from, to, ownerId | Powod niedostepnosci (urlop vs przeglad), typ urlopu, status naprawy |

**Commands**: block(partyId, resourceId, timeRange), unblock(partyId, resourceId), disable(resourceId)
**Events**: Blocked, Unblocked, Disabled

**Boundaries — what this context does NOT know:**
- Why a resource is unavailable (vacation, maintenance, breakdown)
- What type of resource it is beyond an opaque ID
- Capacity of rooms, certifications of trainers, repair history of equipment

---

### Training Enrollment (specific)

**Key question**: "Can participant P enroll in edition E, given seat limits and holds?"

**Specific concepts**: TrainingEdition, Enrollment, Hold (VIP block), CapacityAdjustment
**Type-specific processes**: Conditional capacity increase by organizer, VIP hold with TTL by salesperson
**Commands**: enroll(participantId, editionId), holdSeat(editionId, salespersonId, ttl), adjustCapacity(editionId, delta, reason)
**Events**: Enrolled, SeatHeld, SeatReleased, CapacityAdjusted

**Integration with generalized contexts:**
- Consumes <- Availability: checks resource availability before confirming edition
- Does NOT consume cause of unavailability — only the binary answer

---

### HR / Employee (specific)

**Key question**: "What is the work status and leave balance of employee X?"

**Specific concepts**: Employee, VacationRequest, SickLeave, WorkSchedule
**Type-specific processes**: Vacation approval workflow, sick leave documentation, contract management
**Commands**: requestVacation(employeeId, dateRange), reportSickLeave(employeeId, dateRange, documentation)
**Events**: VacationApproved, SickLeaveReported

**Integration with generalized contexts:**
- Emits -> Availability: UnavailabilityPeriod(resourceId=employeeId, from, to) — cause stripped

---

### Equipment Maintenance (specific)

**Key question**: "What is the maintenance status and schedule of equipment X?"

**Specific concepts**: Equipment, MaintenanceSchedule, RepairRecord, ConditionStatus
**Type-specific processes**: Periodic maintenance scheduling, damage reporting, repair tracking
**Commands**: scheduleMaintenance(equipmentId, dateRange), reportDamage(equipmentId, description)
**Events**: MaintenanceScheduled, DamageReported, RepairCompleted

**Integration with generalized contexts:**
- Emits -> Availability: UnavailabilityPeriod(resourceId=equipmentId, from, to) — cause stripped
- Emits -> Availability: Disabled(resourceId=equipmentId) — when equipment permanently out of service

---
====
## Generalization Safety Notes

**Boundaries that may shift:**
- If training enrollment needs to know *why* a trainer is unavailable (e.g., "show alternative dates after vacation ends") — Availability context would need to expose cause metadata. Consider a thin enrichment layer rather than leaking cause into Availability.

**Generalizations to revisit if:**
- Different resource types need fundamentally different availability logic (e.g., rooms have recurring schedules, trainers have one-off blocks) — may need to split Availability per resource type.
- Capacity of rooms becomes part of availability (not just reserved/free but "3 of 10 seats taken") — this shifts from binary availability to quantity-based, which may warrant a separate Capacity context.

## Notes
- The Availability context is a strong candidate for the accounting archetype (resource = availability units, block = consumption, unblock = reversal). Consider applying `accounting-archetype-mapper` if auditability of availability changes is needed.
- The Enrollment context handles quantity-based seat management — this is resource contention. Consider applying `aggregate-designer` for the enrollment aggregate.
- Start with Availability as a single module; split HR and Equipment Maintenance behind facades initially. If regulatory pressure or team structure demands full separation, the refactoring is straightforward because the integration is event-based.
```
