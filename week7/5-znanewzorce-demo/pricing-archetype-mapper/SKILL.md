---
name: pricing-archetype-mapper
description: Transform domain requirements into a Pricing Archetype model. Identifies complexity level (1–9), designs Calculator layer, Component tree, Validity versioning, Applicability conditions, and context dimensions. Produces implementable model with explicit concept mapping and unmapped concepts sections.
argument-hint: "[domain requirements or feature description]"
---

# Pricing Archetype Mapper

Transform any domain where a **computed price** answers a business question into a structured pricing model. The value being priced does not need to be monetary — it can be rates, credits, multipliers, or any computed value that depends on context.

**Output goal**: A complete, implementable model that gives the system historical reproducibility, full component breakdown, context-sensitivity, and auditability.

## When to Use

**Use this skill when:**
- A domain requires computing a price/rate/value (not just storing it)
- The computed value depends on context: time, quantity, customer segment, channel, product parameters
- Price has temporal lifecycle — changes over time, old transactions must remain reproducible
- Price has multiple components (net + markup + VAT + discount) that stakeholders need to see separately
- Audit or regulatory requirements exist for pricing decisions

**Output is useful for:**
- Pricing engine design before implementation
- Multi-stakeholder billing systems (marketplace, B2B, regulated industries)
- Domain modeling sessions before pricing module implementation

## When NOT to Use — Fit Test

Before starting the mapping, apply this test. If the domain fails it, **stop and tell the user** that the pricing archetype does not fit, and briefly explain why.

### The core question

> *"Can I ask 'how much does X cost for customer Y at time T in context C?' and get a reproducible, auditable answer with full breakdown?"*

If **yes** → pricing archetype likely fits.
If the natural question is **"how much of X does Y have?"** → it's an accounting ledger. Use `accounting-archetype-mapper` instead.
If the natural question is **"what state is X in?"** → it's a state machine. Do not map.

### Signal table

| Signal in requirements | Likely archetype fit? |
|------------------------|-----------------------|
| "price depends on quantity / time of day / customer tier" | ✅ Yes |
| "different prices for different channels or segments" | ✅ Yes |
| "need to audit why this price was charged" | ✅ Yes |
| "price has components: net + VAT + surcharge + discount" | ✅ Yes |
| "price changes and old transactions must stay reproducible" | ✅ Yes |
| "user earns / spends / transfers N units" | ❌ No — accounting archetype |
| "task moves from open → in-progress → closed" | ❌ No — state machine |
| "price is a single stored number, never computed, never changes" | ⚠️ Level 1 only — may not need full archetype |

### If the domain does not fit

Output:

```
## Archetype Fit Assessment: ❌ Does Not Fit

The pricing archetype models computed prices that depend on context. This domain is a
[accounting ledger / state machine / ...] because:

- [specific reason from the requirements]
- The natural question is "[...]" not "how much does X cost for Y at time T?"
```

Do NOT suggest alternative patterns. Stop here.

---

## Mapping Workflow

### Step 0: Get Requirements

- If provided as argument, use it directly
- If not provided, scan the recent conversation for domain context. If found, use that.
- Only if no argument AND no context in session, ask:
  > "Describe the domain — what is being priced, what factors affect the price, and what business questions must the system answer?"

---

### Step 1: Assess Complexity Level

Locate the **highest applicable level** in the requirements. Higher levels include all lower levels.

| Level | Name | Signal in requirements |
|-------|------|------------------------|
| 1 | **Static price** | One stored number, no context dependency, never changes |
| 2 | **Currency-aware** | Multiple currencies or arithmetic correctness required (`Money` type needed) |
| 3 | **Time-dependent** | Price changes over time; history of values must be queryable |
| 4 | **Multi-dimensional** | Price depends on product / customer / channel / quantity / context |
| 5 | **Multi-stakeholder breakdown** | Named components visible separately: net, markup, VAT, commission |
| 6 | **Price change as event** | New version does not overwrite old; change has a `validFrom` date |
| 7 | **Historical reproducibility** | Old transactions can be re-priced using rules active at transaction time |
| 8 | **Algorithm history** | Not just value history — the computation logic itself is versioned (`definedAt`) |
| 9 | **Eligibility + consistency** | Multiple active tariffs; system selects which applies; cross-channel coherence enforced |

