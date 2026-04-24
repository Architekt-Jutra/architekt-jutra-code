---
name: accounting-archetype-mapper
description: Transform domain requirements into an accounting-style value flow model. Identifies resources, accounts, transactions, entries, reversals, validity periods, and allocation rules for any value-tracking system.
argument-hint: "[domain requirements or feature description]"
---

# Accounting Archetype Mapper

Transform any domain description that involves resource tracking into an accounting-style model. The resource does not need to be money — it can be points, quota, inventory, time, credits, energy, or any other value that accumulates or is consumed.

**Output goal**: A complete, implementable model that gives the system traceability, reversibility, auditability, and analytics capability.

## When to Use

**Use this skill when:**
- A domain involves accumulation or consumption of any resource
- You need auditability and traceability for value changes
- Business operations must be reversible without data loss
- Multiple sources of the same value exist (promo vs purchased vs earned)
- Value has time constraints (validity, expiry, monthly resets)

**Output is useful for:**
- Domain modeling sessions before implementation

## When NOT to Use — Fit Test

Before starting the mapping, apply this test. If the domain fails it, **stop and tell the user** that the accounting archetype does not fit, and briefly explain why.

### The core question

> *"Can I ask 'how much X does subject S have?' and get a meaningful number with a transaction history?"*

If **yes** → accounting archetype likely fits.
If the natural question is **"what state is X in?"** → it's a state machine, not a ledger. Do not map.

### Signal table

| Signal in requirements | Likely archetype fit? |
|------------------------|-----------------------|
| "user earns / spends / accrues / consumes N units" | ✅ Yes |
| "balance cannot go below zero" | ✅ Yes |
| "grant / refund / expire / transfer" | ✅ Yes |
| "ticket moves from open → assigned → resolved" | ❌ No — state machine |
| "document has versions / diffs / branches" | ❌ No — version graph |
| "user follows / unfollows another user" | ❌ No — relationship graph |
| "task is assigned / escalated / closed" | ❌ No — workflow/state machine |
| "SLA must be met within 1h" | ❌ No — temporal constraint on event, not value |
| "slot is available / booked / blocked" | ⚠️ Borderline — ask: is there a quantity being reserved? |

### Borderline cases — how to decide

Some domains look like they track a quantity but are actually state machines in disguise:

- **Appointment slots**: "Available" vs "booked" can look like inventory. Apply the test: *can the same slot be partially consumed?* If slots are discrete and binary (booked/free), it's state. If capacity is a numeric quantity (e.g., "room fits 10 people, 7 booked"), it's a resource → fits.
- **Permissions / feature flags**: On/off per user. No accumulation → state, not ledger.
- **Queue position**: Ordinal ranking, not a balance. Does not accumulate or expire as value → state machine.

### If the domain does not fit

Output:

```
## Archetype Fit Assessment: ❌ Does Not Fit

The accounting archetype requires a resource that accumulates, is consumed, and can be
queried as a balance with transaction history. This domain is a [state machine / graph /
workflow / ...] because:

- [specific reason from the requirements]
- The natural question is "what state is X in?" not "how much X does S have?"
```

Do NOT suggest alternative patterns or architectures. Stop here.

---

## Mapping Workflow

### Step 0: Get Requirements

- If provided as argument, use it directly
- If not provided, scan the recent conversation for domain context. If found, use that.
- Only if no argument AND no context in session, ask:
  > "Describe the domain — what value is being tracked, and what business operations affect it?"

---

### Step 1: Identify the Value

Detect what resource behaves like **value** in the domain.

**Detection signals:**
- Nouns that get accumulated, consumed, transferred, or expire
- Quantities with business rules (limits, caps, grants, balances)
- Resources that flow between parties or contexts

**Examples:** money, loyalty points, data quota, leave days, inventory units, credits, API rate limits, energy units

**Key question to answer:** *What is being accumulated or consumed?*

**Output:** Named domain value (e.g., `DATA_QUOTA`, `LOYALTY_POINTS`, `LEAVE_DAYS`) with its unit of measure.

**Multi-unit note:** If the domain uses multiple units (e.g., GB and MB, EUR and USD), identify all units and whether they are interchangeable. If conversion rates exist (1 GB = 1024 MB), document them here. Accounts and entries must always record the canonical unit.

---

### Step 2: Ask Clarifying Questions

