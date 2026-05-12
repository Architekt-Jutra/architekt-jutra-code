# Linguistic Boundary Verifier - Narracja Wykonania

## Prompt uzytego do uruchomienia

```
linguistic-boundary-verifier all
```

> Tryb pojedynczej pary: `linguistic-boundary-verifier product-catalog budget-ledger`

---

## PRZED: Architektura z blednym kierunkiem API

```
┌──────────────────┐  getFactorForCategory()  ┌──────────────────┐
│  Product Catalog │ ────────────────────❌──> │ Emission Factors │
│  (specyficzny)   │  importuje: WskaznikEmisji│ (specyficzny)    │
│                  │  Zakres — omija silnik!   │                  │
└──────────────────┘                           └──────────────────┘
                                                      │
      ┌─────────────────────────┐                     │ (wewnetrzny
      │   Calculation Engine    │  <nie uzyty>        │  dostawca)
      │   (uogolnienie)        │                      │
      └─────────────────────────┘ ◄───────────────────┘

┌─────────────────┐  debituBudzet(zamowienieId, ┌──────────────────────┐
│   Sales Module  │  produkty)                  │  Emission Budget     │
│   (specyficzny) │ ─────────────────────❌───> │  Ledger (uogolnienie)│
└─────────────────┘  jezyk sprzedazowy!         └──────────────────────┘

narzedzia do analizy zaleznosci (ArchUnit, deptrac): ✅ "zaleznos OK, specific->specific / specific->generic"
Granice lingwistyczne:                               ❌ V1: ominieto uogolnienie, V2: obce slownictwo w API
```

---

**Wywolanie**: `linguistic-boundary-verifier all`
**Moduly**: `calculation-engine`, `budget-ledger`, `product-catalog`, `emission-factors`, `sales`

---

## Faza 1: Odkrywanie i Parsowanie

| Modul | Rola | Kluczowe Terminy |
|-------|------|------------------|
| **Footprint Calculation Engine** | Uogolnienie (Pricing Archetype) — oblicza slad weglowy. Nie wie o produktach, kategoriach, zrodlach wskaznikow. | `FootprintResult`, `CalculationContext`, `ProductId`, `AsOfDate`, `ComponentTree` |
| **Emission Budget Ledger** | Uogolnienie (Accounting Archetype) — generyczny ledger budzetow emisji. Nie wie o kontekstach biznesowych (sprzedaz, zwroty, korekty). | `Account`, `AccountId`, `Entry`, `DebitEntry`, `CreditEntry`, `Balance`, `TransactionId` |
| **Product Catalog** | Specyficzny — produkty, kategorie, SKU. | `Produkt`, `ProduktId`, `Kategoria`, `SKU`, `AtrybutProduktu` |
| **Emission Factor Management** | Specyficzny — wskazniki emisji, zakresy, GHG Protocol, audytorzy. | `WskaznikEmisji`, `WskaznikId`, `Zakres`, `Audytor`, `ProtocolGHG` |
| **Sales Module** | Specyficzny — zamowienia, klienci, statusy sprzedazy. | `Zamowienie`, `ZamowienieId`, `Klient`, `Produkty`, `StatusZamowienia` |

Zrekonstruowany graf relacji z `language.md`:
- **Calculation Engine** (OHS) — konsumenci: Product Catalog, Sales, Reporting
- **Budget Ledger** (OHS) — konsumenci: Sales, Returns, Manual Adjustments
- **Emission Factors** — wewnetrzny dostawca danych dla Calculation Engine
- Product Catalog i Sales sa modulami specyficznymi, ktore powinny adaptowac sie do generycznych API

-> Faza 2

---

## Faza 2: Wykrywanie Naruszen

Skanowanie kodu w kazdym module pod katem terminow z `language.md` innych modulow. Pomijam testy (`**/test/**`, `**/*Test.java`).

