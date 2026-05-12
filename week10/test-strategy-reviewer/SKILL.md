---
name: maister:test-strategy-reviewer
description: Reviews test code and suggests when testing strategy mismatches the problem class being solved. Detects output-based tests on integration code, interaction-based tests on pure transformations, missing state verification on stateful objects, and tests at wrong abstraction level. Invoke when user asks to review tests, "is my test strategy correct", "review my tests", "test strategy", "am I testing this right".
argument-hint: "[path to test file or directory, or description of what to review]"
---

# Test Strategy Reviewer

Reviews tests against problem-class-appropriate testing strategies. Does NOT review test quality (naming, structure, coverage) — focuses exclusively on whether the **testing strategy matches the problem class** of the code under test.

---

## Input Acquisition

- If path provided: read test files and the production code they test.
- If no path: ask the user what tests to review.
- Always read both the test AND the production code — you need the production code to classify the problem.

---

## Step 1: Classify the Production Code

For each unit/class/module being tested, form a **preliminary** classification of the problem class:

| Problem Class | Key Signals |
|---------------|-------------|
| **Transformation** | No state mutation, input→output, no side effects, no database, pure computation |
| **Stateful Object** (e.g. aggregate in resource contention) | Has identity, guards invariants, changes state over time, concurrent access possible |
| **Integration** | Orchestrates multiple components, coordinates steps, talks to external systems/modules, manages transactions |

A single file may contain mixed classes (e.g., an application service integrating a stateful aggregate with a database). Classify each tested behavior separately.

### Confirm classification with user

After forming a preliminary classification, **always present it to the user** via `AskUserQuestion` before proceeding. The user may know things that aren't visible in the code:

- A "pure" function may actually call a very expensive external API behind a facade
- What looks like a stateful aggregate may be a simple CRUD entity with no real invariants
- What looks like integration may be a transformation with an injected dependency that happens to be a class (but is stateless and pure)

**Format**:
> "I've read the code and tests. I classify [ClassName] as **[problem class]** based on: [2-3 key signals found]. Does this match your understanding, or do you see it differently?"

Options:
- "Yes, it's [problem class]"
- "No, it's more like [other class], because..." (free text)
- "It's a mix — part is [class A], part is [class B]"

**Do NOT proceed to Step 3 until classification is confirmed.** A wrong classification leads to wrong recommendations.

---

## Step 2: Identify Current Test Strategy

For each test, classify what strategy it uses:

| Strategy | How to recognize |
|----------|-----------------|
| **Output-based** | Calls method, asserts on return value or output. No mocks. No state queries between steps. |
| **State-based** | Puts object in a state (via prior operations), then verifies state after next operation — via getter, event, read model, or query |
| **Interaction-based** | Uses mocks/stubs to verify what was called, how many times, with what arguments |

---

## Step 3: Compare Against Recommended Strategy

### Transformations — recommended: output-based

| Smell | Diagnosis |
|-------|-----------|
| Mocks/stubs on intermediate steps that are themselves pure | Unnecessary — run them for real, test only final output |
| Verifying internal method calls | Implementation leak — transformation's contract is its output |
| Testing internal decomposition (private methods) separately without need | Over-testing — test the public transformation boundary |

**Before diagnosing — ask about exceptions** via `AskUserQuestion`:

> "I see that tests for [ClassName] use mocks/stubs on intermediate steps of the transformation. Before I assess whether this is a problem — is any of these steps: (a) financially expensive (e.g., paid API)? (b) performance-expensive? (c) has side effects (mutates state, sends something)?"

Only after the answer, classify as smell or legitimate exception:
- Mock on a step that is financially/performance-costly — OK
- Mock on a step that has side effects (then that step is integration, not transformation) — OK, but flag that the whole thing is not a pure transformation

### Stateful Objects — recommended: output-based + indirect state-based

| Smell | Diagnosis |
|-------|-----------|
| Only checking return value without ever putting object in prior state | Missing state verification — you're testing a transformer, not a stateful object |
| Mocking internal parts of the aggregate | Aggregate should be tested as a whole — mocks break encapsulation |
| Never querying resulting state (no getter, no event, no read model check) | How do you know the state actually changed? |

**Level of testing — higher vs lower:**

Tests can live at the aggregate level OR at the application service / facade level. Before recommending, **ask the user** via `AskUserQuestion`:

> "I see tests at the [aggregate / facade] level. To assess whether this is the right level, I need to know: (a) Does the orchestration around this object (application service / facade) change often, or is it fairly stable? (b) Is the application service simple (few steps) or complex (lots of logic, branching, many dependencies to mock)? (c) Can the effect of the operation be verified via a read model / view / query, or only by directly querying the object?"

Then recommend based on answers:

