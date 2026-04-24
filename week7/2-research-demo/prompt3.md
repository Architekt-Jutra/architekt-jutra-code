## Prompt

> Zgłoszony problem brzmiał: „mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność".
> Na początku zacząłem zbierać informacje. Przejrzałem dokumentację, raporty z systemu oraz porozmawiałem z działem obsługi klienta, organizatorami i trenerami. W trakcie rozmów wyszły rzeczy, których nie było w żadnym systemie. Handlowcy blokowali miejsca „na telefon" dla klientów VIP. Organizatorzy czasami zwiększali liczbę miejsc „warunkowo", jeśli widzieli duże zainteresowanie. Dodatkowo pojawił się nowy wątek: szkolenie nie zależało tylko od sali i miejsc, ale też od dostępności sprzętu – np. aparatu do nagrania szkolenia. W jednym przypadku szkolenie zostało odwołane, bo aparat był uszkodzony, mimo że były wolne miejsca i dostępna sala. To była wiedza, której wcześniej nie było nigdzie formalnie zapisana.
> Następnie rozrysowałem proces zapisu na szkolenie, zaznaczyłem hotspoty, opisałem scenariusze w postaci user stories i przygotowałem model: szkolenie, sala, miejsce, rezerwacja, blokada, sprzęt. Stworzyłem też diagram pokazujący zależności między tymi elementami.
> Dopiero po zestawieniu wszystkich elementów zauważyłem, że problem nie dotyczy tylko „miejsc na szkolenie", tylko zarządzania różnymi typami zasobów, które są potrzebne do jego realizacji. Sala, miejsca, sprzęt nagraniowy – wszystkie te elementy podlegały podobnym regułom: mogły być rezerwowane, blokowane, zwalniane albo wyłączane z użycia (np. w przypadku awarii). Uogólniłem to do jednego pojęcia: „zasób", który ma swój stan i podlega alokacji. Dzięki temu architektura była rozszerzalna, przyjmowała w łatwy sposób kolejne typy zasobów. Dzięki temu trenera mogłem potraktować jako … zasób. Pojedyncze źródło prawdy zachować spójność i skalowalność.
> przeanalizuj mi ten problem - rozpoznaj klase problemu modelarskiego (lub klasy) uzywajas skilla problem-class-classifier i wypisz wynik dzialania do pliku szkolenie/2-research/prompt3.md i uwzgledjnij tam w poliku najpierw jaki byl prompt

---

# Klasyfikacja problemu modelarskiego: System zapisów na szkolenia

## Classification: COMPOSITE — Resource Contention (primary) + Integration (secondary) + T&P (komponent)

**Confidence**: Wysoka

### Deduction trail

| # | Pytanie | Odpowiedź | Sygnał / Implikacja |
|---|---------|-----------|---------------------|
| 1 | Czy rezerwacja szkolenia musi zająć wszystkie zasoby jednocześnie (sala + miejsca + sprzęt + trener) atomowo? | Tak — all-or-nothing | Potwierdza Integration: potrzebna saga/process manager koordynujący wiele zasobów |
| 2 | Czy wielu handlowców / organizatorów może jednocześnie próbować zarezerwować te same zasoby? | Tak — to się zdarza | Potwierdza Resource Contention: współbieżny dostęp do tych samych zasobów wymaga ochrony niezmienników |
| 3 | Widok dostępności — tylko odczyt czy przechowuje unikalne dane? | Tylko odczyt | Potwierdza T&P: widok dostępności to projekcja stanu zasobów, nie źródło prawdy |
| 4 | Blokada VIP i warunkowe zwiększanie pojemności — system egzekwuje czy decyzja człowieka? | System egzekwuje | Reguły VIP i pojemności warunkowej to niezmienniki domenowe w agregatach RC |

### Why this class

- **„brakuje fizycznie miejsc, mimo że system pokazuje dostępność"** → klasyczny sygnał RC: stan systemu nie chroni rzeczywistej dostępności pod współbieżnym dostępem
- **„blokowali miejsca na telefon dla klientów VIP"** → rezerwacja/blokada z regułami biznesowymi (limit, timeout) — niezmiennik w agregacie
- **„rezerwowane, blokowane, zwalniane albo wyłączane z użycia"** → operacje zmieniające stan zasobu, które wpływają na to, co system pozwala innym użytkownikom zrobić
- **„szkolenie nie zależało tylko od sali i miejsc, ale też od dostępności sprzętu"** → koordynacja wielu niezależnych zasobów = Integration (all-or-nothing)
- **„system pokazuje dostępność"** → widok dostępności to T&P — projekcja stanu zasobów, odtwarzalna ze źródeł

