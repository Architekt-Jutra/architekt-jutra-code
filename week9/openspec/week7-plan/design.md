## Context

Sześć nowych skilli Claude Code migrowanych z `week7/` (read-only, kopiowane, nigdy edytowane w miejscu). Repo nie ma dziś `.claude/agents/` ani `.claude/commands/` poza `.claude/commands/opsx/*` — dwa z sześciu skilli (`research-gatherer`, `archetype-scanner`) wymagają subagentów, co jest pierwszym takim precedensem w tym repo. Plugin `maister` jest zainstalowany w środowisku i dostarcza pokrewne, ale niezależne komponenty (`maister:orchestrator-framework`, `maister:research-planner`, `maister:information-gatherer`, `maister:research-synthesizer`) — jego kod źródłowy nie jest edytowalny z tego repo (`plugins/` w repo to frontend platformy `aj`, TS/React, niepowiązany z maister). Pełne uzasadnienie merytoryczne, statusy i ryzyka per wymaganie: `week9/openspec/plan.md`.

## Goals / Non-Goals

**Goals:**
- Umieścić wszystkie sześć skilli jako działające, samodzielne artefakty w `.claude/skills/` tego repo, wywoływalne przez `Skill` tool.
- Zachować zależności między nimi (archetype-scanner ← accounting/pricing-mapper; aggregate-designer ← opcjonalnie problem-classifier) bez wymuszania cyklicznych blokad.
- Nie modyfikować `week7/`, nie tworzyć w nim plików.
- Nie zmieniać zachowania istniejącego pluginu `maister` ani jego współdzielonych agentów.

**Non-Goals:**
- Migracja `problem-classifier` (`week8/3/`) — poza `week7/`, wymaga osobnej decyzji użytkownika (patrz Open Questions).
- Budowa `party-archetype-mapper` — brak źródłowego `SKILL.md` w `week7/`, tylko demo.
- Umieszczenie skilli jako część pluginu `maister` (`maister:xxx`) — niedostępne z tego repo bez osobnego dostępu do repozytorium pluginu.
- Automatyzacja end-to-end testów interaktywnych wizardów (`aggregate-designer`, mappery) — te skille opierają się na wielu rundach `AskUserQuestion` i są weryfikowane manualnie.

## Decisions

### D1: Lokalizacja docelowa = `.claude/skills/` lokalnie, bez prefiksu `maister:`
Alternatywa (umieścić jako skille pluginu `maister`) odrzucona, bo `plugins/` w tym repo nie zawiera kodu maister — plugin jest zainstalowany zewnętrznie i niedostępny do edycji stąd. Lokalne skille podążają za już istniejącym wzorcem `.claude/skills/aj-kg-query`, `.claude/skills/openspec-*` (jednoplikowe, frontmatter `name`/`description` bez prefiksu). **To założenie robocze** — patrz Open Questions, wymaga jawnego potwierdzenia użytkownika przed T1.

### D2: `research-gatherer` dostaje dedykowane, nowe lite-agenty (nie reużywa `maister:research-planner`/`information-gatherer`)
Alternatywa (reużyć istniejących agentów maister w trybie uproszczonym) odrzucona: zmieniałaby współdzielony komponent używany przez `maister:research`, ryzykując regresję w niepowiązanym workflow, i traciłaby unikalne cechy `research-gatherer` (Declarative Conclusions + Analytical Impact Filter, Rejected Information tracking z "Re-include If"), które nie istnieją w wersji maister. Nowe, dedykowane agenty (`.claude/agents/research-planner.md`, `.claude/agents/information-gatherer-lite.md`) kopiują logikę 1:1 z `week7/3-research-gatherer-demo/research-gatherer-standalone/agents/`.

### D3: `orchestrator-framework` nie jest kopiowany — `research-gatherer` używa uproszczonego, płaskiego przebiegu 3 faz
Zamiast kopiować `orchestrator-patterns.md` (który zakłada `TaskCreate`/`TaskUpdate`/`orchestrator-state.yml` — infrastruktura state-trackingu nieobecna w prostych skillach tego repo), `research-gatherer` implementuje swoje 3 fazy (Initialize → Plan & Gather → Merge & Verify) bezpośrednio w `SKILL.md`, zachowując tylko potrzebne zasady delegacji (Skill tool dla skilli, Task tool dla agentów) jako inline instrukcję. Katalog zadań pozostaje zgodny z istniejącym wzorcem `.maister/tasks/research/YYYY-MM-DD-task-name/`.

