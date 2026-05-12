# Linguistic Boundary Verifier -- Wynik uruchomienia (tryb PR)

**Prompt uzyty do uruchomienia**: `linguistic-boundary-verifier calculation-engine --pr`

**Modul**: `calculation-engine`
**Tryb**: `--pr` (pojedynczy modul, sprawdzenie nowych konceptow)
**Czulosc**: HIGH -- modul jest generalizacja (wylacznie konsumenci w integration points, zero zaleznosci wychodzacych)

---

## Faza 1: Analiza modulu i odczyt language.md

Plik `calculation-engine/language.md` deklaruje:

> **Generalizacja** -- oblicza slad weglowy dla dowolnego wejscia uzywajac kompozytowalnych komponentow, kalkulatorow, okresow waznosci i regul zastosowalnosci. Generyczny -- NIE wie o konkretnych typach produktow, standardach emisyjnych ani procesach audytowych.

| Kto konsumuje (OHS) | Opis |
|----------------------|------|
| Product Catalog | Produkty, kategorie, SKU |
| Emission Factor Management | Wspolczynniki emisji, zakresy GHG, protokoly |
| Compliance & Audit | Audyty, zatwierdzenia, certyfikaty |

**Istniejace slownictwo**: Calculator, Component, SimpleComponent, CompositeComponent, ComponentTree, Validity, Applicability, ContextParameter, FootprintResult, CalculationRequest.
**Operacje**: calculate, resolveApplicability, resolveValidity, composeComponents.

**Test kwalifikacyjny** dla kazdego nowego terminu: *"Czy ten termin ma sens bez wiedzy o jakimkolwiek module downstream?"*

-> Faza 2

---

## Faza 2: Ekstrakcja i klasyfikacja nowych terminow z PR

Diff PR-a wprowadza 4 nowe pliki: `ComponentBreakdown.java`, `HistoricalSnapshot.java`, `FrozenFoodSurcharge.java`, `FootprintEnhancer.java`. Ekstrakcja nowych nazw klas, metod, stalych i literalow tekstowych.

### Tabela klasyfikacji

| # | Nowy termin | Plik zrodlowy | Klasyfikacja | Uzasadnienie |
|---|-------------|---------------|--------------|--------------|
| 1 | `ComponentBreakdown` | ComponentBreakdown.java | ✅ Zgodny z jezykiem modulu | Rozklad rozwiazanych komponentow. `Component` juz istnieje w language.md. Generyczne rozszerzenie -- nie wymaga wiedzy o downstream. |
| 2 | `HistoricalSnapshot` | HistoricalSnapshot.java | ✅ Zgodny z jezykiem modulu | Odpytywanie stanu kalkulacji w przeszlej dacie. Korzysta z Validity i ComponentTree. Czysto generyczny koncept. |
| 3 | `snapshotAt` | FootprintEnhancer.java | ✅ Zgodny z jezykiem modulu | Generyczna operacja tworzaca HistoricalSnapshot na podstawie daty i Validity. |
| 4 | `addApplicabilityRule` | FootprintEnhancer.java | ✅ Zgodny z jezykiem modulu | Applicability juz jest w language.md. Naturalne rozszerzenie operacji. |
| 5 | `retryCount` | FootprintEnhancer.java | ⚪ Infrastruktura | Pole techniczne (logika ponawiania). Nie jest terminem domenowym. |
| 6 | `FrozenFoodSurcharge` | FrozenFoodSurcharge.java | **❌ NARUSZENIE** (Product Catalog) | "Frozen food" to jezyk Product Catalog. Cala klasa jest kaskada obcych terminow: `productCategory`, `freezerEnergyKwh`, `COLD_CHAIN_MULTIPLIER`, `REFRIGERATION_FACTOR`, `isPerishable()`, `"FROZEN"`, `"CHILLED"`. Generyczny silnik nie wie o kategoriach produktow. |
| 7 | `classifyGhgScope` | FootprintEnhancer.java | **❌ NARUSZENIE** (Emission Factor Mgmt) | "GHG Scope" to taksonomia Emission Factor Management. Klasyfikacja Scope 1/2/3 to ich odpowiedzialnosc, nie silnika. |
| 8 | `checkAuditorApproval` | FootprintEnhancer.java | **❌ NARUSZENIE** (Compliance & Audit) | "Auditor" i "Approval" to jezyk Compliance & Audit. Silnik oblicza -- nie wie o audytach ani zatwierdzeniach. |
| 9 | `getScope3TransportFactor` | FootprintEnhancer.java | **❌❌ PODWOJNE NARUSZENIE** (Emission Factor Mgmt) | Dwa niezalezne wycieki w jednej metodzie -- szczegoly ponizej. |

