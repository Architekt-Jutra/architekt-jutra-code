# Linguistic Boundary Verifier -- Wynik uruchomienia

## Prompt uzyty do uruchomienia

```
linguistic-boundary-verifier all
```

> Mozna tez uruchomic na wybranych modulach:
> `linguistic-boundary-verifier calculation-engine product-catalog`

**Zakres**: calculation-engine, product-catalog, emission-factors

---

## PRZED: Architektura z niewidocznym couplingiem

```
┌──────────────────────────────────────────────────────────────────┐
│                Calculation Engine (GENERALIZACJA)                 │
│                                                                  │
│   FootprintCalculator.java:                                      │
│     if (x.equals("MROZONKI"))          ❌ string z Prod.Catalog  │
│     if (x.equals("NABIAJ"))            ❌ string z Prod.Catalog  │
│     if (x.equals("CHEMIA"))            ❌ string z Prod.Catalog  │
│     if (x.equals("SCOPE_3_TRANSPORT")) ❌ string z Em.Factors   │
│     if (x.equals("GHG_PROTOCOL_V2"))   ❌ string z Em.Factors   │
│                                                                  │
│   ComponentType.java:                                            │
│     MROZONKI_TRANSPORT      ❌ enum z Prod.Catalog              │
│     NABIAJ_PRZECHOWYWANIE   ❌ enum z Prod.Catalog              │
│     ELEKTRONIKA_PACKAGING   ❌ enum z Prod.Catalog              │
│     SCOPE_1_DIRECT          ❌ enum z Em.Factors                │
│     SCOPE_3_LOGISTICS       ❌ enum z Em.Factors                │
│     GHG_PROTOCOL_FACTOR     ❌ enum z Em.Factors                │
│     BASE_EMISSION           ✅ wlasny                           │
│     SURCHARGE               ✅ wlasny                           │
│     ADJUSTMENT              ✅ wlasny                           │
│                                                                  │
│   ArchUnit / deptrac / Nx:  ✅ "brak naruszen"                  │
│   Granice lingwistyczne:    ❌ 11 obcych terminow w kodzie       │
└───────────────────────────────┬──────────────────────────────────┘
                                │ generyczne API (OHS)
                 ┌──────────────┴──────────────┐
                 │                             │
      ┌──────────▼──────────┐      ┌──────────▼──────────┐
      │   Product Catalog   │      │  Emission Factors    │
      │  MROZONKI, NABIAJ   │      │  SCOPE_3_TRANSPORT   │
      │  CHEMIA, ELEKTRONIKA│      │  GHG_PROTOCOL_V2     │
      │                     │      │  Audytor, Zakres     │
      └─────────────────────┘      └──────────────────────┘
```

---

## Faza 1: Odkrywanie i Parsowanie

Czytam pliki `language.md` dla wszystkich trzech modulow.

| Modul | Rola | Slownictwo kluczowe |
|-------|------|---------------------|
| **Calculation Engine** | **Generalizacja** -- oblicza kg CO2 z komponentow. Nie wie, dla jakiego produktu liczy. Pure-function pricing archetype. | Component, Calculator, Validity, Applicability, ContextParameter, FootprintResult |
| **Product Catalog** | Specyficzny -- produkty, kategorie (MROZONKI, NABIAJ, ELEKTRONIKA, CHEMIA, OWOCE), SKU, ceny. | Produkt, Kategoria, SKU, Cena, WymagaChlodzenia, WymagaSpecjalnegoOpakowania |
| **Emission Factors** | Specyficzny -- wspolczynniki emisji, zakresy GHG, audytorzy, governance aktualizacji. | WspolczynnikEmisji, Zakres (SCOPE_1/2/3), Audytor, ProtokolGHG (V1/V2/V3), LimitAktualizacji |

**Relacje zrekonstruowane z integration points**:

Oba moduly specyficzne sa **konsumentami OHS** Engine'a. Jezyk plynie OD Engine'a DO konsumentow -- to konsumenci adaptuja sie do generycznego API. Terminy konsumentow **NIE MOGA** pojawiac sie w Engine.

```
Product Catalog ──adapts to──> Calculation Engine (OHS)
Emission Factors ──adapts to──> Calculation Engine (OHS)
```

**Kluczowe**: Engine w `language.md` jest opisany jako generalizacja. To znaczy: kazdy obcy termin jest zagrozeniem. Wysoka czulosc weryfikacji.

