## Purpose

Rozpoznaje wymagania domenowe dotyczące akumulacji/konsumpcji dowolnej wartości i transformuje je w model księgowy (konta, transakcje, ważność, alokacja, storna).

## ADDED Requirements

### Requirement: Fit test przed modelowaniem
Skill SHALL zweryfikować, czy wymaganie pasuje do archetypu accounting (pytanie "ile X ma S, z historią transakcji") zanim przejdzie do modelowania, i SHALL odrzucić wymagania będące w istocie maszyną stanów ("w jakim stanie jest X").

#### Scenario: Wymaganie to state machine, nie accounting
- **WHEN** wymaganie opisuje przejścia jednostki między dyskretnymi stanami bez akumulowanej wartości liczbowej
- **THEN** skill zwraca `fit: false` i wskazuje state machine jako właściwszy archetyp

#### Scenario: Wymaganie pasuje do accounting
- **WHEN** wymaganie opisuje akumulację lub konsumpcję mierzalnej wartości (pieniądze, punkty, uprawnienia) z potrzebą odpytania stanu i historii
- **THEN** skill zwraca `fit: true` i przechodzi do etapu modelowania

### Requirement: Model wynikowy zawiera pełny zestaw elementów księgowych
Skill SHALL wygenerować model zawierający: konta (accounts), typy transakcji, zasadę podwójnego zapisu, reguły ważności/wygasania, strategię alokacji oraz reguły stornowania.

#### Scenario: Model kompletny po zakończeniu wizarda
- **WHEN** użytkownik zakończył proces doprecyzowywania wymagań
- **THEN** wynikowy model zawiera niepuste sekcje Accounts, Transactions & Entries, Validity Rules, Allocation Strategy, Reversal Rules oraz Unmapped Concepts (nawet jeśli pusta, z jawnym komunikatem "None identified")

### Requirement: Decision Sanity Check dla decyzji o wysokim wpływie biznesowym
Skill SHALL oznaczać każdą decyzję modelową etykietą (R) requirement-derived, (A) assumption lub (X) high-impact-guess, i SHALL zadać pytanie doprecyzowujące zamiast milczącego założenia dla każdej decyzji oznaczonej (X) o wysokim wpływie biznesowym.

#### Scenario: Decyzja wysokiego ryzyka bez jednoznacznych danych wejściowych
- **WHEN** skill musi podjąć decyzję modelową (np. strategię alokacji) bez jednoznacznego wsparcia w danych wejściowych
- **THEN** skill oznacza decyzję jako (X) i zadaje pytanie doprecyzowujące użytkownikowi zamiast przyjmować milczące założenie
