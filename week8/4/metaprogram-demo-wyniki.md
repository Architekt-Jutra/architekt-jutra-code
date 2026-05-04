# Wyniki metaprogram-classifier na transkrypcji TransRoute

Trzy przebiegi skilla na tej samej transkrypcji (metaprogram-demo-review.md).

---

## Przebieg 1: Przemek BEZ kontekstu roli

### Kontekst
- **Sytuacja**: Spotkanie techniczne — review propozycji architektonicznej modułu optymalizacji tras
- **Rola**: Nie podana — analizuję wyłącznie na podstawie tekstu
- **Kontekst emocjonalny**: Brak widocznego stresu; ton jest rzeczowy, techniczny, z nutą asertywności.

### Wykryte Metaprogramy

| Metaprogram | Wykryty biegun | Pewność | Dowody |
|---|---|---|---|
| Sortowanie informacji | **Różnice** | **Wysoka** | Każde wystąpienie to szukanie luk: „skąd te benchmarki? Na jakich danych?", „to nie ma nic wspólnego z naszą topologią Warszawy", „To jest breaking change w API", „Testowaliśmy to?". Żadna wypowiedź nie szuka podobieństwa. |
| Granularność | **Szczegóły** | **Wysoka** | Most Łazienkowski i 40 minut, „posortowana lista punktów vs sekwencja segmentów z estymowanymi czasami", „BI pobiera dane batchowo nocą", „ten sam raport, który idzie do zarządu". Nawet otwierając nowy wątek (rollback), natychmiast wchodzi w szczegóły scenariusza. |
| Źródło autorytetu | **Wewnętrzne** | **Wysoka** | „**Wyślij, sam zobaczę.**" — najsilniejszy marker. „ja bym chciał to zobaczyć zanim cokolwiek wejdzie na produkcję" — osobiste warunkowanie. Nie powołuje się na żadne zewnętrzne źródło. |
| Orientacja | **Unikanie problemów** | **Wysoka** | Każda wypowiedź identyfikuje zagrożenie: corrupted data, breaking change, brak testów, brak rollbacku. „bo jak BI zacznie dostawać corrupted data, to raportowanie kwartalne leci". Zero wypowiedzi o korzyściach nowego algorytmu. |
| Samomotywacja | **Reaktywna** | **Średnia** | Reaguje na propozycję Ewy — nie inicjuje własnej alternatywy. Na końcu milczy. Jednak „I jeszcze jedno" — sam dodaje tematy bez pytania, co osłabia diagnozę reaktywności. |
| Autoperswazja | **Konieczność** | **Średnia** | „ja bym chciał to zobaczyć zanim cokolwiek wejdzie" — warunkowanie przez obowiązek. „Testowaliśmy to?" — implikuje: powinniśmy byli. Brak języka możliwości. |
| Priorytet | **Ja** | **Średnia** | „sam zobaczę", „ja bym chciał", „nie mam pojęcia" — argumenty wokół osobistej potrzeby kontroli. Brak odniesień do potrzeb zespołu czy klientów. |

### Wzorce złożone
- **Różnice + Szczegóły** — szuka różnic w szczegółach implementacyjnych
- **Wewnętrzne odniesienie + Unikanie problemów** — musi osobiście zweryfikować i osobiście zobaczyć zagrożenie
- **Profil zbliżony do heurystycznego wzorca „ekspert techniczny"** — niemal pełne dopasowanie

### Profil komunikacyjny
Przemek przetwarza nowe informacje przez szukanie luk i zagrożeń, potrzebuje osobistej weryfikacji, operuje na konkretnych szczegółach implementacyjnych. Nie oczekuje, że ktoś go przekona — oczekuje, że dostanie materiał do samodzielnej oceny.

### Strategie komunikacji

**Źródło autorytetu (najsilniejszy sygnał)**:
- **Rób**: Daj mu repo, dane, środowisko testowe. Pytaj o jego ocenę.
- **Unikaj**: Nie cytuj autorytetów. Nie mów „zaufaj mi" bez udostępnienia danych.
- **Przykładowe otwarcie**: „Przemku, tu jest repo z benchmarkami na naszych danych Q4. Zerknij i powiedz mi, czy widzisz coś, czego nie widzę."

**Orientacja — Unikanie problemów**:
- **Rób**: Zacznij od ryzyk. Pokaż plan mitygacji.
- **Unikaj**: Nie zaczynaj od korzyści. Nie bagatelizuj obaw.
- **Przykładowe otwarcie**: „Widzę trzy ryzyka, które mogą nas ugryźć. Mam plan mitygacji — chcesz przejść?"

### Uwagi kontekstowe
Kontekst spotkania nie został podany. Gdyby Przemek był w roli formalnego reviewera, część sygnałów (szczególnie Unikanie problemów i Różnice) mogłaby wynikać z roli, nie z bazowych filtrów.

---

## Przebieg 2: Przemek Z kontekstem roli (reviewer)

