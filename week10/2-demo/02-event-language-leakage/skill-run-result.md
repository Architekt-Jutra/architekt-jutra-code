# Linguistic Boundary Verifier -- Wynik Uruchomienia Skilla

## Prompt uzyty do uruchomienia

```
linguistic-boundary-verifier all
```

Alternatywnie, jesli chcesz sprawdzic tylko pare kontekstow:

```
linguistic-boundary-verifier calculation-engine emission-factors
```

**Zakres**: `calculation-engine`, `emission-factors`, `product-catalog`

---

## PRZED: Architektura z niewidocznym couplingiem eventowym

```
┌───────────────────────────────────────────────────────────────────┐
│                 Calculation Engine (uogolnienie)                  │
│                                                                   │
│   handle(EmissionFactorUpdated)           ❌ event z Emission F. │
│     event.getGhgScope() == "SCOPE_1"     ❌ termin GHG          │
│   handle(AuditorLockedCategory)           ❌ event z Emission F. │
│     event.getCategoryId(), getLockExpiry() ❌ terminy audytorskie │
│   handle(ProductCategoryChanged)          ❌ event z Prod. Cat.  │
│     event.isMrozonka()                    ❌ termin katalogowy   │
│   handle(ProductCreated)                  ❌ event z Prod. Cat.  │
│     event.getSku(), getKategoriaProdukt() ❌ terminy katalogowe  │
│                                                                   │
│   narzedzia do analizy zaleznosci: "kierunek danych OK" ✅       │
│   Granice lingwistyczne: ❌❌❌ 4 handlery pelne obcego jezyka   │
└──────────────────────────────┬────────────────────────────────────┘
                               │ OHS (generyczne API)
                ┌──────────────┴──────────────┐
                │                             │
     ┌──────────▼──────────┐      ┌──────────▼──────────┐
     │   Product Catalog   │      │ Emission Factor Mgmt │
     │   pub: ProductCat-  │      │ pub: EmissionFactor-  │
     │     egoryChanged    │      │   Updated, Auditor-   │
     │   pub: ProductCre-  │      │   LockedCategory      │
     │     ated            │      │                       │
     └─────────────────────┘      └───────────────────────┘

     Fizyczny kierunek danych: upstream -> downstream = OK
     Kierunek jezyka: upstream -> downstream = NARUSZENIE
     Dane plyna poprawnie, ale JEZYK upstream'ow wcieka do silnika
```

---

## Faza 1: Odkrywanie i Parsowanie

Czytam `language.md` z trzech modulow. Rekonstruuje graf relacji z sekcji Integration Points.

| # | Modul | Rola | Slownik | Eventy |
|---|-------|------|---------|--------|
| 1 | Footprint Calculation Engine | **Generalizacja** -- nie wie co wycenia ani skad dane | 7 terminow | FootprintCalculated, ComponentInvalidated |
| 2 | Emission Factor Management | Specyficzny -- wspolczynniki emisji, GHG, audytorzy | 6 terminow | EmissionFactorUpdated, AuditorLockedCategory |
| 3 | Product Catalog | Specyficzny -- produkty, kategorie, SKU | 5 terminow | ProductCategoryChanged, ProductCreated |

**Relacje**: Oba moduly specyficzne publikuja eventy. Engine je subskrybuje (OHS). Jezyk plynie OD Engine'a DO konsumentow -- nigdy odwrotnie.

**Kluczowe**: Engine jako generalizacja (`calculation-engine/language.md:4`) nie powinien zawierac ZADNEGO obcego slownictwa. Ani jednego terminu z Emission Factors. Ani jednego z Product Catalog. To jest caly sens generalizacji -- dziala tak samo niezaleznie od zrodla danych.

-> Faza 2

---

## Faza 2: Wykrywanie Naruszen

Grepuje terminy z language.md kazdego modulu w kodzie pozostalych. Pomijam testy (`**/test/**`, `**/*Test.java`). Skupiam sie na produkcyjnych handlerach.

### Naruszenia znalezione