```
SKAN: Product Catalog → szukam terminow Emission Factors...
  ProductFootprintService.java:25 — emissionFactorService.getFactorForCategory()
  ProductFootprintService.java:30 — WskaznikEmisji, Zakres.SCOPE_1
  ❌ Product Catalog omija Calculation Engine, wywoluje Emission Factors bezposrednio

SKAN: Sales → szukam terminow Budget Ledger...
  SalesService.java:29 — budgetService.debituBudzet(zamowienieId, produkty)
  ❌ Kierunek OK (specyficzny->generyczny), ale slownictwo sprzedazowe w API Ledgera
```

| # | Typ | Termin/Wywolanie | Lokalizacja | Zrodlo | Co robi kod |
|---|-----|-----------------|-------------|--------|-------------|
| V1 | API omija uogolnienie | `emissionFactorService.getFactorForCategory(kategoria)` | `ProductFootprintService.java:25` | Emission Factors | Product Catalog importuje `WskaznikEmisji`, `Zakres` i sam liczy footprint — omija Calculation Engine |
| V2 | API w niewlasciwym jezyku | `budgetService.debituBudzet(zamowienieId, produkty)` | `SalesService.java:29` | Sales | Sales uzywa sprzedazowego slownictwa (`debituBudzet`, `zamowienieId`, `produkty`) w wywolaniu do generycznego Ledgera |

### Analiza: dlaczego to naruszenia?

**Heurystyka generycznosci:**

> **Bardziej generyczne nie adaptuje sie do specyficznego. To specyficzny adaptuje sie do generycznego. 50 typow zamowien adaptuje sie do 1 API Ledgera — nie Ledger adaptuje sie do 50 typow zamowien.**

**V1 — kontrola kierunku:**
- Product Catalog (specyficzny) -> Emission Factors (specyficzny): specyficzny wywoluje specyficzny ❌
- Oba moduly sa na tym samym poziomie generycznosci, ale miedzy nimi stoi uogolnienie (Calculation Engine), ktore celowo abstrahuje Emission Factors
- Product Catalog powinien uzywac `calculateFootprint()` — **jedynego slusznego API**
- Omijajac Engine, Product Catalog sam musi rozumiec `Zakres`, `WskaznikEmisji` — wiedza, ktora nalezy do silnika

**V2 — kontrola kierunku:**
- Sales (specyficzny) -> Budget Ledger (uogolnienie): kierunek POPRAWNY ✅
- Ale slownictwo BLEDNE ❌: `debituBudzet(zamowienieId, produkty)` to jezyk Salesa, nie Ledgera
- Ledger mowi: `createEntry(AccountId, Entry)` — generycznie, bez wiedzy o zamowieniach

### Diagram naruszen

```
           ┌─────────────────────────┐
           │   Calculation Engine    │
           │   (uogolnienie)        │  <── powinien byc uzywany!
           │   calculateFootprint()  │
           └────────────┬────────────┘
                        │ (wewnetrznie uzywa)
                        ▼
┌──────────────────┐  getFactorForCategory()  ┌──────────────────┐
│  Product Catalog │ ═══════════════════❌══> │ Emission Factors │
│                  │  V1: omija silnik,       │                  │
│                  │  importuje WskaznikEmisji│                  │
└──────────────────┘                          └──────────────────┘


┌─────────────────┐  debituBudzet(zamowienieId, ┌──────────────────────┐
│   Sales Module  │  produkty)                  │  Emission Budget     │
│                 │ ═══════════════════❌══════>│  Ledger              │
│                 │  V2: kierunek OK,           │  "Nie wie o sprzedazy│
└─────────────────┘  slownictwo sprzedazowe!    │   zwrotach, korektach│
                                                └──────────────────────┘
```

### -> Pauza

Wykryto 2 naruszenia. Kontynuowac z propozycjami poprawek? (Tak / Niektore to falszywe alarmy / Dodaj kontekst)

> **Uzytkownik**: "Tak."

---

## Faza 3: Propozycje Poprawek

### Poprawka V1: Product Catalog -> Calculation Engine (nie Emission Factors)