### Kontekst
- **Sytuacja**: Architektoniczne review propozycji nowego modułu
- **Rola**: Senior backend, 12 lat doświadczenia, **pełni rolę REVIEWERA**
- **Kontekst emocjonalny**: Rzeczowy, techniczny.

**⚠️ Rola reviewera systematycznie wymusza zachowania zbieżne z metaprogramami:** szukanie luk (Różnice), wchodzenie w szczegóły (Szczegóły), identyfikowanie ryzyk (Unikanie problemów), kwestionowanie założeń (Wewnętrzne odniesienie).

### Wykryte Metaprogramy

| Metaprogram | Wykryty biegun | Pewność | Dowody |
|---|---|---|---|
| Sortowanie informacji | **Różnice** | **Średnia** ⬇️ | Te same markery co wyżej — ale reviewer MUSI szukać luk. Pewność obniżona z Wysokiej. |
| Granularność | **Szczegóły** | **Średnia** ⬇️ | Te same markery — ale reviewer architektoniczny MUSI wchodzić w szczegóły kontraktu API. Pewność obniżona z Wysokiej. |
| Źródło autorytetu | **Wewnętrzne** | **Wysoka** ✅ | „Wyślij, sam zobaczę." — tu rola NIE wymusza takiej odpowiedzi. Mógł powiedzieć „OK, skoro testy przeszły, to wierzę". Ten metaprogram jest **najpewniejszy, bo wykracza poza obowiązki roli**. |
| Orientacja | **Unikanie problemów** | **Średnia** ⬇️ | Te same markery — ale reviewer został ZAPROSZONY żeby znaleźć problemy. Pewność obniżona z Wysokiej. |
| Samomotywacja | **Reaktywna** | **Niska** ⬇️ | Reviewer Z DEFINICJI reaguje na cudzy materiał. Pewność obniżona do Niskiej — rola prawie całkowicie maskuje ten metaprogram. |
| Autoperswazja | **Konieczność** | **Średnia** | Tu rola ma mniejszy wpływ — reviewer mógłby powiedzieć „moglibyśmy też rozważyć X", ale tego nie robi. |
| Priorytet | **Ja** | **Średnia** | Reviewer mógłby ramować ryzyka jako „zagrożenie dla zespołu/klientów", ale ramuje jako osobiste warunkowanie. |

### Kluczowa zmiana vs przebieg 1
Jedynym metaprogramem z **wysoką pewnością niezależną od roli** jest **Wewnętrzne odniesienie**. Dla 4 z 7 metaprogramów pewność spadła po dodaniu kontekstu roli.

### Wzorce złożone
Profil powierzchniowo zbliżony do wzorca „ekspert techniczny" — ale z zastrzeżeniem: 4 z 7 metaprogramów mogą być aktywacją roli reviewera, nie bazowymi filtrami.

### Strategie komunikacji
Strategie te same co w przebiegu 1 — „daj mu repo, niech sam sprawdzi" działa niezależnie od tego, czy unikanie problemów to bazowy filtr czy aktywacja kontekstowa. Ale diagnoza jest uczciwa o swoich ograniczeniach.

### Weryfikacja
Potrzebne wypowiedzi Przemka z 2-3 innych kontekstów (planowanie, Slack, 1:1). Jeśli tam też szuka dziur — pewność rośnie. Jeśli tam mówi o korzyściach — orientacja na ryzyka była aktywacją kontekstową.

---

## Przebieg 3a: Bartek (staff engineer, moderator review)

### Kontekst
- **Rola**: Staff engineer, **PROWADZI review** — moderator spotkania.

**⚠️ Rola moderatora maskuje prawie wszystkie metaprogramy.** Moderator MUSI: operować na dużym obrazie, pytać każdego, inicjować i zamykać, nie wyrażać własnej opinii technicznej.

### Wykryte Metaprogramy

| Metaprogram | Wykryty biegun | Pewność | Dowody |
|---|---|---|---|
| Sortowanie | **Niejasne** | — | Nie sortuje — przekazuje głos innym. |
| Granularność | **Duży obraz** (pozornie) | **Niska** ⬇️ | Podsumowuje na wysokim poziomie. ALE: „A przy 20?" — konkretne pytanie liczbowe, którego moderator nie musiał zadać. Może sygnalizować ukrytą orientację na szczegóły. |
| Źródło autorytetu | **Niejasne** | — | Pyta innych, ale to moderator MUSI robić. Brak danych niezależnych od roli. |
| Orientacja | **Niejasne** | **Niska** ⬇️ | Zamyka spotkanie (wygląda jak cel), ale „czy jest opcja na 2-3 klientach?" — to pytanie o mitygację ryzyka. |
| Samomotywacja | **Proaktywna** (pozornie) | **Niska** ⬇️ | Inicjuje i zamyka — ale moderator Z DEFINICJI to robi. |
| Autoperswazja | **Niejasne** | — | Brak markerów konieczności lub możliwości. |
| Priorytet | **Inni** (pozornie) | **Niska** ⬇️ | Pyta każdego po kolei — ale to praca moderatora, nie wybór. |

