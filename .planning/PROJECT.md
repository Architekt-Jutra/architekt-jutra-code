# Migracja metodologii week7 do skilli Claude Code

## What This Is

Repozytorium platformy **aj** (Spring Boot 4 / Java 25 monolit z pluginami, React frontend) zawiera w `week7/` materiały kursowe demonstrujące pięć metodologii modelowania domenowego i researchu (scoping researchu, `research-gatherer`, `context-distiller`, mapowanie archetypów `accounting`/`pricing` + orkiestrator `archetype-scanner`, `aggregate-designer`). Ten projekt GSD migruje te metodologie do trwałych, wielokrotnego użytku skilli Claude Code w `.claude/skills/`, gotowych do wykorzystania przy dalszym rozwoju platformy aj. `week7/` pozostaje read-only źródłem — nic w nim się nie zmienia.

## Core Value

Sześć metodologii z `week7` istnieje jako działające skille w `.claude/skills/` tego repo, wywoływalne przez `Skill`/`Agent` tool, bez modyfikacji kodu aplikacji aj.

## Requirements

### Validated

- ✓ Warstwowy monolit Spring Boot (Controller → Service → Repository/jOOQ) z domenami category/product/user/footprint/archetype-pricing — istniejący, produkcyjny
- ✓ Framework pluginów (`core/plugin/`) — rejestr, sandboxed iframes, `postMessage` SDK, generyczne rozszerzanie encji przez `PluginObject`
- ✓ Kompozytowy model cenowy (`archetype/pricing/`) — Component/CompositeComponent/SimpleComponent, wersjonowanie, Validity/Applicability — **już realna implementacja tego samego wzorca co `pricing-archetype-mapper` z week7**, niezależnie zbudowana w Javie
- ✓ OAuth2 Authorization Server + JWT, centralna `SecurityFilterChain`
- ✓ `.planning/codebase/` — kompletna mapa kodu (STACK/ARCHITECTURE/STRUCTURE/CONVENTIONS/TESTING/INTEGRATIONS/CONCERNS)

### Active

- [ ] `context-distiller` (moduł 4) — skill analizy dwukierunkowej (ambiguity/generalizacja) w `.claude/skills/`
- [ ] `accounting-archetype-mapper` (moduł 5) — skill mapowania wymagań akumulacji wartości na model księgowy
- [ ] `pricing-archetype-mapper` (moduł 5) — skill mapowania wymagań cenowych na drzewo komponentów kalkulacyjnych
- [ ] `archetype-scanner` (moduł 5) — orkiestrator równoległy nad zarejestrowanymi archetype-mapperami + 2 companion agenty
- [ ] `aggregate-designer` (moduł 6) — interaktywny wizard projektowania jednostek spójności (agregatów DDD)
- [ ] `research-gatherer` (moduł 3) — lekki workflow zbierania/weryfikacji informacji bez wymuszonej syntezy + 2 subagenty + command

### Out of Scope

- Migracja `problem-classifier` (`week8/3/`) — formalnie poza `week7/`, opcjonalna miękka zależność `aggregate-designer`; świadomie odłożona na później (decyzja użytkownika)
- Skille jako część pluginu `maister` (`maister:xxx`) — `plugins/` w tym repo to frontend platformy aj (TS/React), nie źródła pluginu maister; plugin maister nie jest edytowalny z poziomu tego repo
- Budowa `party-archetype-mapper` — wspomniany tylko w demo (`demo-party-miro.md`), brak źródłowego `SKILL.md` w week7
- Jakakolwiek zmiana kodu aplikacji aj (Java/Spring, React, pluginy TS) — to zadanie dotyczy wyłącznie narzędzi Claude Code, nie funkcjonalności platformy

## Context

- Platforma aj jest znacznie dalej niż sugerowała nieaktualna `.maister/docs/project/architecture.md` (opisująca "pre-alpha scaffolding") — realna mapa kodu (`.planning/codebase/ARCHITECTURE.md`) pokazuje działający monolit z pluginami, OAuth2, jOOQ+JPA, 11 changesetów Liquibase.
- Istnieje druga, niezależna implementacja pokrewnej domeny (carbon footprint / Component Tree) w `week9/AJ-dotnet/` (.NET, plugin Noesis SDLC) — traktowana jako spike/eksploracja, nie produkcyjny komponent (patrz `.planning/codebase/ARCHITECTURE.md` sekcja Anti-Patterns).
- Pełna analiza wymagań week7 (statusy, ryzyka, decyzje projektowe D1-D5, traceability) już wykonana i zapisana w `week9/openspec/plan.md` (OpenSpec change `week7-plan`) — ten projekt GSD ją reużywa jako materiał wejściowy zamiast powtarzać research.
- `week8/3/problem-classifier/SKILL.md` istnieje jako pokrewny skill (nazewnictwo niespójne z odwołaniem w `aggregate-designer`: `maister:problem-classifier` vs `maister:problem-class-classifier`) — świadomie poza zakresem tego milestone'u.

## Constraints

- **Read-only źródło**: `week7/` nie może być modyfikowany, przenoszony ani usuwany w żadnym kroku tego projektu.
- **Brak zmian w kodzie aplikacji**: żadna faza nie dotyka `src/main/java`, `src/main/frontend`, `plugins/*`, `mcp-server/*` — to praca czysto narzędziowa (skille Claude Code).
- **Lokalizacja skilli**: `.claude/skills/` bez prefiksu `maister:` (plugin maister niedostępny do edycji z tego repo) — decyzja potwierdzona przez użytkownika.
- **Pierwszy precedens subagentów**: repo nie ma dziś `.claude/agents/` ani `.claude/commands/` poza `.claude/commands/opsx/*` — `research-gatherer` i `archetype-scanner` wprowadzą pierwsze subagenty/companion agenty w tym repo.
- **Testowanie manualne**: interaktywne wizardy (`aggregate-designer`, mappery) opierają się na wielorundowym `AskUserQuestion` — brak infrastruktury do automatycznych testów headless dla tej klasy skilli.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Lokalizacja = `.claude/skills/` lokalnie, bez `maister:` prefixu | Plugin maister niedostępny do edycji z tego repo (`plugins/` to frontend aj) | — Pending |
| `problem-classifier` (week8) poza zakresem | Formalnie poza `week7/`, opcjonalna miękka zależność | — Pending |
| `research-gatherer` dostaje dedykowane, nowe lite-agenty (nie reużywa `maister:research-planner`) | Unika regresji we współdzielonym komponencie maister, zachowuje unikalne cechy (Declarative Conclusions, Rejected Information tracking) | — Pending |
| `archetype-scanner` woła mappery przez companion agents, nie bezpośrednio jako `subagent_type` | Rozwiązuje wewnętrzną sprzeczność źródła week7 (moduł 3 zabrania Task tool dla skilli) | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-08-16 after initialization*