**Guidance:**
- Levels 1–2: Pricing archetype may be overkill. Document the level and ask whether simplicity is preferred.
- Levels 3–5: Core archetype — Calculator + Component + Validity sufficient.
- Levels 6–8: Add `ComponentVersion` with immutable snapshots and `definedAt` timestamp.
- Level 9: Add Eligibility layer (application layer — never inside the pricing engine).

---

### Step 2: Ask Clarifying Questions

Before continuing, identify gaps. Ask about **two categories** in a single `AskUserQuestion` call (up to 4 questions per call; split into multiple calls if more needed). Always include **"To zależy / It depends"** as an explicit last option in every question.

#### Category A — Standard pricing decisions

Ask only about those **not clearly addressed** in requirements:

- **Interpretation**: Is the business output TOTAL only (how much does N cost?), or also UNIT (average price per unit) and MARGINAL (cost of the N-th unit)?
- **Historical reproducibility**: Must old transactions be re-priceable using the rules active at transaction time? (Determines whether `ComponentVersion` with `definedAt` is required.)
- **Applicability conditions**: Are there business conditions determining whether a component applies — beyond time validity? (customer segment, sales channel, geographic region, promotional context)
- **VersionUpdateStrategy**: How strict are overlapping version rules? (`REJECT_IDENTICAL` | `REJECT_OVERLAPPING` | `ALLOW_ALL`)
- **Product-pricing mapping**: One pricing tree per product (1:1), multiple tariffs per product (1:N), shared pricing across products (N:1), fully independent (N:M), or price stored directly on product (1:0)?

#### Category B — Gap-triggered questions

Scan the requirements for anything the archetype supports but requirements do not mention:

- **Multi-currency**: Are there components in different currencies? Conversion rates needed?
- **Billing period split**: If price changes mid-billing-period, must the system split the charge proportionally?
- **Eligibility**: Are there multiple concurrent tariffs, and must the system select which applies per customer/context?
- **Breakdown visibility**: Do end customers see the full component breakdown (invoice line items) or only the total?
- **Audit/regulatory**: Are there compliance requirements for pricing computation logs?
- **Concurrency/idempotency**: Must the same pricing request return identical results when called multiple times (protection against double-computation)?
- **Any other gap** you identify between what the archetype can model and what the requirements specify.

Collect answers before proceeding. If the user cannot answer, document the assumption in **Implementation Notes**.

#### Handling "it depends / both / varies by situation" answers

Always include **"To zależy / It depends"** as an explicit option in every `AskUserQuestion` call — do not rely on the automatic "Other" fallback. Place it as the last option. If the user selects it, treat it as a **variable policy**:

- Document the *parameter* passed into the pricing engine (e.g., `interpretation`, `applicabilityContext`, `versionUpdateStrategy`)
- Note in **Implementation Notes** that its value is determined externally by a policy/business-rules layer
- Do **not** model the decision logic inside the pricing engine

---

### Step 3: Map Domain Concepts to Pricing Archetypes

For each significant noun and verb in the requirements, produce an explicit mapping table:

```
| Domain Concept       | Pricing Archetype | Notes |
|----------------------|-------------------|-------|
| [domain noun/verb]   | Calculator / Interpretation / Component / ComponentVersion / Validity / Applicability / Parameter / Eligibility | [why] |
```

After the table, list any domain concepts that **could not be mapped**:

```
## Unmapped Concepts

The following domain concepts have no clear pricing archetype equivalent:
- [concept] — [reason / decision needed]
```

This section must be present even if empty (`None identified`).

---

### Step 4: Design Calculator Layer

Identify which **Calculator types** are needed and their parameters.

**Calculator** = pure function `calculate(Parameters) → Money`. No business conditions, no time validity, no segment logic — that belongs in Applicability and Validity.