### D4: `archetype-scanner` woła mappery przez companion agents, nie bezpośrednio jako `subagent_type`
Źródło (`week7`) ma wewnętrzną sprzeczność: moduł 3 zabrania wywoływania skilli przez Task tool (`subagent_type`), a `archetype-scanner` (moduł 5) zakłada właśnie to dla `accounting`/`pricing`-archetype-mapper. Rozwiązanie: dwa cienkie companion agenty (`.claude/agents/accounting-archetype-mapper.md`, `.claude/agents/pricing-archetype-mapper.md`), każdy z frontmatterem `skills: [<nazwa-skilla>]`, preloadujące odpowiedni skill i wywoływane przez `Agent` tool. Wzorzec zaczerpnięty z `orchestrator-patterns.md` (`docs-operator` companion pattern) — stosowalny tu, bo żaden z dwóch mapperów nie spawnuje własnych subagentów.

### D5: Rejestr archetypów w `archetype-scanner` ogranicza się do 2 wpisów (accounting, pricing)
Martwe odwołanie do `party.md` w strukturze katalogu wyjściowego źródłowego `SKILL.md` jest usuwane/komentowane przy kopiowaniu — nie ma w `week7` gotowego `party-archetype-mapper` do zarejestrowania (zgodnie z Non-Goals).

## Risks / Trade-offs

- **[Ryzyko]** Companion-agent pattern (D4) dla `accounting`/`pricing`-archetype-mapper nie jest jeszcze zweryfikowany w praktyce w tym repo (pierwszy przypadek użycia) → **[Mitygacja]** zbudować i przetestować `archetype-scanner` jako ostatni z trójki R6/R7/R5, z jawnym testem, że `Agent` tool poprawnie preloaduje skill przez `skills:` frontmatter przed pełną migracją.
- **[Ryzyko]** Brak `.claude/agents/` jako precedensu w repo — konwencja nazewnictwa/struktury plików agentów nieustalona → **[Mitygacja]** wzorować się na strukturze `agents/*.md` z `week7/3-research-gatherer-demo/research-gatherer-standalone/agents/` (już ma frontmatter zgodny z formatem Claude Code) i zweryfikować zgodność z realnym Agent tool przed uznaniem R2/R5 za ukończone.
- **[Ryzyko]** `aggregate-designer` odwołuje się do `maister:problem-class-classifier`, nazwa niezgodna z istniejącym `week8/3/problem-classifier` (`maister:problem-classifier`) → **[Mitygacja]** przy kopiowaniu `aggregate-designer` (R8) zaktualizować odwołanie na neutralną, nie-maister nazwę zgodną z D1 (np. `problem-classifier`) lub zostawić komentarz "TBD — brak zmigrowanego klasyfikatora" jeśli R9 odrzucone; to nie blokuje działania skilla (odwołanie jest miękkie, "consider ... if unclear").
- **[Trade-off]** Skille testowane manualnie/jakościowo (nie automatycznymi testami headless), bo cała logika opiera się na wielorundowym `AskUserQuestion` — akceptowalne dla tej klasy narzędzi, spójne z brakiem istniejącej infrastruktury testowej dla skilli w tym repo.

## Migration Plan

Kolejność zgodna z `week9/openspec/plan.md` sekcja "Kolejność globalna implementacji":
1. `context-distiller` (brak zależności, weryfikuje konwencję D1).
2. `accounting-archetype-mapper` i `pricing-archetype-mapper` (równolegle, niezależne).
3. `archetype-scanner` (wymaga 2. ukończonego + 2 companion agentów).
4. `aggregate-designer` (niezależny od 1-3, opcjonalna miękka zależność od nieistniejącego problem-classifier).
5. `research-gatherer` (najbardziej złożony — subagenty + command; wykonywany ostatni, po ustaleniu wzorca subagentów w krokach 3-4).

Rollback: każdy skill to pojedynczy katalog w `.claude/skills/` (+ ewentualne pliki w `.claude/agents/`, `.claude/commands/`) — usunięcie katalogu w pełni cofa migrację danego skilla bez wpływu na pozostałe.

## Open Questions

1. Czy użytkownik akceptuje D1 (lokalizacja `.claude/skills/` bez prefiksu `maister:`), czy ma dostęp do osobnego repozytorium źródeł pluginu maister, do którego te skille powinny trafić zamiast tego?
2. Czy migracja `problem-classifier` (`week8/3/`, poza `week7/`) wchodzi w zakres tej pracy?
