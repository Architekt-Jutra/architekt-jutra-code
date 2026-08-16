## Purpose

Rozpoznaje wymagania z komponentem obliczanej ceny/stawki zależnej od kontekstu i transformuje je w model kalkulacyjny: warstwa kalkulatorów, drzewo komponentów, wersjonowanie i stosowalność kontekstowa.

## ADDED Requirements

### Requirement: Fit test odróżniający pricing od accounting i state machine
Skill SHALL zweryfikować, że wymaganie dotyczy reprodukowalnego, audytowalnego obliczenia ceny zależnej od kontekstu (czas, ilość, segment, kanał), a nie akumulacji wartości (accounting) ani przejść stanu.

#### Scenario: Wymaganie pasuje do pricing
- **WHEN** wymaganie opisuje obliczenie ceny/stawki zależnej od co najmniej jednego wymiaru kontekstu, z wymogiem reprodukowalności historycznej
- **THEN** skill zwraca `fit: true` i przechodzi do modelowania Component Tree

### Requirement: Kalkulatory jako czyste funkcje
Skill SHALL modelować warstwę kalkulatorów jako pure functions, bez warunków logiki biznesowej wewnątrz kalkulatorów — warunki stosowalności SHALL być wydzielone do osobnych komponentów Applicability.

#### Scenario: Wynikowy model zawiera logikę warunkową wewnątrz kalkulatora
- **WHEN** proponowany model umieszcza warunek biznesowy (np. "tylko dla klientów VIP") bezpośrednio w funkcji kalkulatora
- **THEN** skill koryguje model, przenosząc warunek do osobnego komponentu Applicability, zachowując kalkulator jako czystą funkcję

### Requirement: Wersjonowanie i reprodukowalność historyczna
Skill SHALL uwzględnić wersjonowanie komponentów cenowych (`definedAt`/`versionAt`) tak, by cena policzona dla przeszłej daty była reprodukowalna niezależnie od późniejszych zmian algorytmu.

#### Scenario: Zapytanie o cenę z przeszłości po zmianie algorytmu
- **WHEN** algorytm wyceny komponentu zmienił się po dacie, dla której liczona jest cena
- **THEN** model zwraca wersję komponentu obowiązującą w momencie `definedAt` żądanej daty, nie bieżącą wersję

### Requirement: Ocena poziomu złożoności
Skill SHALL przypisać wymaganiu poziom złożoności (skala 1-9) wraz z jawnym uzasadnieniem opartym na dowodach z wymagań wejściowych.

#### Scenario: Poziom złożoności bez uzasadnienia
- **WHEN** skill proponuje poziom złożoności modelu cenowego
- **THEN** uzasadnienie odwołuje się do konkretnych cech wymagania (liczba wymiarów kontekstu, głębokość drzewa komponentów, potrzeba wersjonowania historycznego), nie jest arbitralne
