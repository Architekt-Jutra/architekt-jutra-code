---
name: maister:metaprogram-classifier
description: Recognize and classify NLP metaprograms from utterances, written communication, or described behavior. Identifies which of 7 metaprograms are active, detects compound patterns, and suggests communication strategies adapted to the person's cognitive filters. Invoke when the user asks about metaprograms, communication style diagnosis, "jak rozmawiać z tą osobą", "jaki metaprogram", "jak się komunikować", or wants to analyze someone's communication patterns.
argument-hint: "[utterance, email text, or described behavior to analyze]"
---

# Metaprogram Classifier

Analyze utterances, written communication, or described behaviors to identify active NLP metaprograms — contextual cognitive habits that determine how a person filters information, makes decisions, and communicates. Based on the identification, suggest concrete communication strategies adapted to that person's cognitive patterns.

**Core principle**: Metaprograms are NOT fixed personality traits. They are context-dependent filters. The same person activates different metaprograms depending on topic familiarity, emotional state, and role context. Always qualify findings with context.

**Ethical principle**: This tool serves mutual understanding — matching communication interfaces for clearer exchange. It is not a manipulation toolkit. If both parties understand these patterns, manipulation becomes impossible.

## When to Use

**Use this skill when:**
- Someone shares an email, Slack message, or meeting quote and asks "how should I respond?"
- A team communication pattern is breaking down and needs diagnosis
- Someone wants to understand why a specific person "doesn't get it" despite clear explanations
- Preparing for a difficult conversation (selling refactoring, proposing architecture changes, negotiating scope)
- Analyzing recurring communication friction in a team

**Not intended for:**
- Psychometric profiling or personality typing (these are contextual habits, not traits)
- Performance evaluation or hiring decisions
- Labeling people permanently ("he IS a detail person")

## The 7 Metaprograms

Each metaprogram is a spectrum with two poles. Most people operate somewhere along the spectrum, often with compound patterns (e.g., first seeking similarities, then drilling into differences).

---

### MP1: Information Sorting — Similarities vs. Differences

How a person organizes new information relative to what they already know.

#### Similarities Pole (Dopasowywanie)

**Cognitive pattern**: Seeks what is familiar. Filters for continuity with the known. Change triggers discomfort — the unknown represents risk. Can accept a major change roughly once per decade; will self-initiate change even less frequently.

**Linguistic markers:**
- "To działa dokładnie tak jak..." (This works exactly like...)
- "Analogicznie do..." (Analogous to...)
- "Na tej samej zasadzie co..." (On the same principle as...)
- "Coś zbliżonego do tego, co już mamy" (Something similar to what we already have)
- Frequent use of comparisons to established solutions

**Communication strategy:**
- Frame new concepts as extensions of what already exists
- Show continuity: "This is just well-structured OOP based on patterns proven over 25 years"
- Avoid emphasizing novelty or radical departure
- Build bridges: "You already know X — this is X applied to a different context"

#### Differences Pole (Różnicowanie)

**Cognitive pattern**: Filters for contrasts and oppositions to understand incoming information. Change is stimulating and developmental. Needs significant change every 1-2 years. Chooses by elimination — "this I don't want, that I don't like" — and takes what remains.

**Linguistic markers:**
- Agreement through negation: "Niestety nie mogę się z tobą nie zgodzić" (Unfortunately I cannot disagree with you)
- "Nie mam się do czego przyczepić" (I have nothing to criticize)
- "A czym to się różni od..." (And how is this different from...)
- Focus on exceptions and edge cases
- Tendency to express approval by acknowledging the absence of flaws

**Communication strategy:**
- Highlight what's new and different about the proposal
- Present options for comparison and elimination
- Don't be surprised by "agreement through negation" — it IS agreement
- Allow space for critique as a processing mechanism

#### Common compound: Similarities-then-Differences — first anchoring in what's familiar, then examining what's missing or different. This is the most frequent pattern.

---

### MP2: Granularity — Detail vs. Big Picture

The level of abstraction at which a person naturally processes information.

#### Detail Pole (Szczegółowy)

**Cognitive pattern**: Uses specific quantifiers. Needs information arranged in linear sequences, step by step. Can only consider the whole picture once all parts are assembled. Attention naturally zooms into specifics.

**Linguistic markers:**
- "Istnieją takie przypadki, w których..." (There exist cases where...)
- Specific quantifiers rather than generalizations
- Step-by-step descriptions of processes
- Focus on edge cases: "A co jeśli X i jednocześnie Y?"
- Questions about specific methods, parameters, return types