**Kontrola kierunku (Step 1 z SKILL.md):**
- Product Catalog (specyficzny) -> Emission Factors (specyficzny) przez glowe Calculation Engine (uogolnienie)
- Kierunek: **ZLY** — nie dlatego ze generic->specific, ale dlatego ze omija uogolnienie, ktore celowo hermetyzuje Emission Factors
- Poprawka: przekieruj na API uogolnienia

**Co robi kod dzisiaj:**

```java
// ProductFootprintService.java (Product Catalog)
public double obliczSladWeglowyProduktu(Produkt produkt) {
    WskaznikEmisji wskaznik = emissionFactorService.getFactorForCategory(
        produkt.getKategoria()
    );
    double footprint = produkt.getWaga() * wskaznik.getWartosc(Zakres.SCOPE_1);
    return footprint;
}
```

Product Catalog importuje: `EmissionFactorService`, `WskaznikEmisji`, `Zakres` — caly jezyk Emission Factors przecieka do katalogu produktow. Calculation Engine (uogolnienie stworzone wlasnie po to, zeby to ukryc) nie jest uzywany.

#### PRZED

```
┌──────────────────┐    getFactorForCategory()    ┌──────────────────┐
│  Product Catalog │ ─────────────────────────❌──>│ Emission Factors │
│  (specyficzny)   │   importuje: WskaznikEmisji, │ (specyficzny)    │
│                  │   Zakres — omija silnik!      │                  │
└──────────────────┘                               └──────────────────┘
                                                          │
       ┌─────────────────────────┐                        │ (wewnetrzny
       │   Calculation Engine    │    <nie uzyty>         │  dostawca)
       │   (uogolnienie)        │                        │
       └─────────────────────────┘ ◄──────────────────────┘
```

#### PO

```
┌──────────────────┐  calculateFootprint(ProductId,  ┌─────────────────────────┐
│  Product Catalog │  CalculationContext, AsOfDate)   │   Calculation Engine    │
│  (specyficzny)   │ ───────────────────────────✅──>│   (uogolnienie)        │
└──────────────────┘                                  └─────────────────────────┘
                                                              │ (wewnetrznie
       ┌──────────────────┐                                   │  uzywa Emission
       │ Emission Factors │ <─────────────────────────────────┘  Factors)
       └──────────────────┘
```

**Proponowany kod:**

```java
// PO — Product Catalog uzywa generycznego API
FootprintResult result = calculationEngine.calculateFootprint(
    ProductId.from(produkt.getId()),
    CalculationContext.forProduct(produkt.getKategoria()),
    AsOfDate.now()
);
double footprint = result.getTotalFootprint();
```

Product Catalog nie importuje juz `EmissionFactorService`, `WskaznikEmisji`, `Zakres`. Zna tylko generyczne koncepty Engine'a: `FootprintResult`, `CalculationContext`, `ProductId`, `AsOfDate`.

**Test jakosci naprawy:**
- Czy uchwycono zachowanie bez tozsamosci? ✅ — `calculateFootprint()` nie mowi "dla jakiego produktu" ani "z jakiego zrodla wskaznika"
- Czy wiele downstream moze uzywac tego samego API? ✅ — Sales, Reporting, inne moduly uzywaja tego samego `calculateFootprint()`
- Czy termin ma sens w jezyku upstream? ✅ — `FootprintResult`, `CalculationContext` sa juz w `language.md` Engine'a

---

### -> Pauza V1

Czy ta poprawka ma sens? (Tak / Nie, upstream musi wiedziec / Inny fix)

> **Uzytkownik**: "Tak, zgadzam sie."

---

### Poprawka V2: Sales uzywa generycznego API Ledgera

**Kontrola kierunku (Step 1 z SKILL.md):**
- Sales (specyficzny) -> Budget Ledger (uogolnienie): kierunek **POPRAWNY** ✅
- Problem: **slownictwo bledne** — Sales narzuca swoj jezyk na wywolanie generycznego API
- Poprawka: nie zmieniamy kierunku, tylko slownictwo