### What NOT to do

1. **Nie uogólniaj do jednego agregatu „Zasób"** — sala, miejsca, sprzęt i trener mają różne reguły biznesowe (pojemność warunkowa dotyczy miejsc, awaria dotyczy sprzętu, urlop dotyczy trenera). Wspólna abstrakcja albo zgubi reguły, albo rozrośnie się w `if type == ...`, niszcząc sens generalizacji.

2. **Nie rób jednego dużego agregatu „Szkolenie" pilnującego wszystkich zasobów** — to by złamało zasadę: transakcja nie powinna obejmować wielu agregatów. Koordynacja all-or-nothing to zadanie dla sagi/process managera, nie dla jednego agregatu.

3. **Nie traktuj widoku dostępności jako źródła prawdy** — to projekcja (T&P), nie model domenowy.

### Suggested approach

**1. Resource Contention — oddzielne agregaty per typ zasobu:**

Każdy typ zasobu to osobny agregat z własnymi niezmiennikami:
- **Sala** — chroni niezmiennik: „sala nie może być zarezerwowana na nakładające się terminy"
- **Pula miejsc** — chroni niezmiennik: „liczba zarezerwowanych + zablokowanych ≤ pojemność (z uwzględnieniem warunkowego zwiększenia)"
  - Reguła VIP: blokada z limitem i timeout — jawny niezmiennik w agregacie
  - Pojemność warunkowa: organizator może zwiększyć limit (komenda na agregacie), ale agregat pilnuje maksimum
- **Sprzęt** — chroni niezmiennik: „sprzęt niedostępny (awaria/serwis) nie może być zarezerwowany"; ma lifecycle (sprawny → w serwisie → wycofany)
- **Trener** — chroni niezmiennik: „trener nie może być przypisany do nakładających się szkoleń"; ma kompetencje, dostępność, urlopy

Optimistic Locking na każdym agregacie.

**2. Integration — saga „Rezerwacja Szkolenia":**

Process Manager / Saga koordynuje rezerwację all-or-nothing:
1. Zarezerwuj salę → sukces/porażka
2. Zarezerwuj miejsca → sukces/porażka
3. Zarezerwuj sprzęt → sukces/porażka
4. Zarezerwuj trenera → sukces/porażka
5. Jeśli którykolwiek krok się nie powiódł → kompensacja (zwolnij wszystkie już zarezerwowane)

Kolejność: najpierw najtrudniejszy do odwrócenia (lub najrzadszy zasób), żeby szybko failować.

**3. T&P — widok dostępności:**

Read model / projekcja odświeżana eventami domenowymi:
- `SalaZarezerwowana`, `MiejsceZablokowane`, `SprzętWyłączony`, `TrenerPrzypisany` → aktualizują widok
- Widok jest odtwarzalny — można skasować i odbudować ze zdarzeń
- Nie jest źródłem prawdy dla komend

### Open questions before modeling

1. **Jaki jest timeout blokady VIP?** — ile czasu handlowiec ma na potwierdzenie blokady, zanim system ją automatycznie zwalnia?
2. **Jakie są limity warunkowego zwiększania pojemności?** — o ile procent/osób organizator może zwiększyć pojemność i czy wymaga to zatwierdzenia?
3. **Czy kompensacja w sadze jest zawsze możliwa?** — czy istnieją sytuacje, w których anulowanie rezerwacji sali po jej dokonaniu jest kosztowne lub niemożliwe (np. umowa z właścicielem sali)?
4. **Jakie kompetencje trenera muszą pasować do szkolenia?** — czy to prosty matching (trener ma certyfikat X), czy bardziej złożona logika?
5. **Czy sprzęt jest zamienny?** — jeśli aparat A jest w serwisie, czy system automatycznie szuka aparatu B, czy organizator wybiera ręcznie?

---

## Suggested decomposition

Ten problem obejmuje trzy klasy. Proponowany podział:

