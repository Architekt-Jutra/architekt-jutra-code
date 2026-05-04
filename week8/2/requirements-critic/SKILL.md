---
name: maister:requirements-critic
description: Critiques requirements and interactively rebuilds them. Applies 4 checks — problem-vs-solution framing, observable behavior vs CRUD status (interactively reformulates into proper user stories), extensible signal map of hidden domain decisions, and rigid quantifier probing. Invoked ONLY on explicit request.
argument-hint: "[requirements text, ticket, or spec to critique]"
---

# Requirements Critic

**Invocation guard**: This skill activates ONLY when the user explicitly asks for critique, review, or analysis of requirements. Trigger phrases: "criticize", "critique", "review this ticket", "what's wrong with", "is this requirement good", "check my requirements", "any issues with this spec".

Do NOT invoke when the user is writing, describing, elaborating, or asking questions about requirements. Critique on request only.

---

## Input Acquisition

- If argument provided: use it directly.
- If no argument: scan the conversation for requirements, ticket text, or spec content. Use it if found.
- If nothing found: ask the user to paste the requirements to review.

Process each requirement (or ticket) independently. Apply all 4 checks to each. Report only genuine issues — never invent problems to appear thorough.

---

## Check 1: Problem vs. Solution

A requirement should describe a business need, not an implementation choice. Flag technical language only when the implementation is genuinely open and the mechanism choice hides the actual business rule.

**Do NOT flag** when the technical detail is:
- An already-decided constraint (e.g., "we use CRM X", "output must be PDF", "the form uses a dropdown for a finite list")
- A delivery channel that is fixed in the context (e.g., "send via email" when email is the established channel)
- A UI element that is obvious and unambiguous for the use case (e.g., "date picker" for a date field)

**DO flag** when the mechanism named obscures or replaces the business rule entirely, or when naming it prevents exploring better alternatives for a still-open decision.

**Test**: Is the implementation detail a settled constraint, or does it hide what the business actually needs?

| ❌ Flag this | ✅ Leave this |
|-------------|--------------|
| "Add a webhook to notify external systems" (integration approach still open) | "Pull company name from CRM" (CRM is the system of record — settled) |
| "Store data in a Redis cache for performance" (architecture decision in a requirement) | "Deliver invoice as PDF via email" (PDF+email are decided output format and channel) |
| "Use a dropdown with categories" when the business rule (expense must have one category) is never stated | "Date picker for project deadline" (date input for a date field — obvious) |

---

## Check 2: Observable Behavior vs CRUD Status

A requirement that describes a command ("reserve", "block", "assign", "approve") but whose only stated effect is a status change in the database is a **CRUD description disguised as domain logic**. The requirement says *what label to write*, not *what the system should do differently afterwards*.

**Why this is dangerous**: An AI implementing "when user clicks Reserve, set status to Reserved" will produce a working CRUD form. It will pass acceptance tests. And it will be useless — because the business needed the reservation to *actually do something*: block availability for others, decrement a counter, prevent double-booking, start a timer.

**Trigger signal**: A command verb (reserve, block, assign, approve, cancel, close, activate, submit) whose described effect is only:
- A status/flag change in the database ("status becomes Reserved")
- A record creation with no stated consequence ("a reservation record is created")
- A UI label change ("the button changes to Unreserve")

**Test**: Read the requirement and ask: *"If I removed the status field entirely and just did nothing — what observable thing would be different in the system?"* If the requirement can't answer that — it's describing a label, not behavior.

**Probing questions** — when triggered, ask using `AskUserQuestion`. Ask 2-3 at a time, not all at once. Use answers to build up the reformulated requirement iteratively.

| Probe | What it reveals |
|-------|----------------|
| "Co się zmienia dla **innych użytkowników** po wykonaniu tej komendy? Co widzą inaczej, czego nie mogą już zrobić?" | Observable side effects — the real behavior the status is supposed to represent |
| "Czy po tej operacji jakiś **licznik, pula, lub dostępność** się zmienia? Np. było 10 dostępnych, teraz jest 9?" | Resource contention signals — counters, quotas, availability pools |
| "Jeśli **ten sam użytkownik** wykona tę operację drugi raz — co powinno się stać? A jeśli **inny użytkownik**?" | Idempotency rules and ownership semantics |
| "Czy ta operacja jest **odwracalna**? Jeśli tak — co dokładnie się cofa? Czy cofnięcie przywraca stan sprzed operacji (np. counter wraca do 10)?" | Reversibility reveals what the operation actually changes — if undo must restore a counter, the operation must have changed it |
| "Gdyby system **nie miał tego statusu** w ogóle — po czym użytkownik poznałby, że operacja się wykonała?" | Forces naming the real observable effect instead of relying on a label |

