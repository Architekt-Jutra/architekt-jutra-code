## Why

`week7/` demonstruje pięć metodologii modelowania i researchu domenowego (scoping researchu, `research-gatherer`, `context-distiller`, mapowanie archetypów `accounting`/`pricing` + orkiestrator `archetype-scanner`, `aggregate-designer`), ale żadna z nich nie istnieje jako gotowy, wielokrotnego użytku artefakt w tym repozytorium. Bez migracji te metodologie pozostają uwięzione w materiale kursowym i nie są dostępne przy dalszym rozwoju platformy `aj` (obecnie pre-alpha, bez modułów domenowych — patrz `.maister/docs/project/architecture.md`). Pełna analiza źródłowa (status per wymaganie, ryzyka, kolejność) jest udokumentowana w `week9/openspec/plan.md`.

## What Changes

- Dodanie sześciu nowych, samodzielnych skilli Claude Code w `.claude/skills/` (kopiowanych i dostosowanych z `week7/`, `week7/` pozostaje nietknięty):
  - `context-distiller` (moduł 4) — najprostszy, bez zależności, pierwszy do migracji.
  - `accounting-archetype-mapper` i `pricing-archetype-mapper` (moduł 5) — niezależne od siebie.
  - `archetype-scanner` (moduł 5) — orkiestrator równoległy, zależny od dwóch powyższych oraz od dwóch nowych companion-agentów (`.claude/agents/accounting-archetype-mapper.md`, `.claude/agents/pricing-archetype-mapper.md`).
  - `aggregate-designer` (moduł 6) — wizard projektowania jednostek spójności DDD.
  - `research-gatherer` (moduł 3) — najbardziej złożony: wymaga dwóch nowych subagentów (`.claude/agents/research-planner.md`, `.claude/agents/information-gatherer-lite.md`) i commanda `.claude/commands/research-gather.md`; zasady scopingu researchu z modułu 2 są wchłonięte jako sekcja w jego pliku referencyjnym (nie stają się osobnym skillem).
- Wykorzystanie już dostępnego `maister:orchestrator-framework` jako referencji wzorców delegacji, bez kopiowania go do repo.
- **Poza zakresem tej propozycji** (otwarte pytania wymagające decyzji użytkownika przed implementacją, patrz `week9/openspec/plan.md` sekcja "Otwarte pytania"): docelowa lokalizacja (`.claude/skills/` lokalnie vs plugin `maister`), migracja `problem-classifier` (`week8/3/`, poza `week7/`), budowa nienazwanego `party-archetype-mapper`.

## Capabilities

### New Capabilities
- `claude-skills/context-distiller`: analiza dwukierunkowa (niejednoznaczność / generalizacja) konceptów domenowych, produkuje distilled context map.
- `claude-skills/accounting-archetype-mapper`: rozpoznaje i modeluje wymagania akumulacji/konsumpcji wartości jako model księgowy (konta, transakcje, ważność, alokacja).
- `claude-skills/pricing-archetype-mapper`: rozpoznaje i modeluje wymagania obliczanej ceny/stawki jako drzewo komponentów kalkulacyjnych z wersjonowaniem i kontekstową stosowalnością.
- `claude-skills/archetype-scanner`: uruchamia równolegle wszystkie zarejestrowane archetype mappery na tych samych wymaganiach i scala wyniki fit/no-fit w jeden raport.
- `claude-skills/aggregate-designer`: interaktywny wizard projektowania agregatów DDD jako jednostek lockingu (fit check, macierz konfliktów, strategia lockingu, model końcowy).
- `claude-skills/research-gatherer`: lekki, trójfazowy workflow zbierania i krzyżowej weryfikacji informacji z wielu źródeł bez wymuszonej syntezy, z klasyfikacją internal/external/mixed, śledzeniem odrzuconych informacji i mapowaniem aktorów.

### Modified Capabilities
(brak — wszystkie zmiany to nowe, samodzielne capabilities; żadna istniejąca specyfikacja w `openspec/specs/` nie jest modyfikowana)

## Impact

- **Nowe pliki**: `.claude/skills/{context-distiller,accounting-archetype-mapper,pricing-archetype-mapper,archetype-scanner,aggregate-designer,research-gatherer}/SKILL.md` (+ pliki referencyjne), `.claude/agents/{research-planner,information-gatherer-lite,accounting-archetype-mapper,pricing-archetype-mapper}.md`, `.claude/commands/research-gather.md`.
- **Brak zmian w kodzie produkcyjnym** (Java/Spring `aj`, `plugins/*`, `week9/AJ-dotnet`) — to praca czysto narzędziowa/meta (skille Claude Code), nie funkcjonalność aplikacji.
- **`week7/` pozostaje read-only** — źródło do skopiowania, nigdy nie modyfikowane.
- **Zależności międzymodułowe**: `archetype-scanner` blokowany przez `accounting-archetype-mapper` + `pricing-archetype-mapper`; `aggregate-designer` ma miękką (opcjonalną) zależność od nieistniejącego jeszcze `problem-classifier`.
- Pełna traceability wymaganie → rozwiązanie → plik → zadanie → test → kryterium akceptacji: `week9/openspec/plan.md`.