Before continuing, identify gaps between the requirements and accounting archetype capabilities. 
Ask about **two categories** of questions in a single `AskUserQuestion` call (up to 4 questions per call; split into multiple calls if more needed):

#### Category A — Standard accounting decisions

Ask only about those **not clearly addressed** in the requirements. Frame questions as **design choices**, not assumed defaults — the answer may be "yes for some cases, no for others":

- **Deletion**: Should the ledger be immutable (append-only), or is deletion/editing of entries allowed in some cases?
- **Expiry**: Should value entries be able to expire? (Some entries might expire, others might not — or expiry might not apply at all.)
- **Negative balance**: Should any account or transaction type be allowed to go below zero? (May differ per account or initiator.)
- ..

#### Category B — Gap-triggered questions

Scan the requirements for **anything the accounting archetype supports but the requirements do not mention**. For each gap found, ask whether that dimension is wanted. Do not limit yourself to the list above — reason freely. Examples of gaps to look for:

- **Allocation strategy**: If multiple value sources exist (earned, purchased, bonus…) — should the system define which is consumed first (FIFO, LIFO, priority order)? Or is this not needed?
- **Balance cap**: Should there be a maximum balance limit? Or a maximum earn rate per period?
- **Validity per source**: Should different sources of the same value have different expiry rules?
- **Earned vs granted distinction**: Should the system distinguish credits earned by the user vs granted by admin for analytics or policy reasons?
- ..

Collect answers before proceeding. If the user cannot answer, document the assumption made in **Implementation Notes**.

#### Handling "it depends / both / varies by situation" answers

Always include **"To zależy / It depends"** as an explicit option in every `AskUserQuestion` call — do not rely on the automatic "Other" fallback. Place it as the last option in each question. If the user selects it, treat it as a **variable policy**:

- Document the *parameter* the ledger will accept (e.g., `valid_to`, `negative_balance_policy`, `max_balance`)
- Note in **Implementation Notes** that its value is computed externally by a policy/business-rules layer and passed in at transaction time
- Do **not** attempt to model the decision logic inside the accounting archetype

This is the correct outcome — variability means the rule lives above the ledger, not inside it.

---

### Step 3: Map Domain Concepts to Accounting Archetypes

For each significant noun and verb in the requirements, produce an explicit mapping table:

```
| Domain Concept       | Accounting Archetype | Notes                          |
|----------------------|---------------------|--------------------------------|
| [domain noun/verb]   | Account / Transaction / Entry / Validity Rule / Allocation Strategy | [why] |
```

After the table, list any domain concepts that **could not be mapped**:

```
## Unmapped Concepts

The following domain concepts have no clear accounting archetype equivalent:
- [concept] — [reason it doesn't fit / decision needed]
```

This section must be present even if empty (`None identified`).

---

### Step 4: Identify Accounts

Determine all **contexts where value lives** — the containers.

**Detection signals:**
- Different ownership or scope contexts for the same value
- Different sources of the same value (promo vs earned vs purchased)
- Counterpart accounts needed for double-entry balance

**Naming convention:** `{owner}_{value_type}_{purpose}` (e.g., `customer_data_balance`, `promo_data_pool`)

**Account types to consider:**
| Type | Purpose | Example |
|------|---------|---------|
| Asset | Value owned by the subject | `customer_wallet` |
| Pool | Source/bucket of value | `promo_pool`, `monthly_grant_pool` |
| Liability | Value owed or pending | `pending_refund_account` |
| Revenue | Value received by the system | `revenue_account` |
| Expense | Value consumed or given away | `cost_account` |

For each account, define:
- **Negative balance policy**: `block` (reject transactions that would go negative), `allow` (overdraft permitted), or `overdraft_limit: N` (allow up to N below zero).
- **Unit**: which unit of measure this account holds.

---

### Step 5: Identify Transaction Types

Find all business operations that **move value between accounts**.

**Detection signals:**
- Verbs in the domain description: grant, purchase, consume, refund, expire, transfer, adjust, allocate
- State changes that affect balance
- Scheduled or triggered operations (monthly reset, expiration job)

**For each transaction type, determine:**
- Business event that triggers it
- Direction of value flow (which accounts affected)
- Whether it is user-initiated or system-initiated
- Whether it can be reversed

---

### Step 6: Define Entries

For each transaction type, define the **debit/credit entry pairs**.