-> Faza 2

---

## Faza 2: Wykrywanie Naruszen

Przeszukuje kod produkcyjny Engine'a (pomijam testy) pod katem terminow z `language.md` Product Catalog i Emission Factors.

### FootprintCalculator.java -- stringi w contextParameters

| # | Typ | Obcy termin | Lokalizacja | Zrodlo | Co robi kod |
|---|-----|-------------|-------------|--------|-------------|
| V1 | String | `"MROZONKI"` | `FootprintCalculator.java:5` | Product Catalog | Mnozy wklad x1.35 -- narzut cold chain |
| V2 | String | `"NABIAJ"` | `FootprintCalculator.java:16` | Product Catalog | Mnozy wklad x1.12 -- narzut chlodzenia |
| V3 | String | `"CHEMIA"` | `FootprintCalculator.java:20` | Product Catalog | Loguje obliczenie jako hazardous |
| V4 | String | `"SCOPE_3_TRANSPORT"` | `FootprintCalculator.java:8` | Emission Factors | Stosuje korekte transportowa GHG |
| V5 | String | `"GHG_PROTOCOL_V2"` | `FootprintCalculator.java:12` | Emission Factors | Ustawia skale na 6 miejsc dziesietnych |

### ComponentType.java -- enum z obcymi nazwami

| # | Typ | Obcy termin | Lokalizacja | Zrodlo | Co robi kod |
|---|-----|-------------|-------------|--------|-------------|
| V6 | Enum | `MROZONKI_TRANSPORT` | `ComponentType.java:2` | Product Catalog | Typ komponentu -- mroz. + transport |
| V7 | Enum | `NABIAJ_PRZECHOWYWANIE` | `ComponentType.java:3` | Product Catalog | Typ komponentu -- nabiaj + przechowywanie |
| V8 | Enum | `ELEKTRONIKA_PACKAGING` | `ComponentType.java:6` | Product Catalog | Typ komponentu -- elektronika + opakowanie |
| V9 | Enum | `SCOPE_1_DIRECT` | `ComponentType.java:4` | Emission Factors | Typ komponentu -- scope 1 |
| V10 | Enum | `SCOPE_3_LOGISTICS` | `ComponentType.java:5` | Emission Factors | Typ komponentu -- scope 3 logistyka |
| V11 | Enum | `GHG_PROTOCOL_FACTOR` | `ComponentType.java:6` | Emission Factors | Typ komponentu -- wspolczynnik GHG |

**Razem**: 11 naruszen. Zero importow pakietow -- **ArchUnit / deptrac / Nx nie wykryje zadnego**.

Wzorzec jest zawsze ten sam: Engine sprawdza **tozsamosc** (`equals("MROZONKI")`, `SCOPE_1_DIRECT`) zamiast pytac o **zachowanie** (`requiresColdChainSurcharge`, `adjustmentType`). Silnik wie CO liczy zamiast wiedziec JAK liczyc.

### -> Pauza

Znaleziono 11 naruszen (5 stringow, 6 enumow). Czy przejsc do propozycji napraw?

- Tak
- Niektore to falszywe alarmy
- Dodaj kontekst

> **Uzytkownik**: Tak, zaproponuj naprawy.

---

## Faza 3: Propozycje Napraw

Kluczowa obserwacja przed naprawami: wiele naruszen **kolapsuje do tej samej generalizacji**. To dobry znak -- oznacza, ze uogolnienie jest trafne.

---

### Naprawa #1: `"MROZONKI"` + `"NABIAJ"` -- kolaps do cold chain

**Naruszenia V1 + V2**: Dwa rozne stringi, ale **ten sam efekt** -- mnoznik za cold chain.

**Zachowanie V1**: `equals("MROZONKI")` -> mnozy wklad x1.35
**Zachowanie V2**: `equals("NABIAJ")` -> mnozy wklad x1.12

**Uogolnienie**: "Niektorym komponentom nalezy doliczyc narzut za lancuch chlodniczy. Mnoznik zalezy od kontekstu, nie od kategorii produktu."

**Naprawa**: Dwie wlasciwosci na Component:
- `requiresColdChainSurcharge: boolean`
- `coldChainSurchargeFactor: BigDecimal`

