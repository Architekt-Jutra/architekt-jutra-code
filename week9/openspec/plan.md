# Plan: Adaptacja metodologii z `week7/` do zestawu skilli projektu `architekt-jutra-code`

Status dokumentu: ANALIZA I PLANOWANIE — zero implementacji kodu. Sporządzony bez modyfikacji `week7/` (read-only).

---

## Executive Summary

`week7/` to katalog materiałów kursowych demonstrujących pięć metodologicznych modułów pracy architekta/modelarza domeny, wspieranych przez Claude Code:

- **Moduł 2** (`2-research-demo/`) — studium przypadku (`historia-seby.md`) + 4 kontrastowe podejścia do prowadzenia researchu (naiwny prompt, szeroki cel bez filtra, konkretny cel — obejścia ludzi, konkretny cel — koordynacja zasobów). Uczy **jak formułować cel researchu**, żeby uniknąć information overload i trafić w konkretne, użyteczne wnioski. Nie jest samodzielnym skillem — jest materiałem uzasadniającym metodologiczne decyzje modułu 3.
- **Moduł 3** (`3-research-gatherer-demo/`) — kompletny, samodzielny (`standalone`) zestaw: skill `research-gatherer`, agenci `research-planner` i `information-gatherer-lite`, command `/research-gather`, oraz zależność `orchestrator-framework` (reference doc). Dodatkowo pełny przykład wykonania na zadaniu `2026-03-10-fitbox-order-workarounds` (zduplikowany identycznie w `week7/tasks/research/2026-04-10-fitbox-order-workarounds/` — **potwierdzony bit-identyczny duplikat**, `Compare-Object` zwrócił 0 różnic na `research-brief.md`; oba katalogi mają identyczną strukturę plików).
- **Moduł 4** (`4-uogolnienie-demo/`) — skill `context-distiller` (`maister:context-distiller` we frontmatterze) + trzy progresywne demo-transkrypty (`uogolnienie.md` → `uogolnienie-plus.md` → `uogolnienie-ze-sprawdzeniem.md`) pokazujące ewolucję promptu uogólnienia (bez propozycji dodatkowych konceptów → z propozycjami → z kontrprzykładami/testem fałszywego uogólnienia) na tym samym przykładzie domenowym (system zapisów na szkolenia z `historia-seby.md`) + `analiza-encji-modulow.md` (naiwna analiza encji/modułów bez techniki uogólnienia, punkt odniesienia "przed").
- **Moduł 5** (`5-znanewzorce-demo/`) — trzy skille rozpoznawania archetypów domenowych: `archetype-scanner` (orkiestrator równoległy nad rejestrem archetypów), `accounting-archetype-mapper`, `pricing-archetype-mapper` + demo pliki (CO₂ ledger, oceny kwartalne, rozpoznanie Party Archetype z obrazka Miro).
- **Moduł 6** (`6-jednostkispojnosci-demo/`) — skill `aggregate-designer` (`maister:aggregate-designer`) — interaktywny wizard projektowania agregatów DDD/jednostek spójności (fit test, ekstrakcja komend, macierz konfliktów, sondowanie sekwencji biznesowej, wolumen, zakres danych, strategia lockingu, model końcowy + fazy opcjonalne).

**Cel Week7** (wyprowadzony z materiałów): przenieść te pięć metodologii do trwałego zestawu narzędzi tego repozytorium — analogicznie do istniejących skilli `.claude/skills/aj-kg-query` i `.claude/skills/openspec-*` — gotowych do użycia przy dalszym rozwoju platformy **aj** (microkernel Spring Boot 4.0.5 / Java 25, obecnie w fazie pre-alpha scaffoldingu, patrz `.maister/docs/project/architecture.md` i `tech-stack.md`).

**Kluczowe odkrycie architektoniczne**: trzy z pięciu skilli (`context-distiller`, `aggregate-designer`, wg frontmatteru także pośrednio `research-gatherer`) noszą prefiks `maister:` i są pisane w konwencji pluginu **maister** (zainstalowanego w tym środowisku — widoczny w liście dostępnych skilli jako `maister:*`, w tym `maister:orchestrator-framework`). To zmienia strategię przeniesienia: te skille nie są neutralnymi, samodzielnymi artefaktami do skopiowania 1:1 do `.claude/skills/`, tylko kandydatami na **skille pluginu maister** (albo lekkie, projekt-lokalne skille w `.claude/skills/` — konwencja tego repo, w którym jak dotąd NIE istnieje `.claude/agents/`, więc skille tu są proste, bez subagentów). Wymaga to jawnej decyzji użytkownika, udokumentowanej jako ryzyko poniżej.

**Drugie kluczowe odkrycie**: `week9/AJ-dotnet` to **już istniejący, konkretny, w pełni skodowany przykład zastosowania Pricing Archetype (Level 7/8)** w praktyce — `week9/AJ-dotnet/noesis/archetype/pricing.md` jest bit-identyczną kopią `week7/5-znanewzorce-demo/pricing-archetype-mapper/SKILL.md`, a `week9/AJ-dotnet/noesis/design-docs/footprint-calculation-engine-*.json` opisuje wprost: *"Architektura mapuje Pricing Archetype Level 7: drzewo komponentów, wersjonowane temporalnie współczynniki emisji, kontekstowa applicability, reprodukowalność historyczna przez versionAt(timestamp)"* — potwierdzone realnym kodem C# (`ComponentTree/`, `Applicability.cs`, `EmissionCalculator.cs` + testy). Jest to jednak osobny projekt .NET używający **wtyczki Noesis SDLC** (`git clone https://github.com/NoesisVision/SDLC.git`, patrz `week9/AJ-dotnet/README.md`), nie tego repozytorium ani pluginu maister — więc satysfakcjonuje wymaganie modułu 5 (pricing) tylko **częściowo i pośrednio**: dowodzi wartości metodologii, ale nie tworzy artefaktu w `.claude/skills/` tego repo ani nie jest dostępny dla głównego projektu Java/Spring **aj**.

---

## Tabela przeglądowa wymagań

| # | Wymaganie (Week7) | Moduł | Status | Priorytet |
|---|---|---|---|---|
| R1 | Zasady dobrego scopingu researchu (cel, kryteria odrzucenia, koordynacja zasobów) jako wejście do metodologii researchu | 2 | **Partially satisfied** — zasady odzwierciedlone fragmentarycznie w Step 1A/1C research-planner (moduł 3), ale nie istnieją w tym repo jako samodzielny artefakt ani nie są wyciągnięte jako jawna checklist | Niski (materiał wspierający, nie osobny skill) |
| R2 | Skill `research-gatherer` (+ agents `research-planner`, `information-gatherer-lite`, command `/research-gather`) | 3 | **Not satisfied** | Wysoki |
| R3 | Dependency `orchestrator-framework` (delegation rules, interactive mode, state schema) | 3 | **Satisfied** — dostarczane przez zainstalowany plugin `maister` jako `maister:orchestrator-framework` (widoczne w liście dostępnych skilli tej sesji) | — (już spełnione, do wykorzystania) |
| R4 | Skill `context-distiller` (bidirectional linguistic analysis, generalizacja/wyabstrahowanie/zmiana reprezentacji) | 4 | **Not satisfied** | Wysoki |
| R5 | Skill `archetype-scanner` (równoległy orkiestrator nad rejestrem archetypów) | 5 | **Not satisfied** — dodatkowo zależny od R6+R7 | Średni |
| R6 | Skill `accounting-archetype-mapper` | 5 | **Not satisfied** | Wysoki |
| R7 | Skill `pricing-archetype-mapper` | 5 | **Partially satisfied** — zweryfikowany w praktyce w `week9/AJ-dotnet` (osobny projekt, plugin Noesis SDLC), ale nieobecny w `.claude/skills/` tego repo ani dostępny dla głównego projektu Java/Spring | Wysoki |
| R8 | Skill `aggregate-designer` (interaktywny wizard jednostek spójności) | 6 | **Not satisfied** | Wysoki |
| R9 | Dependency (opcjonalna) `maister:problem-class-classifier` dla `aggregate-designer` Phase 1 fit-check i dla RC classification przed pricing/accounting mapperów | 5, 6 | **Not satisfied w tym repo** — `week8/3/problem-classifier/SKILL.md` istnieje w `week8/` (poza zakresem edycji, ale poza `week7/` — sprawdzić z użytkownikiem czy w zakresie), frontmatter nazywa go `maister:problem-classifier`, a `aggregate-designer` odwołuje się do `maister:problem-class-classifier` — **niezgodność nazw**, patrz Ryzyka | Średni (blokuje pełną funkcjonalność R8/R9, nie blokuje MVP) |

Legenda statusu: **Satisfied** = artefakt istnieje i jest gotowy do użycia w tym repo; **Partially satisfied** = koncepcja/wartość potwierdzona, ale nie istnieje jako gotowy, używalny artefakt w `.claude/skills/` tego repo; **Not satisfied** = nic nie istnieje w tym repo.