### Podsumowanie

| Kategoria | Liczba | Terminy |
|-----------|--------|---------|
| ✅ Zgodne z jezykiem modulu | 4 | ComponentBreakdown, HistoricalSnapshot, snapshotAt, addApplicabilityRule |
| ⚪ Infrastruktura | 1 | retryCount |
| **❌ Z Product Catalog** | 1 | FrozenFoodSurcharge (+ caly plik) |
| **❌ Z Emission Factor Mgmt** | 2 | classifyGhgScope, getScope3TransportFactor |
| **❌ Z Compliance & Audit** | 1 | checkAuditorApproval |

**Lacznie**: 9 terminow | **Naruszenia**: 4 (w tym 1 podwojne) | **OK**: 4 | **Infra**: 1

---

## PRZED -- co PR wprowadza do Engine

```
┌──────────────────────────────────────────────────────────────┐
│              CALCULATION ENGINE (generalizacja)               │
│                                                              │
│  Istniejace: Calculator, Component, Validity, Applicability  │
│  ─────────────────────────────────────────────────────────── │
│  Nowy kod z PR:                                              │
│    ✅ ComponentBreakdown            (generyczne)             │
│    ✅ HistoricalSnapshot            (generyczne)             │
│    ✅ snapshotAt, addApplicabilityRule                        │
│    ⚪ retryCount                     (infrastruktura)        │
│    ❌ FrozenFoodSurcharge            ← Product Catalog!      │
│    ❌ classifyGhgScope               ← Emission Factors!     │
│    ❌ checkAuditorApproval           ← Compliance & Audit!   │
│    ❌❌ getScope3TransportFactor()   ← nazwa + string leak!  │
│                                                              │
│  ⚠️  Generyczny modul zaczyna WIEDZIEC o downstream          │
│  ⚠️  Kazdy z 3 konsumentow wcieka do silnika                 │
└──────────────────────────────────────────────────────────────┘
         ▲                        ▲                  ▲
         │ OHS                    │ OHS               │ OHS
┌────────┴────────┐  ┌───────────┴──────────┐  ┌────┴───────────────┐
│ Product Catalog  │  │ Emission Factor Mgmt │  │ Compliance & Audit │
│ "frozen food"    │  │ "GHG Scope 3"        │  │ "auditor approval" │
└──────────────────┘  └──────────────────────┘  └────────────────────┘
```

---

## Spotlight: podwojne naruszenie `getScope3TransportFactor`

To najbardziej pouczajace naruszenie w calym PR -- i jednoczesnie pokaz tego, czego narzedzia do analizy zaleznosci (ArchUnit, deptrac, Nx) nigdy nie znajda.

```java
// FootprintEnhancer.java
public double getScope3TransportFactor(CalculationRequest request) {
    String category = (String) params.getOrDefault("emissionCategory", "");
    if (category.equals("SCOPE_3_TRANSPORT")) {  // ← string leak
        return 2.5;
    }
    return 1.0;
}
```

**Naruszenie #1 -- nazwa metody**: `getScope3TransportFactor` zawiera "Scope 3" i "Transport" -- slownictwo Emission Factor Management. To naruszenie jest przynajmniej teoretycznie mozliwe do wykrycia -- narzedzie do analizy zaleznosci mogloby miec regule na nazwy metod zawierajace obce terminy (w praktyce nikt takich regul nie pisze).

**Naruszenie #2 -- string leak**: `"SCOPE_3_TRANSPORT"` to literalny tekst. Nie ma importu. Nie ma typu. Nie ma pakietu do zablokowania. **Zaden analizator statyczny tego nie widzi.** Brak referencji typowej -- tylko string niosacy jezyk innego modulu. To dokladnie ten rodzaj sprzezenia, ktore lingwistyczne sprawdzanie granic znajduje, a analiza zaleznosci ignoruje.