| # | Typ | Obcy termin/event | Lokalizacja | Zrodlo | Co robi kod |
|---|-----|-------------------|-------------|--------|-------------|
| V1 | Event w obcym jezyku | `EmissionFactorUpdated` + `getGhgScope()`, `getFactorId()` | `EmissionFactorEventHandler.java:23-32` | Emission Factors | Rozgalezienie: SCOPE_1 -> typ "DIRECT", reszta -> "INDIRECT". Odswieza komponent nowa wartoscia. |
| V2 | Event w obcym jezyku | `ProductCategoryChanged` + `isMrozonka()`, `getKategoriaProdukt()` | `ProductCatalogEventHandler.java:20-29` | Product Catalog | if mrozonka -> mnoznik (applyFrozenProductMultiplier), else -> reassign drzewa komponentow |
| V3 | Event w obcym jezyku | `AuditorLockedCategory` + `getCategoryId()`, `getLockExpiry()` | `EmissionFactorEventHandler.java:36-39` | Emission Factors | Invaliduje komponenty po categoryId na czas lockExpiry |
| V4 | Event w obcym jezyku | `ProductCreated` + `getSku()`, `getKategoriaProdukt()` | `ProductCatalogEventHandler.java:33-39` | Product Catalog | Inicjalizuje nowy komponent z SKU i kategoria |

**Uwaga o V4**: `ProductCreated` to wariant tego samego antywzorca co V2 -- jezyk Product Catalog w kodzie Engine'a. Laczne z V2 jako jeden wezel naprawy, bo oba zyja w `ProductCatalogEventHandler`.

**Dlaczego narzedzia do analizy zaleznosci (ArchUnit, deptrac, Nx itp.) tego nie widza**: Fizyczny kierunek danych jest poprawny -- upstream publikuje, downstream subskrybuje. Ale typ eventu, nazwy pol, logika branchowania -- to wszystko jest JEZYKIEM upstream'u, ktory wcieka do kodu generycznego silnika. Import `emissionfactors.events.EmissionFactorUpdated` w `EmissionFactorEventHandler.java:3` jest widoczny, ale narzedzia traktuja go jako "poprawny kierunek". Problem nie jest w kierunku danych, lecz w kierunku JEZYKA.

### Diagram naruszen

```
     Emission Factor Mgmt                Product Catalog
     ┌───────────────────┐               ┌───────────────────┐
     │ pub: EmissionFactor│               │ pub: ProductCat-  │
     │      Updated       │               │   egoryChanged    │
     │ pub: AuditorLocked │               │ pub: ProductCre-  │
     │      Category      │               │   ated            │
     └────────┬───────────┘               └────────┬──────────┘
              │                                    │
              │ V1: getGhgScope()=="SCOPE_1"       │ V2: isMrozonka()
              │ V3: getCategoryId(), getLockExpiry()│ V4: getSku(), getKategoriaProdukt()
              ▼                                    ▼
     ┌──────────────────────────────────────────────────────┐
     │              Calculation Engine (uogolnienie)         │
     │                                                       │
     │  ❌ EmissionFactorUpdated  ❌ ProductCategoryChanged  │
     │  ❌ AuditorLockedCategory  ❌ ProductCreated          │
     │  ❌ ghgScope, factorId     ❌ mrozonka, kategoriaProdukt │
     │                                                       │
     │  Generalizacja zlamana -- silnik zna detale emisji    │
     │  I detale katalogu produktow                          │
     └───────────────────────────────────────────────────────┘
```

### -> Pauza

Znaleziono 4 naruszenia eventowe (3 unikalne wezly naprawy -- V2 i V4 laczone). Przejsc do propozycji napraw?

> **Uzytkownik**: Tak.

---

## Faza 3: Propozycje Napraw

Dla kazdego naruszenia stosuje heurystyke eventowa:

> **Czy publikujacy wie CO ma sie stac?**
> - **Tak**, zna nastepny krok -> **komenda** w jezyku odbiorcy (lub generycznym wspoldzielonym)
> - **Nie**, jedynie oglasza co sie stalo -> **event + ACL** (translacja na granicy)

Fizyczny kierunek danych != kierunek lingwistyczny. To ze dane plyna "poprawnie" nie znaczy, ze jezyk nie wcieka.

---

### V1: `EmissionFactorUpdated` -- EmissionFactorEventHandler.java:23-32

