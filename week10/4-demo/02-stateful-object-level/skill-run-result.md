# Test Strategy Reviewer -- Wynik uruchomienia

## Prompt uzyty do uruchomienia

```
test-strategy-reviewer product-pricing/test/ProductPricingTest.java
```

**Zakres**: ProductPricing (object), ProductPricingFacade (application service)

---

## Step 1: Klasyfikacja kodu produkcyjnego

### ProductPricing.java

| Sygnal | Obecny? |
|--------|---------|
| Tozsamosc (productId) | TAK |
| Invarianty (cena >= 0, brak duplikatu ceny) | TAK |
| Zmiana stanu w czasie (priceHistory, currentPrice) | TAK |
| Emitowanie zdarzen domenowych | TAK |
| Brak efektow ubocznych poza wlasnym stanem | TAK |

**Klasyfikacja**: **Stateful Object** (obiekt ze stanem ze stanem)

> "Przeczytalem kod i testy. Klasyfikuje ProductPricing jako **Obiekt ze stanem (Stateful Object)** na podstawie: tozsamosc (productId), invarianty (cena nie moze byc ujemna, ta sama cena odrzucana), zmiana stanu w czasie (historia cen). Czy to sie zgadza?"

> **Uzytkownik**: "Tak, to Obiekt ze stanem."

### ProductPricingFacade.java

| Sygnal | Obecny? |
|--------|---------|
| Orkiestracja wielu krokow | TAK (load -> call -> save) |
| Koordynacja komponentow zewnetrznych | TAK (repository) |
| Wlasna logika / branching | NIE |
| Efekty uboczne | TAK (zapis do DB) |

**Klasyfikacja**: **Integration** (prosta orkiestracja -- load/call/save)

---

## Step 2: Aktualna strategia testowa

### ProductPricingTest.java

| Test | Strategia | Objasnieni |
|------|-----------|------------|
| `should_accept_valid_price_change` | Output + State | Sprawdza return value (Result.ACCEPTED) + stan (currentPrice, priceChangeCount) |
| `should_reject_negative_price` | Output + State | Sprawdza return value + brak zmiany stanu |
| `should_reject_same_price` | Output + State | Sprawdza return value + brak zmiany stanu |
| `should_emit_price_changed_event` | State | Sprawdza zdarzenia domenowe (stan wewnetrzny) |
| `should_track_price_history` | State | Sprawdza historie cen po wielu operacjach |

**Podsumowanie**: Strategia **output-based + indirect state-based** -- poprawna dla Stateful Object.

**Poziom testowania**: Testy na **poziomie obiekt ze stanemu** (bezposrednio `new ProductPricing(...)`, bez fasady).

---

## Step 3: Porownanie ze strategia rekomendowana

### Dopasowanie strategii do klasy problemu

| Aspekt | Rekomendacja dla Stateful Object | Aktualnie | Ocena |
|--------|----------------------------------|-----------|-------|
| Output-based (return value) | TAK | TAK | OK |
| Indirect state-based (stan po operacji) | TAK | TAK | OK |
| Brak mockow wnetrza obiekt ze stanemu | TAK | TAK (zero mockow) | OK |
| Weryfikacja stanu po sekwencji operacji | TAK | TAK (price history test) | OK |

**Strategia jest poprawna.** Nie ma mismatch na poziomie output vs state vs interaction.

---

### Level of Testing -- higher vs lower

Testy sa na poziomie obiekt ze stanemu. Fasada (`ProductPricingFacade`) istnieje ale nie jest testowana.

> "Widze testy na poziomie obiekt ze stanemu. Zeby ocenic czy to dobry poziom, musze wiedziec:
> (a) Czy orkiestracja wokol tego obiektu (fasada) zmienia sie czesto, czy jest raczej stabilna?
> (b) Czy serwis aplikacyjny jest prosty (kilka krokow) czy zlozony (duzo logiki, branching)?
> (c) Czy efekt operacji da sie zweryfikowac przez read model / widok / zapytanie?"