**Kto ustawia**: Product Catalog. Wie, ze MROZONKI -> factor=1.35, NABIAJ -> factor=1.12.
**Kto czyta**: Engine. Stosuje mnoznik jesli flaga=true. Nie wie, ze to mrozonki czy nabiaj.

**Kolaps**: V1 i V2 znikaja w jednej generyzacji. Jutro pojawi sie RYBY z factor=1.22 -- zero zmian w Engine.

#### PRZED (V1 + V2)

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  contextParams.get("productCategory")   │
│       │                                 │
│       ├── equals("MROZONKI") ─❌        │
│       │       * 1.35                    │
│       │                                 │
│       └── equals("NABIAJ") ──❌         │
│               * 1.12                    │
│                                         │
│  Engine zna nazwy kategorii ❌          │
│  ArchUnit: "OK, brak importow" ✅      │
└─────────────────────────────────────────┘
```

#### PO

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  if (component.requiresColdChainSurcharge())
│       │                          ✅     │
│       ▼                       generyczny│
│  contribution * component.coldChainSurchargeFactor()
│                                         │
│  Nie wie co to mrozonki ani nabiaj ✅   │
│                                         │
│  Product Catalog ustawia:               │
│    MROZONKI -> coldChain=true, 1.35     │
│    NABIAJ   -> coldChain=true, 1.12     │
│    OWOCE   -> coldChain=false           │
└─────────────────────────────────────────┘
```

---

### Naprawa #1b: `"CHEMIA"` -- hazardous logging

**Naruszenie V3**: `equals("CHEMIA")` -> loguje obliczenie jako hazardous.

**Zachowanie**: Przy produkcie chemicznym, silnik loguje szczegoly obliczenia w dzienniku hazardous.

**Uogolnienie**: "Niektorym komponentom trzeba zalogowac obliczenie jako potencjalnie niebezpieczne."

**Naprawa**: `Component.requiresHazardousAudit: boolean`

**Kto ustawia**: Product Catalog. Wie, ze CHEMIA wymaga audytu.
**Kto czyta**: Engine. Loguje jesli flaga=true. Nie wie, ze to chemia.

#### PRZED (V3)

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  contextParams.get("productCategory")   │
│       │                                 │
│       └── equals("CHEMIA") ──❌         │
│               auditLogger               │
│                .logHazardousCalculation  │
│                                         │
│  Engine zna "CHEMIA" ❌                 │
└─────────────────────────────────────────┘
```

#### PO

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  if (component.requiresHazardousAudit())│
│       │                          ✅     │
│       ▼                       generyczny│
│  auditLogger.logHazardousCalculation    │
│                                         │
│  Nie wie co to chemia ✅                │
│  Product Catalog ustawia:               │
│    CHEMIA -> hazardousAudit=true        │
└─────────────────────────────────────────┘
```

---

### Naprawa #1c: `"SCOPE_3_TRANSPORT"` -- transport adjustment

**Naruszenie V4**: `equals("SCOPE_3_TRANSPORT")` -> stosuje korekte transportowa GHG Protocol.

**Zachowanie**: Przy scope 3 transport, silnik mnozy wklad przez wspolczynnik korekty transportowej.

**Uogolnienie**: "Niektorym komponentom trzeba zastosowac dodatkowy wspolczynnik korekty."

**Naprawa**: `Component.adjustmentFactor: BigDecimal` (wartosc domyslna: 1.0, czyli brak korekty).

**Kto ustawia**: Emission Factors. Wie, ze SCOPE_3_TRANSPORT wymaga korekty transportowej.
**Kto czyta**: Engine. Mnozy przez adjustmentFactor. Nie wie, ze to scope 3 transport.

**Uwaga**: `adjustmentFactor` jest juz obecny w `language.md` Engine'a w operacji `calculate()` -- "Components carry generic properties (...adjustmentFactor...)". To potwierdza, ze uogolnienie jest trafne.

#### PRZED (V4)

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  contextParams.get("scope")             │
│       │                                 │
│       └── equals("SCOPE_3_TRANSPORT") ❌│
│               * ghgProtocolTransport-   │
│                 Adjustment()            │
│                                         │
│  Engine zna zakresy GHG ❌              │
└─────────────────────────────────────────┘
```

#### PO

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  contribution * component.adjustmentFactor()
│       │                          ✅     │
│       ▼                       generyczny│
│  (domyslnie 1.0 = brak korekty)        │
│                                         │
│  Nie wie co to scope 3 ✅               │
│  Emission Factors ustawia:              │
│    SCOPE_3_TRANSPORT -> adj=1.12        │
│    SCOPE_1_DIRECT    -> adj=1.0         │
└─────────────────────────────────────────┘
```