**Double-entry rule:** Every transaction must balance — total debits equal total credits.

**Date fields on every entry:**
- `created_at` — when the entry was recorded in the system (always now, never editable)
- `applied_at` — the point in time the entry is effective for balance calculations (may differ from `created_at` for backdated corrections or retroactive adjustments)

**Format for each transaction:**

```
Transaction: [transaction_name]
Trigger: [what causes it]
  Debit:  [account_name]  [amount + unit]  [notes]
  Credit: [account_name]  [amount + unit]  [notes]
```

---

### Step 7: Model Reversals

Define how each transaction type is **compensated** when reversed.

**Core rule:** Never delete entries. Create a reversing transaction that mirrors the original with swapped debits/credits.

**For each reversible transaction:**

```
Transaction: [transaction_name]_reversal
Trigger: [what causes reversal — refund request, error correction, cancellation]
  Entries: Mirror of original with debits/credits swapped
  Constraint: References original transaction ID
```

**Identify which transactions are:**
- Always reversible (e.g., purchases → refunds)
- Conditionally reversible (e.g., consumption → only within support window)
- Non-reversible (e.g., expiration — once expired, value is gone)

---

### Step 8: Detect Validity

If value has **time constraints**, define validity rules.

**Detection signals:**
- "expires after X days/months"
- "valid until end of billing period"
- "monthly reset"
- "promotional period"

**For each time-constrained value pool:**

```
Account: [account_name]
  validFrom: [when value becomes active]
  validTo:   [when value expires]
  onExpiry:  [what happens — deactivate, zero-out, create expiration transaction]
```

**Validity affects balance calculation:** Balance queries must filter by `applied_at` within `[validFrom, validTo]` to exclude expired entries.

---

### Step 9: Define Allocation Strategy

When multiple value sources exist, define **which is consumed first**.

**Detection signals:**
- Multiple account types holding the same value for one subject
- Business rules like "use promotional credit before paid credit"
- Regulatory rules like "oldest credit expires soonest"

**Allocation strategies:**

| Strategy | Description | When to Use |
|----------|-------------|-------------|
| FIFO | Oldest value consumed first | When value expires and fairness matters |
| LIFO | Newest value consumed first | Rare — mostly for tax accounting scenarios |
| Priority | Explicit ordering by account type | Promo before earned before purchased |
| Proportional | Consume from all sources proportionally | Shared pool scenarios |

---

### Step 9.5: Decision Sanity Check

**Before producing the final output**, enumerate every concrete decision embedded in the draft model and verify each one has a source. This prevents silent assumptions from leaking into the output.

For each decision, classify its source:
- **(R)** — explicitly stated in the requirements
- **(A)** — asked and answered in Step 2
- **(X)** — neither: assumed silently

**Decision checklist** (go through every one that appears in your draft):

| Decision area | Example decisions to check |
|---------------|---------------------------|
| Negative balance policy | Can each account go below zero? Per initiator (user vs admin)? |
| Expiry | Does each value type expire? Which entries? Calendar vs rolling? What happens at expiry? |
| Allocation strategy | Which source consumed first? FIFO/LIFO/priority? Explicitly chosen or assumed? |
| Transfer model | Escrow vs direct? Who can initiate? Bidirectional? |
| Reversal rules | Which transactions are reversible? Conditionally? By whom? Within what window? |
| Backdating | Which transactions allow `applied_at ≠ created_at`? |
| Pending/approval flow | Does a pending state exist? Where does value live during approval? |
| Admin correction | Exists? Can it override all constraints? Can it go negative? |
| Immutability | Append-only or edits allowed? |
| Units / granularity | Integer vs decimal? Minimum unit? |
| Caps / limits | Max balance? Max earn rate? Max redemptions per period? |
| Edge cases at boundary | What happens to value in escrow/pending when it expires? When quota resets? |

**For every (X) decision found:**

1. If the decision has low impact (purely technical, easily changed): mark as explicit assumption in Implementation Notes.
2. If the decision affects business behavior (e.g., allocation order, what happens to escrow at expiry, reversal windows): **stop and ask** using `AskUserQuestion` before delivering the model.

Do not deliver the model until all material (X) decisions are either confirmed or documented as explicit assumptions.

---

## Output Format

