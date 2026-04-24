# Analiza uogólnień — system zapisów na szkolenia

## Prompt z instrukcjami uogólnienia

> Masz blok wymagań domenowych. Użyj uogólnienia jako techniki szukania modułów — znajdź różne koncepty, które w danym procesie zachowują się identycznie.
>
> Szukaj po czasownikach, nie rzeczownikach ("rezerwuję salę", "rezerwuję trenera" — ten sam mechanizm → kandydat do wspólnej abstrakcji). Testuj efektem w kontekście konsumenta, nie przyczyną u źródła — urlop i awaria to różne procesy, ale oba powodują niedostępność, więc w kontekście dostępności to jedno.
>
> Jeśli model uogólniony potrzebuje wiedzieć czym coś jest (a nie co robi) — uogólnienie jest fałszywe.
>
> Następnie szukaj kontrprzykładów — miejsc w wymaganiach, gdzie uogólnienie się łamie. Granica pojawia się tam, gdzie jeden typ potrzebuje procesu, który nie ma sensu dla innego (np. trener ma urlopy, sprzęt ma przeglądy — tych procesów nie da się uogólnić). Te specyficzne procesy to sygnał osobnego modułu. Ale zanim odrzucisz uogólnienie, przetestuj głębiej: czy w kontekście konsumenta efekt tych różnych procesów jest jednak taki sam? Jeśli tak — uogólnienie trzyma się na poziomie efektu, a specyfika zostaje w module źródłowym.
>
> Daj: tabelę uogólnień z techniką (uogólnienie / wyabstrahowanie / zmiana reprezentacji), kontrprzykłady gdzie uogólnienie się łamie i jakie moduły specyficzne z tego wynikają, mapę modułów z kluczowym pytaniem każdego.

---

## Kontekst problemu

> Zgłoszony problem: „mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność".
>
> Handlowcy blokowali miejsca „na telefon" dla klientów VIP. Organizatorzy zwiększali liczbę miejsc „warunkowo". Szkolenie zależało nie tylko od sali i miejsc, ale też od dostępności sprzętu (aparat do nagrania). Szkolenie odwołane mimo wolnych miejsc i sali — bo aparat uszkodzony.

---

## 1. Tabela uogólnień

| Koncepty źródłowe | Uogólnienie | Technika | Uzasadnienie |
|---|---|---|---|
| Trener, Sala, Aparat (sprzęt) | **Zasób** (Resource) | Wyabstrahowanie | W kontekście "czy szkolenie może się odbyć?" konsument pyta: "czy zasób jest dostępny w oknie czasowym?" — nie musi wiedzieć *czym* jest zasób. Czasownik identyczny: "rezerwuję salę", "rezerwuję trenera", "rezerwuję sprzęt" → ten sam mechanizm: **zajmij zasób na czas**. |
| Urlop trenera, Awaria sprzętu, Zajętość sali | **Niedostępność** (Unavailability) | Uogólnienie | Różne procesy źródłowe, ale efekt w kontekście konsumenta (szkolenie) jest identyczny: **zasób nie może być użyty w oknie T**. Testujemy efektem u konsumenta, nie przyczyną u źródła. |
| Zapis uczestnika, Blokada VIP przez handlowca | **Roszczenie do pojemności** (Capacity Claim) | Wyabstrahowanie | Oba dekrementują pulę wolnych miejsc. Pula nie musi wiedzieć *kto* i *dlaczego* rości — zna tylko: zajmij / zwolnij / ile zostało. |
| Liczba miejsc na szkoleniu, Warunkowe zwiększenie miejsc | **Pula pojemności** (Capacity Pool) | Zmiana reprezentacji | Zamiast "sztywna liczba miejsc" → pula z operacjami: `claim`, `release`, `adjust_limit`. Warunkowe zwiększenie to `adjust_limit` z polityką. |

---

## 2. Kontrprzykłady — gdzie uogólnienie się łamie

| Uogólnienie | Kontrprzykład | Dlaczego się łamie | Wniosek |
|---|---|---|---|
| **Zasób** (trener = sala = sprzęt) | Trener ma **kwalifikacje** (może prowadzić tylko pewne tematy). Sprzęt ma **specyfikację techniczną**. Sala ma **pojemność fizyczną**. | Dobór zasobu do szkolenia wymaga wiedzy *czym* jest zasób → model uogólniony musiałby znać typ → fałszywe uogólnienie na poziomie doboru. | Uogólnienie trzyma się **na poziomie dostępności** (dostępny/niedostępny w T), łamie się **na poziomie selekcji** (kto pasuje do tego szkolenia). → Selekcja zostaje w modułach specyficznych. |
| **Niedostępność** (urlop = awaria) | Urlop jest **planowany** (harmonogram, zatwierdzenia). Awaria jest **nieplanowana** (zgłoszenie, naprawa, wymiana). Przegląd techniczny to jeszcze inny proces. | Procesy *powstawania* niedostępności są radykalnie różne. | Ale efekt w kontekście konsumenta jest ten sam: "niedostępny w T". → Uogólnienie trzyma się na poziomie efektu. Specyfika procesu zostaje w module źródłowym (trener zarządza urlopami, sprzęt zarządza naprawami). Oba **publikują** fakt niedostępności w ujednoliconej formie. |
=
---

