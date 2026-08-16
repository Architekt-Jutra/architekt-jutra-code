## 0. Decyzje wstępne (blokujące)

- [ ] 0.1 Potwierdzić z użytkownikiem D1 (lokalizacja `.claude/skills/` lokalnie bez prefiksu `maister:`, zamiast pluginu maister) — patrz design.md Open Questions #1
- [ ] 0.2 Potwierdzić z użytkownikiem zakres R9/`problem-classifier` (`week8/3/`, poza `week7/`) — patrz design.md Open Questions #2

## 1. `context-distiller`

- [ ] 1.1 Skopiować `week7/4-uogolnienie-demo/context-distiller/SKILL.md` do `.claude/skills/context-distiller/SKILL.md`
- [ ] 1.2 Usunąć prefiks `maister:` z `name:` frontmatter zgodnie z D1
- [ ] 1.3 Naprawić artefakt edycyjny (osamotniona litera `a` przed "## Core Principles")
- [ ] 1.4 Uruchomić skill na `week7/4-uogolnienie-demo/analiza-encji-modulow.md` jako input testowy
- [ ] 1.5 Porównać jakościowo wynik z `week7/4-uogolnienie-demo/uogolnienie-ze-sprawdzeniem.md`
- [ ] 1.6 Uruchomić negatywny test fit (prosty, jednoznaczny proces bez ambiguity/generalizacji) i potwierdzić poprawne odrzucenie

## 2. `accounting-archetype-mapper`

- [ ] 2.1 Skopiować `week7/5-znanewzorce-demo/accounting-archetype-mapper/SKILL.md` do `.claude/skills/accounting-archetype-mapper/SKILL.md`
- [ ] 2.2 Dostosować `name:` frontmatter zgodnie z D1
- [ ] 2.3 Odtworzyć scenariusz `week7/5-znanewzorce-demo/demo-accounting-co2.md` (fit test + pytania doprecyzowujące + model wynikowy)
- [ ] 2.4 Uruchomić negatywny test (wymaganie typu state machine) i potwierdzić `fit: false`
- [ ] 2.5 Zweryfikować obecność Decision Sanity Check z etykietami (R)/(A)/(X) w wyniku

## 3. `pricing-archetype-mapper`

- [ ] 3.1 Skopiować `week7/5-znanewzorce-demo/pricing-archetype-mapper/SKILL.md` do `.claude/skills/pricing-archetype-mapper/SKILL.md`
- [ ] 3.2 Dostosować `name:` frontmatter zgodnie z D1
- [ ] 3.3 Uruchomić wbudowany przykład EV charging station i potwierdzić complexity level 8 oraz strukturę Component Tree
- [ ] 3.4 (opcjonalnie) Uruchomić skill na opisie domeny z `week9/AJ-dotnet/noesis/design-docs/footprint-calculation-engine-6e3108da.json` i porównać koncepcyjnie z istniejącą implementacją C#

## 4. `archetype-scanner` (wymaga ukończonych 2 i 3)

- [ ] 4.1 Utworzyć companion agent `.claude/agents/accounting-archetype-mapper.md` (`skills: [accounting-archetype-mapper]`)
- [ ] 4.2 Utworzyć companion agent `.claude/agents/pricing-archetype-mapper.md` (`skills: [pricing-archetype-mapper]`)
- [ ] 4.3 Zweryfikować, że `Agent` tool poprawnie preloaduje skill przez `skills:` frontmatter i wykonuje go (test techniczny wzorca D4)
- [ ] 4.4 Skopiować `week7/5-znanewzorce-demo/archetype-scanner/SKILL.md` do `.claude/skills/archetype-scanner/SKILL.md`
- [ ] 4.5 Ograniczyć rejestr archetypów do 2 wpisów (accounting, pricing), usunąć/skomentować martwe odwołanie do `party.md` w strukturze katalogu wyjściowego
- [ ] 4.6 Test negatywny: wymaganie czysto CRUD → oba archetypy `fit: false`
- [ ] 4.7 Test pozytywny pojedynczy: scenariusz z `demo-accounting-co2.md` → tylko accounting `fit: true`
- [ ] 4.8 Test pozytywny podwójny: scenariusz mieszający accounting + pricing → oba `fit: true`, overlap widoczny w Domain Concept Distribution
- [ ] 4.9 Potwierdzić równoległe (nie sekwencyjne) uruchomienie obu agentów w jednej turze