**Available Calculator types:**

| Type | Formula | Use when |
|------|---------|---------|
| `SimpleFixedCalculator` | `f(x) = c` | Flat fee, constant component |
| `StepFunctionCalculator` | `f(q) = base + ⌊q/step⌋ × increment` | Tiered pricing, graduated rates |
| `DiscretePointsCalculator` | `f(key) = map[key]` | Exact lookup table; throws for undefined keys |
| `DailyIncrementalCalculator` | `f(date) = start + days × increment` | Date-based linear growth |
| `ContinuousLinearTimeCalculator` | Linear interpolation between two time points | Smooth time-based transitions |
| `CompositeFunctionCalculator` | Delegates to sub-calculator matching range(x) | Piecewise: different formulas per numeric/time range |

**For each Calculator, define:**
- `CalculatorId` (stable identifier)
- Type and constructor-time parameters (e.g., `stepSize`, `basePrice`, `rate`)
- Which call-time parameters come from the `Parameters` object (e.g., `quantity`, `duration`)
- Interpretation (TOTAL | UNIT | MARGINAL)

---

### Step 5: Design Component Tree

Map the price structure as a tree of **SimpleComponent** (leaves) and **CompositeComponent** (nodes).

**SimpleComponent** — semantic leaf:
- Maps business parameters to calculator parameters (`parameterMappings`)
- Has `CalculatorId` and `Interpretation`
- Examples: `startup-fee`, `energy-cost`, `cpo-markup`, `vat-23`

**CompositeComponent** — semantic node:
- Aggregates children; manages inter-component dependencies via **ParameterValue algebra**:
  - `ValueOf(componentId)` — use computed value of a sibling
  - `SumOf(componentIds)` — sum of multiple siblings (e.g., VAT base = sum of net components)
  - `DifferenceOf(a, b)` — a minus b
  - `ProductOf(a, b)` — a times b
- Examples: `net-cost`, `total-invoice`, `customer-subtotal`

**ComponentBreakdown** — the result tree: mirrors the component tree with computed `Money` values at every node, enabling full auditability and invoice line-item generation.

**For each component, specify:**
- ID and type (Simple/Composite)
- For Simple: `CalculatorId` + `parameterMappings` + `Interpretation`
- For Composite: children list + ParameterValue dependencies

---

### Step 6: Define Validity & Versioning

If complexity level ≥ 3, every component needs temporal versioning.

**Validity** = half-open interval `[validFrom, validTo)`:
- `validFrom`: first moment the version is effective (inclusive)
- `validTo`: first moment it is no longer effective (exclusive); use "end of time" sentinel for open-ended
- Constructors: `ALWAYS`, `from(t)`, `until(t)`, `between(t1, t2)`

**ComponentVersion** = immutable snapshot of configuration:
- `SimpleComponentVersion`: `{calculatorId, parameterMappings, applicability, validity, definedAt}`
- `CompositeComponentVersion`: `{children, parameterValueDependencies, applicability, validity, definedAt}`
- `definedAt` = system timestamp when the version was recorded (never editable)
- `Component` = `{ComponentId, List<ComponentVersion>}`

**`versionAt(timestamp)`**: selects the version where `validFrom ≤ t < validTo`. If multiple versions match (overlap allowed), resolve by latest `validFrom`, then latest `definedAt`.

**VersionUpdateStrategy** (governs new version creation):
- `REJECT_IDENTICAL`: reject if new version has same configuration as current
- `REJECT_OVERLAPPING`: reject if new validity overlaps any existing version
- `ALLOW_ALL`: accept any; overlaps resolved by recency rule

**For each component, specify:**
- VersionUpdateStrategy
- Current version's `validFrom` / `validTo`
- How "end of promotion" is modeled: explicit version covering remaining time, or auto-expiry of temporary version

---

### Step 7: Define Applicability Conditions

If complexity level ≥ 4 with context-dependent activation, define **Applicability** per component version.

**Applicability** answers: "Is this component active for *this* context, beyond just being temporally valid?"