**Communication strategy:**
- Don't yank them to a higher abstraction level — first descend to their level, then gently guide upward
- Ask them to look from their own next level up: "OK, this method is part of a broader pattern. What do you see when you compose several methods written this way?"
- Respect that detail focus serves a function — catching problems early

**Risk signal**: When detail orientation activates at the wrong moment (e.g., during a strategic discussion), the person may appear obstructive — stuck in specifics while losing sight of the overall goal. This is usually a context mismatch, not a character flaw.

#### Big Picture Pole (Ogólny)

**Cognitive pattern**: Uses general quantifiers and broad generalizations. Doesn't attach importance to sequence. Can generalize from a single example without examining differences. Prolonged focus on details is frustrating and draining.

**Linguistic markers:**
- "Bo ty zawsze..." (Because you always...)
- "Bo ty nigdy..." (Because you never...)
- "Ogólnie to jest tak..." (Generally it's like this...)
- "Dokąd ty w ogóle zmierzasz?" (Where are you even going with this?) — when overwhelmed by details
- Abstract examples, metaphorical language

**Communication strategy:**
- Start with a shared positive intention before requesting details: "So we can better estimate and reduce risk, I need something more specific..."
- Always consider timing: Is this the right moment to drill into details? Is this the best use of time in this project phase?
- Lead with the destination, then the route — not the other way around

---

### MP3: Source of Authority — Internal vs. External Reference

Where a person seeks validation that their understanding or decision is correct. **This is the most powerful of all metaprograms** because it touches self-awareness and identity.

#### Internal Reference (Wewnętrzne)

**Cognitive pattern**: Seeks proof through internal retrospection. When they've decided something, they simply "know." Acts on their own judgment regardless of external opinions. Hard to manage through conventional authority. Does not need external praise — and does not respect praise from someone who "doesn't know the field." May USE praise strategically to build group status.

**Linguistic markers:**
- "Sam wiem" (I know myself)
- "Sam muszę sprawdzić" (I need to check myself)
- "Będę wiedział, jak sprawdzę" (I'll know when I check)
- Resistance to arguments from authority: "They don't even know the specifics of our project"
- Self-referential decision justifications

**Communication strategy:**
- NEVER cite external authority as primary argument — they'll dismiss it
- Propose a personal experiment: "Here's a repo with this approach. Try it, see how it works for you, see if it solves these problems, and tell me what you think"
- If they're also problem-avoidance oriented (common in technical experts): frame a problem and ask how THEY would solve it. They now own the problem AND must solve it themselves
- They may consider research/studies, but they decide which studies are trustworthy

#### External Reference (Zewnętrzne)

**Cognitive pattern**: Relies on others' opinions for validation. Knows something because someone said it, because research confirms it, because the market validated it. Needs external feedback and recommendations to know they're heading in the right direction.

**Linguistic markers:**
- "Bo większość ludzi..." (Because most people...)
- "Bo klienci kupują..." (Because clients buy...)
- "Bo tak wszyscy mówią..." (Because everyone says so...)
- "Bo badania potwierdzają..." (Because research confirms...)
- References to books, experts, articles, market trends, consensus

**Communication strategy:**
- Provide data, research, testimonials, case studies
- Citing your own experience alone won't suffice unless you have recognized authority status in their eyes
- They may need to consult others before deciding — build that into your timeline
- If they have high intellectual standards, be prepared with rigorous evidence

---

### MP4: World Orientation — Away-From Problems vs. Toward Goals

What motivates action — avoiding negatives or pursuing positives. **This is one of the biggest blockers in communication** when two people sit on opposite poles.

#### Away-From Problems (Unikanie problemów)

**Cognitive pattern**: Oriented toward fears, threats, and risks. Sees problems everywhere. Focuses on what didn't work, might not work, or won't work. Motivated by problems to solve and things to avoid. Has trouble setting and maintaining goals because problems easily divert attention. Knows very well what NOT to do, but struggles to articulate what TO do.

**Linguistic markers:**
- "Będzie nieźle" (It'll be not bad) — positive expressed through double negation
- "Nie trzeba psuć" (No need to break it)
- "Żeby tylko nie było..." (Just so there won't be...)
- "Uważaj, tylko nie spadnij" (Careful, just don't fall)
- "A jak nas to kopnie w przyszłości?" (What if this kicks us in the future?)
- "Może tak, może nie, nigdy nie wiadomo" (Maybe yes, maybe no, you never know)

**Communication strategy:**
- NEVER say "everything will be fine, focus on goals" — this invalidates their entire processing model
- Build certainty that whatever happens, you'll know how to handle it, or at least have time to figure it out
- Connect with their authority source: if external, show how others handled similar risks; if internal, remind them of cases where they personally navigated similar situations
- Acknowledge risks genuinely before proposing solutions

#### Toward Goals (Dążenie do celu)

**Cognitive pattern**: Motivated by benefits, goals, and rewards. Simply knows what to do. Sees obstacles as temporary hurdles, not fundamental blockers. Reacts to positive reinforcement. Has difficulty perceiving problems — may blame failures on others rather than systemic issues.

**Linguistic markers:**
- "Będzie lepiej" (It will be better)
- "Doskonała okazja" (Excellent opportunity)
- "Wyprzedźmy ich oczekiwania" (Let's exceed their expectations)
- "Wyprzedźmy konkurencję" (Let's outpace the competition)
- Focus on improvement, opportunity, forward momentum

**Communication strategy:**
- Don't lead with obstacles and risks — this reads as defeatism and whining from their perspective
- If you must raise a problem, ask yourself: Is this the best moment? Then connect the problem to a threat against a specific goal they care about
- Frame technical concerns as "threats to the deadline / quality / competitive advantage" — not as abstract risks

#### The IT worldview clash: Technical experts often want to demonstrate professionalism by showing how many problems they can foresee. Goal-oriented managers perceive this as negativity and obstruction. Neither is wrong — they're processing through different filters.

---

### MP5: Self-Motivation — Reactive vs. Proactive

Whether a person initiates action or waits for external triggers.

#### Reactive

**Cognitive pattern**: Waits for others to act or for the right situation to emerge. Postpones action through analysis. Does not speak about themselves directly — replaces the subject with generalizations.

**Linguistic markers:**
- Uses "człowiek" (a person/one) instead of "ja" (I): "Jak człowiek głodny, to zły" (When a person is hungry, they're angry) — suggesting helplessness, lack of agency over one's environment
- "Poczekajmy na wyniki badań" (Let's wait for survey results)
- "Czy ktoś tego od nas wymagał?" (Did anyone require this of us?)
- Passive voice constructions
- Conditional phrasing: "If the situation develops..."

**Communication strategy:**
- Find them an external trigger for action
- Whether that trigger should be a goal or a problem depends on their world orientation (MP4)
- If also problem-oriented: the problem itself becomes the trigger — show the problem clearly
- If also goal-oriented (rare combination): show an opportunity that has a deadline

#### Proactive

**Cognitive pattern**: Self-initiates action. Pursues goals without waiting. Sometimes acts too hastily without sufficient reflection. Reluctant to accept suggestions — very sensitive to feeling manipulated.

**Linguistic markers:**
- "Wybieram" (I choose)
- "Decyduję" (I decide)
- "Tworzę" (I create)
- "Mogę" (I can)
- "Przejrzyjmy się innym możliwościom" (Let's look at other possibilities)
- "Po co czekać?" (Why wait?)
- "Wyprzedźmy ich" (Let's get ahead of them)

**Communication strategy:**
- Confront them with goals and plans to verify alignment — channel their energy toward checking direction
- Direct their thinking toward evaluating whether their current initiative is the best use of energy
- Don't try to slow them with obstacles — redirect instead

---

### MP6: Self-Persuasion — Necessity vs. Possibility

Whether a person acts because they must or because they can.

#### Necessity Pole (Konieczność)

**Cognitive pattern**: Acts because circumstances require it. Follows rules and procedures. Assumes requirements always exist even if not explicitly stated. Will not break rules even when nobody is watching.

**Linguistic markers:**
- "Muszę" (I must)
- "Trzeba" (It's necessary)
- "Powinienem/Powinnam" (I should)
- "Zróbmy to dla zasady" (Let's do it for the principle) — even when nobody can name which principle
- Language of obligation, duty, compliance

**Communication strategy:**
- When rigid rule-following limits potential, ask: "What would happen if we broke this rule? What does it give us, what does it limit?"
- Propose an exception clause or a new, better rule rather than rule-breaking
- Frame proposed changes as new requirements rather than rule violations
- Anchor to established standards, best practices, documented conventions

#### Possibility Pole (Możliwość)

**Cognitive pattern**: Acts because they see an opportunity. Will bend rules without remorse. Can create procedures — but for others, not for themselves (to prevent others from causing problems). May have commitment issues because choosing one option means losing others. May see so many possibilities that they don't act at all or don't finish tasks, switching to the next exciting option.

**Linguistic markers:**
- "Mogę" (I can)
- "Chcę" (I want)
- "Mam możliwość" (I have the possibility)
- "Mam taką wolę" (I have the will)
- Language of choice, freedom, options, opportunity

**Communication strategy:**
- Present at least 3 options (2 creates a dilemma, not a choice)
- Provide options at both the action level AND the implementation level
- **Order of rhetoric matters**: If you say "we MUST deal with X because we CAN do Y" — they'll react to the MUST. Start with possibilities, not obligations
- Channel their option-seeking by asking which possibility creates the most value given current constraints

---

### MP7: Priority — Self vs. Others

Where attention naturally goes — to one's own experience or to the reactions of others.

#### Self Pole (Ja)

**Cognitive pattern**: Focuses on their own feelings, comfort, and experience. Doesn't pay attention to others' body language. Evaluates situations based on personal impact. Builds arguments around personal comfort and interest.

**Linguistic markers:**
- Statements beginning with "Ja chcę..." (I want...)
- Self-referential framing: "For me this means...", "I feel that..."
- Arguments centered on personal benefit or inconvenience
- Limited awareness of team dynamics or others' reactions

**Communication strategy:**
- Find personal benefits in the proposal
- When appropriate, gently widen the lens: the project doesn't revolve around a single person

#### Others Pole (Inni)

**Cognitive pattern**: Pays attention to others' reactions and adjusts based on signals from the group. Easily establishes rapport. May sacrifice personal needs for others.

**Linguistic markers:**
- "The team needs...", "Our clients feel...", "People are saying..."
- Awareness of group dynamics in speech
- Adjusts position based on others' reactions mid-conversation

**Communication strategy:**
- If self-sacrificing to their own detriment: point out that their own condition matters — if they burn out, they can't care for others
- True leadership marker: "I'll be satisfied when my people are satisfied" — then names each team member and their needs

---

## The IT Communication Pattern

These 7 metaprograms systematically align differently in technical experts vs. management, creating a predictable "communication tragedy":

| Metaprogram | Mid/Senior Management | Technical Experts |
|---|---|---|
| Information Sorting | Similarities | Differences |
| Granularity | Big Picture | Detail (+ differences in details) |
| Authority Source | Internal | Internal |
| World Orientation | Toward goals | Away from problems |
| Self-Motivation | Proactive | Reactive |
| Self-Persuasion | Possibilities | Necessity |
| Priority | Others (team-oriented) | Self |

**Note**: Both groups share Internal Reference — but from different bases (business intuition vs. technical expertise), which paradoxically increases rather than decreases friction.

This table is a heuristic, not a rule. Always verify against actual observed language.

---

## Compound Patterns

Metaprograms combine and interact:

- **Differences + Detail**: Seeks differences in specifics. Common in technical experts. Will find the one edge case in a leap year on a Sunday.
- **Differences + Big Picture**: Disagrees on principles and ideas. Much harder to bridge than detail-level differences.
- **Reactive + Away-From-Problems**: The problem becomes the trigger. Show the problem clearly and they will move — but always away from it, not toward a goal.
- **Internal Reference + Away-From-Problems**: Experts who must own the problem and solve it personally. Frame a problem, make them the owner, and step back.
- **Maximizers** (multi-metaprogram compound): Want to extract maximum from every situation. Combined with detail-differentiation, leads to never being fully satisfied with any solution.
- **Satisficers** (multi-metaprogram compound): Accept the first option meeting basic criteria and move on. Efficient but may miss optimization opportunities.

---

## Skill Workflow

### Step 0: Input Acquisition

- If argument provided: use it directly as the text to analyze.
- If no argument: scan conversation for an utterance, email, message, or described behavior pattern. If found, use it.
- If nothing found: ask: *"Podaj wypowiedź, email, fragment rozmowy lub opis zachowania, który chcesz przeanalizować pod kątem metaprogramów. Im więcej kontekstu (sytuacja, rola osoby, temat rozmowy), tym trafniejsza analiza."*

### Step 1: Context Identification (silent)

Before analyzing, identify:
- **Situation context**: What was being discussed? What topic area? Work, technology, strategy, personal?
- **Role context**: If known — is this a manager, technical expert, peer, client?
- **Emotional context**: Is there stress, conflict, enthusiasm, neutrality?

Context matters because the same person uses different metaprograms in different situations. Flag this in output.

### Step 2: Metaprogram Signal Scan

For each of the 7 metaprograms, scan the input for linguistic markers and behavioral signals. Build a signal table:

| Metaprogram | Detected Pole | Confidence | Evidence |
|---|---|---|---|
| Information Sorting | Similarities / Differences / Both / Unclear | High / Medium / Low | [specific phrases] |
| Granularity | Detail / Big Picture / Unclear | ... | ... |
| Authority Source | Internal / External / Unclear | ... | ... |
| World Orientation | Away-From / Toward / Unclear | ... | ... |
| Self-Motivation | Reactive / Proactive / Unclear | ... | ... |
| Self-Persuasion | Necessity / Possibility / Unclear | ... | ... |
| Priority | Self / Others / Unclear | ... | ... |

**Confidence levels:**
- **High**: 2+ clear linguistic markers present
- **Medium**: 1 marker or behavioral signal without linguistic confirmation
- **Low**: Inferred from context or role heuristic only
- **Unclear**: Insufficient data — do not guess

### Step 3: Compound Pattern Detection

Check for known compound patterns:
- Do the detected poles form a recognized compound? (e.g., Detail + Differences, Reactive + Away-From)
- Does the profile match the IT management or IT expert heuristic pattern?
- Are there unexpected combinations that may indicate context-specific activation?

### Step 4: Communication Strategy Generation

For each detected metaprogram (confidence Medium or High), generate:

1. **What to do**: Concrete communication approach adapted to their pole
2. **What to avoid**: The specific communication mistake most likely to trigger resistance or shutdown
3. **Opening phrase template**: A concrete way to start the conversation that matches their filters

Group strategies by priority — address the strongest/most confident signals first.

### Step 5: Output

```markdown
## Analiza Metaprogramów

### Kontekst
[Situation, role, emotional context — and how it affects interpretation]

### Wykryte Metaprogramy

| Metaprogram | Wykryty biegun | Pewność | Dowody |
|---|---|---|---|
| [each of 7] | ... | ... | [cited phrases from input] |

### Wzorce złożone
[Compound patterns detected, if any]

### Profil komunikacyjny
[2-3 sentence summary of how this person processes information in this context]

### Strategie komunikacji

#### [Metaprogram name — strongest signal first]

**Rób**: [What to do]
**Unikaj**: [What NOT to do]
**Przykładowe otwarcie**: "[Template opening phrase]"

[Repeat for each detected metaprogram with Medium+ confidence]

### Uwagi kontekstowe
[Caveats: what would change if the context were different, what additional data would increase confidence, reminder that these are contextual patterns not personality labels]
```

---

## Practice Guidance

For users wanting to develop metaprogram awareness:

1. **Start with written communication** — analyzing both semantic content and meta-structure in real-time conversation is cognitively expensive. Written text gives processing time.
2. **Write first, then analyze**: Draft your instinctive response but don't send it. After emotions subside, re-read the incoming message — what deeper cognitive patterns underlie the words?
3. **Name the meta-structures** you observe in both the other person's and your own communication.
4. **Consider interpretation through different lenses**: How would your words land on someone with opposite metaprograms?
5. **Use body language deliberately** (in person): Precise gestures when focusing on details; sweeping gestures for big picture. Segregating gestures when differentiating; gathering gestures when finding similarities.
6. **Over time**, the meta-level analysis becomes automatic background processing — no longer burdening conscious attention.
7. **The adaptation obligation lies with the more aware person.** If your conversation partner doesn't know these patterns, you cannot expect them to adapt. They simply lack that capability in their cognitive repertoire. Adaptation always falls to the more conscious party.

---

## Edge Cases & Reminders

- **Single short utterance**: May only reveal 1-2 metaprograms. Mark the rest as "Unclear — insufficient data." Do not guess to fill the table.
- **Formal/template language**: Emails written in corporate template style may mask natural patterns. Note this limitation.
- **Stress context**: Under stress, people often shift toward more extreme poles. Flag when stress may be amplifying signals.
- **Multilingual speakers**: Metaprogram markers may manifest differently across languages. This skill's marker list is optimized for Polish but the cognitive patterns are universal.
- **Self-analysis**: Users can analyze their own communication. Remind them that awareness creates choice — between stimulus and response, a pause appears that grows longer with practice.
- **"Can this be used for manipulation?"**: Technically yes. But: (1) intention matters — are we matching interfaces or pushing something unwanted? (2) If the whole team learns these patterns, manipulation becomes impossible because everyone can see the meta-level.

---

## Quality Checks

Before returning analysis:

- [ ] All 7 metaprograms assessed (even if "Unclear")
- [ ] Every detected pole has specific evidence from the input text (no unsupported claims)
- [ ] Confidence levels are honest — "Unclear" is better than a wrong guess
- [ ] Context caveats are present
- [ ] Communication strategies are actionable — not generic advice but specific to detected patterns
- [ ] No permanent labeling language ("this person IS" → "in this context, this person ACTIVATES")
- [ ] Compound patterns checked
- [ ] Opening phrase templates are concrete and usable
