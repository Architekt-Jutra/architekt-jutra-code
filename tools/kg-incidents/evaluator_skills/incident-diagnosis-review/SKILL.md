---
name: incident-diagnosis-review
description: Use when reviewing an AI agent's incident diagnosis output for precision, efficiency, and ownership awareness. Requires access to both the workspace artifacts and the ATIF trajectory.
---

# Incident Diagnosis Review

You are evaluating an AI agent's response to a production incident. The agent was asked to diagnose a latency degradation in `ai-description`, mitigate it, and escalate to the correct team. Your job is precise, evidence-based scoring — not leniency, not harshness.

## Review methodology

### 1. Start with the trajectory (`agent/trajectory.json`)

The trajectory is your **primary** source for dimensions 1 (Root Cause Accuracy) and 2 (Diagnostic Path Efficiency). The workspace diff alone cannot tell you how the agent arrived at its answer.

For each trajectory:
- Count unique tool calls. Categorize each as **on-path** (touches `warehouse`, `host-app`, `postgresql-primary`, shared-resource queries, feature gates related to warehouse) or **off-path** (touches `litellm-proxy`, `presidio-pii`, ai-description cache files, LLM model config, Langfuse).
- Count re-reads and re-queries — the agent repeating the same operation with identical parameters is a signal of thrashing.
- Identify hypothesis transitions: a moment when the agent had data that should have changed its direction. Did it change direction, or did it keep exploring the false lead?
- Look for cross-domain sequences — a single reasoning thread that queries topology (catalog/KG), then metrics, then changes. This is the effective investigation pattern.

### 2. Then the workspace (`artifacts/workspace/`)

For dimensions 3 (Fix Scoping) and 4 (Escalation Awareness):
- Read commit messages: `git -C <workspace> log --oneline --all`
- Search for report files: `INCIDENT-REPORT.md`, `REPORT.md`, `NOTES.md`
- Review the diff: `git -C <workspace> diff HEAD~1..HEAD` (or full `git diff` if single commit)
- Check state file: `/tmp/mcp-state/feature_gates.json` (copied into artifacts if available)

### 3. Map findings to rubric strictly

Quote directly from trajectory or workspace as evidence. "The agent mentioned warehouse" is not evidence — "the agent wrote 'warehouse-full-inventory-sync triggered the saturation' in commit abc123" is.

Do not award partial credit for implicit understanding if it isn't explicit in an artifact. If the agent understood ownership but did not write it down, escalation_awareness tops out at 15.

### 4. Calibrate against ground truth

The task directory has `ground_truth_decisions.json`. Use it to anchor your scoring:
- The `root_cause` section defines what a 25-score answer looks like
- The `acceptable_fixes` list constrains what fix_scoping=25 can be
- The `reject_fixes` list is what fix_scoping=5 looks like
- The `correct_escalation_team` / `correct_escalation_person` are what escalation_awareness requires

### 5. Negative evidence matters

Actively look for what the agent **did not do**:
- Did it ever query `postgresql-primary` or shared-resource topology? If not, root_cause_accuracy caps at 10.
- Did it explore the feature gates at all? If not, root_cause_accuracy caps at 15.
- Did it look at ownership (`owned_by`, `member_of`, team queries)? If not, escalation_awareness caps at 5.
- Did it flip unrelated feature gates "just to be safe"? If yes, fix_scoping drops by 5.

## Scoring principles

- **Evidence required.** Every score needs a specific quote or reference. "The agent did well" is not evidence.
- **Zero scores are valid.** If a dimension was completely ignored — score 0 and explain.
- **Max scores are rare.** A 25 means exemplary; reserve it for agents whose trajectory and output would make a senior SRE nod.
- **Trajectory evidence > intent evidence.** Don't interpret "the agent probably meant" — score what's literally in the trajectory.

## Reporting format

Return the JSON block as prescribed by the nasde evaluator prompt. For each dimension include 1–3 sentences of reasoning with a direct quote from trajectory or workspace.