| Komponent | Klasa | Uzasadnienie |
|-----------|-------|-------------|
| Agregat Sali | Resource Contention | Współbieżna rezerwacja sali na terminy, ochrona przed nakładaniem |
| Agregat Puli Miejsc | Resource Contention | Współbieżna rezerwacja miejsc z regułami VIP i pojemnością warunkową |
| Agregat Sprzętu | Resource Contention | Rezerwacja z lifecycle (sprawny/w serwisie/wycofany) |
| Agregat Trenera | Resource Contention | Rezerwacja z kompetencjami i dostępnością czasową |
| Saga „Rezerwacja Szkolenia" | Integration | Koordynacja all-or-nothing rezerwacji wielu zasobów z kompensacją |
| Widok Dostępności | T&P | Projekcja stanu zasobów, odtwarzalna, nie jest źródłem prawdy |

Nie modelować ich razem w jednej klasie — wymusi to logikę domenową w warstwie CRUD lub odwrotnie.

## Component relationship diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  SAGA: Rezerwacja Szkolenia                 │
│                      (Integration)                          │
│                                                             │
│  Koordynuje all-or-nothing:                                 │
│  1. Zarezerwuj → 2. Zarezerwuj → 3. Zarezerwuj → 4. Zarezerwuj │
│     Salę          Miejsca         Sprzęt          Trenera   │
│                                                             │
│  Porażka na dowolnym kroku → kompensacja wcześniejszych     │
└────┬──────────┬──────────────┬──────────────┬───────────────┘
     │ command   │ command       │ command       │ command
     ▼           ▼               ▼               ▼
┌─────────┐ ┌──────────┐  ┌──────────┐   ┌──────────┐
│  Sala   │ │  Pula    │  │  Sprzęt  │   │  Trener  │
│  (RC)   │ │  Miejsc  │  │  (RC)    │   │  (RC)    │
│         │ │  (RC)    │  │          │   │          │
│ Inwar.: │ │ Inwar.:  │  │ Inwar.:  │   │ Inwar.:  │
│ brak    │ │ zajęte + │  │ nie      │   │ brak     │
│ nakła-  │ │ blokady  │  │ rezerwuj │   │ nakła-   │
│ dania   │ │ ≤ pojem- │  │ uszkodz. │   │ dania    │
│ terminów│ │ ność     │  │ sprzętu  │   │ terminów │
│         │ │ + VIP    │  │          │   │ + kompe- │
│         │ │ limity   │  │ lifecycle│   │ tencje   │
└────┬────┘ └────┬─────┘  └────┬─────┘   └────┬─────┘
     │ event     │ event       │ event         │ event
     │           │             │               │
     ▼           ▼             ▼               ▼
┌─────────────────────────────────────────────────────────────┐
│              Widok Dostępności (T&P)                         │
│                                                             │
│  Projekcja stanu zasobów — odtwarzalna ze zdarzeń           │
│  SalaZarezerwowana, MiejsceZablokowane,                     │
│  SprzętWyłączony, TrenerPrzypisany → aktualizacja widoku   │
└─────────────────────────────────────────────────────────────┘
```

### Uwaga do generalizacji „zasób"

Uogólnienie sali, miejsc, sprzętu i trenera do jednego pojęcia „zasób" jest kuszące, bo operacje wyglądają podobnie (rezerwuj/blokuj/zwolnij/wyłącz). Ale **niezmienniki są różne** dla każdego typu:

| Typ | Specyficzne reguły, których „zasób" nie pokrywa |
|-----|--------------------------------------------------|
| Sala | Nakładanie terminów, pojemność fizyczna, lokalizacja |
| Miejsca | Pojemność warunkowa, blokady VIP z timeout, fungible (liczy się ilość, nie instancja) |
| Sprzęt | Lifecycle (sprawny → serwis → wycofany), zamienność między egzemplarzami |
| Trener | Kompetencje, urlopy, dostępność czasowa, jest osobą — nie „wyłączasz" trenera jak aparat |

Wspólna abstrakcja albo zgubi te reguły (uproszczenie), albo rozrośnie się w `if type == trainer then...` (zniszczenie sensu generalizacji). Lepsze podejście: **oddzielne agregaty z własnymi niezmiennikami**, skoordynowane przez sagę.