**Co robi kod dzisiaj:**

```java
// SalesService.java (Sales)
public void zlozZamowienie(Zamowienie zamowienie) {
    // ... logika sprzedazy ...
    budgetService.debituBudzet(
        zamowienie.getId(),       // ZamowienieId — koncept Salesa
        zamowienie.getProdukty()  // Produkty — koncept Salesa
    );
}
```

`debituBudzet(zamowienieId, produkty)` — kazdy element tego wywolania mowi jezykiem Salesa. Budget Ledger, ktory w swoim `language.md` deklaruje "nie wie o kontekstach biznesowych (sprzedaz, zwroty, korekty)", nagle musi rozumiec zamowienia i produkty.

#### PRZED

```
┌─────────────────┐   debituBudzet(zamowienieId,    ┌──────────────────────┐
│   Sales Module  │   produkty)                      │  Emission Budget     │
│   (specyficzny) │ ──────────────────────────❌───> │  Ledger (uogolnienie)│
│                 │   jezyk sprzedazowy w API!        │  "Nie wie o sprzedazy│
│                 │   Ledger musi rozumiec            │   zwrotach, korektach│
│                 │   zamowienia i produkty            │   ani korektach"     │
└─────────────────┘                                  └──────────────────────┘
```

#### PO

```
┌─────────────────┐   createEntry(AccountId,         ┌──────────────────────┐
│   Sales Module  │   DebitEntry, TransactionId)     │  Emission Budget     │
│   (specyficzny) │ ──────────────────────────✅───> │  Ledger (uogolnienie)│
│                 │   jezyk Ledgera — generyczny      │  Widzi: Account,     │
│   tlumaczenie:  │                                  │  Entry, Balance      │
│   zamowienie -> │                                  │  Nie wie KTO ani     │
│   AccountId +   │                                  │  DLACZEGO ksieguje   │
│   DebitEntry    │                                  └──────────────────────┘
└─────────────────┘
```

**Proponowany kod:**

```java
// PO — Sales tlumazy swoje koncepty na jezyk Ledgera
ledgerService.createEntry(
    AccountId.from(zamowienie.getEmissionAccountId()),
    DebitEntry.builder()
        .transactionId(TransactionId.generate())
        .amount(calculateEmissionCost(zamowienie.getProdukty()))
        .description("emission debit")
        .build()
);
```

Sales importuje teraz `AccountId`, `DebitEntry`, `TransactionId` — koncepty z `language.md` Ledgera. Tlumaczenie odbywa sie PO STRONIE Salesa: `zamowienie.getEmissionAccountId()` -> `AccountId`, obliczone produkty -> `amount`. Ledger nigdy nie widzi zamowien.

---

### ANTY-WZORZEC: "Sales publikuje event, Ledger subskrybuje"

Typowa reakcja na V2: "Wyrzucmy bezposrednie wywolanie — niech Sales opublikuje `SprzedazZrealizowana`, a Ledger zasubskrybuje."

**To odwraca generycznosc.** Ledger — modul, ktory **z definicji nie wie o kontekstach biznesowych** — nagle musi wiedziec co to `SprzedazZrealizowana` i jak ja przetlumaczyc na wpis ksiegowy.

```java
// ANTY-WZORZEC — generyczny modul adaptuje sie do specyficznego
// Budget Ledger:

@EventListener
public void handle(SprzedazZrealizowana event) {
    createEntry(mapFromSale(event));          // Ledger wie o sprzedazy
}

@EventListener
public void handle(ZwrotZrealizowany event) {
    createEntry(mapFromReturn(event));        // Ledger wie o zwrotach
}

@EventListener
public void handle(KorektaReczna event) {
    createEntry(mapFromAdjustment(event));    // Ledger wie o korektach
}

// ... rosnie z kazdym nowym konsumentem
// za miesiac: handle(KaraUmowna), handle(RabatWolumenowy), handle(OdpisAktualizacyjny)
// Ledger staje sie patchworkiem obcych handlerow — generycznosc utracona
```