Suggest **testing at facade/service level** when:
- The application service is simple (few steps, no complex branching)
- The orchestration steps are stable (don't change often)
- The effect can be verified via a read model, view, or query (not by poking into aggregate internals)
- This gives a more realistic test — verifying the actual user-observable outcome (e.g., a changed view, a projection update)

Suggest **keeping tests at aggregate level** when:
- The orchestration around the aggregate changes frequently — testing the aggregate directly isolates it from that churn
- The aggregate has complex invariants that deserve focused, fast unit tests
- Multiple application services use the same aggregate differently

### Integration — recommended: interaction-based

| Smell | Diagnosis |
|-------|-----------|
| Testing full integration end-to-end when you only own the orchestration | Over-testing — stub external modules, verify interactions |
| Output-based testing of a coordinator that calls 5 external systems | You're not testing your logic, you're testing whether external systems work |
| No separation between "what's the next step" logic and "execute the step" logic | Missed opportunity — extract the decision logic as a transformation, test it output-based separately |
| Mocking the database when it's a managed dependency | Wrong — use a real database instance, verify final state. Mock only unmanaged dependencies |
| Mocking an intermediate wrapper instead of the last type before the external system | Weak protection — mock at the system edge (the adapter/anti-corruption layer), not a mid-chain abstraction |
| Asserting interactions with stubs (incoming queries) | Overspecification — stubs provide input data, they are not outcomes. Only assert on mocks (outgoing commands/side effects) |

**Managed vs Unmanaged dependencies — what to mock:**

Before writing an integration test, classify each out-of-process dependency:

| Dependency type | Definition | Test strategy |
|-----------------|-----------|---------------|
| **Managed** (only your app accesses it) | Interactions are implementation details, not visible externally. Typical example: your application database. | **Use real instance**. Verify final state (query the DB after the operation). Do NOT mock — mocking a managed dependency removes protection against regressions and couples tests to implementation. |
| **Unmanaged** (other systems observe it) | Interactions are part of your system's observable behavior / contract. Examples: message bus, SMTP, external APIs. | **Mock it**. Verify the interaction (what was sent, how many times). This is the contract you must maintain backward compatibility for. |

**Exception**: A database shared with other systems is both managed and unmanaged. Treat tables visible to external apps as unmanaged (mock/verify contract). Treat private tables as managed (use real DB, verify state).

**Where to place the mock — mock at the system edge:**

When mocking an unmanaged dependency, mock the **last type in the chain** between your controller and the external system — the adapter at the very edge, not an intermediate abstraction.

Why? The further from the edge you mock, the less production code your test exercises. Mocking at the edge:
- Maximizes the amount of code covered by the integration test (better regression protection)
- Verifies the actual message/payload that leaves your system (better resistance to refactoring)
- Allows you to delete intermediate interfaces that exist only for mocking (less code to maintain)

| Mock placement | Example | Effect |
|----------------|---------|--------|
| Mid-chain (`IMessageBus`) | `messageBusMock.Verify(x => x.SendEmailChanged(...))` | Tests skip the serialization/formatting layer. If that layer has a bug, tests still pass. |
| At the edge (`IBus` adapter) | `busMock.Verify(x => x.Send("Type: USER EMAIL CHANGED; Id: 1; ..."))` | Tests exercise the full chain. The actual payload is verified. |

**Mock vs Stub — never assert interactions with stubs:**

- **Mock** = emulates and examines **outgoing interactions** (commands, side effects). The SUT *tells* a mock to do something. Assert on these.
- **Stub** = emulates **incoming interactions** (queries, data retrieval). The SUT *asks* a stub for data. Never assert on these — a call to a stub is a means to produce the end result, not the end result itself.

Asserting that a stub was called is overspecification: it couples the test to *how* the SUT gathers data, not *what* it produces. This leads to fragile tests that break on harmless refactors.

**Two sub-strategies for integration tests:**

| What you're verifying | Strategy |
|----------------------|----------|
| **The actual structure/contract flying over the wire** (serialization format, headers, schema compatibility) | **Contract tests** — verify the shape of data between producer and consumer without running full integration |
| **Behavior in the face of failures, timeouts, retries, partial results** (how the orchestrator reacts to external system behavior) | **Interaction-based with stubs** — stub the external boundary, simulate failure/success/partial, assert on the orchestrator's reaction |

Contract tests answer: "are we speaking the same language?" Stub-based tests answer: "what do we do when things go wrong (or right)?"

**Key insight — separating transformation from integration:**

When integration code contains non-trivial decision logic (e.g., calculating the next step based on accumulated state), extract that decision logic into a separate unit. Then:
- Decision logic → test output-based (no mocks needed)
- Integration/orchestration shell → test interaction-based (mocks for boundaries)

This separation makes tests more stable and easier to write.

---

## Step 4: Report

For each test file/class, report:

```
### [TestClassName]

**Tests**: [ProductionClassName]
**Problem class**: [Transformation | Stateful Object | Integration | Mixed]
**Current strategy**: [output-based | state-based | interaction-based | mixed]
**Recommended strategy**: [what it should be]
**Verdict**: [OK | MISMATCH]

[If MISMATCH — explain what to change and why, with concrete suggestion]
```

---

## Principles

1. **No dogma** — these are heuristics. If the user has a good reason to deviate, respect it. Flag the deviation, explain the trade-off, let them decide.
2. **Problem class drives strategy** — never recommend a strategy without first classifying the problem.
3. **Separation enables better strategies** — if code mixes problem classes, the best advice is often "separate first, then each part gets its natural test strategy."
4. **Stability of tests is the goal** — not adherence to a style. If a test breaks every time you refactor internals but the contract didn't change → wrong strategy.
5. **Cost of mocks** — mocks couple tests to implementation. Recommend them only when you genuinely can't (or shouldn't) run the real thing.