**Dlaczego to groznie**: Dzis `"SCOPE_3_TRANSPORT"`, jutro `"SCOPE_1_STATIONARY"`, pojutrze `"SCOPE_2_PURCHASED_ELECTRICITY"`. Silnik powoli staje sie encyklopedia taksonomii GHG Protocol -- cala wiedza Emission Factor Management zostaje zduplikowana jako literaly tekstowe. A narzedzia do analizy zaleznosci radosnie raportuja: "zero violations, all clean."

```
narzędzia do analizy zależności:

  ┌─────────────────────┐       ┌─────────────────────┐
  │ Calculation Engine   │       │ Emission Factor Mgmt│
  │                      │       │                     │
  │ (brak importow z  ──┼── ✅──┼── brak zaleznosci)  │
  │  Emission Factors)   │       │                     │
  └──────────────────────┘       └─────────────────────┘
  Werdykt: OK, brak coupling

Weryfikacja lingwistyczna:

  ┌──────────────────────┐       ┌─────────────────────┐
  │ Calculation Engine    │       │ Emission Factor Mgmt│
  │                       │       │                     │
  │ "SCOPE_3_TRANSPORT"  ─┼── ❌──┼── to ich termin!    │
  │  getScope3Transport() │       │                     │
  └───────────────────────┘       └─────────────────────┘
  Werdykt: NARUSZENIE -- jezyk downstream'u w generalizacji
```

---

### -> Pauza: Prezentacja klasyfikacji

4 nowe terminy (ComponentBreakdown, HistoricalSnapshot, snapshotAt, addApplicabilityRule) wyglądaja na spojne z jezykiem Calculation Engine. 1 termin (retryCount) to infrastruktura. 4 terminy sa naruszeniami: FrozenFoodSurcharge (Product Catalog), classifyGhgScope i getScope3TransportFactor (Emission Factor Mgmt), checkAuditorApproval (Compliance & Audit). getScope3TransportFactor to podwojne naruszenie -- nazwa metody + wyciek przez string. Zgadzasz sie z ta klasyfikacja?

- **Tak, przejdz do rekomendacji**
- **Niektore to falszywe alarmy** (wskazuje ktore)
- **Dodaj kontekst**

> **Uzytkownik**: Tak, przejdz do rekomendacji.

---

## Faza 3: Rekomendacje

### R1: `ComponentBreakdown`, `HistoricalSnapshot`, `snapshotAt`, `addApplicabilityRule`

**Akcja**: Dodaj do `calculation-engine/language.md` jako nowe terminy i operacje.

Te koncepty rozszerzaja generalizacje w jej wlasnym jezyku. ComponentBreakdown to rozklad komponentow, HistoricalSnapshot to widok historyczny z uzyciem Validity -- zadne nie wymaga wiedzy o downstream.

### R2: `FrozenFoodSurcharge.java` -- caly plik do usuniecia z Engine

**Problem**: Caly plik to kaskada obcego slownictwa. `productCategory`, `freezerEnergyKwh`, `COLD_CHAIN_MULTIPLIER`, `REFRIGERATION_FACTOR`, `isPerishable()`, literaly `"FROZEN"` i `"CHILLED"`.

**Naprawa**: Product Catalog modeluje narzut za cold chain jako generyczny `Component` z odpowiednimi `ContextParameter`. Silnik nie wie, ze cos jest mrozone -- dostaje komponent z wartoscia i liczy.

```
PRZED:
  Engine zna: "frozen", "chilled", "perishable", "freezerEnergyKwh"
  Engine DECYDUJE: jesli mrozonka -> mnoznik 1.35

PO:
  Product Catalog tworzy: Component(value=X, type=SURCHARGE)
  Engine dostaje: komponent z wartoscia. Liczy. Nie pyta "dlaczego?"
```

### R3: `classifyGhgScope` -- metoda do przeniesienia

**Problem**: Klasyfikacja zakresow GHG (Scope 1/2/3) to core Emission Factor Management. Silnik nie powinien klasyfikowac -- powinien dostac juz sklasyfikowana wartosc.