**Dlaczego to zle:**
1. Ledger importuje typy eventow z kazdego modulu specyficznego
2. Kazdy nowy konsument = nowy handler w Ledgerze
3. Ledger musi rozumiec semantyke kazdego eventu (co jest debit, co credit, jaki amount)
4. `language.md` Ledgera mowi "nie wie o kontekstach biznesowych" — a tu wie o wszystkich

**Heurystyka**: 50 typow eventow ma adaptowac sie do 1 generycznego API `createEntry()` — nie Ledger ma adaptowac sie do 50 typow eventow.

**Poprawny kierunek**: Sales (specyficzny, wie co sie stalo) wywoluje `createEntry()` (generyczne API). Sales tlumazy swoja semantyke na jezyk Ledgera. Ledger nie musi wiedziec, ze to byla sprzedaz.

---

### -> Pauza V2

Czy ta poprawka ma sens? (Tak / Nie, upstream musi wiedziec / Inny fix)

> **Uzytkownik**: "Tak, ale potrzebujemy tez `SprzedazZrealizowana` dla innych modulow — CRM chce wiedziec o sprzedazy do aktualizacji scoringu klienta. Czy event jest OK?"

---

## Faza 4: Wlaczenie Feedbacku

### Niuans V2: Event OK dla CRM, nie OK dla Ledgera

Kluczowe pytanie: **kto jest konsumentem i jaka jest jego generycznosc wzgledem Salesa?**

Dwie odrebne kwestie, dwa odrebne wzorce:

**1. Integracja Sales -> Budget Ledger**

Ledger jest BARDZIEJ GENERYCZNY niz Sales. Ledger nie powinien wiedziec o sprzedazy — to jego `language.md` wprost deklaruje. Sales wie dokladnie, co ma sie stac (obciazenie budzetu emisji) i zna parametry (ktore konto, jaka kwota).

**Wzorzec: bezposrednie wywolanie API** — Sales wywoluje `ledgerService.createEntry()`, tlumaczac swoje koncepty na jezyk Ledgera.

**2. Event `SprzedazZrealizowana` -> CRM**

CRM jest ROWNORZEDNY wobec Salesa — inny modul specyficzny, nie uogolnienie. CRM sam decyduje, jak zareagowac na event (aktualizacja scoringu, powiadomienie opiekuna, etc.). Sales jedynie oglasza "sprzedaz zakonczona" — nie wie i nie dba, co CRM z tym zrobi.

**Wzorzec: event + ACL** — Sales publikuje `SprzedazZrealizowana`, CRM subskrybuje (opcjonalnie przez ACL).

### Tabela decyzyjna

| Konsument | Wzgledna Generycznosc | Wzorzec | Dlaczego |
|-----------|----------------------|---------|----------|
| **Budget Ledger** | Bardziej generyczny niz Sales | Bezposrednie API (`createEntry`) | Generyczne nie subskrybuje specyficznego. Sales wie, co ma sie stac — wywoluje API w jezyku Ledgera. |
| **CRM** | Rownorzedny (peer) | Event `SprzedazZrealizowana` + ACL | CRM sam decyduje reakcje. Sales tylko oglasza. Peer moze subskrybowac peera. |

### Diagram po uwzglednieniu feedbacku

```
                 SprzedazZrealizowana (event)
               ┌─────────────────────────────────> ┌──────────────┐
               │  CRM subskrybuje — peer, OK  ✅   │     CRM      │
               │                                   │ (rownorzedny)│
┌─────────────────┐                                └──────────────┘
│   Sales Module  │
│   (specyficzny) │
└────────┬────────┘
         │  createEntry(AccountId, DebitEntry)
         │  bezposrednie API — NIE event    ✅
         ▼
┌──────────────────────┐
│  Emission Budget     │
│  Ledger (uogolnienie)│
│  Nie subskrybuje     │
│  zadnych eventow     │
└──────────────────────┘
```