**Analiza kodu**:
```java
if (event.getGhgScope().equals("SCOPE_1")) {
    calculationService.refreshComponent(componentId, newValue, "DIRECT");
} else {
    calculationService.refreshComponent(componentId, newValue, "INDIRECT");
}
```

Engine czyta `ghgScope` z eventu i tlumaczy na swoje pojecia (DIRECT/INDIRECT). Problem: ta translacja siedzi WEWNATRZ Engine'a zamiast na granicy.

**Heurystyka**: Emission Factor Management aktualizuje wspolczynnik, bo audytor wprowadzil nowa wartosc albo zmienil sie protokol GHG. Z perspektywy Factor Mgmt proces jest zakonczony -- wspolczynnik zaktualizowany, koniec. Factor Mgmt nie wie i nie dba, ze Engine odswieza komponenty. -> **Event + ACL**

#### PRZED ❌

```
┌─────────────────────────┐
│  Emission Factor Mgmt   │
│  pub: EmissionFactor-    │
│       Updated            │
│  (faktId, ghgScope,     │
│   auditorId, protocol-  │
│   Version, newValue,    │
│   effectiveDate)        │
└──────────┬──────────────┘
           │ event bezposrednio w Engine
           │
           ▼
┌─────────────────────────┐
│  Calculation Engine      │
│                          │
│  handle(EmissionFactor-  │  ❌ typ eventu z Emission Factors
│         Updated)         │
│  event.getGhgScope()    │  ❌ termin GHG w kodzie Engine'a
│  == "SCOPE_1" ?          │  ❌ string literal z Emission F.
│    -> DIRECT / INDIRECT  │
│                          │
│  Generalizacja zlamana   │
└──────────────────────────┘
```

#### PO ✅

```
┌─────────────────────────┐
│  Emission Factor Mgmt   │
│  pub: EmissionFactor-    │
│       Updated            │
│  (bez zmian -- upstream  │
│   nie wie o Engine)      │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  ACL (na granicy)        │
│                          │
│  ghgScope SCOPE_1        │
│    -> refreshType=DIRECT │  translacja slow
│  ghgScope !=SCOPE_1      │  Emission Factors
│    -> refreshType=       │  na slowa Engine'a
│       INDIRECT           │
│  factorId -> componentId │
└──────────┬──────────────┘
           │ ComponentRefreshRequested(componentId, newValue, refreshType)
           ▼
┌─────────────────────────┐
│  Calculation Engine      │  ✅ zero terminow GHG
│                          │
│  handle(ComponentRefresh-│     wlasny event
│         Requested)       │     w jezyku Engine'a
│  refreshComponent(       │
│    componentId,          │
│    newValue,             │
│    refreshType)          │
└──────────────────────────┘
```

**Translacja w ACL**: `EmissionFactorUpdated` -> `ComponentRefreshRequested(componentId, newValue, DIRECT|INDIRECT)`

Engine nie importuje juz `emissionfactors.events.EmissionFactorUpdated`. Handler przyjmuje `ComponentRefreshRequested` -- event zdefiniowany w jezyku Engine'a.

### -> Pauza V1

Czy ta naprawa ma sens? (Tak / Nie, upstream musi wiedziec / Inny fix)

> **Uzytkownik**: Tak.

---

### V2 + V4: `ProductCategoryChanged` + `ProductCreated` -- ProductCatalogEventHandler.java

**Analiza kodu (V2)**:
```java
String category = event.getKategoriaProdukt();
if (event.isMrozonka()) {
    calculationService.applyFrozenProductMultiplier(componentId, category);
} else {
    calculationService.reassignComponentTree(componentId, category);
}
```

**Analiza kodu (V4)**:
```java
calculationService.initializeComponent(
    ComponentId.from(event.getProductId()),
    event.getSku(),
    event.getKategoriaProdukt()
);
```

Engine czyta `kategoriaProdukt`, `isMrozonka`, `sku` -- pelne slownictwo Product Catalog. A metoda `applyFrozenProductMultiplier` to juz nawet nie translacja, tylko zabetonowanie konceptu "mrozonka" w nazwie metody serwisu Engine'a.