## 5. `aggregate-designer`

- [ ] 5.1 Skopiować `week7/6-jednostkispojnosci-demo/aggregate-designer/SKILL.md` do `.claude/skills/aggregate-designer/SKILL.md`
- [ ] 5.2 Dostosować `name:` frontmatter zgodnie z D1
- [ ] 5.3 Zaktualizować odwołanie do klasyfikatora problemu w Phase 1 zgodnie z decyzją z zadania 0.2 (nazwa spójna z `problem-classifier` lub komentarz "TBD" jeśli R9 odrzucone)
- [ ] 5.4 Przygotować zestaw odpowiedzi testowych na bazie `week7/2-research-demo/historia-seby.md` (zasoby RC: sala/trener/sprzęt; aktorzy: handlowiec/organizator; wolumen: niski-średni)
- [ ] 5.5 Przeprowadzić pełny przebieg wizarda: Fit Check → Extract Commands → Conflict Matrix → Business Process Sequencing → Frequency/Volume → Data Scope → Boundary Decision → Locking Strategy → Final Model
- [ ] 5.6 Zweryfikować wykrycie self-conflict i (jeśli zastosowane komendy z zakresami czasowymi) time-range conflict trap w Conflict Matrix
- [ ] 5.7 Porównać jakościowo finalny boundary diagram z modelem "Pula Pojemności"/`SlotClaim` z `week7/4-uogolnienie-demo/uogolnienie-ze-sprawdzeniem.md`

## 6. `research-gatherer` (wykonać jako ostatni)

- [ ] 6.1 Zdecydować: nowe dedykowane lite-agenty (rekomendacja D2) vs reużycie `maister:research-planner`/`information-gatherer`
- [ ] 6.2 Skopiować i dostosować `.claude/skills/research-gatherer/SKILL.md` z `week7/3-research-gatherer-demo/research-gatherer-standalone/skills/research-gatherer/SKILL.md`, usuwając odwołania do plików spoza zakresu migracji
- [ ] 6.3 Skopiować `.claude/skills/research-gatherer/references/research-methodologies.md`, dodać sekcję "Anti-pattern: Broad Goal Without Rejection Criteria" (z wnioskiem z `week7/2-research-demo/podejscie-2-szeroki-cel.md`)
- [ ] 6.4 Utworzyć `.claude/agents/research-planner.md` na bazie `week7/3-research-gatherer-demo/research-gatherer-standalone/agents/research-planner.md`, zachowując Scope Extraction (1A) / Success Criteria (1B) / Actor Detection (1C)
- [ ] 6.5 Utworzyć `.claude/agents/information-gatherer-lite.md` na bazie odpowiednika w `week7/3-research-gatherer-demo/research-gatherer-standalone/agents/information-gatherer-lite.md`, zachowując Declarative Conclusions tagging + Analytical Impact Filter oraz Rejected Information tracking
- [ ] 6.6 Utworzyć `.claude/commands/research-gather.md` wzorem `.claude/commands/opsx/*.md` (krótki, deleguje do skilla przez wymuszoną instrukcję delegacji)
- [ ] 6.7 Skopiować przykładowe dane testowe (`week7/3-research-gatherer-demo/tasks/research/2026-03-10-fitbox-order-workarounds/historia-agnieszki.md`) do lokalizacji poza `week7/` (np. `.maister/tasks/research/`) przed testem, ponieważ `week7/` jest read-only i test nie może tam zapisywać wyników
- [ ] 6.8 Uruchomić `/research-gather` na skopiowanym scenariuszu FitBox i porównać strukturę wynikowych plików (`00-summary.md`, `97-actor-map.md`, `98-rejected.md`, `99-verification.md`) z oryginałem w `week7/3-research-gatherer-demo/tasks/research/2026-03-10-fitbox-order-workarounds/analysis/findings/`
- [ ] 6.9 Zweryfikować poprawną klasyfikację `mixed` dla pytania łączącego źródło wewnętrzne i zewnętrzne
- [ ] 6.10 Zaktualizować `.maister/docs/INDEX.md`, jeśli konwencja dokumentacji repo tego wymaga

## 7. Zamknięcie

- [ ] 7.1 Zweryfikować, że żaden plik w `week7/` nie został zmodyfikowany (git diff/status na `week7/` puste)
- [ ] 7.2 Zaktualizować `week9/openspec/plan.md`, jeśli w trakcie implementacji ujawniono nowe rozbieżności względem analizy