## 3. Mapa modułów

```
┌─────────────────────────────────────────────────────────────┐
│                    MODUŁY UOGÓLNIONE                        │
│                                                             │
│  ┌─────────────────────┐    ┌────────────────────────────┐  │
│  │  Dostępność Zasobów │    │   Pula Pojemności          │  │
│  │                     │    │                            │  │
│  │  "Czy zasób X jest  │    │  "Ile wolnych jednostek    │  │
│  │   wolny w oknie T?" │    │   zostało do zajęcia?"     │  │
│  │                     │    │                            │  │
│  │  Nie zna typów.     │    │  Nie zna kto rości.        │  │
│  │  Nie zna przyczyn.  │    │  claim / release /         │  │
│  │  available(X,T)→bool│    │  adjust_limit              │  │
│  └────────▲────────────┘    └──────▲───────▲─────────────┘  │
│           │                        │       │                │
└───────────┼────────────────────────┼───────┼────────────────┘
            │ publikuje              │       │ claim/release
            │ niedostępność          │       │
┌───────────┼────────────────────────┼───────┼────────────────┐
│           │  MODUŁY SPECYFICZNE    │       │                │
│           │                        │       │                │
│  ┌────────┴──────┐ ┌──────────┐   │  ┌────┴─────────────┐  │
│  │ Trenerzy      │ │ Sprzęt   │   │  │ Zapisy           │  │
│  │               │ │          │   │  │                  │  │
│  │ "Kto ma jakie │ │ "Jaki    │   │  │ "Kto jest        │  │
│  │  kwalifikacje │ │  stan    │   │  │  zapisany, na    │  │
│  │  i kiedy jest │ │  technicz│   │  │  jakich          │  │
│  │  na urlopie?" │ │  ny i    │   │  │  warunkach?"     │  │
│  │               │ │  kiedy   │   │  │                  │  │
│  │ urlopy,       │ │  przegląd│   │  │ rejestracja,     │  │
│  │ kwalifikacje, │ │  ?"      │   │  │ potwierdzenie,   │  │
│  │ preferencje   │ │          │   │  │ rezygnacja       │  │
│  └───────────────┘ │ naprawy, │   │  └──────────────────┘  │
│                    │ przeglądy│   │                         │
│  ┌───────────────┐ │ specyfik.│   │  ┌──────────────────┐  │
│  │ Sale          │ └──────────┘   │  │ Rezerwacje       │  │
│  │               │                │  │ Handlowe         │  │
│  │ "Jaka jest    │                │  │                  │  │
│  │  pojemność    │                │  │ "Jakie blokady   │  │
│  │  fizyczna i   │                │  │  VIP istnieją    │  │
│  │  harmonogram?"│                │  │  i kiedy         │  │
│  │               │                │  │  wygasają?"      │  │
│  │ pojemność,    │                │  │                  │  │
│  │ wyposażenie   │                │  │ blokada,         │  │
│  └───────────────┘                │  │ wygaśnięcie,     │  │
│                                   │  │ konwersja→zapis  │  │
│                                   │  └──────────────────┘  │
└───────────────────────────────────┘                         │
                                                              │
┌─────────────────────────────────────────────────────────────┐
│  MODUŁ KONSUMENTA                                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Wykonalność Szkolenia                               │    │
│  │                                                     │    │
│  │ "Czy to szkolenie może się odbyć?"                  │    │
│  │                                                     │    │
│  │ Odpytuje Dostępność + Pulę Pojemności.              │    │
│  │ Nie zarządza zasobami. Nie zna procesów źródłowych. │    │
│  │ Reaguje na zmiany (odwołanie jeśli krytyczny zasób  │    │
│  │ staje się niedostępny).                             │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Podsumowanie kluczowych decyzji

**Uogólnienie trzyma się na poziomie efektu, specyfika zostaje przy źródle.**

Dwa moduły uogólnione (Dostępność, Pula Pojemności) nie wiedzą *czym* są zasoby ani *kto* rości pojemność. To ich siła — są stabilne wobec zmian. Gdy pojawi się nowy typ zasobu (np. tłumacz), moduły uogólnione nie wymagają zmian. Nowy moduł specyficzny (Tłumacze) po prostu publikuje niedostępność w tym samym formacie.