**Heurystyka**: Czy Product Catalog wie, co Engine powinien zrobic po reklasyfikacji produktu?

Tu odpowiedz nie jest oczywista -- moge wyobrazic sobie oba scenariusze. Dlatego prezentuje OBA warianty naprawy i pytam uzytkownika.

**Wariant A (ACL)**: Product Catalog jedynie oglasza "zmienila sie kategoria produktu". Nie wie i nie dba, ze Engine przelicza slad weglowy. -> Event + ACL.

**Wariant B (Komenda)**: Istnieje orkiestrator (np. Budget Ledger), ktory WIE, ze reklasyfikacja do kategorii wysokoemisyjnej MUSI natychmiast wywolac przeliczenie. Ten orkiestrator wysyla komende do Engine'a w jego jezyku. -> Komenda.

#### PRZED ❌ (wspolny dla V2 i V4)

```
┌──────────────────────────┐
│  Product Catalog          │
│  pub: ProductCategory-    │
│       Changed             │
│  (productId, kategoria-  │
│   Produkt, isMrozonka,   │
│   previousCategory)      │
│  pub: ProductCreated      │
│  (productId, sku,        │
│   kategoriaProdukt)      │
└──────────┬───────────────┘
           │ eventy bezposrednio w Engine
           ▼
┌──────────────────────────┐
│  Calculation Engine       │
│                           │
│  handle(ProductCategory-  │  ❌ typ eventu z Prod. Catalog
│         Changed)          │
│  event.isMrozonka()      │  ❌ "mrozonka" w Engine'u?!
│  event.getKategoria-     │  ❌ "kategoriaProdukt" w Engine
│         Produkt()        │
│  applyFrozenProduct-     │  ❌ metoda z nazwa "frozen product"
│         Multiplier()     │     w generycznym silniku
│                           │
│  handle(ProductCreated)   │  ❌ inicjalizacja z SKU i kategoria
│  event.getSku()          │
│                           │
│  Generalizacja zlamana   │
└──────────────────────────┘
```

#### PO -- Wariant A: ACL ✅

```
┌──────────────────────────┐
│  Product Catalog          │
│  pub: ProductCategory-    │
│       Changed             │
│  pub: ProductCreated      │
│  (bez zmian)             │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│  ACL (na granicy)         │
│                           │
│  ProductCategoryChanged:  │
│    isMrozonka=true        │
│      -> ComponentMulti-   │  translacja: "mrozonka"
│         plierChange-      │  -> "mnoznik komponentu"
│         Requested(id,     │
│         multiplier=1.35,  │
│         group=COLD_CHAIN) │
│    isMrozonka=false       │
│      -> ComponentTree-    │
│         Reassignment-     │  translacja: "kategoria"
│         Requested(id,     │  -> "przesuniecie drzewa"
│         newGroup)         │
│                           │
│  ProductCreated:          │
│    -> ComponentInit-      │  translacja: init
│       Requested(id,       │  w jezyku Engine'a
│       sourceRef, group)   │
└──────────┬───────────────┘
           │ eventy w jezyku Engine'a
           ▼
┌──────────────────────────┐
│  Calculation Engine       │  ✅ zero terminow katalogowych
│                           │
│  handle(ComponentMulti-   │     wlasne eventy
│    plierChangeRequested)  │
│  handle(ComponentTree-    │
│    ReassignmentRequested) │
│  handle(ComponentInit-    │
│    Requested)             │
└──────────────────────────┘
```

#### PO -- Wariant B: Komenda z orkiestratora ✅

```
┌──────────────────────────┐
│  Product Catalog          │
│  pub: ProductCategory-    │       ┌──────────────────────┐
│       Changed             │──────>│  Budget Ledger        │
│  pub: ProductCreated      │       │  (orkiestrator)       │
└──────────────────────────┘       │                       │
                                    │  WIE, ze reklasyfi-   │
                                    │  kacja do kategorii   │
                                    │  wysokoemisyjnej MUSI │
                                    │  wywolac przeliczenie │
                                    │  + ocene budzetu CO2  │
                                    └──────────┬───────────┘
                                               │ komenda w jezyku Engine'a
                                               │ reassignComponentTree(id, group)
                                               │ applyMultiplier(id, 1.35, COLD_CHAIN)
                                               ▼
                                    ┌──────────────────────┐
                                    │  Calculation Engine   │  ✅ dostaje
                                    │  (uogolnienie)        │     komende w
                                    │                       │     swoim jezyku
                                    └──────────────────────┘
```