---

### Naprawa #2: `"GHG_PROTOCOL_V2"` -- precyzja regulacyjna

**Naruszenie V5**: `equals("GHG_PROTOCOL_V2")` -> ustawia skale na 6 miejsc dziesietnych.

**Zachowanie**: Przy wspolczynnikach z GHG Protocol V2, silnik wymusza precyzje 6 miejsc.

**Uogolnienie**: "Niektorym obliczeniom trzeba wymusic okreslona precyzje dziesietna."

**Naprawa**: `Component.regulatoryPrecision: int`

**Kto ustawia**: Emission Factors. Wie, ze GHG V2 wymaga 6 miejsc.
**Kto czyta**: Engine. Ustawia `setScale(precision, HALF_UP)`. Nie wie o wersjach protokolu.

#### PRZED (V5)

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  contextParams.get("factorSource")      │
│       │                                 │
│       └── equals("GHG_PROTOCOL_V2") ─❌ │
│               │                         │
│               ▼                         │
│         setScale(6, HALF_UP)            │
│                                         │
│  Engine zna wersje protokolu GHG ❌     │
└─────────────────────────────────────────┘
```

#### PO

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  component.regulatoryPrecision()        │
│       │                          ✅     │
│       ▼                       generyczny│
│  setScale(precision, HALF_UP)           │
│                                         │
│  Nie wie o GHG Protocol ✅              │
│  Emission Factors ustawia:              │
│    GHG_V2 -> regulatoryPrecision=6      │
│    GHG_V3 -> regulatoryPrecision=8      │
└─────────────────────────────────────────┘
```

---

### Naprawa #3: Kolaps enuma ComponentType

**Naruszenia V6-V11**: Enum `ComponentType` koduje tozsamosc downstream'ow zamiast generycznych zachowan.

6 z 9 wartosci to obce terminy. Tylko 3 sa wlasne: `BASE_EMISSION`, `SURCHARGE`, `ADJUSTMENT`.

**Uogolnienie**: Zachowania zakodowane w enumie (`MROZONKI_TRANSPORT` = cold chain + transport adjustment) sa juz pokryte przez wlasciwosci z napraw #1 i #1c:
- `MROZONKI_TRANSPORT` -> `requiresColdChainSurcharge=true` + `adjustmentFactor` dla transportu
- `NABIAJ_PRZECHOWYWANIE` -> `requiresColdChainSurcharge=true` + inna wartosc
- `SCOPE_1_DIRECT` -> `adjustmentFactor=1.0` (brak korekty)
- itd.

**Naprawa**: Usun obce wartosci enuma. Zachowaj: `BASE_EMISSION`, `SURCHARGE`, `ADJUSTMENT`. Zachowania przejmuja wlasciwosci Componentu.

#### PRZED (V6-V11)

```
┌───────────────────────────────────────┐
│  ComponentType (Calculation Engine)   │
│                                       │
│  MROZONKI_TRANSPORT      ❌ Prod.Cat. │
│  NABIAJ_PRZECHOWYWANIE   ❌ Prod.Cat. │
│  ELEKTRONIKA_PACKAGING   ❌ Prod.Cat. │
│  SCOPE_1_DIRECT          ❌ Em.Fact.  │
│  SCOPE_3_LOGISTICS       ❌ Em.Fact.  │
│  GHG_PROTOCOL_FACTOR     ❌ Em.Fact.  │
│  ─────────────────────────────────    │
│  BASE_EMISSION           ✅ wlasny   │
│  SURCHARGE               ✅ wlasny   │
│  ADJUSTMENT              ✅ wlasny   │
└───────────────────────────────────────┘
```

#### PO

```
┌───────────────────────────────────────┐
│  ComponentType (Calculation Engine)   │
│                                       │
│  BASE_EMISSION           ✅          │
│  SURCHARGE               ✅          │
│  ADJUSTMENT              ✅          │
│                                       │
│  Zachowanie przejmuja wlasciwosci:    │
│  - requiresColdChainSurcharge         │
│  - coldChainSurchargeFactor           │
│  - adjustmentFactor                   │
│  - regulatoryPrecision                │
│  - requiresHazardousAudit            │
└───────────────────────────────────────┘
```

