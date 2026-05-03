# Incident: ai-description latency degradation

## Alert

```
[ALERT] ai_description_latency_p99_degradation
component:   ai-description
metric:      p99 latency
value:       4200ms (baseline: 1300ms)
duration:    ongoing 2h 15min
severity:    high
```

The incident was first flagged at approximately **2026-04-17 11:45 UTC** and is ongoing. Current time is **2026-04-17 14:00 UTC**.

## Task

1. Diagnose the root cause of the latency degradation in the `ai-description` service.
2. Apply a mitigation that stops the degradation at its source. A mitigation that only masks the symptom (e.g., scaling up postgresql, swapping LLM models, rolling back unrelated services) will not be accepted.
3. Document your diagnosis. Leave a written record — a commit message, a file like `INCIDENT-REPORT.md`, or both — describing the causal chain and the decision you made.
4. Notify the correct team about the cause. The team responsible for the component where the root cause lies may not be the team that owns `ai-description`.

## Constraints

- **Check ownership before modifying code.** Do not edit components owned by teams outside your authority. The host platform grants you authority to adjust feature gates via `aj-changes.set_feature_gate_state`, but that does not imply authority to modify third-party plugin source code.
- You have access to multiple MCP servers that expose the platform's catalog, metrics, traces, and change history. Use them to gather evidence.
- Do not run long-running builds or tests unless your fix requires them. The task environment is not instrumented for end-to-end verification; it is a diagnostic sandbox.

## Deliverables

When complete:
- The mitigation is in place (either state change via MCP or a code change in the workspace).
- A written diagnosis exists in the workspace (commit + optional report file).
- The correct team is named in your written record.