**Naprawa**: Emission Factor Mgmt klasyfikuje i przekazuje wynik jako `ContextParameter` lub jako wlasciwosc `Component`.

### R4: `getScope3TransportFactor` -- podwojne naruszenie do przeniesienia

**Problem**: Nazwa metody + string literal `"SCOPE_3_TRANSPORT"`. Dwa kanaly wycieku w jednej metodzie.

**Naprawa**: Emission Factor Mgmt rozwiazuje factor i przekazuje go jako `ContextParameter`. Silnik dostaje liczbe, nie taksonomie.

```
PRZED:
  Engine: getScope3TransportFactor() { if "SCOPE_3_TRANSPORT" -> 2.5 }
  Engine zna: nazwe zakresu, jego kategoryzacje, wartosc faktora

PO:
  Emission Factor Mgmt: resolveTransportFactor() -> 2.5
  Engine dostaje: ContextParameter("transportFactor", 2.5)
  Engine liczy: * transportFactor. Nie wie co to Scope 3.
```

### R5: `checkAuditorApproval` -- metoda do przeniesienia

**Problem**: "Auditor" i "Approval" to jezyk Compliance & Audit. Silnik oblicza slad weglowy -- nie weryfikuje zatwierdzen audytorskich.

**Naprawa**: Compliance & Audit sprawdza zatwierdzenie i -- jesli potrzebne -- ustawia flage na `CalculationRequest` lub `Component` (np. `locked: boolean`). Silnik reaguje na generyczna flage, nie na koncept audytora.

---

### -> Pauza: Akceptacja rekomendacji

| # | Rekomendacja | Zgadzasz sie? |
|---|-------------|---------------|
| R1 | Dodaj 4 terminy do language.md | ? |
| R2 | Usun FrozenFoodSurcharge.java z Engine, Product Catalog modeluje jako Component | ? |
| R3 | Przenies classifyGhgScope do Emission Factor Mgmt | ? |
| R4 | Przenies getScope3TransportFactor do Emission Factor Mgmt, przekaz jako ContextParameter | ? |
| R5 | Przenies checkAuditorApproval do Compliance & Audit, uzyj generycznej flagi | ? |

> **Uzytkownik (R1)**: Tak.
>
> **Uzytkownik (R2)**: Tak. Product Catalog powinien zbudowac Component z odpowiednimi parametrami -- silnik nie musi wiedziec o cold chain.
>
> **Uzytkownik (R3)**: Tak.
>
> **Uzytkownik (R4)**: Tak. To jest najwazniejsze -- ten string leak to idealny przyklad dlaczego ArchUnit nie wystarczy.
>
> **Uzytkownik (R5)**: Tak, ale raczej jako Applicability z warunkiem "unlocked" niz osobna flaga. Applicability juz jest w language.md i obsluguje warunki kontekstowe.

---

## Faza 4: Uwzglednienie feedbacku

| # | Decyzja | Wynik |
|---|---------|-------|
| R1 | Zaakceptowana | Dodaj do language.md |
| R2 | Zaakceptowana | Usun plik, Product Catalog tworzy Component |
| R3 | Zaakceptowana | Przenies do Emission Factor Mgmt |
| R4 | Zaakceptowana | Przenies, przekaz jako ContextParameter |
| R5 | **Zrewidowana** | Zamiast flagi `locked` -- Applicability z warunkiem kontekstowym. Silnik juz zna Applicability, wiec sprawdzenie zatwierdzenia audytorskiego staje sie regula zastosowalnosci ustawiana przez Compliance & Audit. |

### Zrewidowana rekomendacja R5

Compliance & Audit ustawia `Applicability` rule na Component:

```
PRZED:
  Engine: checkAuditorApproval(tree) -> boolean
  Engine zna: "auditor", "approval", logike zatwierdzania

PO:
  Compliance & Audit ustawia: Applicability(condition="audit_approved")
  Engine: resolveApplicability(component, context) -> true/false
  Engine nie wie KTO zatwierdza ani DLACZEGO -- ocenia generyczna regule
```

Eleganckie -- uzywa istniejacego slownictwa modulu zamiast wprowadzania nowego konceptu.

---

## PO -- modul po zastosowaniu rekomendacji