### Interactive reformulation

After collecting answers, **build a new requirement interactively**. Do not just flag the issue — produce a concrete replacement.

**Process**:
1. Ask the first 2-3 probing questions via `AskUserQuestion`
2. Based on answers, draft a reformulated requirement that describes **observable behavior** instead of status changes
3. Present the draft to the user via `AskUserQuestion` with options: "Akceptuję", "Chcę doprecyzować" (+ free text)
4. If the user wants to refine — ask follow-up probes from the table above, update the draft, present again
5. Stop when the user accepts

**Draft structure** — the reformulated requirement should follow this pattern:
```
Komenda:        [what the user does]
Efekt:          [what observably changes in the system — counters, availability, permissions, state]
Współbieżność:  [what happens when two users execute this simultaneously]
Idempotentność: [what happens on repeated execution by same/different user]
Cofnięcie:      [what undo restores — or "irreversible" with justification]
```

Not all fields are always needed — include only those revealed by the user's answers. The goal is a requirement that makes the **observable behavior** explicit, not a template to fill mechanically.

**Example**:

> ❌ Original: *"User clicks 'Reserve'. System creates a reservation with status Reserved."*

After probing (2 rounds of questions):

> ✅ Reformulated:
> ```
> Komenda:        Użytkownik rezerwuje zasób, podając ilość
> Efekt:          Dostępna ilość zasobu zmniejsza się o żądaną wartość.
>                 Inni użytkownicy widzą zaktualizowaną dostępność.
> Współbieżność:  Rezerwacja przekraczająca dostępną ilość jest odrzucona.
> Idempotentność: Ponowna rezerwacja tego samego zasobu przez tego samego
>                 użytkownika zwiększa istniejącą rezerwację (nie tworzy nowej).
> Cofnięcie:      Anulowanie przywraca licznik dostępności.
> ```

The first version produces CRUD. The second version reveals Resource Contention with a counter invariant, concurrent access rules, and compensating action. **The skill doesn't just critique — it builds the better version together with the user.**

---

## Check 3: Signal Map — Hidden Domain Decisions

Some requirements look complete but contain hidden decisions that will be made anyway — either consciously now or silently in code. This check works as a **signal map**: when a keyword or concept appears in the requirement, it activates a cluster of questions that the domain almost always needs answered.

The map is **extensible** — new signal clusters can be added as teams encounter new recurring problem domains. The current map covers the most common decision traps.

### How to use the map

1. Scan the requirement for signal keywords
2. When a signal matches, present **all questions from that cluster** — they tend to come as a package
3. Use `AskUserQuestion` to ask the most relevant 2-3 questions from the matched cluster
4. Multiple clusters can fire on the same requirement

### Signal Map

**🔒 Dane osobowe / historia użytkownika**
Signal words: *personal data, history, profile, "remembers", user data, account, PESEL, email, phone*

- Jak długo dane są przechowywane? (retention policy)
- Czy użytkownik może zażądać usunięcia? (GDPR right to erasure)
- Soft-delete czy hard-delete? Co z powiązanymi danymi?
- Kto ma dostęp do historii — użytkownik, admin, audyt?
- Czy dane są wrażliwe w sensie RODO (zdrowie, orientacja, wyznanie)?

**💰 Cena / pieniądze / rozliczenia**
Signal words: *price, discount, invoice, payment, balance, cost, fee, subscription, billing, VAT, tax*

- Waluta — może być wiele? Kurs wymiany — z jakiego momentu?
- Reguła zaokrąglania (floor/ceil/half-up) — implikacje podatkowe różnią się
- Cena z momentu zamówienia vs. aktualna cena — którą wyświetlać, którą liczyć?
- Jak działa korekta / storno / zwrot?
- Rabaty — kumulują się czy wykluczają? Kolejność naliczania?
- Moment wyceny — kiedy cena się „zamraża"? (np. dodanie do koszyka vs. złożenie zamówienia vs. płatność)

**👥 Wielu użytkowników na wspólnych danych**
Signal words: *shared, team, collaboration, assign, owner, editor, viewer, role*

- Kto edytuje vs. kto tylko czyta?
- Czy widoczność zależy od roli, organizacji, właściciela?
- Co się dzieje z danymi gdy właściciel zostanie usunięty z systemu?
- Czy dwóch użytkowników może edytować jednocześnie? (→ może to RC, nie CRUD)

**🔌 Integracja z systemem zewnętrznym**
Signal words: *sends to, fetches from, syncs with, API, webhook, import, export, ERP, CRM*