---

### -> Pauza: Walidacja napraw

Dla kazdej naprawy:
- **Tak**
- **Nie, upstream musi wiedziec** (wyjasnienie -- moze granica jest zle postawiona)
- **Inny fix** (opisz)

| # | Propozycja | Odpowiedz? |
|---|-----------|-------------|
| #1 | MROZONKI+NABIAJ+CHEMIA -> coldChainSurcharge + hazardousAudit | ? |
| #2 | GHG_PROTOCOL_V2 -> regulatoryPrecision na Component | ? |
| #3 | Kolaps enuma do BASE_EMISSION, SURCHARGE, ADJUSTMENT | ? |

### Odpowiedzi Uzytkownika

**#1 (MROZONKI + NABIAJ -> requiresColdChainSurcharge, CHEMIA -> requiresHazardousAudit)**: Tak.

**#2 (GHG_PROTOCOL_V2 -> regulatoryPrecision na Component)**: **Inny fix.** Precyzja nie powinna byc na Component -- powinna byc ContextParameter `requiredPrecision: int` na wywolaniu `calculate()`. Engine ma juz ContextParameter w slownictwie. To ustawienie per-obliczenie, nie per-komponent.

**#3 (kolaps enuma)**: Tak.

---

## Faza 4: Uwzglednienie Feedbacku

| # | Decyzja | Akcja |
|---|---------|-------|
| #1 | Potwierdzona | Bez zmian. coldChainSurcharge i hazardousAudit na Component. |
| #1b | Potwierdzona | adjustmentFactor na Component -- juz w language.md. |
| #2 | **Inny fix** | Precyzja jako ContextParameter zamiast wlasciwosci Component |
| #3 | Potwierdzona | Usun obce wartosci enuma |

### Zrewidowana Naprawa #2

Uzytkownik ma racje: precyzja jest ustawieniem **per-obliczenie** (wszystkie komponenty w jednym wywolaniu `calculate()` powinny miec ta sama precyzje), nie per-komponent. Engine juz ma `ContextParameter` w swoim slownictwie -- to naturalne miejsce.

Emission Factors przekazuje `requiredPrecision: 6` jako ContextParameter. Engine czyta generyczna liczbe calkowita -- nie nazwe protokolu.

#### PO (zrewidowane)

```
┌─────────────────────────────────────────┐
│  Calculation Engine                     │
│                                         │
│  int precision = contextParameters      │
│       .getInt("requiredPrecision", 2);  │
│       │                          ✅     │
│       ▼                   ContextParam  │
│  setScale(precision, HALF_UP)           │
│                                         │
│  Nie wie o GHG Protocol ✅              │
│  Emission Factors ustawia:              │
│    requiredPrecision=6 w ContextParams  │
└─────────────────────────────────────────┘
```

```java
// Przed: if (factorSource.equals("GHG_PROTOCOL_V2")) { setScale(6, HALF_UP); }
// Po:    int precision = contextParameters.getInt("requiredPrecision", 2);
//        contribution = contribution.setScale(precision, RoundingMode.HALF_UP);
```

**Roznica vs oryginalna propozycja**: Component.regulatoryPrecision nakladalo precyzje per-komponent. Ale precyzja regulacyjna dotyczy calego obliczenia (wszystkich komponentow lacznie) -- jest wlasciwoscia kontekstu wywolania, nie pojedynczego komponentu. ContextParameter to wlasciwy poziom.

---

## Faza 5: Raport

### Podsumowanie

| Metryka | Wartosc |
|---------|---------|
| Moduly przeanalizowane | 3 |
| Naruszenia ogolnie | 11 (5 stringow, 6 enumow) |
| Kolaps do napraw | 4 unikalne naprawy (11 naruszen -> 4 uogolnienia) |
| Potwierdzone bez zmian | 3 |
| Zrewidowane przez uzytkownika | 1 (precyzja: Component -> ContextParameter) |
| Pytania o granice | 0 |

**Zdrowie granic**: **SLABE**. Engine zanieczyszczony jezykiem obu konsumentow -- niewidocznie dla ArchUnit/deptrac/Nx.

### Tabela koncowa naruszen i napraw