**Evaluation logic:**
- `SimpleComponentVersion`: active when `validity.isValidAt(t) AND applicability.isSatisfiedBy(context)`
- `CompositeComponentVersion`: active when `validity.isValidAt(t) AND at least one child isApplicableFor(context)`

**Common applicability dimensions:**
- Customer segment (B2C / B2B / VIP)
- Sales channel (web / app / in-store / API)
- Geographic region (country, timezone)
- Time-of-day window (night rate, peak hours)
- Promotional context (`promotion_code`, `campaign_id`)
- Product category or usage type

**Non-applicable component behavior** (business decision):
- Return `Money.zero()` and include in breakdown with zero value
- Exclude from breakdown entirely

**For each component with applicability, specify:**
- Condition dimensions checked
- Logic (AND of all dimension checks)
- Behavior when not applicable

---

### Step 8: Define Parameters & Context Dimensions

Every pricing computation receives a `Parameters` object. Define all dimensions.

**Always mandatory:**
- `timestamp` — determines which `ComponentVersion` is active via `versionAt()`

**Domain-specific (detect from requirements):**

| Dimension | Purpose | Example |
|-----------|---------|---------|
| `quantity` | Input to calculators (units, kWh, GB, minutes) | `38.4 kWh` |
| `duration` | Time-based calculators | `37 min` |
| `unit` | Unit of measure for quantity | `kWh`, `GB`, `kg` |
| `customer_segment` | Applicability conditions | `B2C`, `B2B_PREMIUM` |
| `channel` | Applicability conditions | `web`, `mobile`, `pos` |
| `country` | Geographic applicability | `PL`, `DE` |
| `product_id` | Links to product-pricing mapping | `pkg-enterprise-v2` |
| `currency` | For multi-currency models | `PLN`, `EUR` |

---

### Step 9: Determine Product-Pricing Mapping Scenario

Identify the relationship between the Product Catalog and Pricing Module:

| Scenario | Structure | When to use |
|----------|-----------|-------------|
| **1:1** | One product → one pricing component tree | Utilities, telco — stable one-to-one |
| **1:N** | One product → multiple pricing tariffs | Banking, cloud — standard + premium + promo tariffs |
| **N:1** | Many products → one pricing rule | SaaS flat subscription shared across plan variants |
| **N:M** | Independent lifecycles; mapping via eligibility | Mature pricing — products and tariffs evolve independently |
| **1:0** | Price stored directly on product record | Simple catalogs, low volatility, no breakdown needed |

**For the chosen scenario, define:**
- Mapping table (product IDs → component tree root IDs)
- If 1:N or N:M: how is eligibility determined (which tariff applies for which customer/context)?
- Whether catalog versioning (product structure) is needed independently from pricing versioning

**Eligibility belongs in the application layer** — it selects which pricing tree to invoke for a given customer/context. The pricing engine receives the selected root component ID and computes; it does not choose.

---

### Step 9.5: Decision Sanity Check

**Before producing the final output**, enumerate every concrete decision in the draft model and verify each has a source:
- **(R)** — explicitly stated in requirements
- **(A)** — asked and answered in Step 2
- **(X)** — neither: assumed silently

**Decision checklist:**

| Decision area | Example decisions to check |
|---------------|---------------------------|
| Complexity level | Which of the 9 levels applies? Is full versioning needed? |
| Interpretation | TOTAL only, or also UNIT and MARGINAL? Adapters needed? |
| Calculator type per component | Which of the 6 types? Piecewise or simple? |
| VersionUpdateStrategy | REJECT_IDENTICAL / REJECT_OVERLAPPING / ALLOW_ALL? |
| Applicability dimensions | Which context dimensions trigger conditions? |
| Non-applicable behavior | `Money.zero()` or exclude from breakdown? |
| Historical reproducibility | Required? Determines whether `definedAt` matters |
| Billing period split | Mid-period price changes — split or not? |
| Eligibility | Multiple concurrent tariffs? How is one selected? |
| Product-pricing mapping | Scenario (1:1 / 1:N / N:1 / N:M / 1:0)? |
| Multi-currency | Single or multi? Conversion rates? |
| Parameter granularity | Which dimensions go into Parameters? Typed or generic map? |
| Boundary behavior | `>` or `≥` at range edges? What happens at exact 10 min? |