**Podsumowanie**: Event `SprzedazZrealizowana` jest zasadny — ale jego konsumentem jest CRM (peer), nie Ledger (uogolnienie). To sa dwa odrebne mechanizmy integracji, bo relacja generycznosci jest inna.

---

## Faza 5: Raport Koncowy

**Zdrowie granic**: UMIARKOWANE. Kierunki API w wiekszosci poprawne (specyficzny->generyczny), ale V1 omija uogolnienie, a V2 uzywa obcego slownictwa.

**Wykryto 2 naruszenia, potwierdzone 2 poprawki.**

| # | Naruszenie | Typ | Poprawka | Status |
|---|-----------|-----|----------|--------|
| V1 | ProductCatalog omija Calculation Engine, wywoluje Emission Factors bezposrednio | API omija uogolnienie | Wywolaj `calculationEngine.calculateFootprint(ProductId, CalculationContext, AsOfDate)` — usun import `EmissionFactorService`, `WskaznikEmisji`, `Zakres` | Potwierdzona |
| V2 | Sales uzywa jezyka sprzedazowego (`debituBudzet`, `zamowienieId`, `produkty`) w API Ledgera | API w blednym slownictwie | Wywolaj `ledgerService.createEntry(AccountId, DebitEntry, TransactionId)`. Event `SprzedazZrealizowana` zachowany dla CRM (peer), NIE dla Ledgera (uogolnienie). | Potwierdzona z niuansem |

### Aktualizacje language.md

**product-catalog/language.md:**
- Usunac z Integration Points: `Emission Factor Management (should NOT call directly)`
- Potwierdzic: `Footprint Calculation Engine (OHS)` — jedyna integracja z obliczeniami

**sales/language.md:**
- Potwierdzic import z Budget Ledger: `AccountId`, `DebitEntry`, `TransactionId`
- Usunac: `budgetService.debituBudzet()` jako wzorzec integracji
- Dodac: event `SprzedazZrealizowana` — konsumenci: CRM (nie Ledger)

---

## PO: Poprawna architektura

```
                 SprzedazZrealizowana (event)
               ┌────────────────────────────────> ┌──────────────┐
               │  peer subskrybuje peera ✅        │     CRM      │
               │                                  └──────────────┘
┌──────────────┴──┐                    ┌─────────────────────────┐
│   Sales Module  │  createEntry()     │   Calculation Engine    │
│   (specyficzny) │ ───────┐    ┌────> │   (uogolnienie)        │
└─────────────────┘        │    │      │   calculateFootprint()  │
                           │    │      └────────────┬────────────┘
                           ▼    │                   │ (wewnetrznie)
┌──────────────────────┐   │  ┌─┴────────────────┐  ▼
│  Emission Budget     │   │  │  Product Catalog │  ┌──────────────────┐
│  Ledger (uogolnienie)│ ✅│  │  (specyficzny)   │  │ Emission Factors │
│  Widzi: Account,     │   │  └──────────────────┘  └──────────────────┘
│  Entry, Balance      │   │    uzywa API Engine'a ✅
│  Nie wie KTO ksieguje│◄──┘
└──────────────────────┘

Kazdy specyficzny modul adaptuje sie do generycznego API ✅
Generyczne moduly nie wiedza o specyficznych kontekstach ✅
Eventy miedzy peerami — OK ✅
Eventy do uogolnien — NIE ❌
```

---

**Kluczowy wniosek** — dwie heurystyki steruja kazdym API:

> **1. Kierunek**: Specyficzny adaptuje sie do generycznego. Nigdy odwrotnie.
>
> **2. Slownictwo**: Nawet przy poprawnym kierunku — uzywaj jezyka modulu, do ktorego wywolujesz, nie swojego.
>
> **3. Eventy**: Event to nie "darmowa integracja" — generyczny modul subskrybujacy specyficzny event to ten sam problem co bledne API, tylko w innym opakowaniu.
