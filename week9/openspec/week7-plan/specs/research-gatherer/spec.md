## Purpose

Zbiera i krzyżowo weryfikuje informacje z wielu źródeł wewnętrznych i zewnętrznych bez wymuszonej syntezy, z jawnym śledzeniem odrzuconych informacji i mapowaniem aktorów.

## ADDED Requirements

### Requirement: Klasyfikacja typu źródeł przed zbieraniem
Skill SHALL sklasyfikować pytanie badawcze jako internal, external lub mixed przed uruchomieniem zbierania, stosując self-check przed ostatecznym przypisaniem klasy.

#### Scenario: Pytanie łączy źródło wewnętrzne i zewnętrzne
- **WHEN** pytanie badawcze wymaga zarówno wewnętrznej transkrypcji/danych jak i zewnętrznych praktyk branżowych
- **THEN** skill klasyfikuje zapytanie jako `mixed` i planuje zbieranie z obu kategorii źródeł

### Requirement: Zasady scopingu researchu
Skill SHALL wymagać ekstrakcji zakresu (co jest w zakresie / poza zakresem), kryteriów odrzucenia oraz wykrycia aktorów przed rozpoczęciem zbierania informacji, i SHALL odrzucić przejście do zbierania bez tych elementów.

#### Scenario: Brak kryteriów odrzucenia w celu researchu
- **WHEN** sformułowany cel researchu jest szeroki i nie zawiera kryteriów odrzucenia informacji spoza zakresu
- **THEN** skill zatrzymuje się i wymaga doprecyzowania zakresu przed przejściem do fazy zbierania, aby uniknąć information overload

### Requirement: Deklaratywne wnioski z filtrem wpływu analitycznego
Skill SHALL tagować w zebranych informacjach tylko twierdzenia, które mogłyby zniekształcić wniosek analityczny (Declarative Conclusions), pomijając twierdzenia bez wpływu na analizę (np. przechwałki marketingowe).

#### Scenario: Źródło zawiera twierdzenie marketingowe bez wpływu na analizę
- **WHEN** zebrane źródło zawiera twierdzenie niepowiązane z pytaniem badawczym (np. ogólna przechwałka firmy)
- **THEN** skill nie oznacza go jako Declarative Conclusion

#### Scenario: Źródło zawiera twierdzenie mogące zniekształcić wniosek
- **WHEN** zebrane źródło zawiera niepotwierdzone twierdzenie bezpośrednio wpływające na odpowiedź na pytanie badawcze
- **THEN** skill oznacza je jako Declarative Conclusion wymagającą jawnego zaufania lub weryfikacji

### Requirement: Śledzenie odrzuconych informacji
Skill SHALL prowadzić rejestr odrzuconych informacji z powodem odrzucenia i warunkiem ponownego włączenia ("Re-include If"), nawet gdy żadna informacja nie została odrzucona.

#### Scenario: Brak odrzuconych informacji w danym przebiegu
- **WHEN** żadna zebrana informacja nie została odrzucona jako poza zakresem
- **THEN** plik rejestru odrzuceń nadal istnieje, z jawnym komunikatem o braku odrzuceń

### Requirement: Zbieranie bez wymuszonej syntezy
Skill SHALL zwrócić zweryfikowane, krzyżowo potwierdzone dane źródłowe jako wynik końcowy, bez tworzenia zsyntetyzowanego raportu narracyjnego (w odróżnieniu od pełnego workflow researchu z syntezą).

#### Scenario: Użytkownik oczekuje surowych, zweryfikowanych danych
- **WHEN** użytkownik uruchamia `research-gatherer` zamiast pełnego workflow research z syntezą
- **THEN** wynikiem jest zestaw zweryfikowanych ustaleń per źródło, nie jeden zsyntetyzowany wniosek narracyjny