**Odpowiedzi uzytkownika**:
- (a) "Fasada sie nie zmienia od miesiecy"
- (b) "Jest prosta -- 3 linijki, zero branchingu"
- (c) "Tak, efekt widac przez getCurrentPrice() i getPriceChangeCount()"

### Analiza: Wszystkie 3 warunki spelnione

| Warunek | Spelniony? | Konsekwencja |
|---------|------------|--------------|
| Fasada stabilna (nie zmienia sie) | TAK | Testy nie beda lamaly sie przez churn orkiestracji |
| Fasada prosta (brak branchingu) | TAK | Nie potrzebujemy izolowac obiekt ze stanemu od zlozonosci |
| Efekt weryfikowalny przez query | TAK | Mozemy sprawdzac stan "z perspektywy uzytkownika" (przez fasade) |

**Rekomendacja**: Przeniesc testy na poziom fasady.

---

## PRZED: Testy na poziomie obiekt ze stanemu

```
┌─────────────────────────────────────────────────────────────────┐
│  ProductPricingTest                                              │
│                                                                  │
│  @Test should_accept_valid_price_change()                       │
│  ┌───────────────────────────────────────┐                      │
│  │ var pricing = new ProductPricing(...)  │ <-- bezposrednia     │
│  │ pricing.changePrice(120, now)          │     konstrukcja      │
│  │ assertThat(pricing.currentPrice())     │     obiekt ze stanemu         │
│  └───────────────────────────────────────┘                      │
│                                                                  │
│  Testuje:     ProductPricing (object)                        │
│  Pomija:      ProductPricingFacade (load/save)                  │
│  Pomija:      ProductPricingRepository (persystencja)           │
│  Weryfikuje:  Stan przez bezposredni getter na obiekcie         │
└─────────────────────────────────────────────────────────────────┘

          Test uderza BEZPOSREDNIO w obiekt ze stanem:

          ┌────────────┐
          │   TEST     │
          └─────┬──────┘
                │ new ProductPricing(...)
                │ .changePrice(...)
                │ .currentPrice()
                ▼
          ┌────────────────────┐
          │  ProductPricing    │  <-- testowany obiekt
          │  (object)       │
          └────────────────────┘

          ProductPricingFacade -- NIEOBJETA TESTEM
          ProductPricingRepository -- NIEOBJETY TESTEM
```

---

## PO: Testy na poziomie fasady (rekomendacja)

```
┌─────────────────────────────────────────────────────────────────┐
│  ProductPricingTest (facade-level)                               │
│                                                                  │
│  @Test should_accept_valid_price_change()                       │
│  ┌───────────────────────────────────────┐                      │
│  │ facade.changePrice(productId, 120, now) │ <-- przez fasade   │
│  │ assertThat(                             │                    │
│  │   facade.getCurrentPrice(productId)     │ <-- weryfikacja    │
│  │ ).isEqualTo(120)                        │     jak uzytkownik │
│  └───────────────────────────────────────┘                      │
│                                                                  │
│  Testuje:     Caly stos (facade -> object -> repository)     │
│  Weryfikuje:  Efekt widoczny "z zewnatrz" (getCurrentPrice)    │
│  Repository:  InMemory (managed dependency -- real impl)        │
└─────────────────────────────────────────────────────────────────┘

          Test przechodzi przez CALY STOS:

          ┌────────────┐
          │   TEST     │
          └─────┬──────┘
                │ facade.changePrice(productId, 120, now)
                ▼
          ┌────────────────────────┐
          │  ProductPricingFacade  │  <-- orkiestracja (load/call/save)
          └─────────┬─────────────┘
                    │ findById / save
                    ▼
          ┌────────────────────────┐
          │  InMemoryRepository    │  <-- managed dependency (real)
          └─────────┬─────────────┘
                    │
                    ▼
          ┌────────────────────┐
          │  ProductPricing    │  <-- obiekt ze stanem (przetestowany posrednio)
          │  (object)       │
          └────────────────────┘

          Weryfikacja:
          facade.getCurrentPrice(productId) == 120  ✅
          facade.getPriceChangeCount(productId) == 1  ✅
```

