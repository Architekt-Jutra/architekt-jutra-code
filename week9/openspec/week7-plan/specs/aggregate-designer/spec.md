## Purpose

Prowadzi interaktywny wizard projektowania jednostek spójności (agregatów DDD jako locking units) — od fit checku po finalny model granic i strategii lockingu.

## ADDED Requirements

### Requirement: Fit check odróżniający resource contention od CRUD
Skill SHALL zweryfikować przed rozpoczęciem projektowania, czy dane wejściowe stanowią rzeczywisty problem współbieżnego dostępu do zasobu (resource contention), a nie CRUD lub walidację pojedynczego rekordu.

#### Scenario: Wejście to problem CRUD
- **WHEN** dane sprawdzane przy decyzji "czy operacja jest dozwolona" nie mogą się zmienić w wyniku równoległego żądania
- **THEN** skill zgłasza brak potrzeby agregatu i proponuje alternatywy (unique constraint, walidacja aplikacyjna) zamiast kontynuować projektowanie

#### Scenario: Wejście to resource contention
- **WHEN** wiele równoległych aktorów może w tym samym momencie zmienić dane decydujące o dozwoloności operacji
- **THEN** skill przechodzi do ekstrakcji komend

### Requirement: Macierz konfliktów komend
Skill SHALL zbudować pełną macierz konfliktów par komend (włącznie z self-conflict) i SHALL wykryć przypadek "time-range conflict trap", gdy konflikt zależy od nakładania się zakresów czasowych.

#### Scenario: Komenda konfliktuje sama ze sobą
- **WHEN** dwóch aktorów może jednocześnie wykonać tę samą komendę na tych samych danych, obserwując ten sam stan "przed"
- **THEN** macierz oznacza tę komendę jako konfliktującą samą ze sobą (self-conflict)

#### Scenario: Konflikt zależy od nakładania się zakresów czasowych
- **WHEN** komendy przyjmują jako parametr zakres czasowy, a inwariant dotyczy braku nakładania się zakresów
- **THEN** skill jawnie sygnalizuje time-range conflict trap i prowadzi przez drzewo decyzyjne oparte na wolumenie ruchu

### Requirement: Rekomendacja strategii lockingu na podstawie wolumenu
Skill SHALL rekomendować strategię lockingu (optimistic/pessimistic/compensating) na podstawie profilu wolumenu i struktury konfliktów, z jawnym uzasadnieniem.

#### Scenario: Niski wolumen, akceptowalne retry
- **WHEN** oczekiwany wolumen komend jest niski, a retry jest akceptowalne biznesowo
- **THEN** skill rekomenduje locking optymistyczny (pole wersji) z uzasadnieniem

#### Scenario: Wysoki wolumen, retry niedopuszczalne
- **WHEN** oczekiwany wolumen jest wysoki lub skokowy, a retry jest niedopuszczalne
- **THEN** skill rekomenduje locking pesymistyczny lub podejście kompensacyjne z uzasadnieniem

### Requirement: Finalny model z diagramem granic
Skill SHALL wygenerować finalny model zawierający diagram ASCII granicy agregatu (komendy wewnątrz/na zewnątrz, inwarianty) oraz szczegółowy model (komendy, pola, wykluczenia, strategia lockingu, otwarte decyzje).

#### Scenario: Zakończenie wizarda
- **WHEN** użytkownik potwierdził macierz konfliktów i zakres danych dla każdej komendy
- **THEN** skill prezentuje diagram granic i szczegółowy model z wszystkimi wymaganymi sekcjami przed zakończeniem