**For every (X) decision found:**
1. If low impact (purely technical, easily changed): mark as explicit assumption in Implementation Notes.
2. If affects business behavior: **stop and ask** using `AskUserQuestion` before delivering the model.

---

## Output Format

```markdown
# Pricing Archetype Model: [Domain Name]

## Pricing Domain
[What's being priced, detected complexity level (1–9), justification]

## Concept Mapping

| Domain Concept | Pricing Archetype | Notes |
|----------------|-------------------|-------|
| ...            | ...               | ...   |

## Unmapped Concepts
[List or "None identified"]

## Calculator Design

| Calculator ID | Type | Parameters | Interpretation | Notes |
|---------------|------|-----------|----------------|-------|
| [id] | [type] | [params] | TOTAL/UNIT/MARGINAL | [purpose] |

## Component Tree

[ASCII tree representation]

| Component ID | Type | Calculator / Children | ParameterValue Dependencies | Notes |
|-------------|------|----------------------|---------------------------|-------|
| [id] | Simple/Composite | [calculatorId or child list] | [algebra] | [purpose] |

## Validity Rules

| Component | VersionUpdateStrategy | validFrom (current) | validTo | Notes |
|-----------|----------------------|---------------------|---------|-------|
| [id] | [strategy] | [rule] | [rule] | [notes] |

## Applicability Conditions

| Component | Condition Dimensions | Logic | Non-Applicable Behavior |
|-----------|---------------------|-------|------------------------|
| [id] | [dimensions] | AND/OR rule | Money.zero() / exclude |

## Context Dimensions (Parameters)

| Parameter | Type | Mandatory | Purpose |
|-----------|------|-----------|---------|
| timestamp | Instant | Yes | versionAt() selection |
| [param] | [type] | Yes/No | [purpose] |

## Product-Pricing Mapping

**Scenario**: [1:1 / 1:N / N:1 / N:M / 1:0]

| Product | Pricing Component Root | Notes |
|---------|----------------------|-------|
| [product] | [component root ID] | [notes] |

## Interpretation
[Which interpretations needed; adapters required; facade methods]

## Implementation Notes
[Key decisions, assumptions, edge cases, boundaries]
```

---

## Common Patterns & Pitfalls

### Pattern: Calculators Are Pure Functions — Keep Them That Way

Calculators must contain **only math**. They must not contain:
- Business conditions ("if customer is B2B...")
- Time validity checks ("if now is after 2024-01-01...")
- Tariff selection logic ("which pricing applies...")

These belong in **Applicability** (business conditions), **Validity** (time), and **Eligibility** (tariff selection — application layer). A calculator that contains conditions is a symptom of architectural drift — the system works until the first business rule change.

```
Calculator:    calculate(Parameters) → Money       (math only)
Applicability: isSatisfiedBy(context) → boolean   (business conditions)
Validity:      isValidAt(timestamp)   → boolean   (time)
Eligibility:   selectTariff(customer, context)     (application layer)
```

### Pattern: Interpretation Is Configuration, Not Class Hierarchy

Anti-pattern: `StepFunctionTotalCalculator`, `StepFunctionUnitCalculator`, `StepFunctionMarginalCalculator` — 6 calculator types × 3 interpretations = 18 classes, three different implementations of the same math.

Correct: one `StepFunctionCalculator` configured with `Interpretation` enum. Adapters (`UnitToTotalAdapter`, `MarginalToTotalAdapter`) wrap a calculator and convert its output without touching the math.

Facade pattern: `calculateTotal()`, `calculateUnit()`, `calculateMarginal()` — automatically selects the appropriate adapter based on the source calculator's declared interpretation.

### Pattern: Product Catalog and Pricing Module Are Independent Trees