---

## Przyklad: Jak wygladaja testy PO zmianie

### PRZED (object-level)

```java
@Test
void should_accept_valid_price_change() {
    var pricing = new ProductPricing(productId, new BigDecimal("100.00"));

    var result = pricing.changePrice(new BigDecimal("120.00"), now);

    assertThat(result).isEqualTo(Result.ACCEPTED);
    assertThat(pricing.currentPrice()).isEqualByComparingTo("120.00");
    assertThat(pricing.priceChangeCount()).isEqualTo(1);
}
```

### PO (facade-level)

```java
// setup: InMemoryRepository + ProductPricingFacade
ProductPricingRepository repo = new InMemoryProductPricingRepository();
ProductPricingFacade facade = new ProductPricingFacade(repo);

// given: produkt z cena poczatkowa (przez fasade lub seed)
repo.save(new ProductPricing(productId, new BigDecimal("100.00")));

@Test
void should_accept_valid_price_change() {
    var result = facade.changePrice(productId, new BigDecimal("120.00"), now);

    assertThat(result).isEqualTo(Result.ACCEPTED);
    assertThat(facade.getCurrentPrice(productId)).isEqualByComparingTo("120.00");
    assertThat(facade.getPriceChangeCount(productId)).isEqualTo(1);
}
```

---

## Dlaczego to lepsze?

| Aspekt | Aggregate-level (teraz) | Facade-level (rekomendacja) |
|--------|--------------------------|------------------------------|
| Realistycznosc | Pomija load/save | Testuje pelny cykl zycia |
| Perspektywa | "Wewnatrz obiektu" | "Jak uzytkownik / klient API" |
| Regresja save/load | Nie wykryje bledu w repo | Wykryje (bo przechodzi przez save/load) |
| Kruchodajnosc | Niska | Niska (fasada stabilna) |
| Szybkosc | Szybkie (in-memory) | Tak samo szybkie (InMemoryRepo) |
| Refactoring obiekt ze stanemu | Testy sie lamia | Testy przetrwaja (jesli API fasady stabilne) |

---

## Raport koncowy

### ProductPricingTest

| Pole | Wartosc |
|------|---------|
| **Tests** | ProductPricing (object) |
| **Problem class** | Stateful Object |
| **Current strategy** | Output-based + indirect state-based |
| **Recommended strategy** | Output-based + indirect state-based |
| **Strategy verdict** | **OK** -- strategia dopasowana do klasy |
| **Level of testing** | Aggregate-level |
| **Recommended level** | Facade-level |
| **Level verdict** | **SUGGEST CHANGE** |

### Uzasadnienie

Strategia testowania (output + state) jest prawidlowa -- testy weryfikuja zwracany `Result` oraz stan (currentPrice, priceChangeCount, domainEvents). To jest dokladnie to, czego oczekujemy od testow Stateful Object.

Natomiast **poziom testowania** mozna podniesc. Poniewaz:

1. Fasada jest stabilna (nie zmienia sie od miesiecy)
2. Fasada jest prosta (3 linijki: load -> call -> save, zero branchingu)
3. Efekt da sie zweryfikowac przez query fasady (getCurrentPrice, getPriceChangeCount)

...testy na poziomie fasady daja **wieksza ochrone przed regresja** (obejmuja tez load/save) przy **zerowym koszcie dodatkowej zlozonosci** (InMemoryRepository jest trywialne).

### Kiedy NIE robic tej zmiany

- Gdyby fasada sie czesto zmieniala -- testy obiekt ze stanemu izoluja od churnu
- Gdyby fasada byla zlozna (branching, wiele zaleznosci) -- trudniej ustawic test
- Gdyby wielu serwisow uzywalo tego samego obiekt ze stanemu na rozne sposoby -- lepiej testowac obiekt ze stanem raz, a serwisy osobno
- Gdyby nie dalo sie sprawdzic efektu przez read model -- trzeba grzebac w obiekt ze stanemach

**Zadne z tych warunkow nie zachodzi tutaj** -- stad rekomendacja przenosin.