W wariancie B: `ProductCatalogEventHandler` znika z Engine'a calkowicie. Budget Ledger subskrybuje event od Product Catalog (bo jest specyficzny -- wie o kontekscie biznesowym), a nastepnie WYWOLUJE Engine uzywajac istniejacego generycznego API (`reassignComponentTree`, `initializeComponent`).

### -> Pauza V2

Ktory wariant? ACL (A) czy komenda z orkiestratora (B)?

> **Uzytkownik**: Nie, upstream faktycznie musi wiedziec. Budget Ledger orkiestruje ten krok -- wie, ze reklasyfikacja do kategorii wysokoemisyjnej MUSI natychmiast wywolac przeliczenie i ocene budzetu CO2. To zamaskowana komenda, nie event.

**Wniosek**: Wariant B -- komenda. Subskrypcja eventowa `ProductCategoryChanged` w Engine'u to zamaskowana komenda. Prawdziwy wlasciciel przeplywu (Budget Ledger) WIE, ze po reklasyfikacji MUSI nastapic przeliczenie. To nie jest "cos sie stalo, reaguj jak chcesz" -- to jest "przelicz natychmiast, bo musimy ocenic budzet."

Handler `ProductCatalogEventHandler` w Engine'u do usuniecia. Budget Ledger przejmuje odpowiedzialnosc za wywolanie Engine'a.

---

### V3: `AuditorLockedCategory` -- EmissionFactorEventHandler.java:36-39

**Analiza kodu**:
```java
String categoryId = event.getCategoryId();
calculationService.invalidateComponentsByCategory(categoryId, event.getLockExpiry());
```

Engine czyta `categoryId` i `lockExpiry` -- terminy ze swiata audytorow. Metoda `invalidateComponentsByCategory` przyjmuje `categoryId` ktory jest konceptem Emission Factors, nie Engine'a.

**Heurystyka**: Emission Factor Management blokuje kategorie bo audytor rozpoznal problem compliance'owy. Z perspektywy Factor Mgmt -- zablokowano, koniec. Factor Mgmt NIE WIE, ze Engine powinien invalidowac obliczenia. -> **Event + ACL**

#### PRZED ❌

```
┌─────────────────────────┐
│  Emission Factor Mgmt   │
│  pub: AuditorLocked-     │
│       Category           │
│  (auditorId, categoryId,│
│   lockExpiry)            │
└──────────┬──────────────┘
           │ event bezposrednio w Engine
           ▼
┌─────────────────────────┐
│  Calculation Engine      │
│                          │
│  handle(AuditorLocked-   │  ❌ "auditor" w generycznym silniku
│         Category)        │
│  event.getCategoryId()  │  ❌ "categoryId" z Emission Factors
│  event.getLockExpiry()   │  ❌ "lockExpiry" -- koncept blokady
│                          │     audytorskiej w Engine'u?
│  invalidateComponents-   │
│    ByCategory(           │
│    categoryId, expiry)   │
│                          │
│  Generalizacja zlamana   │
└──────────────────────────┘
```

#### PO ✅

```
┌─────────────────────────┐
│  Emission Factor Mgmt   │
│  pub: AuditorLocked-     │
│       Category           │
│  (bez zmian -- upstream  │
│   nie wie o Engine)      │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  ACL (na granicy)        │
│                          │
│  categoryId -> groupId   │  translacja:
│  lockExpiry -> horizon   │  terminy audytorskie
│                          │  -> terminy Engine'a
└──────────┬──────────────┘
           │ ComponentInvalidationRequested(groupId, horizon)
           ▼
┌─────────────────────────┐
│  Calculation Engine      │  ✅ zero terminow audytorskich
│                          │
│  handle(ComponentInvali- │     wlasny event
│    dationRequested)      │     w jezyku Engine'a
│  invalidateComponents-   │
│    ByGroup(groupId,      │
│    horizon)              │
└──────────────────────────┘
```