```markdown
# Accounting Archetype Model: [Domain Name]

## Domain Value
[Value name, description, and canonical unit of measure]
[If multi-unit: conversion rates and canonical unit]

## Concept Mapping

| Domain Concept | Accounting Archetype | Notes |
|----------------|---------------------|-------|
| ...            | ...                 | ...   |

## Unmapped Concepts
[List or "None identified"]

## Accounts

| Account | Type | Unit | Negative Balance Policy | Description |
|---------|------|------|------------------------|-------------|
| [name]  | [type] | [unit] | block / allow / overdraft_limit: N | [purpose] |

## Transactions & Entries

### [transaction_name]
**Trigger**: [what causes this]
**Reversible**: Yes/No/Conditional ([condition])

| Entry | Account | Direction | Amount | created_at | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-----------|-------|
| 1 | [account] | Debit/Credit | [amount + unit] | now | [rule] | [notes] |
| 2 | [account] | Debit/Credit | [amount + unit] | now | [rule] | [notes] |

[Repeat for each transaction type]

## Validity Rules

| Account | Valid From | Valid To | On Expiry |
|---------|-----------|---------|-----------|
| [account] | [rule] | [rule] | [action] |

## Allocation Strategy

Consumption order when multiple sources exist:
1. [First consumed] — [reason]
2. [Second consumed] — [reason]

## Reversal Rules

| Transaction | Reversal Trigger | Reversible? | Constraint |
|-------------|-----------------|-------------|------------|
| [name] | [trigger] | Yes/No/Conditional | [notes] |

## Implementation Notes
[Key decisions, assumptions made for unanswered clarifying questions, edge cases]
```

---

## Common Patterns & Pitfalls

### Pattern: Authorization Logic Belongs Outside the Ledger

Whether a transaction is *allowed* to happen often depends on many variables: user role, time of day, approval status, business rules, feature flags, relationships between entities. **This logic does not belong in the accounting model.**

The ledger's job is to record what happened, not to decide whether it should happen. Authorization lives in the application layer — it evaluates conditions and, if satisfied, calls the ledger to create the transaction.

```
Application layer:  "Can employee X transfer days to Y?"
                    → check: is X active? does X have ≥ N days? is transfer within annual limit? HR approved?
                    → if all pass: create peer_transfer transaction in ledger

Ledger:             records the transaction, enforces structural invariants only
```

**The one exception — immutable numeric constraints**: If a rule is *unconditionally* numeric ("balance can never go below 0", "account can never exceed 1000 units"), the ledger can pragmatically enforce this via the account's `negative_balance_policy` or a hard cap. These are simple, context-free checks the ledger can own without needing to understand business context.

**Rule of thumb**: If enforcing the constraint requires knowing *who is asking*, *why*, or *what else is happening*, it belongs outside. If it's purely "this number cannot cross this threshold, ever, regardless of anything" — the ledger can own it.

### Pattern: Variable Policy Is Computed Above the Ledger and Passed In

If the *behavior* of any accounting concept varies depending on context — e.g., whether entries expire and after how many days, whether a negative balance is allowed or not, whether double-booking is permitted — that variability does not belong inside the ledger.

The ledger accepts a policy as input and enforces it mechanically. The module above (business rules layer, policy engine, configuration) is responsible for deciding *what* the policy is for this particular case.

Examples:

- "Premium users' points expire after 365 days, free users' after 90 days" → the ledger receives `valid_to` already computed; it does not contain the tier logic
- "Overdraft is allowed for employees with seniority > 2 years, blocked otherwise" → the application evaluates seniority and sets `negative_balance_policy` accordingly before calling the ledger
- "Double-booking of slots is allowed during promotional periods" → the promotion engine passes `allow_overlap: true`; the ledger enforces whatever it receives

**In the model**: when you encounter variable behavior, document the *parameter* the ledger accepts (e.g., `valid_to`, `negative_balance_policy`, `max_balance`) and note that its value is determined externally. Do not model the decision logic itself — that is out of scope for the accounting archetype.

---

## Quality Checks

Before returning the model, verify:

- [ ] Every transaction has at least one debit and one credit entry
- [ ] All accounts referenced in entries are defined in the Accounts section
- [ ] Every account has a defined negative balance policy
- [ ] Every entry has both `created_at` and `applied_at` semantics documented
- [ ] All reversible transactions have a defined reversal mechanism
- [ ] Time-constrained accounts have explicit validity rules
- [ ] Allocation strategy covers all combinations of available sources
- [ ] Concept mapping table is present and complete
- [ ] Unmapped concepts section is present (even if empty)
- [ ] All clarifying question answers (or assumptions) are reflected in the model
- [ ] Multi-unit accounts have canonical unit and any conversion rates documented

