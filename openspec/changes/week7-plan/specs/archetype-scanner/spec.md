## Purpose

Orkiestruje równoległe uruchomienie wszystkich zarejestrowanych archetype mapperów na tych samych wymaganiach domenowych i scala wyniki w jeden raport fit/no-fit.

## ADDED Requirements

### Requirement: Równoległe uruchomienie zarejestrowanych mapperów
Skill SHALL uruchomić wszystkie mappery z rejestru archetypów równolegle (w jednej wiadomości/turze), nie sekwencyjnie, przekazując im te same wymagania wejściowe.

#### Scenario: Rejestr zawiera dwa mappery
- **WHEN** użytkownik dostarcza wymagania domenowe do skanowania
- **THEN** oba zarejestrowane mappery (accounting, pricing) są wywołane w tej samej turze, a nie jeden po drugim

### Requirement: Raport scalający wyniki wszystkich mapperów
Skill SHALL wygenerować `summary.md` zawierający Quick View, Matched Archetypes, Domain Concept Distribution (z overlaps i gaps), oraz Archetype Rejection Reasons dla każdego mappera, który zwrócił `fit: false`.

#### Scenario: Żaden archetyp nie pasuje
- **WHEN** wszystkie mappery zwracają `fit: false`
- **THEN** `summary.md` zawiera pustą sekcję Matched Archetypes i kompletną sekcję Gaps wyjaśniającą, dlaczego żaden archetyp nie pasował

#### Scenario: Dwa archetypy pasują z overlapem konceptów
- **WHEN** wymagania wejściowe zawierają sygnały pasujące jednocześnie do accounting i pricing (np. limit uprawnień + zmienna cena za przekroczenie)
- **THEN** `summary.md` pokazuje oba archetypy jako `fit: true` i jawnie odnotowuje overlap w Domain Concept Distribution

### Requirement: Obsługa błędów pojedynczego mappera
Skill SHALL kontynuować scalanie wyników pozostałych mapperów, jeśli pojedynczy mapper zwróci błąd lub przekroczy limit czasu, i SHALL odnotować ten fakt w raporcie.

#### Scenario: Jeden z mapperów przekracza limit czasu
- **WHEN** jeden z uruchomionych mapperów nie odpowiada w oczekiwanym czasie
- **THEN** skill nie przerywa całego procesu, kończy scalanie z pozostałymi wynikami i oznacza brakujący wynik jako "timeout" w raporcie