**Translacja w ACL**: `AuditorLockedCategory` -> `ComponentInvalidationRequested(groupId, horizon)`

Zmiana nazwy metody: `invalidateComponentsByCategory` -> `invalidateComponentsByGroup` -- "category" to termin Emission Factors, "group" to termin Engine'a.

### -> Pauza V3

Czy ta naprawa ma sens? (Tak / Nie, upstream musi wiedziec / Inny fix)

> **Uzytkownik**: Tak.

---

## Faza 4: Uwzglednienie Feedbacku

| # | Decyzja | Wynik |
|---|---------|-------|
| V1 | Zaakceptowana | ACL: `EmissionFactorUpdated` -> `ComponentRefreshRequested(componentId, newValue, DIRECT\|INDIRECT)` |
| V2+V4 | **Upstream musi wiedziec** -- komenda | Budget Ledger orkiestruje: subskrybuje eventy od Product Catalog, wywoluje Engine'a komenda. `ProductCatalogEventHandler` do usuniecia. |
| V3 | Zaakceptowana | ACL: `AuditorLockedCategory` -> `ComponentInvalidationRequested(groupId, horizon)` |

### Szczegoly V2+V4: Przejscie z subskrypcji na komende

**Przed** (Engine zna Product Catalog):
```java
// USUNAC: ProductCatalogEventHandler.java w calculation-engine
@EventListener
public void handle(ProductCategoryChanged event) {
    if (event.isMrozonka()) {
        calculationService.applyFrozenProductMultiplier(...);
    } else {
        calculationService.reassignComponentTree(...);
    }
}
```

**Po** (Budget Ledger orkiestruje):
```java
// NOWE: w Budget Ledger -- orkiestrator
@EventListener
public void handle(ProductCategoryChanged event) {
    // Budget Ledger WIE o kontekscie biznesowym
    if (event.isMrozonka()) {
        calculationEngine.applyMultiplier(
            ComponentId.from(event.getProductId()),
            BigDecimal.valueOf(1.35),
            "COLD_CHAIN"
        );
    } else {
        calculationEngine.reassignComponentTree(
            ComponentId.from(event.getProductId()),
            mapToGroup(event.getKategoriaProdukt())
        );
    }
    // ... nastepnie ocena budzetu CO2
    budgetAssessment.evaluate(...);
}
```

Kluczowa roznica: logika translacji `isMrozonka -> mnoznik` przenoszona z generycznego Engine'a do specyficznego Budget Ledger. Engine nie wie juz o mrozonkach -- dostaje generyczne wywolania `applyMultiplier` i `reassignComponentTree`.

---

## Faza 5: Raport Koncowy

### Podsumowanie

| Metryka | Wartosc |
|---------|---------|
| Moduly przeanalizowane | 3 |
| Naruszenia znalezione | 4 (w 3 wezlach naprawy) |
| ACL potwierdzone | 2 (V1, V3) |
| Komenda (orkiestrator) | 1 (V2+V4) |
| Pytania o granice | 1 -- Budget Ledger jako wlasciciel przeplywu reklasyfikacji |

### Mapa Relacji -- Stan po naprawach

```
     Emission Factor Mgmt                Product Catalog
     ┌───────────────────┐               ┌───────────────────┐
     │ pub: EmissionFactor│               │ pub: ProductCat-  │
     │      Updated       │               │   egoryChanged    │
     │ pub: AuditorLocked │               │ pub: ProductCre-  │
     │      Category      │               │   ated            │
     └────────┬───────────┘               └────────┬──────────┘
              │                                    │
              ▼                                    │
     ┌────────────────────┐                        │
     │ ACL (V1)           │                        │
     │ EmissionFactor-    │                        │
     │   Updated ->       │                        ▼
     │   ComponentRefresh-│               ┌────────────────────┐
     │   Requested        │               │ Budget Ledger       │
     ├────────────────────┤               │ (orkiestrator V2)   │
     │ ACL (V3)           │               │ subskrybuje eventy  │
     │ AuditorLocked-    │               │ od Product Catalog,  │
     │   Category ->      │               │ wywoluje Engine     │
     │   ComponentInvali- │               │ komendami            │
     │   dationRequested  │               └────────┬───────────┘
     └────────┬───────────┘                        │ komendy w jezyku
              │ eventy w jezyku                    │ Engine'a
              │ Engine'a                           │
              ▼                                    ▼
     ┌──────────────────────────────────────────────────────┐
     │              Calculation Engine (uogolnienie)         │
     │                                                       │
     │  handle(ComponentRefreshRequested)       ✅           │
     │  handle(ComponentInvalidationRequested)  ✅           │
     │  reassignComponentTree(id, group)        ✅           │
     │  applyMultiplier(id, factor, type)       ✅           │
     │  initializeComponent(id, ref, group)     ✅           │
     │                                                       │
     │  Zadnych obcych terminow -- generalizacja czysta      │
     └───────────────────────────────────────────────────────┘
```

