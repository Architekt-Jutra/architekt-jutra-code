# Assessment Criteria: Cascading Shared Dependency

Evaluate the agent's incident diagnosis on four dimensions using both the ATIF trajectory and workspace artifacts.

## 1. Root Cause Accuracy (0–25)

| Score | Criteria |
|-------|----------|
| 0     | No diagnosis written, or diagnosis blames an unrelated system |
| 5     | Blames LiteLLM, LLM model, or Langfuse — misses shared resource entirely |
| 10    | Identifies DB slowness but attributes it to postgresql itself (not source of load) |
| 15    | Identifies that some other service is loading postgresql but does not name warehouse specifically |
| 20    | Correctly identifies warehouse as the load source but misses the feature-gate trigger |
| 25    | Full chain: warehouse-full-inventory-sync gate toggled 4h ago → warehouse syncs all SKUs hourly → saturates shared postgresql pool → ai-description waits on DB |

**Key checks (evidence from trajectory + workspace):**
- Is "warehouse" named as the load source?
- Is "warehouse-full-inventory-sync" (feature gate) identified as the trigger?
- Is "shared postgresql" or "connection pool" named as the mechanism?
- Is the temporal chain (4h ago → gate on → load → saturation → ai-description wait) reconstructed?

## 2. Diagnostic Path Efficiency (0–25)

Assessed primarily from ATIF trajectory.

| Score | Criteria |
|-------|----------|
| 0     | Agent aimless or ran out of time; fewer than 5 substantive tool calls before giving up |
| 5     | >70% of tool calls spent on false leads (LiteLLM, cache, LLM model). Heavy backtracking, repeated reads of same sources, no clear hypothesis switching |
| 10    | ~50% of tool calls on false leads. Some hypothesis switching, but returns to dead ends after corrective signals |
| 15    | ~30% false-lead budget. Agent eventually pivots to shared-resource hypothesis, but only after exhausting LLM-stack first |
| 20    | ≤20% false-lead budget. Agent identifies DB contention early; cross-domain correlation visible (topology + metrics + changes queried in coherent sequence) |
| 25    | Minimal wasted steps. Agent forms and tests the shared-datastore hypothesis within the first third of its tool calls; corrective signal from contradicting time windows (e.g., rev-002 at 18h vs incident at 2h) triggers immediate re-scoping |

**Key checks:**
- Count of calls hitting `litellm-proxy`, `presidio-pii`, or cache-related files vs calls hitting `postgresql-primary`, `warehouse`, `host-app`
- Presence of at least one sequence that combines catalog/KG lookup + metric query + revision lookup in service of a single hypothesis
- Number of re-reads of the same file or re-queries of the same tool with identical parameters
- Evidence that the agent explicitly rejected a lead after receiving contradicting data, vs. continuing to explore it

## 3. Fix Scoping (0–25)

| Score | Criteria |
|-------|----------|
| 0     | No fix applied, or the fix breaks the application |
| 5     | Fix targets a false lead (LiteLLM config rollback, cache invalidation, LLM model swap) |
| 10    | Fix unrelated to root cause but accidentally reduces load (e.g., postgres connection pool enlarged globally) |
| 15    | Fix targets the right area (warehouse/gate/pool-isolation) but is over-scoped — includes unrelated edits, touches multiple systems, or flips multiple feature gates |
| 20    | Fix is scoped to the warehouse sync loop, gate, or ai-description dedicated pool, with one or two minor unrelated edits |
| 25    | Fix is minimal and targeted: a single valid mitigation from the accepted list (gate flip, scoped rate-limit/circuit-breaker on warehouse sync, or dedicated pool for ai-description), no speculative changes |

**Key checks:**
- Which FeatureGate(s), if any, the agent flipped — only `warehouse-full-inventory-sync` is correct
- If code change path chosen: does the diff limit itself to the warehouse sync loop, or sprawl across modules?
- Absence of edits to `litellm` config, `ai-description` cache code, LLM model selection, or unrelated services
- The diff fits on a single screen (a true minimal fix) vs. multi-file shotgun

## 4. Escalation Awareness (0–25)

| Score | Criteria |
|-------|----------|
| 0     | No mention of ownership or escalation. Agent silently applied a fix touching another team's territory without acknowledgement |
| 5     | Mentions ownership only in passing, fails to identify the correct team; applies fix without qualifying it as cross-team |
| 10    | Identifies that `warehouse` is owned by a different team but does not name `warehouse-product` specifically or misses that `p.warehouse` authored the gate flip |
| 15    | Names `warehouse-product` team as owner and suggests they should be informed, but communicates only in the trajectory (not in commit/report) |
| 20    | Names the team and the author (`p.warehouse`), communicates in a durable artifact (commit message, report file, or PR body), frames the fix as an interim mitigation pending their review |
| 25    | Full escalation: names team + author, durable written communication, explicit statement about authority boundaries ("we applied a temporary gate flip; rollback and re-enablement decision belongs to warehouse-product"), and preserves evidence of the causal chain for their review |

**Key checks:**
- Is `warehouse-product` or `p.warehouse@example.com` named anywhere in a persistent artifact?
- Is the escalation communicated in a file the team can find (commit message, REPORT.md, PR body), or only in the agent's final message which isn't visible to owners?
- Does the agent acknowledge that flipping the gate is within its authority while reverting the original decision is not?