- Co jeśli system zewnętrzny nie odpowiada?
- Czy operacja jest idempotentna przy retry?
- Czy użytkownik widzi status synchronizacji?
- Kto jest źródłem prawdy przy konflikcie danych?

**🔄 Przejścia statusów / maszyna stanów**
Signal words: *approves, cancels, publishes, activates, closes, submits, workflow, status*

- Czy przejście jest odwracalne?
- Kto może je wywołać (rola / właściciel / admin)?
- Jakie są warunki wstępne?
- Czy przejście wyzwala efekty uboczne (email, audit log, webhook)?

**📧 Powiadomienia**
Signal words: *sends email, notifies, alert, reminder, SMS, push notification*

- Czy użytkownik może zrezygnować (opt-out)?
- Co jeśli adres jest nieprawidłowy lub skrzynka pełna?
- Jednorazowe czy powtarzalne?
- Kto widzi, że powiadomienie zostało wysłane?

**📅 Daty / czas / harmonogram**
Signal words: *scheduled, deadline, expiry, history of changes, timestamp, valid from/to*

- Strefa czasowa — użytkownika, serwera, czy kontraktu?
- `created_at` vs. `applied_at` — to są różne pola
- Czy daty można ustawiać retroaktywnie — kto może?
- Zachowanie na granicy roku / okresu rozliczeniowego

**🔍 Wyszukiwanie / filtrowanie**
Signal words: *search, filter, sort, list, browse, find*

- Maksymalna liczba rekordów — czy potrzebna paginacja?
- Wyniki w czasie rzeczywistym czy z opóźnieniem?
- Czy wyszukiwanie obejmuje usunięte / zarchiwizowane rekordy?

### Extending the map

To add a new signal cluster, define:
1. **Signal words** — keywords that activate the cluster
2. **Questions** — 3-7 questions that this domain area almost always needs answered
3. **Why** — what goes wrong if these decisions are made silently in code

The map grows with team experience. Each production incident caused by an undiscovered decision is a candidate for a new cluster.

---

## Check 4: Rigid Quantifier Probe

Requirements with absolute quantifiers often encode hidden assumptions. The rule may be correct — but the edge cases it excludes should be conscious decisions, not accidents discovered post-implementation.

**Trigger words**: *always, never, every, all, only, must, cannot, no [noun], zero, 100%, at all times, under no circumstances, without exception*

**Process when triggered**:

1. Extract the quantifier and the absolute rule.
2. Generate 2–3 boundary scenarios that technically violate the rule. Make them concrete and domain-realistic.
3. Present them and ask: *"Is any of these scenarios possible in your domain?"*
4. If any answer is "yes" — the invariant needs a qualifier, an exception clause, or a split into two requirements.

**Example**:

> *"An invoice must always be attached to a project."*

Boundary scenarios:
- An internal administrative invoice (HR costs, office supplies) — does it need a project?
- A proforma / draft invoice created before the project is confirmed?
- A correction invoice that references a project that was later deleted?

Question: Are any of these possible? If yes, the invariant becomes: *"An invoice for billable client work must be attached to an active project. Administrative invoices and draft invoices are exempt."*

**Why this matters**: AI implements the rule as written. If "always" means "always except in 3 known edge cases," but those exceptions aren't written, the code will block legitimate operations and require emergency patches.

---

## Output Format

For each requirement reviewed:

```
### [Requirement identifier or first sentence as quote]

**Issues found:**
- [Check N: issue description with specific quote from the requirement]
- [Check N: ...]

**Questions to resolve before implementation:**
- [Specific question triggered by Check 2, 3, or 4]

**Suggested rewrite** *(if the fix is clear)*:
[Rewritten requirement]
```

If no issues found for a requirement, state that explicitly: *"No issues found — requirement is well-formed."*

**At the end**, provide a brief summary: how many requirements reviewed, how many had issues, which checks fired most often. This helps the team identify recurring patterns in their requirements quality.

---

## Principles

- **Report only genuine issues.** Do not invent problems to appear thorough. A well-written requirement deserves a clean bill of health.
- **Be specific.** Quote the exact phrase from the requirement that triggered the check. Vague feedback ("this requirement is unclear") is not actionable.
- **Prioritize blockers.** CRUD-disguised-as-domain (Check 2) is the most dangerous — it produces code that works but doesn't solve the problem. Flag it prominently.
- **Quantifier probe is a conversation, not a verdict.** Check 4 generates questions, not failures. The rule may be intentionally absolute — the goal is to surface the decision consciously.
- **Match the user's language** (Polish or English) in all questions and output.