### Naruszenia z Naprawami

| # | Naruszenie | Typ naprawy | Naprawa | Status |
|---|------------|-------------|---------|--------|
| V1 | `handle(EmissionFactorUpdated)` + `getGhgScope()=="SCOPE_1"` | ACL | `EmissionFactorUpdated` -> `ComponentRefreshRequested(componentId, newValue, DIRECT\|INDIRECT)` | Potwierdzona |
| V2 | `handle(ProductCategoryChanged)` + `isMrozonka()`, `getKategoriaProdukt()` | Komenda | Budget Ledger orkiestruje: subskrybuje od Product Catalog, wywoluje Engine komenda. Usuniecie `ProductCatalogEventHandler`. | Potwierdzona -- upstream orkiestruje |
| V3 | `handle(AuditorLockedCategory)` + `getCategoryId()`, `getLockExpiry()` | ACL | `AuditorLockedCategory` -> `ComponentInvalidationRequested(groupId, horizon)` | Potwierdzona |
| V4 | `handle(ProductCreated)` + `getSku()`, `getKategoriaProdukt()` | Komenda | Lacznie z V2 -- Budget Ledger przejmuje. | Potwierdzona -- j.w. |

### Aktualizacje language.md

**calculation-engine/language.md** -- dodac:
- Events (odbierane): `ComponentRefreshRequested`, `ComponentInvalidationRequested`
- Operations: `applyMultiplier`, `initializeComponent` (juz istnieja, ale nazwy do generyzacji)
- Usunac: wzmianki o bezposredniej subskrypcji eventow z upstream'ow

**emission-factors/language.md** -- bez zmian (upstream nie wie o ACL)

**product-catalog/language.md** -- bez zmian (upstream nie wie o zmianie wzorca)

### Kluczowy Wniosek

Wszystkie 4 naruszenia realizuja ten sam antywzorzec: **"opublikuj event, pozwol downstream'owi nasluchiwac" -- BEZ translacji na granicy**. Fizycznie architektura wyglada na rozprzezona (eventy, brak importow domenowych). Lingwistycznie -- jezyk upstream'ow zalal kod generycznego silnika.

Heurystyka **"Czy publikujacy wie CO ma sie stac?"** rozroznia dwa fundamentalnie rozne swiaty:

| Scenariusz | Przyklad | Wzorzec |
|------------|----------|---------|
| Upstream nie wie, co nastapi | V1: Factor Mgmt aktualizuje wspolczynnik. Koniec. | **Event + ACL** -- translacja na granicy |
| Upstream nie wie, co nastapi | V3: Factor Mgmt blokuje kategorie. Koniec. | **Event + ACL** -- translacja na granicy |
| Orkiestrator wie dokladnie | V2+V4: Budget Ledger WIE, ze reklasyfikacja MUSI wywolac przeliczenie | **Komenda** -- subskrypcja to zamaskowana komenda |

**Anty-lekcja**: Zamiana bezposrednich wywolan na eventy ("bo eventy sa luzno sprzezione") nie rozwiazuje problemu. Bez ACL na granicy zamieniasz sprzezenie importowe na sprzezenie lingwistyczne -- niewidoczne, trudniejsze do wykrycia, a rownie bolacze.

Generalizacja Engine'a zostanie przywrocona dopiero gdy jego kod domenowy nie bedzie zawierac **ani jednego** obcego terminu.