---

## Ryzyka i niejednoznaczności (zbiorcze)

1. **Konwencja docelowa nieznana bez decyzji użytkownika**: trzy z pięciu skilli mają frontmatter `name: maister:xxx`. To sugeruje, że autorzy zamierzali je dostarczyć jako część pluginu maister (`.maister/` w repo to dane runtime pluginu — `.maister/docs/`, `.maister/tasks/` — a nie kod samego pluginu; kod pluginu maister żyje poza tym repo, instalowany jako plugin Claude Code). **Zweryfikowano**: `plugins/` w repo root to katalog frontendowych wtyczek platformy **aj** (`plugins/ai-description/`, `plugins/box-size/`, `plugins/warehouse/` — projekty TS/React z `manifest.json`, `package.json`, `node_modules/`, konsumujące `plugins/sdk.ts`/`plugins/server-sdk.ts`) — **nie zawiera** kodu pluginu maister ani żadnych plików `SKILL.md`. Repo **nie ma dostępu do źródeł pluginu maister do edycji** — plugin jest zainstalowany zewnętrznie wobec repozytorium. Wniosek: opcja "dodać jako `maister:xxx`" nie jest wykonalna w ramach tego repo bez dostępu do repozytorium pluginu maister poza tym środowiskiem. **Rekomendacja domyślna: T0 = lokalne `.claude/skills/`** (bez `maister:` prefiksu, bez twardej zależności od TaskCreate/TaskUpdate/orchestrator-state.yml, wzorem `openspec-*`), chyba że użytkownik wskaże inną, dostępną lokalizację źródeł pluginu maister. **To pozostaje decyzją wymagającą jawnego potwierdzenia użytkownika przed T1** — wybór wpływa na wszystkie zadania implementacyjne poniżej.
2. **Brak `.claude/agents/` w tym repo**: `research-gatherer` (R2) wymaga dwóch subagentów (`research-planner`, `information-gatherer-lite`) wywoływanych przez Task tool. Obecne skille w `.claude/skills/` tego repo (`aj-kg-query`, `openspec-*`) są proste, jednoplikowe, bez subagentów — nie ma precedensu ani katalogu `.claude/agents/`. Trzeba albo (a) utworzyć `.claude/agents/research-planner.md` i `.claude/agents/information-gatherer-lite.md` jako pierwszy tego typu artefakt w repo, albo (b) zaadaptować `research-gatherer` do wywoływania **istniejących** agentów pluginu maister (`maister:research-planner`, `maister:information-gatherer` — widoczne w liście dostępnych agentów tej sesji), tracąc uproszczoną klasyfikację internal/external/mixed na rzecz istniejącej 4-typowej klasyfikacji (technical/requirements/literature/mixed) maister. Opcja (b) jest szybsza i spójniejsza z istniejącym ekosystemem, ale nie odwzorowuje 1:1 zachowania z demo (m.in. traci "Declarative Conclusions" tagging i "Rejected Information" tracking, które są unikalne dla `information-gatherer-lite`). Decyzja wymaga potwierdzenia użytkownika.
3. **Zduplikowany przykład wykonania badania**: `week7/3-research-gatherer-demo/tasks/research/2026-03-10-fitbox-order-workarounds/` i `week7/tasks/research/2026-04-10-fitbox-order-workarounds/` są identyczne (zweryfikowano `Compare-Object` na `research-brief.md` → 0 różnic; identyczna struktura katalogów `planning/`, `analysis/findings/`). Prawdopodobnie artefakt kopiowania/testowania demo. Nie wpływa na plan — nie trzeba czytać obu, ale warto odnotować w razie pytania użytkownika "dlaczego dwa razy to samo".
4. **Command injection-style tekst w `week7/3-research-gatherer-demo/research-gatherer-standalone/commands/research/gather.md`**: plik zawiera frazę `"ACTION REQUIRED: ... Call the Skill tool NOW. Do not read files, explore code, or execute workflow steps yourself."` — to standardowy wzorzec Claude Code dla plików `commands/*.md` (wymuszenie delegacji do skilla), NIE jest to złośliwa treść, ale warto to świadomie odróżnić przy przenoszeniu: cel tej frazy to zapobiec agentowi "ręcznemu" wykonywaniu kroków workflow zamiast wejścia przez `Skill` tool.
5. **Niezgodność nazw `problem-classifier` vs `problem-class-classifier`**: `week8/3/problem-classifier/SKILL.md` ma `name: maister:problem-classifier`, ale `aggregate-designer` (moduł 6) i `pricing`/`accounting`-archetype-mapper referencje w innych miejscach mówią `maister:problem-class-classifier`. Jeśli to dwa różne zamierzone skille (klasyfikator ogólny problemu modelowania vs specyficzny do RC) — trzeba zapytać użytkownika, który z nich ma być kanonicznym prerequisite. Jeśli to literówka w jednym z materiałów kursowych — udokumentować i ujednolicić przy migracji (whichever name is chosen, must be consistent across `aggregate-designer`'s fit-check text and the actual skill file name).
6. **`week8/` jest poza jawnie wskazanym zakresem `week7/`**: użytkownik poprosił o sprawdzenie `week8/3/problem-classifier/SKILL.md` jako "pokrewny skill" — potwierdzam jego istnienie i treść, ale traktuję go jako **zewnętrzny prerequisite do rozważenia**, nie jako wymaganie week7 do zaimplementowania w ramach tego planu (poza zakresem R1–R9). Migracja `problem-classifier` (jeśli w ogóle potrzebna) powinna być osobnym, jawnie zaakceptowanym zadaniem — nie została w tym planie rozpisana jako R-numer, tylko jako zależność opcjonalna w R9.
7. **`.maister/docs/project/architecture.md` i `tech-stack.md` są mocno pre-alpha**: `src/main/java/pl/devstyle/aj/` zawiera wyłącznie bootstrap (`AjApplication.java`), brak modułów domenowych, brak schematu bazy (Liquibase changelog pusty), plugin framework nie wybrany (PF4J/OSGi/JPMS "researched but not selected"). Oznacza to, że **żaden z pięciu skilli nie ma jeszcze realnego kodu domenowego "aj" do przetestowania end-to-end** poza syntetycznymi/demo scenariuszami z week7 lub hipotetycznymi wymaganiami. Strategia weryfikacji (patrz każda sekcja R2–R8) musi więc opierać się na scenariuszach demo z week7 (odtworzenie ich na nowym skillu i porównanie jakościowe wyniku), nie na rzeczywistej domenie platformy aj — dopóki platforma nie ma modułów biznesowych.
8. **`archetype-scanner` (R5) ma twardo zakodowany rejestr archetypów** (`accounting`, `pricing` — tabela w SKILL.md wspomina też `party.md` w strukturze wyjściowej, ale rejestr wymienia tylko 2 wpisy mimo że output structure zakłada `party.md`). To niespójność w źródle: sekcja "Archetype Registry" ma tylko 2 wiersze (`accounting`, `pricing`), ale sekcja "Step 1: Create Output Directory" pokazuje `fit/party.md` jako możliwy plik wyjściowy, mimo że nie ma `party-archetype-mapper` w rejestrze ani w week7 jako osobny skill (choć `demo-party-miro.md` demonstruje rozpoznawanie Party Archetype "z wyobraźni", bez istniejącego mappera). Trzeba zdecydować: (a) zaimportować `archetype-scanner` z rejestrem ograniczonym do 2 wpisów (accounting, pricing) zgodnie z tym, co faktycznie istnieje, usuwając martwe odwołanie do `party.md` z sekcji struktury katalogu, albo (b) potraktować `party-archetype-mapper` jako trzeci, brakujący skill do zbudowania w przyszłości (nie jest wymagany przez R1–R9, bo nie ma dla niego SKILL.md w week7 — tylko demo output). Rekomendacja: (a), z notatką w Implementation Notes o możliwym rozszerzeniu.
9. **Testowanie interaktywnych wizardów (`aggregate-designer`, `accounting-archetype-mapper`, `pricing-archetype-mapper`) wymaga wielu rund `AskUserQuestion`** — nie da się ich zweryfikować w pełni automatycznie/headless. Strategia weryfikacji musi polegać na scenariuszu manualnym z udziałem człowieka (deweloper odtwarza scenariusz z demo pliku i porównuje odpowiedzi/model wynikowy z demo), nie na czysto automatycznym teście.

---

## Kolejność globalna implementacji

Zależności międzymodułowe:

```
T0 (decyzja: docelowa lokalizacja — plugin maister vs .claude/skills/ lokalne)
        │
        ▼
T1: Migracja orchestrator-framework — NIE WYMAGANA jeśli T0 = plugin maister
    (już dostępny jako maister:orchestrator-framework).
    Jeśli T0 = lokalne .claude/skills/: uprościć research-gatherer, usuwając
    zależność od TaskCreate/TaskUpdate/orchestrator-state.yml (R2 zadanie).
        │
        ▼
R2: research-gatherer (+ agents lub reuse maister agents) ──┐
        │                                                     │ (opcjonalnie: R2 output
        ▼                                                     │  może zasilać wejście R4)
R4: context-distiller ───────────────────────────────────────┤
        │                                                     │
        ▼                                                     │
R6: accounting-archetype-mapper  ─┐                           │
R7: pricing-archetype-mapper     ─┼─► R5: archetype-scanner ◄─┘
        │                         │        (wymaga R6 + R7 gotowych)
        ▼                         │
R9 (opt): problem-classifier ─────┼──► R8: aggregate-designer
    (nazewnictwo do ujednolicenia)     (Phase 1 fit-check odsyła do problem-classifier,
                                        ale działa też bez niego — miękka zależność)
```

**Rekomendowana kolejność wykonania (sekwencyjna, dla jednego dewelopera/agenta)**:

1. **T0** — Decyzja z użytkownikiem: lokalizacja docelowa (plugin maister repo vs `.claude/skills/` lokalnie). Blokuje wszystko poniżej.
2. **R4 — context-distiller** (najprostszy: brak subagentów, brak zewnętrznych zależności, jeden plik SKILL.md). Dobry pierwszy krok do zweryfikowania konwencji migracji.
3. **R6 — accounting-archetype-mapper** i **R7 — pricing-archetype-mapper** (równolegle — niezależne od siebie, oba proste jednoplikowe skille bez subagentów).
4. **R5 — archetype-scanner** (wymaga R6+R7 gotowych jako `subagent_type` / `Agent` targety — jeśli T0 = lokalne `.claude/skills/`, trzeba zweryfikować czy Agent tool może kierować `subagent_type` na inny skill, czy wymaga faktycznego zdefiniowanego `agent`; to jest odkryta niejasność, patrz zadanie T-R5-1 poniżej).
5. **R9 (opcjonalnie, po konsultacji z użytkownikiem)** — ujednolicenie/migracja `problem-classifier`.
6. **R8 — aggregate-designer** (może być zbudowany niezależnie od R9, z miękkim fallbackiem "no problem-classifier available — proceed with fit test only").
7. **R2 — research-gatherer** (najbardziej złożony: 2 subagentów + command + zależność od orchestrator-framework). Wykonać jako ostatni, po ustaleniu wzorca subagentów w T0/T1 — najwyższe ryzyko techniczne najlepiej rozwiązywać mając już przetestowany prostszy wzorzec migracji z R4/R6/R7.
8. **R1** — Nie generuje osobnego artefaktu; po zakończeniu R2 zweryfikować, czy `research-planner`/lite agent faktycznie odzwierciedla zasady scopingu z modułu 2 (Scope Extraction, Actor Detection już są w źródle — potwierdzić, że migracja ich nie utraciła).

---

## R1 — Zasady scopingu researchu (moduł 2)

**Opis wymagania**: `week7/2-research-demo/` nie definiuje skilla, lecz demonstruje (przez 4 kontrastowe podejścia na tym samym materiale źródłowym `historia-seby.md`) zasady dobrego formułowania celu researchu:
- Podejście 1 (naiwny prompt) — brak konkretnego celu → odpowiedź powierzchowna, ograniczona do jednego źródła.
- Podejście 2 (szeroki cel bez kryterium odrzucenia) — 29 sekcji z wielu domen (hotelarstwo, lotnictwo, MRP, DDD aggregates, itd.) → *"information overload"*, trudno wyciągnąć actionable wnioski bez dalszej syntezy.
- Podejście 3 (konkretny cel — obejścia ludzi) — wąski, trafny research → jasna tabela wzorców absorpcji obejść (Eventbrite Holds, hotelowe courtesy holds, soft/hard booking, itd.).
- Podejście 4 (konkretny cel — koordynacja zasobów) — wąski, trafny research → 5 domen (chirurgia, lotnictwo, MRP, eventy, RCPSP), zbieżny wniosek: "Bill of Resources" + atomowa walidacja.

**Obecny stan projektu**: **Partially satisfied**. Zasady scopingu z modułu 2 są już częściowo zoperacjonalizowane w `research-planner` (moduł 3): Step 1A "Scope Extraction" (in/out of scope, source restrictions), Step 1B "Success Criteria Discovery", Step 1C "Actor Detection". To dokładnie odpowiada lekcji z podejść 3 i 4 (konkretny cel + kryteria odrzucenia). Nie istnieje jednak w tym repo jako samodzielna, czytelna checklist czy sekcja dokumentacji ("jak dobrze sformułować cel researchu") — jest ukryta wewnątrz promptu subagenta.

**Proponowane podejście techniczne**: Nie tworzyć osobnego skilla. Zamiast tego:
1. Podczas migracji R2 (research-gatherer), upewnić się, że Step 1A/1B/1C `research-planner` (lub jego odpowiednika w wybranej architekturze z T0) zachowuje Scope Extraction + Success Criteria + Actor Detection.
2. Dodać do `references/research-methodologies.md` (kopiowanego w ramach R2) krótką sekcję "Anti-pattern: Broad Goal Without Rejection Criteria" cytującą wprost wnioski z `podejscie-2-szeroki-cel.md` jako uzasadnienie, dlaczego Scope Extraction jest obowiązkowy (nie opcjonalny) krok.

**Istniejące komponenty do reużycia**: `research-planner.md` Step 1A/1B/1C (moduł 3) już koduje tę logikę — patrz `week7/3-research-gatherer-demo/research-gatherer-standalone/agents/research-planner.md` linie 52–165.

**Pliki/komponenty do modyfikacji**: `references/research-methodologies.md` (docelowa kopia — patrz R2) — dodać sekcję Anti-pattern.

**Pliki/komponenty do utworzenia**: Brak nowego pliku dedykowanego R1 — połączone z R2.

**Zależności między wymaganiami**: R1 zależy od R2 (musi istnieć docelowy plik referencyjny do rozszerzenia).

**Zadania implementacyjne**:
1. Po ukończeniu R2, przeczytać zmigrowany `research-methodologies.md`.
2. Dodać sekcję z 2–3 zdaniami podsumowującymi wniosek z `podejscie-2-szeroki-cel.md` ("Obserwacja końcowa") jako motywację dla obowiązkowego Scope Extraction.

**Edge case'y i niejednoznaczności**: Brak istotnych — to najniższego ryzyka wymaganie w planie.

**Strategia testowania/weryfikacji**: Manualny przegląd — porównać treść dodanej sekcji z oryginalnym wnioskiem w `podejscie-2-szeroki-cel.md`, upewnić się że nie zniekształca sensu.

**Kryteria akceptacji**: `references/research-methodologies.md` w docelowej lokalizacji zawiera jawną sekcję ostrzegającą przed szerokim researchem bez kryterium odrzucenia, z odniesieniem do przyczyny (information overload).

**Metoda weryfikacji**: Code review / manualny odczyt pliku po migracji.

---

## R2 — Skill `research-gatherer` (moduł 3)

**Opis wymagania**: Lekki workflow researchu (3 fazy: Initialize → Plan & Gather → Merge & Verify) który zbiera i krzyżowo weryfikuje informacje z wielu źródeł **bez syntezy** (w odróżnieniu od pełnego `maister:research`). Wymaga dwóch subagentów (`research-planner`, `information-gatherer-lite`) i entry-point commanda `/research-gather`. Kluczowe unikalne cechy nieobecne w prostszych podejściach: klasyfikacja internal/external/mixed z self-check, Actor Detection + per-actor tailored output (`97-actor-map.md`), Declarative Conclusions tagging (z "Analytical Impact Filter" — tagować tylko twierdzenia, które mogłyby zniekształcić wniosek analityczny, nie przechwałki), Rejected Information tracking (`98-rejected.md`, z kolumną "Re-include If").

**Obecny stan projektu**: **Not satisfied**. W `.claude/skills/` nie ma żadnego odpowiednika. Plugin maister dostarcza pełniejszy `maister:research` (orkiestrator z pełną syntezą) oraz agentów `maister:research-planner`, `maister:information-gatherer`, `maister:research-synthesizer` — ale to inny, cięższy workflow (4-typowa klasyfikacja technical/requirements/literature/mixed, zawsze kończy się syntezowanym raportem). `research-gatherer` wypełnia lukę: "chcę surowe, zweryfikowane dane bez narzuconej syntezy" — czego obecny plugin nie oferuje wprost.

**Proponowane podejście techniczne**:
- Jeśli T0 = plugin maister: dodać `research-gatherer` jako nowy skill pluginu maister (`maister:research-gatherer`), reużywając `maister:orchestrator-framework` bezpośrednio (bez kopiowania `orchestrator-patterns.md`), i albo (a) napisać dwa nowe, dedykowane subagenty pluginu (`maister:research-planner-lite`, `maister:information-gatherer-lite` — nazwy różne od istniejących, by uniknąć konfliktu), albo (b) sparametryzować istniejące `maister:research-planner`/`maister:information-gatherer`, aby przyjmowały uproszczony tryb klasyfikacji (ryzykowne — zmienia współdzielony komponent używany przez `maister:research`).
- Jeśli T0 = lokalne `.claude/skills/`: utworzyć `.claude/skills/research-gatherer/SKILL.md` (bez `maister:` prefiksu), `.claude/agents/research-planner.md`, `.claude/agents/information-gatherer-lite.md` (pierwszy precedens subagentów w tym repo), `.claude/commands/research-gather.md` (analogicznie do istniejącej konwencji `.claude/commands/opsx/*.md`). Zależność `orchestrator-framework` — skopiować `orchestrator-patterns.md` jako `.claude/skills/research-gatherer/references/orchestrator-patterns.md` (tylko potrzebne sekcje: Delegation Rules, Interactive Mode, State Schema — bez sekcji specyficznych dla `development`/`performance`/`migration` orkiestratorów, których to repo nie ma) LUB uprościć: usunąć zależność od `TaskCreate`/`TaskUpdate`/`orchestrator-state.yml` całkowicie i zastąpić lżejszym, płaskim przebiegiem 3 faz bez formalnego state-trackingu (odpowiedniejsze dla prostego, jednoplikowego stylu istniejących skilli tego repo).
- Task directory: zachować `.maister/tasks/research/YYYY-MM-DD-task-name/` (już istniejący wzorzec w tym repo — widoczne prawdziwe użycie w `.maister/tasks/development/2026-03-28-*/`), niezależnie od T0.

**Istniejące komponenty do reużycia**:
- `maister:orchestrator-framework` (jeśli T0 = plugin) — Delegation Rules, Interactive Mode (`AskUserQuestion` przy `→ Pause`), State Schema.
- Struktura katalogów `.maister/tasks/*/` — już używana wzorcowo przez `maister:development` (patrz `.maister/tasks/development/2026-03-28-ecommerce-product-management/`).
- Konwencja `.claude/commands/opsx/*.md` jako wzór struktury command file (krótki, deleguje do skilla).

**Pliki/komponenty do modyfikacji**: Brak istniejących plików do modyfikacji (nowy skill), poza ewentualnym `.maister/docs/INDEX.md` — dodać wzmiankę o nowym skillu jeśli konwencja repo tego wymaga (do potwierdzenia z `maister:docs-manager` przy realnej implementacji).

**Pliki/komponenty do utworzenia** (wariant lokalny, T0 = `.claude/skills/`):
- `.claude/skills/research-gatherer/SKILL.md`
- `.claude/skills/research-gatherer/references/research-methodologies.md`
- `.claude/skills/research-gatherer/references/orchestrator-patterns.md` (lub uproszczony inline w SKILL.md)
- `.claude/agents/research-planner.md`
- `.claude/agents/information-gatherer-lite.md`
- `.claude/commands/research-gather.md`

**Zależności między wymaganiami**: R2 zależy od T0 (decyzja lokalizacji) i pośrednio od T1 (czy orchestrator-framework jest reużywany czy uproszczony). R1 (moduł 2) jest logicznie zagnieżdżony w R2 (Scope Extraction). R4 (context-distiller) może opcjonalnie konsumować output R2 jako wejście domenowe (typowy przepływ: research → distillation), ale to nie jest twarda zależność — obie mogą działać niezależnie.

**Zadania implementacyjne**:
1. T0: potwierdzić z użytkownikiem lokalizację docelową.
2. Zdecydować (T-R2-1): nowe dedykowane lite-agenty vs reużycie istniejących `maister:research-planner`/`information-gatherer` w trybie uproszczonym.
3. Skopiować i dostosować `SKILL.md`, usuwając odwołania do plików spoza zakresu (np. `research-orchestrator` wspomniany jako "For full research with synthesis" — zastąpić odwołaniem do `maister:research` jeśli ten plugin jest dostępny).
4. Skopiować `research-methodologies.md`, dodać sekcję R1 (Anti-pattern: Broad Goal).
5. Utworzyć/dostosować agentów (`research-planner`, `information-gatherer-lite`) zachowując: Declarative Conclusions tagging + Analytical Impact Filter, Rejected Information tracking, Actor Relevance tagging.
6. Utworzyć command `/research-gather` (lub `/research-gatherer` — potwierdzić konwencję nazewnictwa command vs skill w tym repo, `opsx:*` sugeruje krótkie aliasy).
7. Wykonać przebieg testowy (patrz Strategia testowania) na scenariuszu FitBox z demo.
8. Zaktualizować `.maister/docs/INDEX.md` jeśli wymagane przez konwencję dokumentacji repo.

**Edge case'y i niejednoznaczności**:
- Duplikat przykładu wykonania (patrz Ryzyko 3) — nie wpływa na implementację, tylko na wybór, którego przykładu użyć do testu (rekomendacja: `2026-03-10-fitbox-order-workarounds`, starszy/oryginalny wg nazwy katalogu).
- Tekst "ACTION REQUIRED" w `commands/research/gather.md` (Ryzyko 4) — zachować wzorzec przy tworzeniu nowego commanda, to standardowa praktyka wymuszania delegacji w Claude Code, nie usuwać.
- Maksymalna liczba gatherer instances (8) i domyślne 4 kategorie (codebase/documentation/configuration/external) — zachować bez zmian, są dobrze uzasadnione w źródle.

**Strategia testowania/weryfikacji**:
1. Odtworzyć scenariusz `2026-03-10-fitbox-order-workarounds` uruchamiając nowy `/research-gather` na tym samym pytaniu badawczym (`historia-agnieszki.md` jako źródło wewnętrzne — **UWAGA**: ten plik istnieje tylko w `week7/`, więc do pełnego testu E2E trzeba go skopiować do lokalizacji poza `week7/` przed uruchomieniem, np. `.maister/tasks/research/`, ponieważ `week7/` jest read-only i test nie może zapisywać tam wyników).
2. Porównać strukturę wynikowych plików (`00-summary.md`, `98-rejected.md`, `99-verification.md`, `97-actor-map.md`) z oryginałem — nie oczekując identycznej treści (LLM niedeterministyczny), ale identycznej **struktury sekcji** i obecności wymaganych elementów (Declarative Conclusions, Rejected Information, Actor Relevance).
3. Zweryfikować, że klasyfikacja typu (internal/external/mixed) poprawnie wykrywa `mixed` dla pytania mieszającego źródło wewnętrzne (transkrypcja) i zewnętrzne (praktyki branżowe) — zgodnie z self-check w SKILL.md.

**Kryteria akceptacji**:
- `research-gatherer` (lub `maister:research-gatherer`) uruchamia się przez Skill/command tool i przechodzi 3 fazy bez błędów na testowym pytaniu.
- Generuje wszystkie wymagane pliki wyjściowe zgodnie ze strukturą z sekcji "Task Structure" źródłowego SKILL.md.
- `99-verification.md` zawiera sekcję Declarative Conclusions z poprawnie zastosowanym Analytical Impact Filter (nie taguje przechwałek).
- `98-rejected.md` istnieje nawet gdy brak odrzuceń (z odpowiednim komunikatem).

**Metoda weryfikacji**: Manualne uruchomienie end-to-end na środowisku deweloperskim + code review struktury wygenerowanych plików względem specyfikacji SKILL.md.

---

## R4 — Skill `context-distiller` (moduł 4)

**Opis wymagania**: Skill analizujący domenę pod kątem bezpiecznych generalizacji między konceptami domenowymi (analiza dwukierunkowa: ambiguity detection — jedno słowo, wiele znaczeń; generalization detection — wiele słów, jedno znaczenie) + Analysis C (proponowanie dodatkowych, niewymienionych w tekście konceptów pasujących do znalezionego uogólnienia — spekulatywne, do potwierdzenia z użytkownikiem). Dwa tryby: pełna dystylacja domeny / sonda pojedynczego konceptu. 6 zasad rdzeniowych (generalizuj zachowanie nie tożsamość, granice tam gdzie pojawiają się procesy specyficzne dla typu, testuj efektem w kontekście konsumenta nie przyczyną u źródła, generalizacje żyją wewnątrz jednego bounded context, model uogólniony nie zna specyfiki, szukaj po czasownikach nie rzeczownikach).

**Obecny stan projektu**: **Not satisfied**. Brak jakiegokolwiek odpowiednika w `.claude/skills/` ani w pluginie maister (nie widoczny na liście dostępnych skilli tej sesji pod żadną nazwą `context-distiller` ani podobną).

**Proponowane podejście techniczne**: To najprostszy do migracji skill z całego zestawu — jeden plik `SKILL.md`, zero subagentów, zero zewnętrznych zależności (poza opcjonalną wzmianką o `accounting-archetype-mapper` i `aggregate-designer` jako "next steps" w Notes sekcji przykładu — te odwołania to tylko sugestie tekstowe, nie techniczne zależności wykonawcze). Skopiować niemal 1:1.
- Jeśli T0 = plugin maister: umieścić jako `maister:context-distiller` (frontmatter już to zakłada).
- Jeśli T0 = lokalne: usunąć prefiks `maister:` z `name:` we frontmatterze, dostosować argument-hint bez zmian merytorycznych.

**Istniejące komponenty do reużycia**: Brak potrzebnych — samodzielny.

**Pliki/komponenty do modyfikacji**: Brak.

**Pliki/komponenty do utworzenia**:
- `.claude/skills/context-distiller/SKILL.md` (lub odpowiednik w pluginie maister zależnie od T0).

**Zależności między wymaganiami**: Brak zależności wejściowych. Wyjściowo: sugerowany (nieobowiązkowy) input dla R6/R8 (accounting-archetype-mapper, aggregate-designer) — distillation map jako wejście do dalszego modelowania.

**Zadania implementacyjne**:
1. T0: potwierdzić lokalizację.
2. Skopiować `SKILL.md` 1:1, dostosowując tylko `name:` frontmatter zgodnie z T0.
3. Zweryfikować przykład ("Example" sekcja na końcu pliku, system szkoleń) renderuje się poprawnie jako dokumentacja wewnętrzna skilla (to jest zamrożony przykład referencyjny, nie wymaga zmian).
4. Uruchomić skill na przykładzie `analiza-encji-modulow.md` (naiwna analiza encji, "przed") jako input i porównać wynik z `uogolnienie-ze-sprawdzeniem.md` (finalna, najpełniejsza wersja demo, "po") — najlepszy dostępny punkt odniesienia jakościowego.

**Edge case'y i niejednoznaczności**:
- Plik ma literówkę-artefakt: linia 73 zawiera samotną literę `a` na początku sekcji "## Core Principles" (`## Core Principles\na\n\nThese principles...`) — najprawdopodobniej błąd edycyjny w źródle. **Naprawić przy migracji** (usunąć osamotnione `a`), udokumentować jako drobną korektę, nie jako zmianę merytoryczną.
- Plik `uogolnienie-ze-sprawdzeniem.md` linia 42 zawiera samotny znak `=` w tabeli kontrprzykładów (artefakt formatowania) — nie wpływa na `context-distiller` SKILL.md (to plik demo, nie skill), ale warto odnotować przy ewentualnym wykorzystaniu tego pliku jako przykładu w dokumentacji wewnętrznej.
- Trzy pliki demo (`uogolnienie.md`, `-plus.md`, `-ze-sprawdzeniem.md`) reprezentują 3 kolejne iteracje tego samego promptu z rosnącą liczbą instrukcji (podstawowa tabela → + propozycje dodatkowych konceptów → + kontrprzykłady/test fałszywego uogólnienia). Finalny `SKILL.md` już integruje wszystkie trzy poziomy (Step 2C = propozycje, Principle 2/3 = kontrprzykłady/test efektu) — nie trzeba nic dodatkowo wyciągać z plików demo do SKILL.md, ponieważ SKILL.md to już finalna, w pełni zintegrowana wersja. Pliki demo służą wyłącznie jako materiał testowy/porównawczy.

**Strategia testowania/weryfikacji**:
1. Uruchomić `context-distiller` na treści `analiza-encji-modulow.md` (surowa lista encji i modułów, bez techniki uogólnienia) jako input.
2. Sprawdzić czy wynik zawiera Ambiguities Detected, Generalizations Detected, Proposed Additional Concepts (Analysis C), Distilled Context Map z jasno rozdzielonymi kontekstami generalized/specific.
3. Jakościowo porównać z `uogolnienie-ze-sprawdzeniem.md` — sprawdzić czy nowy skill dochodzi do analogicznych generalizacji (ReservableResource / Zasób, UnavailabilityPeriod / Niedostępność, SlotClaim / Roszczenie do pojemności) — nie oczekując identycznego nazewnictwa, ale identycznej struktury wniosków.
4. Sprawdzić Quality Checks listę z końca SKILL.md — każdy punkt musi być spełniony w wygenerowanym wyniku.

**Kryteria akceptacji**:
- Skill poprawnie odróżnia tryb pełnej dystylacji od sondy pojedynczego konceptu.
- Output zawiera wszystkie wymagane sekcje z "Output Format" (Linguistic Analysis Summary, Distilled Context Map, Generalization Safety Notes, Notes).
- Fit Test ("When NOT to Use") poprawnie odrzuca domeny bez ambiguity/generalization (test na prostym, jednoznacznym przykładzie spoza week7 — np. "system wysyła email po zapisaniu formularza" powinien zostać odrzucony).

**Metoda weryfikacji**: Manualne uruchomienie na 2 scenariuszach (fit + no-fit) + code review struktury wyniku.

---

## R6 — Skill `accounting-archetype-mapper` (moduł 5)

**Opis wymagania**: Transformuje wymagania domenowe zawierające akumulację/konsumpcję dowolnej wartości (pieniądze, punkty, kredyty, uprawnienia emisyjne CO₂ itd.) w model księgowy: value, accounts, transaction types, double-entry, reversals, validity/expiry, allocation strategy. Fit test: "czy mogę zapytać 'ile X ma S' i dostać liczbę z historią transakcji" vs "w jakim stanie jest X" (state machine → nie pasuje).

**Obecny stan projektu**: **Not satisfied**. Brak odpowiednika w `.claude/skills/` lub pluginie maister.

**Proponowane podejście techniczne**: Kopiowanie 1:1, jednoplikowy skill bez subagentów, analogiczny wzorzec do R4.
- `name:` frontmatter dostosować do T0.

**Istniejące komponenty do reużycia**: Brak.

**Pliki/komponenty do modyfikacji**: Brak.

**Pliki/komponenty do utworzenia**: `.claude/skills/accounting-archetype-mapper/SKILL.md`.

**Zależności między wymaganiami**: Wejście (opcjonalne) od R4 (context-distiller output). Wyjście: wejście dla R5 (archetype-scanner, wywołuje ten skill jako subagent/Agent target). Miękka zależność koncepcyjna od R9 (problem-classifier) — jeśli fit test daje wynik niejednoznaczny, klasyfikator problemu mógłby pomóc rozstrzygnąć CRUD vs RC vs accounting, ale nie jest to twarda zależność w źródle.

**Zadania implementacyjne**:
1. T0: potwierdzić lokalizację.
2. Skopiować `SKILL.md` 1:1.
3. Test na przykładzie z demo (`demo-accounting-co2.md`) — porównać czy nowy skill dochodzi do tej samej struktury Accounts/Transactions/Validity dla identycznego promptu wejściowego.

**Edge case'y i niejednoznaczności**:
- Sekcja "Borderline cases" (appointment slots, permissions/feature flags, queue position) wymaga subiektywnej oceny modelarskiej — nie jest to coś do "naprawienia" przy migracji, ale warto potwierdzić w testach, że skill poprawnie odrzuca np. czysty state machine.
- `demo-accounting-co2.md` zawiera pełny, zamrożony przebieg (fit test → pytania → model wynikowy) — to gotowy złoty scenariusz testowy, wysokiej wartości.

**Strategia testowania/weryfikacji**:
1. Uruchomić skill z promptem identycznym jak w `demo-accounting-co2.md` (linie 3–5: wymagania wejściowe o śladzie węglowym / EU ETS).
2. Porównać czy Fit Test przechodzi (tak jak w demo).
3. Odpowiedzieć na te same pytania doprecyzowujące co w demo (deweloper ręcznie odgrywa rolę użytkownika z demo).
4. Porównać strukturę wynikowego modelu (Accounts, Transactions & Entries, Validity Rules, Allocation Strategy, Reversal Rules) z demo — sprawdzić czy pokrywa te same konta (`ets_allocation_pool`, `market_purchased_pool`, itd.) koncepcyjnie, nawet jeśli nazewnictwo się różni.
5. Uruchomić dodatkowo negatywny test (np. "zadanie przechodzi ze stanu open do closed" — powinien zostać odrzucony jako state machine, nie accounting).

**Kryteria akceptacji**:
- Fit Test poprawnie klasyfikuje demo scenariusz jako "pasuje".
- Wynikowy model zawiera wszystkie sekcje z Output Format, w tym niepustą sekcję "Unmapped Concepts" (nawet jeśli "None identified").
- Decision Sanity Check (Step 9.5) jest wykonywany — każda decyzja ma oznaczenie (R)/(A)/(X) i (X) o wysokim wpływie biznesowym generuje pytanie doprecyzowujące zamiast cichego założenia.

**Metoda weryfikacji**: Manualne odtworzenie scenariusza CO₂ + negatywny test state machine.

---

## R7 — Skill `pricing-archetype-mapper` (moduł 5)

**Opis wymagania**: Transformuje wymagania z komponentem obliczanej ceny/stawki (zależnej od kontekstu: czas, ilość, segment klienta, kanał) w model: Calculator layer (6 typów pure-function kalkulatorów), Component tree (Simple/Composite z ParameterValue algebra: ValueOf/SumOf/DifferenceOf/ProductOf), Validity & Versioning (poziom złożoności 1–9, `ComponentVersion` z `definedAt` dla algorithm history), Applicability conditions, Context dimensions, Product-Pricing Mapping (1:1/1:N/N:1/N:M/1:0). Fit test: "ile kosztuje X dla Y w czasie T w kontekście C, reprodukowalnie i audytowalnie" — odróżnia się od accounting ("ile ma") i state machine ("w jakim jest stanie").

**Obecny stan projektu**: **Partially satisfied**. Sam artefakt SKILL.md nie istnieje w `.claude/skills/` tego repo ani w pluginie maister — ale **metodologia jest już zweryfikowana w praktyce** w `week9/AJ-dotnet`:
- `week9/AJ-dotnet/noesis/archetype/pricing.md` = bit-identyczna kopia treści `week7/5-znanewzorce-demo/pricing-archetype-mapper/SKILL.md` (potwierdzone porównaniem treści — identyczne nagłówki, tabele, przykład EV charging session).
- `week9/AJ-dotnet/noesis/design-docs/footprint-calculation-engine-6e3108da.json` jawnie deklaruje: *"Architektura mapuje Pricing Archetype Level 7: drzewo komponentów, wersjonowane temporalnie współczynniki emisji, kontekstowa applicability, reprodukowalność historyczna przez versionAt(timestamp)"*.
- Kod C# potwierdza rzeczywistą implementację: `week9/AJ-dotnet/src/FootprintCalculation/ComponentTree/{Component,CompositeComponent,SimpleComponent,SimpleComponentVersion,Applicability,AlwaysApplicable,RequiresRefrigeration,Validity}.cs` + `EmissionMeasurement/{EmissionCalculator,EmissionFactorRate,KgCO2,Quantity}.cs` + testy w `tests/FootprintCalculation.Tests/`.
- Ograniczenie: to osobny projekt .NET, osobna wtyczka (`Noesis SDLC`, sklonowana z `https://github.com/NoesisVision/SDLC.git`, patrz `week9/AJ-dotnet/README.md`) — **niedostępna** dla głównego projektu Java/Spring **aj** ani dla `.claude/skills/` tego repo.

**Proponowane podejście techniczne**: Kopiowanie 1:1 do `.claude/skills/` tego repo (lub pluginu maister wg T0) — niezależnie od istnienia w Noesis SDLC, ponieważ ten skill musi być dostępny **w kontekście głównej platformy aj** (Java/Spring), nie tylko w osobnym projekcie .NET. Potraktować `week9/AJ-dotnet` jako **walidację jakości metodologii i gotowy materiał referencyjny** (dodatkowy, trzeci przykład testowy obok EV charging z SKILL.md), nie jako substytut migracji.

**Istniejące komponenty do reużycia**: Cały przykład `footprint-calculation-engine` (design-doc JSON + kod C#) jako dodatkowy, wysokiej jakości materiał testowy — do wykorzystania w Strategii testowania poniżej (jako trzeci scenariusz, obok EV charging z SKILL.md i demo z week7 jeśli istnieje).

**Pliki/komponenty do modyfikacji**: Brak.

**Pliki/komponenty do utworzenia**: `.claude/skills/pricing-archetype-mapper/SKILL.md`.

**Zależności między wymaganiami**: Wyjście: wejście dla R5 (archetype-scanner).

**Zadania implementacyjne**:
1. T0: potwierdzić lokalizację.
2. Skopiować `SKILL.md` 1:1 z `week7/5-znanewzorce-demo/pricing-archetype-mapper/SKILL.md`.
3. Test na przykładzie EV charging (wbudowany w SKILL.md jako "Example").
4. Test dodatkowy (opcjonalny, wysokiej wartości) — uruchomić skill na opisie domeny footprint calculation (na podstawie `week9/AJ-dotnet/noesis/design-docs/footprint-calculation-engine-6e3108da.json` description) i porównać wynikowy model koncepcyjnie z istniejącą implementacją C#.

**Edge case'y i niejednoznaczności**: Brak istotnych nowych — źródło jest kompletne i już zwalidowane w niezależnym projekcie.

**Strategia testowania/weryfikacji**:
1. Uruchomić skill z promptem EV charging station z SKILL.md.
2. Porównać complexity level (oczekiwany: 8) i strukturę Component Tree z wbudowanym przykładem.
3. (Opcjonalnie, wysoka wartość) Uruchomić skill na opisie domeny "silnik obliczeniowy carbon footprint produktu" (z design-doc JSON) i sprawdzić czy proponuje analogiczną strukturę do rzeczywistej implementacji C# (ComponentTree z Applicability, SimpleComponentVersion z temporal versioning, `versionAt(timestamp)`).

**Kryteria akceptacji**:
- Complexity Level jest jawnie uzasadniony dowodami z requirements.
- Wynikowy model zawiera Calculator Design z czystymi funkcjami (bez warunków biznesowych w kalkulatorach — zgodnie z Pattern "Calculators Are Pure Functions").
- Component Tree renderuje się jako czytelny ASCII tree.

**Metoda weryfikacji**: Manualne odtworzenie scenariusza EV charging + porównawcze uruchomienie na scenariuszu footprint calculation względem istniejącego kodu C#.

---

## R5 — Skill `archetype-scanner` (moduł 5)

**Opis wymagania**: Orkiestrator uruchamiający wszystkie znane archetype mappery **równolegle** (jedna wiadomość, N agentów) na tych samych wymaganiach domenowych, zbierający wyniki fit/no-fit, po czym delegujący do agenta scalającego (`general-purpose`), który produkuje `summary.md` z tabelą Quick View, Domain Concept Distribution (w tym overlaps i gaps), Archetype Rejection Reasons.

**Obecny stan projektu**: **Not satisfied**, dodatkowo **zablokowany przez R6+R7** (Archetype Registry wskazuje na `accounting-archetype-mapper` i `pricing-archetype-mapper` jako `subagent_type` — nie mogą być wywołane przez Agent tool, dopóki nie istnieją jako zarejestrowane skille/agenci).

**Proponowane podejście techniczne**: Kluczowa niejasność techniczna: `archetype-scanner` zakłada, że `subagent_type` w wywołaniu Agent tool może wskazywać bezpośrednio na nazwę **skilla** (`accounting-archetype-mapper`, `pricing-archetype-mapper`) — ale zgodnie z `orchestrator-patterns.md` (moduł 3, sekcja "Delegation Rules"): *"Skills and agents are NOT interchangeable. Skills always use Skill tool; agents always use Task tool. Never invoke a skill via Task tool (subagent_type) — it will fail with 'Agent type not found.'"* To jest **wewnętrzna sprzeczność między moduł 3 i moduł 5** w źródle week7: `archetype-scanner` (moduł 5) wywołuje archetype mappery jako `subagent_type` (czyli jako agentów przez Task/Agent tool), ale R6/R7 są zdefiniowane jako **skille** (`SKILL.md`, nie `agent.md`), które zgodnie z zasadą modułu 3 powinny być wywoływane przez `Skill` tool, nie `Task`/`Agent` tool z `subagent_type`.
- **Rozwiązanie proponowane**: przed implementacją R5, każdy z R6/R7 (`accounting-archetype-mapper`, `pricing-archetype-mapper`) musi być **także** zarejestrowany jako companion agent (wzorem `docs-operator` companion pattern opisanego w `orchestrator-patterns.md`: *"A companion agent preloads the skill via the `skills` frontmatter field and is invoked via Task tool. This pattern fails for any skill that needs to spawn subagents."* — oba mappery NIE spawnują subagentów, więc kwalifikują się do tego wzorca). Czyli R5 wymaga dodatkowo utworzenia `.claude/agents/accounting-archetype-mapper.md` i `.claude/agents/pricing-archetype-mapper.md` jako cienkich companion-agentów preloadujących odpowiedni skill.
- Rejestr archetypów: skopiować tabelę z 2 wpisami (accounting, pricing), usunąć martwe odwołanie do `party.md` w strukturze katalogu wyjściowego (patrz Ryzyko 8) lub dodać komentarz "party-archetype-mapper nie istnieje jeszcze — zarezerwowane na przyszłość".

**Istniejące komponenty do reużycia**: Wzorzec companion agent z `orchestrator-patterns.md` (moduł 3) — jedyny znaleziony w źródłach week7 opis tego wzorca, mimo że sam moduł 3 go nie używa (research-gatherer używa pełnych subagentów, nie companion pattern).

**Pliki/komponenty do modyfikacji**: `week7/5-znanewzorce-demo/archetype-scanner/SKILL.md` → skopiowana wersja: usunąć/zakomentować odwołanie do `party.md`.

**Pliki/komponenty do utworzenia**:
- `.claude/skills/archetype-scanner/SKILL.md`
- `.claude/agents/accounting-archetype-mapper.md` (companion agent, `skills: [accounting-archetype-mapper]` frontmatter)
- `.claude/agents/pricing-archetype-mapper.md` (companion agent, `skills: [pricing-archetype-mapper]` frontmatter)

**Zależności między wymaganiami**: Twarda zależność na R6 i R7 (muszą istnieć jako skille PRZED utworzeniem companion agentów). Zależność techniczna na wzorcu companion agent z modułu 3 (R2/R3).

**Zadania implementacyjne**:
1. Upewnić się, że R6 i R7 są ukończone i przetestowane.
2. Utworzyć dwa companion agenty.
3. Skopiować `archetype-scanner/SKILL.md`, poprawić rejestr (usunąć/oznaczyć `party.md` jako future work).
4. Test: uruchomić scanner na wymaganiach mieszających sygnały accounting + pricing (np. rozszerzony wariant CO₂: "firma ma limit uprawnień (accounting) ORAZ płaci zmienną cenę za przekroczenie zależną od pory roku (pricing)") — potwierdzić że oba archetypy trafiają jako "fit", a Domain Concept Distribution poprawnie pokazuje overlap.

**Edge case'y i niejednoznaczności**:
- Sprzeczność Skill-tool-vs-Task-tool opisana wyżej jest głównym ryzykiem technicznym tego wymagania — wymaga potwierdzenia z użytkownikiem/testu w rzeczywistym środowisku Claude Code, czy companion agent pattern faktycznie działa dla tych dwóch skilli (żaden z nich nie spawnuje subagentów, więc teoretycznie kwalifikuje się).
- "Agent times out" i "All archetypes return no-fit" mają już zdefiniowaną obsługę błędów w źródle — zachować bez zmian.

**Strategia testowania/weryfikacji**:
1. Test negatywny: wymagania czysto CRUD (np. "użytkownik edytuje swój profil") → oba archetypy powinny zwrócić `fit: false`, `summary.md` powinien skupić się na sekcji Gaps.
2. Test pozytywny pojedynczy: wymagania czysto accounting (np. z demo CO₂) → tylko `accounting` fit.
3. Test pozytywny podwójny: wymagania mieszające oba archetypy → oba fit, sprawdzić Domain Concept Distribution i Overlaps.

**Kryteria akceptacji**:
- Oba companion agenty poprawnie preloadują i wykonują odpowiedni skill.
- `summary.md` zawiera wszystkie wymagane sekcje (Quick View, Matched Archetypes, Domain Concept Distribution, Overlaps, Gaps, Archetype Rejection Reasons).
- Agenty uruchamiają się równolegle (jedna wiadomość Task/Agent), nie sekwencyjnie.

**Metoda weryfikacji**: 3 manualne przebiegi testowe (negatywny, pozytywny pojedynczy, pozytywny podwójny) + code review wygenerowanego `summary.md`.

---

## R9 — Zależność opcjonalna: `problem-classifier` / `problem-class-classifier` (moduły 5, 6)

**Opis wymagania**: Nie jest to wymaganie week7 samo w sobie (`week8/` jest poza `week7/`), ale jest **przywoływane jako miękka zależność** przez `aggregate-designer` (Phase 1 Fit Check: *"Consider: ... maister:problem-class-classifier if the problem class is unclear"*) i strukturalnie komplementarne do `accounting`/`pricing`-archetype-mapper (klasyfikacja Resource Contention vs CRUD/T&P/Integration poprzedza wybór archetypu).

**Obecny stan projektu**: **Not satisfied w tym repo** (nie istnieje w `.claude/skills/` ani w pluginie maister wg listy dostępnych skilli tej sesji). Istnieje wyłącznie w `week8/3/problem-classifier/SKILL.md` — poza zakresem edycji `week7/`, ale odczytany na prośbę użytkownika. Zawiera pełną klasyfikację 4 klas problemu modelowania (CRUD, Transformation & Presentation, Integration, Resource Contention) z sygnałami tekstowymi i UI-mockup, drzewem decyzyjnym pytań doprecyzowujących, i **explicite odsyła do `maister:aggregate-designer`** na końcu ("Resource Contention — next step offer").

**Niezgodność nazw** (patrz Ryzyko 5): plik ma `name: maister:problem-classifier`, ale `aggregate-designer` odwołuje się do `maister:problem-class-classifier` (dodatkowe słowo "class"). To musi zostać ujednolicone — rekomendacja: zachować nazwę z faktycznie istniejącego pliku (`maister:problem-classifier`) jako kanoniczną i poprawić odwołanie w migrowanym `aggregate-designer` (R8), a nie odwrotnie (nie tworzyć nowego pliku pod inną nazwą).

**Proponowane podejście techniczne**: To zadanie jest **poza formalnym zakresem week7 (R1–R8)** — wymaga jawnej osobnej decyzji użytkownika, czy w ogóle migrować `problem-classifier` w ramach tej pracy, czy poprzestać na odesłaniu tekstowym w R8 bez wymuszania zależności. Rekomendacja: potraktować jako **opcjonalny krok**, nie blokujący R5/R8 — oba mogą działać bez niego (R8 ma już wbudowany fallback "no problem-classifier" — patrz Phase 1: *"consider ... if the problem class is unclear"*, sformułowanie miękkie, nie wymagane).

**Istniejące komponenty do reużycia**: `week8/3/problem-classifier/SKILL.md` — gotowy do kopiowania 1:1, tym samym wzorcem co R4/R6/R7 (jednoplikowy, bez subagentów).

**Pliki/komponenty do modyfikacji**: `week8/3/problem-classifier/SKILL.md` → w kopii poprawić nic (plik jest wewnętrznie spójny) — poprawka niezgodności nazw następuje w R8, nie tutaj.

**Pliki/komponenty do utworzenia** (jeśli użytkownik zaakceptuje migrację): `.claude/skills/problem-classifier/SKILL.md`.

**Zależności między wymaganiami**: Miękka zależność wejściowa dla R8 (aggregate-designer Phase 1) i pośrednio dla R6/R7 (RC vs accounting/pricing rozróżnienie).

**Zadania implementacyjne** (warunkowe, wymaga potwierdzenia użytkownika):
1. Potwierdzić z użytkownikiem, czy migracja `problem-classifier` wchodzi w zakres tej pracy (formalnie jest poza `week7/`).
2. Jeśli tak: skopiować 1:1, dostosować `name:` wg T0.
3. Zaktualizować R8 (`aggregate-designer`), by referencja do nazwy klasyfikatora była spójna z faktyczną nazwą pliku.

**Edge case'y i niejednoznaczności**: Główna niejednoznaczność to sam zakres (czy w ogóle robić) — patrz wyżej. Druga: `problem-classifier` sam odsyła na końcu do `maister:aggregate-designer` — więc istnieje wzajemna zależność cykliczna na poziomie UX (klasyfikator → agregat, agregat → klasyfikator w razie niepewności), co jest zamierzone i poprawne (dwa wejścia do tego samego procesu decyzyjnego), nie błąd projektowy.

**Strategia testowania/weryfikacji**: Jeśli migrowany — test na przykładzie z `week8/1/historia-agnieszki-2.md` lub podobnym scenariuszu z resource contention (np. `historia-seby.md` — blokady VIP na szkolenia to klasyczny przykład RC) — sprawdzić czy klasyfikator poprawnie identyfikuje Resource Contention i oferuje przejście do `aggregate-designer`.

**Kryteria akceptacji**: Jeśli migrowany — nazwa w `name:` frontmatter jest identyczna z tą używaną w referencjach `aggregate-designer` (R8).

**Metoda weryfikacji**: Manualny test klasyfikacji na scenariuszu blokad VIP z `historia-seby.md`.

---

## R8 — Skill `aggregate-designer` (moduł 6)

**Opis wymagania**: Interaktywny, wieloetapowy wizard (10 faz + 3 fazy opcjonalne) do projektowania jednostek spójności (agregatów DDD jako "locking units"): Fit Check (odróżnia resource contention od CRUD), Extract Commands, Pairwise Conflict Analysis (macierz konfliktów, w tym wykrywanie "time-range conflict trap" z drzewem decyzyjnym niskiego/średniego/wysokiego wolumenu), Business Process Sequencing Probe, Frequency/Volume Probe, Data Scope per Command, Boundary Decision (inclusions/exclusions, "process aggregate" option), Locking Strategy (optimistic/pessimistic/compensating decision matrix), Final Model (boundary diagram ASCII + detailed model). Fazy opcjonalne: Locking Mechanics, Persistence Hints, Testing Strategy.

**Obecny stan projektu**: **Not satisfied**. Brak odpowiednika w `.claude/skills/` ani w pluginie maister.

**Proponowane podejście techniczne**: Kopiowanie 1:1 — jednoplikowy skill, bez subagentów (cała logika to seria `AskUserQuestion` wewnątrz jednego wykonania skilla — silny kandydat na prosty, niskiego ryzyka artefakt jak R4/R6/R7).
- Poprawić odwołanie do klasyfikatora problemu w Phase 1 (`maister:problem-class-classifier` → nazwa zgodna z decyzją w R9, domyślnie `maister:problem-classifier` / `problem-classifier` zależnie od T0).

**Istniejące komponenty do reużycia**: Opcjonalnie R9 (`problem-classifier`) jako miękka zależność wejściowa. Opcjonalnie R4 (`context-distiller`) — Notes sekcja przykładu w R4 explicite sugeruje: *"Consider applying `aggregate-designer` for the enrollment aggregate"* — potwierdza naturalny przepływ context-distiller → aggregate-designer.

**Pliki/komponenty do modyfikacji**: Brak istniejących w tym repo.

**Pliki/komponenty do utworzenia**: `.claude/skills/aggregate-designer/SKILL.md`.

**Zależności między wymaganiami**: Miękka zależność na R9 (problem-classifier, opcjonalny fallback). Naturalny downstream od R4 (context-distiller) i R6 (accounting-archetype-mapper — jego przykład CO₂ Notes też sugeruje aggregate-designer dla enrollment-style agregatów, choć to nie jest w źródle R6, tylko analogia domenowa z przykładu w R4).

**Zadania implementacyjne**:
1. T0: potwierdzić lokalizację.
2. Skopiować `SKILL.md` 1:1.
3. Poprawić nazwę referencji do problem-classifier zgodnie z decyzją R9 (lub zostawić z komentarzem "TBD — problem-classifier nie zmigrowany w tej fazie" jeśli R9 odrzucony).
4. Test na scenariuszu `historia-seby.md` (blokady VIP + warunkowe zwiększanie miejsc + zależność od sprzętu) — kanoniczny przykład RC z całego week7, używany konsekwentnie w modułach 2 i 4.

**Edge case'y i niejednoznaczności**:
- Time-range conflict trap (Phase 3) to najbardziej subtelna, wysoko wartościowa część tego skilla — wymaga szczególnej uwagi przy testowaniu, bo to jedyna część z wbudowanym drzewem decyzyjnym opartym na PostgreSQL-specific rekomendacji (`EXCLUDE USING gist`) — warto potwierdzić zgodność z `.maister/docs/project/tech-stack.md` (projekt aj używa PostgreSQL — **zgodne**, rekomendacja ma pełne zastosowanie).
- Aggregate-designer zakłada, że użytkownik może odpowiadać na wiele rund `AskUserQuestion` — dla scenariusza testowego trzeba przygotować z góry zestaw odpowiedzi (np. bazując na `historia-seby.md`: sala/trener/sprzęt = zasoby RC, handlowiec/organizator = aktorzy, wolumen niski-średni dla firmy szkoleniowej).

**Strategia testowania/weryfikacji**:
1. Uruchomić na opisie z `historia-seby.md` (system zapisów na szkolenia).
2. Przejść przez Phase 1 (Fit Check) — potwierdzić klasyfikację jako resource contention (blokady VIP + limity miejsc).
3. Przejść przez Phase 2 (Extract Commands) — oczekiwane komendy: blockSlot/reserveSlot, holdForVIP, adjustCapacity, disableResource (sprzęt uszkodzony).
4. Przejść przez Phase 3 (Conflict Matrix) — potwierdzić wykrycie self-conflict na "block slot" i parameter-dependent conflict.
5. Dojść do Phase 9 (Final Model) — porównać wynikowy boundary diagram jakościowo z modelem `SlotClaim`/`Pula Pojemności` z `uogolnienie-ze-sprawdzeniem.md` (moduł 4) — sprawdzić spójność między metodologiami (context-distiller identyfikuje "Pula Pojemności" jako generalized context, aggregate-designer powinien dojść do analogicznej granicy jako consistency unit).

**Kryteria akceptacji**:
- Fit Check poprawnie odróżnia RC od CRUD na testowym scenariuszu.
- Conflict Matrix wykrywa self-conflict i flaguje time-range trap jeśli zastosowane komendy używają zakresów czasowych.
- Final Model zawiera boundary diagram + detailed model zgodnie z Output Format źródła.
- Locking Strategy recommendation jest uzasadniona wolumenem z Phase 5.

**Metoda weryfikacji**: Pełny manualny przebieg wizarda na scenariuszu `historia-seby.md`, code review wynikowego modelu względem struktury z Phase 9 źródła + jakościowe porównanie z modułem 4 (spójność granic modułów między dwiema metodologiami).

---

## Traceability Matrix (skrót)

| Wymaganie | Plik źródłowy (week7) | Plik docelowy (proponowany) | Zależności | Test | Kryterium akceptacji (skrót) |
|---|---|---|---|---|---|
| R1 | `2-research-demo/*.md` | (wchodzi w R2 references) | R2 | Code review sekcji | Anti-pattern sekcja obecna |
| R2 | `3-research-gatherer-demo/research-gatherer-standalone/**` | `.claude/skills/research-gatherer/**`, `.claude/agents/{research-planner,information-gatherer-lite}.md`, `.claude/commands/research-gather.md` | T0, T1, (R3 satisfied) | Odtworzenie FitBox scenario | Wszystkie pliki wyjściowe + struktura sekcji |
| R3 | `orchestrator-framework/references/orchestrator-patterns.md` | już satisfied (`maister:orchestrator-framework`) | — | — | — |
| R4 | `4-uogolnienie-demo/context-distiller/SKILL.md` | `.claude/skills/context-distiller/SKILL.md` | — | Test na `analiza-encji-modulow.md` vs `uogolnienie-ze-sprawdzeniem.md` | Wszystkie sekcje Output Format obecne |
| R5 | `5-znanewzorce-demo/archetype-scanner/SKILL.md` | `.claude/skills/archetype-scanner/SKILL.md` + 2 companion agents | R6, R7 | 3 scenariusze (neg/pos-single/pos-double) | `summary.md` kompletny, równoległe uruchomienie |
| R6 | `5-znanewzorce-demo/accounting-archetype-mapper/SKILL.md` | `.claude/skills/accounting-archetype-mapper/SKILL.md` | — | Odtworzenie `demo-accounting-co2.md` | Fit test + Decision Sanity Check |
| R7 | `5-znanewzorce-demo/pricing-archetype-mapper/SKILL.md` | `.claude/skills/pricing-archetype-mapper/SKILL.md` | — | EV charging example + footprint calc porównanie z `week9/AJ-dotnet` | Complexity level uzasadniony, pure Calculators |
| R8 | `6-jednostkispojnosci-demo/aggregate-designer/SKILL.md` | `.claude/skills/aggregate-designer/SKILL.md` | R9 (miękka) | Pełny przebieg na `historia-seby.md` | Boundary diagram + detailed model kompletne |
| R9 | `week8/3/problem-classifier/SKILL.md` (poza week7, opcjonalne) | `.claude/skills/problem-classifier/SKILL.md` | — | Klasyfikacja blokad VIP jako RC | Nazwa spójna z referencjami w R8 |

---

## Otwarte pytania do użytkownika przed rozpoczęciem implementacji

1. **T0**: Potwierdzone: `plugins/` w tym repo to wtyczki frontendowe platformy aj (TS/React), NIE źródła pluginu maister — plugin maister nie jest edytowalny z poziomu tego repo. Domyślna rekomendacja to lokalizacja `.claude/skills/`. Czy użytkownik akceptuje tę rekomendację, czy ma dostęp do osobnego repozytorium źródeł pluginu maister, do którego te skille powinny trafić zamiast tego?
2. Czy `research-gatherer` (R2) powinien dostać **nowych, dedykowanych** subagentów lite, czy powinien reużywać istniejących `maister:research-planner`/`maister:information-gatherer` kosztem utraty uproszczonej klasyfikacji i Declarative Conclusions/Rejected Information tracking?
3. Czy migracja `problem-classifier` (R9, `week8/3/`) wchodzi w zakres tej pracy, mimo że formalnie leży poza `week7/`?
4. Czy `party-archetype-mapper` (wspomniany tylko przez demo `demo-party-miro.md`, bez istniejącego SKILL.md) powinien zostać zbudowany jako nowy, czwarty skill archetypu w ramach tej pracy, czy pozostać poza zakresem (rekomendacja: poza zakresem, brak SKILL.md źródłowego w week7 do migracji)?