| # | Naruszenie | Naprawa | Status |
|---|------------|---------|--------|
| V1 | `equals("MROZONKI")` x1.35 | `component.requiresColdChainSurcharge()` + `coldChainSurchargeFactor()` | Potwierdzona |
| V2 | `equals("NABIAJ")` x1.12 | Kolaps z V1 -- ta sama generyzacja, inny factor | Potwierdzona |
| V3 | `equals("CHEMIA")` audit | `component.requiresHazardousAudit()` | Potwierdzona |
| V4 | `equals("SCOPE_3_TRANSPORT")` | `component.adjustmentFactor()` | Potwierdzona |
| V5 | `equals("GHG_PROTOCOL_V2")` setScale(6) | `contextParameters.getInt("requiredPrecision", 2)` | **Zrewidowana** |
| V6-V11 | 6 obcych wartosci enuma ComponentType | Usun; zachowaj BASE_EMISSION, SURCHARGE, ADJUSTMENT | Potwierdzona |

### Kolaps -- swiadectwo trafnosci

Kluczowa obserwacja: 11 naruszen zkolapsowalo sie do 4 generyzacji. To silny sygnal, ze uogolnienia sa trafne:

| Generyzacja | Pochlaniane naruszenia |
|-------------|----------------------|
| `requiresColdChainSurcharge` + `factor` | V1 (MROZONKI), V2 (NABIAJ), V6 (MROZONKI_TRANSPORT), V7 (NABIAJ_PRZECHOWYWANIE) |
| `requiresHazardousAudit` | V3 (CHEMIA) |
| `adjustmentFactor` | V4 (SCOPE_3_TRANSPORT), V9 (SCOPE_1_DIRECT), V10 (SCOPE_3_LOGISTICS) |
| `requiredPrecision` (ContextParam) | V5 (GHG_PROTOCOL_V2), V11 (GHG_PROTOCOL_FACTOR) |
| enum cleanup | V8 (ELEKTRONIKA_PACKAGING) -- pokryty przez istniejace flagi |

---

## PO: Architektura z czystymi granicami

```
┌──────────────────────────────────────────────────────────────────┐
│                Calculation Engine (GENERALIZACJA)                 │
│                                                                  │
│   FootprintCalculator.java:                                      │
│     component.requiresColdChainSurcharge()      ✅ generyczny    │
│     component.adjustmentFactor()                ✅ generyczny    │
│     component.requiresHazardousAudit()          ✅ generyczny    │
│     contextParameters.getInt("requiredPrecision")  ✅ generyczny │
│                                                                  │
│   ComponentType.java:                                            │
│     BASE_EMISSION  ✅                                            │
│     SURCHARGE      ✅                                            │
│     ADJUSTMENT     ✅                                            │
│                                                                  │
│   Zadnych obcych terminow -- czysty generyczny modul ✅          │
└───────────────────────────────────────────────────────────────────┘
                                │ generyczne API (OHS)
                 ┌──────────────┴──────────────┐
                 │                             │
      ┌──────────▼──────────┐      ┌──────────▼──────────┐
      │   Product Catalog   │      │  Emission Factors    │
      │  ustawia:           │      │  ustawia:            │
      │  MROZONKI:          │      │  SCOPE_3_TRANSPORT:  │
      │   coldChain=true    │      │   adjustmentFactor   │
      │   factor=1.35       │      │   =1.12              │
      │  NABIAJ:            │      │  GHG_V2:             │
      │   coldChain=true    │      │   requiredPrecision  │
      │   factor=1.12       │      │   =6                 │
      │  CHEMIA:            │      │                      │
      │   hazardousAudit    │      │                      │
      │   =true             │      │                      │
      └─────────────────────┘      └──────────────────────┘
```

### Wzorzec

**Zamien sprawdzanie tozsamosci na flagi zachowania.** Engine nie pyta "co to jest?" (MROZONKI? SCOPE_3?) -- pyta "jak mam liczyc?" (cold chain? adjustment? precyzja?). Wiedza domenowa zostaje w modulach downstream. Engine operuje na generycznych wlasciwosciach nie znajac ich pochodzenia.

Jutro Product Catalog doda kategorie RYBY z `coldChainSurchargeFactor=1.18` -- zero zmian w Engine. Emission Factors zaktualizuje GHG Protocol do V4 z `requiredPrecision=10` -- zero zmian w Engine. Generalizacja trzyma.