Both are versioned trees, but they change at different rates and for different reasons:
- **Catalog changes**: new feature added, package retired, product structure changed
- **Pricing changes**: rate update, promotion, regulatory adjustment, competitor response

Keep them independent and connected only by the mapping table (`product_id → component_root_id`). Merging them creates change interference — a pricing update forces a catalog release and vice versa.

### Pattern: Eligibility Lives Outside the Pricing Engine

Selecting *which tariff applies* to a customer requires knowing the customer, their history, active campaigns, channel, and business rules. This logic does not belong inside the pricing engine.

```
Application layer:  "Which tariff applies to customer X on channel Y?"
                    → evaluate eligibility rules → returns component_root_id
                    → call pricing engine: calculate(component_root_id, Parameters)

Pricing engine:     given (component_root_id, Parameters) → ComponentBreakdown
```

### Pattern: History Is a Model Outcome, Not a Log

When versioning is implemented correctly, historical reproducibility is automatic — no separate logging needed. The system recomputes the historical price by calling `versionAt(historical_timestamp)` on the component tree. The model is its own audit log.

"Luty mija. Nie robimy nic. I to jest najważniejsze zdanie." — after a promotional version expires, the system automatically returns to the previous version. Zero conditional logic in the application layer.

---

## Quality Checks

Before returning the model, verify:

- [ ] Complexity level is explicitly stated and justified with evidence from requirements
- [ ] Every calculator is a pure function (no conditions, no time checks embedded)
- [ ] Every SimpleComponent has a `CalculatorId` and `Interpretation`
- [ ] Every CompositeComponent has a children list and any `ParameterValue` dependencies
- [ ] All `ParameterValue` dependencies (`SumOf`, `ValueOf`, etc.) reference valid component IDs
- [ ] Applicability conditions are in `Applicability` — not embedded in Calculator math
- [ ] Validity rules use `[validFrom, validTo)` half-open interval notation consistently
- [ ] `VersionUpdateStrategy` is defined for each component
- [ ] `timestamp` is in Parameters and documented as mandatory
- [ ] Concept mapping table is present and complete
- [ ] Unmapped concepts section is present (even if empty)
- [ ] Product-pricing mapping scenario is identified
- [ ] Interpretation strategy documented (TOTAL only, or with adapters)
- [ ] All clarifying question answers (or assumptions) are reflected in the model
- [ ] Implementation Notes document all (X) assumptions and boundary decisions

---

## Example

**Input:** "Stacja ładowania EV pobiera: opłatę startową 2 PLN, stawkę 0.80 PLN/kWh, dopłatę czasową 0.50 PLN/min po pierwszych 10 minutach, rabat nocny -10% na całość między 22:00 a 6:00. VAT 23%. Stawki mogą się zmieniać w czasie — stare sesje muszą być przeliczalne wg stawek z dnia sesji."

**Detected complexity level**: 8 — multi-component, context-dependent (time of day), temporally versioned, historically reproducible.

**Output:**

