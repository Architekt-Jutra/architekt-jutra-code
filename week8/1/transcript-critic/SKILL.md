# Transcript Critic

Analyze meeting transcripts to surface hidden decision-making problems that a naive summary would miss: false consensus, marginalized voices, opinions disguised as facts, hidden dependencies between "separate" topics, and scope drift.

**Output goal**: A structured report of detected problems with severity, evidence (quotes), and diagnostic questions to take to the next meeting. This is NOT a summary — it's a critique of the decision-making process visible in the text.

## When to Use

- After a meeting where decisions were made — to verify if they're well-founded
- Before acting on meeting notes — to check what's missing
- When preparing for a follow-up meeting — to generate targeted questions
- When reviewing someone else's meeting notes — to find what the note-taker missed

**What this skill does NOT do:**
- Summarize content (use a regular prompt for that)
- Replace being at the meeting (it can't see tone, body language, facial expressions)
- Make decisions (it surfaces problems — humans decide what to do about them)

## Core Principle

**A transcript is a lossy compression of a meeting.** It preserves words but drops tone, body language, interruptions-that-weren't-recorded, and everything that happened between the lines. This skill assumes the worst about what's missing and asks questions to verify.

---

## Analysis Framework

Run all seven checks on the transcript. Each check produces findings independently. A single sentence in the transcript can trigger multiple checks.

### Check 1: Fact vs Opinion vs Hearsay

For every claim made by a participant, classify:

- **(F) Fact** — verifiable, with evidence in the transcript (data, specific incident, measurement)
- **(O) Opinion** — stated without evidence, based on experience or feeling ("I think", "probably", "from my experience")
- **(H) Hearsay** — information from a third party, not verified ("a client told me", "I heard that")
- **(D) Declarative conclusion** — stated with authority as if it were fact, but without supporting evidence

**Critical sub-check: Opinion → Fact escalation.** Track when an (O) or (H) gets treated as (F) later in the conversation. This is the most dangerous pattern — someone says "I think it affects maybe a third of users", and ten minutes later the group is allocating budget based on "a third of users" as if it were measured.

For each finding, note:
- Who said it
- Original classification
- Whether it escalated
- What verification would look like

### Check 2: Consensus Audit

When the conversation reaches a decision point, verify:

- **Who explicitly agreed?** (said "yes", "I agree", "let's do it")
- **Who was asked and said "OK" after being overruled or interrupted?** — this is compliance, not agreement
- **Who was never asked?**
- **Who said "no impact" or "doesn't affect me" without explanation?** — may be disengagement, not genuine independence

Produce a consensus matrix:

| Participant | Position | Genuine agreement? | Evidence |
|-------------|----------|-------------------|----------|
| ... | ... | Yes / Compliance / Not asked / Unclear | quote |

### Check 3: Interrupted & Marginalized Topics

Track every topic that was:

- **Raised and cut off** — someone started talking about X, got interrupted, topic didn't return
- **Raised and deferred** — "that's a separate topic", "next quarter" — was it genuinely separate or was it inconvenient?
- **Raised by someone who then went silent** — the person stopped pushing after being shut down

For each interrupted topic:
- Who raised it
- Who cut it off (and how — interruption, deferral, dismissal)
- Was the topic genuinely separate, or was there a hidden dependency with the main discussion?
- What's the risk of ignoring it?

### Check 4: Hidden Dependencies

Look for topics that the group treats as independent but are actually connected.

**Signal**: Someone says "that's a separate topic" or "we'll handle that later" — but the "separate" topic is affected by the decision being made now.

For each potential dependency:
- Topic A (being decided now)
- Topic B (deferred or dismissed)
- How A affects B (or vice versa)
- Risk of deciding A without considering B

### Check 5: Scope Drift Detection

Track the stated goal of the meeting vs what actually happened.

- **What was the meeting supposed to decide?** (stated at the beginning)
- **When did the actual decision happen?** (often much earlier than participants realize)
- **Was the decision space explored, or did the first proposal win by default?**

**Signal**: If the first person to speak proposes a solution, and the rest of the meeting is about refining that solution rather than evaluating alternatives — the decision was made by speaking order, not by analysis.

### Check 6: Severity Mismatch

Look for moments where the group treats a low-frequency problem as low-severity, or vice versa.

**Signal**: "That happens maybe twice a year" used to dismiss something — but the consequences of that rare event could be catastrophic (safety, legal, financial).

For each finding:
- What was dismissed
- On what basis (frequency)
- What's the actual severity if it happens (consequence)
- frequency × consequence = real risk

### Check 7: Authority & Social Dynamics

Detect patterns where social position influences the decision more than argument quality:

- **First-mover advantage** — first proposal gets adopted because alternatives never surface
- **Authority override** — boss/senior agrees with someone and the rest follows
- **Loudest voice wins** — someone who speaks more confidently gets treated as more credible
- **Politeness trap** — someone disagrees softly ("well, I see the point, but...") and gets steamrolled

---

## Workflow

### Step 1: Read and Inventory

Read the entire transcript. Build:
- List of participants with their roles
- Timeline of topics raised
- List of decisions made (explicit and implicit)

### Step 2: Run All Seven Checks

Apply each check independently. A single moment in the transcript can trigger multiple checks.

### Step 3: Cross-Reference Findings

Look for patterns across checks:
- Is the same person marginalized (Check 3) AND their topic has a hidden dependency (Check 4)?
- Was a severity mismatch (Check 6) dismissed by an authority figure (Check 7)?
- Did scope drift (Check 5) prevent alternatives from being discussed, leading to false consensus (Check 2)?

### Step 4: Generate Diagnostic Questions

For each finding, generate 1-2 questions to take to the next meeting. Questions should be:
- **Specific** — not "tell me more about X" but "[Name], how much time do you need to complete [process] after [trigger event]?"
- **Verifiable** — asking for data, not opinions
- **Non-threatening** — phrased to open discussion, not to accuse

### Step 5: Produce Report

---

## Output Format

```markdown
# Transcript Critique: [Meeting Name / Date]

## Meeting Metadata
- **Stated goal**: [what the meeting was supposed to decide]
- **Actual outcome**: [what was actually decided]
- **Participants**: [who was there, with roles]

## Critical Findings

### [Finding title]
**Checks triggered**: [which of the 7 checks]
**Severity**: Critical / High / Medium / Low
**Evidence**: "[exact quote from transcript]"
**Problem**: [what's wrong with this moment]
**Hidden risk**: [what could go wrong if this isn't addressed]
**Diagnostic question for next meeting**: "[specific question]"

[Repeat for each finding, ordered by severity]

## Consensus Audit

| Participant | Stated position | Genuine agreement? | Evidence |
|-------------|----------------|-------------------|----------|
| ... | ... | ... | ... |

## Deferred Topics — Dependency Check

| Topic deferred | Deferred by | Reason given | Hidden dependency with current decision? |
|---------------|-------------|-------------|----------------------------------------|
| ... | ... | ... | ... |

## Questions for Next Meeting

[Ordered list of all diagnostic questions, grouped by topic]
```

---

## Pitfalls

### Pitfall: Over-reading silence

Not every silence is marginalization. Someone may genuinely have nothing to add. The skill should flag silence but not assume it's always a problem — the diagnostic question should verify (e.g., "You said this change has no impact on your area — can you walk us through why?").

### Pitfall: Crying wolf on opinions

Not every opinion is dangerous. "I think the logo should be blue" doesn't need fact-checking. Focus on opinions that **drive decisions** — especially those affecting budget allocation, priority ordering, and safety trade-offs.

### Pitfall: Assuming bad intent

The skill detects patterns, not motives. A meeting leader interrupting a specialist doesn't mean they don't care about the specialist's topic. It may mean they're under time pressure, or genuinely believe the topics are separate. The diagnostic questions should open exploration, not assign blame.

### Pitfall: Transcript artifacts

Some "interruptions" in a transcript are just overlapping speech that the transcription tool rendered sequentially. Don't over-interpret the exact sequence if the transcript comes from automated speech-to-text.