```
┌──────────────────────────────────────────────────────────────┐
│              CALCULATION ENGINE (generalizacja)               │
│                                                              │
│  Calculator, Component, Validity, Applicability              │
│  ✅ ComponentBreakdown    (nowe -- dodane do language.md)    │
│  ✅ HistoricalSnapshot    (nowe -- dodane do language.md)    │
│  ✅ snapshotAt            (nowe -- dodane do language.md)    │
│  ✅ addApplicabilityRule  (nowe -- dodane do language.md)    │
│                                                              │
│  Generyczny -- NIE wie o produktach, emisjach, audytach      │
│  Zadnych obcych terminow ✅                                  │
└──────────────────────────────────────────────────────────────┘
         ▲                        ▲                  ▲
         │ konsumuje OHS          │ konsumuje OHS     │ konsumuje OHS
┌────────┴────────┐  ┌───────────┴──────────┐  ┌────┴───────────────┐
│ Product Catalog  │  │ Emission Factor Mgmt │  │ Compliance & Audit │
│                  │  │                      │  │                    │
│ ← FrozenFood-   │  │ ← classifyGhgScope   │  │ ← checkAuditor-   │
│   Surcharge      │  │   (lokalna logika)   │  │   Approval         │
│   modeluje jako  │  │ ← getScope3Transport │  │   (ustawia         │
│   Component +    │  │   Factor (rozwiazuje │  │   Applicability    │
│   ContextParam   │  │   i przekazuje jako  │  │   rule na          │
│                  │  │   ContextParameter)  │  │   Component)       │
└──────────────────┘  └──────────────────────┘  └────────────────────┘
```

---

## Werdykt: Podziel PR na dwa

| PR | Zawartosc | Akcja |
|----|-----------|-------|
| **PR A** (merge) | `ComponentBreakdown.java`, `HistoricalSnapshot.java`, generyczne metody z `FootprintEnhancer.java` (breakdownComponents, snapshotAt, addApplicabilityRule) | Merge -- rozszerza generalizacje w jej wlasnym jezyku. Zaktualizuj `language.md` o nowe terminy. |
| **PR B** (do przerobienia) | `FrozenFoodSurcharge.java` (caly plik), metody z `FootprintEnhancer.java`: calculateWithFrozenFoodSurcharge, checkColdChainCompliance, classifyGhgScope, getScope3TransportFactor, checkAuditorApproval | Do przerobienia -- przenies logike do wlasciwych modulow downstream. Kazdy konsument modeluje swoja specyfike i przekazuje wynik przez generyczne API silnika (Component, ContextParameter, Applicability). |

---

## Kluczowy wniosek

Sila Calculation Engine bierze sie z tego, ze **NIE wie**, dla czego oblicza slad weglowy. Kazdy konsument (Product Catalog, Emission Factor Mgmt, Compliance & Audit) uzywa generycznego API silnika w jego jezyku -- i to konsument adaptuje sie do generalizacji, nie odwrotnie.

Ten PR jest pouczajacy, bo pokazuje **trzy rozne konsumenty wyciekajace jednoczesnie** do jednej generalizacji. Gdyby PR przeszedl w calosci, silnik zaczalby wiedziec o mrozonych produktach, zakresach GHG i audytorach -- a kazdy kolejny PR dodalby nastepne specyficzne terminy. Generalizacja umiera smiercia przez tysiace ciec.

`getScope3TransportFactor()` to najbardziej pouczajace naruszenie: nazwa metody wycieka slownictwo Emission Factor Management, a implementacja przemyca ich semantyke przez literal tekstowy `"SCOPE_3_TRANSPORT"`. Narzedzia do analizy zaleznosci widza zero problemow -- bo nie ma importu do zablokowania. Lingwistyczne sprawdzanie granic znajduje dokladnie to, czego analiza statyczna nie widzi.

**Nota o czulosci**: Calculation Engine to generalizacja obslugujaca wielu konsumentow. Tryb HIGH sensitivity jest uzasadniony -- kazdy obcy termin niesie ryzyko, ze silnik zaczyna "wiedziec" o specyficznych downstream-ach i traci swoja generycznosc. W module integrujacym (np. OrderFulfillment) ta sama analiza bylaby lagodniejsza -- bo integrator z definicji zna wiele modulow.