```markdown
# Pricing Archetype Model: EV Charging Session

## Pricing Domain
**What's priced**: Single charging session at EV station.
**Complexity level**: 8 — multi-component breakdown, time-of-day applicability, full version history with `definedAt` for algorithm reproducibility.

## Concept Mapping

| Domain Concept | Pricing Archetype | Notes |
|----------------|-------------------|-------|
| Opłata startowa 2 PLN | SimpleComponent + SimpleFixedCalculator | Flat fee per session, always applicable |
| Stawka 0.80 PLN/kWh | SimpleComponent + SimpleFixedCalculator | Linear: rate × kWh |
| Dopłata czasowa po 10 min | SimpleComponent + CompositeFunctionCalculator | Range [0,10) = 0, [10,∞) = 0.50/min |
| Rabat nocny -10% | SimpleComponent + SimpleFixedCalculator(-10%) | Applicability: session_start ∈ [22:00, 06:00) |
| VAT 23% | SimpleComponent + SimpleFixedCalculator(0.23) | ParameterValue: SumOf(net components) |
| Cena końcowa | CompositeComponent (root) | Aggregates net + VAT |
| Zmiana stawki | New ComponentVersion with new validFrom | REJECT_OVERLAPPING strategy |
| Historia sesji | versionAt(session.startTimestamp) | Reproduces prices from session time |
| Rozbicie faktury | ComponentBreakdown tree | Full tree returned per calculation |

## Unmapped Concepts
- Wybór taryfy dla stacji — eligibility (application layer, not pricing engine)

## Calculator Design

| Calculator ID | Type | Parameters | Interpretation | Notes |
|---------------|------|-----------|----------------|-------|
| `calc-startup` | SimpleFixed | `amount = 2.00 PLN` | TOTAL | Per session |
| `calc-energy` | SimpleFixed | `rate = 0.80 PLN/kWh` | TOTAL | Linear: rate × kwh |
| `calc-time-surcharge` | CompositeFunctionCalculator | ranges: [0,10) → 0 PLN/min; [10,∞) → 0.50 PLN/min | TOTAL | Zero for first 10 min |
| `calc-night-discount` | SimpleFixed | `rate = -0.10` | TOTAL | -10% of base |
| `calc-vat` | SimpleFixed | `rate = 0.23` | TOTAL | 23% of SumOf(net) |

## Component Tree

```
total-session-price (Composite)
├── net-cost (Composite)
│   ├── startup-fee       (Simple) → calc-startup
│   ├── energy-cost       (Simple) → calc-energy          [param: kwh]
│   ├── time-surcharge    (Simple) → calc-time-surcharge  [param: duration_min]
│   │     Applicability: duration_min > 10
│   └── night-discount    (Simple) → calc-night-discount
│         Applicability: session_start_time ∈ [22:00, 06:00)
│         ParameterValue: ValueOf(net-cost-subtotal)
└── vat                   (Simple) → calc-vat
      ParameterValue: SumOf(startup-fee, energy-cost, time-surcharge, night-discount)
```

## Validity Rules

| Component | VersionUpdateStrategy | validFrom (current) | validTo | Notes |
|-----------|----------------------|---------------------|---------|-------|
| All components | REJECT_OVERLAPPING | Business launch date | open-ended | Rate change → new version |

## Applicability Conditions

| Component | Condition Dimensions | Logic | Non-Applicable Behavior |
|-----------|---------------------|-------|------------------------|
| `time-surcharge` | `duration_min` | `duration_min > 10` | Money.zero(), included in breakdown |
| `night-discount` | `session_start_time` | `time ∈ [22:00, 06:00)` | Excluded from breakdown |

## Context Dimensions (Parameters)

| Parameter | Type | Mandatory | Purpose |
|-----------|------|-----------|---------|
| `timestamp` | Instant | Yes | versionAt() — selects active component versions |
| `kwh` | BigDecimal | Yes | Input for energy-cost calculator |
| `duration_min` | BigDecimal | Yes | Input for time-surcharge calculator |
| `session_start_time` | LocalTime | Yes | Applicability check for night-discount |
| `currency` | Currency | No | Defaults to PLN |

## Product-Pricing Mapping
**Scenario**: 1:1 — one station type maps to one pricing component tree root.

| Product | Pricing Component Root | Notes |
|---------|----------------------|-------|
| `ev-station-standard` | `total-session-price` | Single tariff per station type |

## Interpretation
TOTAL only — billing system needs total charge per session. UNIT (price per kWh average) not needed in current scope.

## Implementation Notes
- Complexity level 8: `ComponentVersion` with `definedAt` mandatory for full algorithm history
- `REJECT_OVERLAPPING` chosen: no ambiguity in which version is active at a given timestamp
- Night discount: `session_start_time` determines applicability, not `session_end_time`
- Boundary: `duration_min > 10` (strict), not `≥ 10` — exactly 10 minutes = no surcharge
- VAT base: `SumOf` of all net components including the night discount (negative value reduces VAT base)
- Assumption: single currency (PLN); multi-currency not required per current requirements
- Assumption: append-only versions; no deletion of historical ComponentVersions
```