### Profil komunikacyjny
Bartek jest niemal nieczytelny metaprogramowo. Rola moderatora skutecznie maskuje bazowe filtry. Jedyne potencjalne sygnały bazowych metaprogramów: pytanie „A przy 20?" (szczegóły?) i pytanie o stopniowe wdrożenie (unikanie problemów?).

### Strategie komunikacji
**Brak podstaw do budowania strategii.** Potrzebna analiza komunikacji Bartka z kontekstu, w którym NIE moderuje.

---

## Przebieg 3b: Marta (product owner)

### Kontekst
- **Rola**: Product owner.
- **Kontekst emocjonalny**: Entuzjastyczny — ulga, że temat rusza.

**Rola PO wzmacnia, nie maskuje** — PO ma swobodę w TYM JAK komunikuje, w przeciwieństwie do moderatora i reviewera.

### Wykryte Metaprogramy

| Metaprogram | Wykryty biegun | Pewność | Dowody |
|---|---|---|---|
| Sortowanie | **Niejasne** | — | Nie szuka ani podobieństw, ani różnic. Za mało danych. |
| Granularność | **Duży obraz** | **Średnia** | „żeby kierowcy dostawali trasy w ciągu minuty" — user outcome, nie implementacja. „Kiedy będzie gotowe i czy klienci zobaczą różnicę?" — efekt, nie mechanizm. |
| Źródło autorytetu | **Zewnętrzne** | **Średnia** | „klienci narzekają", „klienci zobaczą różnicę?", „trzech klientów zgodzili się na beta" — klienci jako źródło prawdy. Mogła powiedzieć „Ja uważam, że to ważne" — nie powiedziała. |
| Orientacja | **Dążenie do celu** | **Wysoka** ✅ | „Cieszę się, że w ogóle to ruszamy", „Wreszcie się rusza", „Chcę wiedzieć: kiedy?", „Mogę to zorganizować w tydzień". Zero wypowiedzi o ryzykach. Entuzjazm wykracza poza wymagania roli. |
| Samomotywacja | **Proaktywna** | **Średnia** | „Mogę to zorganizować w tydzień" — natychmiastowa gotowość bez pytania o pozwolenie. Ale tylko dwa zdania. |
| Autoperswazja | **Możliwość** | **Średnia** | „Mogę to zorganizować", „Chcę wiedzieć" — język możliwości. Brak „musimy" ani „powinniśmy". |
| Priorytet | **Inni** | **Wysoka** ✅ | Każda wypowiedź odnosi się do klientów/kierowców. Ani jedno zdanie o osobistym wpływie. |

### Wzorce złożone
**Dążenie do celu + Zewnętrzne odniesienie + Inni** — compound bliski wzorcowi „menedżer". Rola PO pokrywa się z diagnozą — wzmacnia zamiast maskować.

### Strategie komunikacji

**Orientacja — Dążenie do celu (najsilniejszy sygnał)**:
- **Rób**: Zacznij od efektu i timeline'u. Ramuj ryzyka jako zagrożenia dla celu.
- **Unikaj**: Nie zaczynaj od listy ryzyk.
- **Przykładowe otwarcie**: „Marta, mamy ścieżkę do wejścia na produkcję w 6 tygodni. Trzy rzeczy muszą się udać — chcesz przejść szybko?"

**Priorytet — Inni/Klienci**:
- **Rób**: Ramuj wszystko przez perspektywę klienta i kierowcy.
- **Unikaj**: Nie mów w abstrakcjach technicznych. „Breaking change w API" → „kierowcy mogą przez 2 dni dostawać trasy w starym formacie".
- **Przykładowe otwarcie**: „Marta, który z trzech beta klientów ma najwięcej kierowców? Bo tam efekt będzie najbardziej widoczny."

---

## Podsumowanie porównawcze: wpływ kontekstu roli

| Osoba | Rola | Wpływ roli na diagnozę | Metaprogramy z wysoką pewnością |
|---|---|---|---|
| Przemek (bez roli) | Nie podana | Brak korekty | 4 z 7 (Różnice, Szczegóły, Wewnętrzne, Unikanie) |
| Przemek (z rolą) | Reviewer | Obniża pewność 4 z 7 | **1 z 7** (Wewnętrzne odniesienie) |
| Bartek | Moderator | Maskuje prawie wszystko | **0 z 7** |
| Marta | PO | Wzmacnia, nie maskuje | 2 z 7 (Dążenie do celu, Inni) |

**Kluczowa lekcja**: Jedno zdanie kontekstu roli zmienia diagnozę fundamentalnie. Reviewer wygląda jak unikacz problemów. Moderator wygląda jak menedżer big-picture. PO wygląda jak PO — bo rola pokrywa się z filtrami. Skill bez kontekstu roli produkuje pewne diagnozy, które mogą być fałszywe. Skill z kontekstem — produkuje uczciwe diagnozy z odpowiednimi poziomami pewności.