---

## Example

**Input:** "Customer gets 10GB monthly data. Unused data expires. Purchased data valid for 30 days."

**Output:**

```markdown
# Accounting Archetype Model: Mobile Data Quota

## Domain Value
DATA_QUOTA — measured in gigabytes (GB, canonical unit); represents available mobile data for a customer.

## Concept Mapping

| Domain Concept | Accounting Archetype | Notes |
|----------------|---------------------|-------|
| Customer's available data | Asset account (customer_data_balance) | Computed view across pools |
| Monthly grant | Pool account + monthly_grant transaction | System-initiated credit |
| Data purchase | Pool account + data_purchase transaction | User-initiated, reversible |
| Data usage | Expense account + data_consumption transaction | Non-reversible |
| Expiry | Validity rule + expiration transaction | Scheduled |

## Unmapped Concepts
None identified.

## Accounts

| Account | Type | Unit | Negative Balance Policy | Description |
|---------|------|------|------------------------|-------------|
| customer_data_balance | Asset | GB | block | Customer's usable data (computed view across pools) |
| monthly_grant_pool | Pool | GB | block | Monthly system-granted data; expires end of billing cycle |
| purchased_data_pool | Pool | GB | block | Paid data add-ons; valid 30 days from purchase |
| consumption_account | Expense | GB | allow | Tracks data actually used (for analytics) |
| system_grant_source | Pool | GB | allow | System-side counterpart for grants |
| revenue_account | Revenue | GB | allow | System-side counterpart for purchases |
| expired_data_account | Expense | GB | allow | Records expired value for analytics |

## Transactions & Entries

### monthly_grant
**Trigger**: First day of billing cycle (scheduled system job)
**Reversible**: No (administrative correction via adjustment transaction)

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | monthly_grant_pool | Credit | 10 GB | Billing cycle start date | Grants quota |
| 2 | system_grant_source | Debit | 10 GB | Billing cycle start date | System issues grant |

### data_purchase
**Trigger**: Customer purchases a data add-on
**Reversible**: Yes → data_purchase_refund (within refund policy window)

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | purchased_data_pool | Credit | N GB | Purchase timestamp | Adds quota |
| 2 | revenue_account | Debit | N GB | Purchase timestamp | System receives value |

### data_consumption
**Trigger**: Customer uses data
**Reversible**: No

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | consumption_account | Debit | X GB | Actual usage timestamp | Records usage |
| 2 | [source pool] | Credit | X GB | Actual usage timestamp | Per allocation strategy |

### expiration
**Trigger**: validTo reached (scheduled job)
**Reversible**: No

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | expired_data_account | Debit | remaining GB | validTo timestamp | Records expired value |
| 2 | monthly_grant_pool | Credit | remaining GB | validTo timestamp | Zeroes pool |

## Validity Rules

| Account | Valid From | Valid To | On Expiry |
|---------|-----------|---------|-----------|
| monthly_grant_pool | Billing cycle start | Billing cycle end | Create expiration transaction; remaining balance zeroed |
| purchased_data_pool | Purchase timestamp | Purchase + 30 days | Create expiration transaction; remaining balance zeroed |

## Allocation Strategy

1. monthly_grant_pool — consumed first (expires soonest)
2. purchased_data_pool — consumed second (FIFO by purchase date)

## Reversal Rules

| Transaction | Reversal Trigger | Reversible? | Constraint |
|-------------|-----------------|-------------|------------|
| data_purchase | Customer refund request | Conditional | Within refund window; purchased_data_pool balance must be sufficient |
| monthly_grant | N/A | No | Use adjustment transaction instead |
| data_consumption | N/A | No | Usage is permanent |
| expiration | N/A | No | Expired value cannot be restored |

## Implementation Notes
- Balance queries must filter by `applied_at` within `[validFrom, validTo]` and applied_at ≤ now
- `created_at` is always system clock at insert time; `applied_at` may differ for backdated corrections
- Negative balance policy is `block` for all customer-facing accounts; overdraft not permitted
- Assumption: deletion not allowed (no mention in requirements); ledger is append-only
```