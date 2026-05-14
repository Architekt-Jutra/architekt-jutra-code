# Test Strategy Reviewer -- Wynik uruchomienia

## Prompt uzyty do uruchomienia

```
test-strategy-reviewer calculator/test/FeeCalculatorTest.java
```

**Zakres**: `FeeCalculator`, `DiscountPolicy`, `SurchargePolicy`

---

## Krok 1: Klasyfikacja kodu produkcyjnego

| Klasa | Klasa problemu | Sygnaly |
|-------|---------------|---------|
| **FeeCalculator** | **Transformata** | Brak mutacji stanu, input (products + context) -> output (FeeResult), zero efektow ubocznych, zero bazy danych |
| **DiscountPolicy** | **Transformata** | Czysta funkcja: products + context -> BigDecimal. Jawny komentarz: "No state. No side effects." |
| **SurchargePolicy** | **Transformata** | Czysta funkcja: products + context -> BigDecimal. Jawny komentarz: "No state. No side effects." |

**Caly graf wywolan jest czystą transformatą** -- FeeCalculator komponuje dwie czyste funkcje (DiscountPolicy, SurchargePolicy) i produkuje wynik. Zadna z zaleznosci nie ma efektow ubocznych, nie jest kosztowna, nie komunikuje sie z zewnetrznym systemem.

### -> Pauza (symulacja)

> "Klasyfikuje FeeCalculator jako **Transformate** na podstawie: brak stanu, brak efektow ubocznych, deterministic input->output. Czy to sie zgadza?"

> **Uzytkownik**: "Tak, to Transformata."

---

## Krok 2: Identyfikacja aktualnej strategii testowej

| Test | Strategia | Uzasadnienie |
|------|-----------|--------------|
| `should_calculate_fee_with_discount` | **Interaction-based** | Mock na DiscountPolicy + SurchargePolicy, `verify()` na koncu |
| `should_calculate_fee_with_surcharge` | **Interaction-based** | Mock na SurchargePolicy, `verify()` na koncu |
| `should_apply_both_discount_and_surcharge` | **Interaction-based** | Mock na obie policy, `verify(times(1))`, `verifyNoMoreInteractions` |

**Podsumowanie**: 3/3 testow uzywa strategii interaction-based (mocki + verify).

---

## Krok 3: Porownanie -- Smells

### Pytanie o wyjatki (symulacja)

> "Widze, ze testy FeeCalculatorTest uzywaja mockow/stubow na krokach posrednich transformaty. Zanim powiem czy to problem -- czy ktoryś z tych krokow (DiscountPolicy, SurchargePolicy) jest: (a) kosztowny finansowo? (b) kosztowny wydajnosciowo? (c) ma efekty uboczne?"

> **Uzytkownik**: "(d) zadne z powyzszych -- to czysta funkcja."

### Wykryte smelle

| # | Smell | Lokalizacja | Diagnoza |
|---|-------|-------------|----------|
| S1 | **Mock na czystej funkcji** | `mock(DiscountPolicy.class)` | DiscountPolicy to czysta transformata -- mozna ja uruchomic za darmo. Mock jest zbedny. |
| S2 | **Mock na czystej funkcji** | `mock(SurchargePolicy.class)` | SurchargePolicy to czysta transformata -- mozna ja uruchomic za darmo. Mock jest zbedny. |
| S3 | **Verify na pure function** | `verify(discountMock).calculateDiscount(...)` | Weryfikowanie ze czysta funkcja zostala wywolana to wyciek implementacji. Kontrakt transformaty to jej OUTPUT, nie interakcje. |
| S4 | **Verify times(1) + verifyNoMoreInteractions** | test #3 | Sprawdzanie krotnosci wywolan czystej funkcji -- nadmierna specyfikacja. Refaktor wewnetrzny (np. cache, memoizacja) zlamie testy mimo niezmienionych wynikow. |
| S5 | **Hardcoded stub zamiast prawdziwego wyniku** | `thenReturn(new BigDecimal("12.50"))` | Stub zwraca magiczna liczbe -- test nie weryfikuje logiki rabatu. Jesli DiscountPolicy ma buga, ten test go nie wykryje. |

### Konsekwencje smelli

```
┌─────────────────────────────────────────────────────────────────┐
│  Co sie dzieje gdy refaktoryzujesz FeeCalculator?               │
│                                                                 │
│  Scenariusz: Dodajesz cache na discount (memoizacja)            │
│                                                                 │
│    verify(discountMock, times(1)) -- ❌ CZERWONE                │
│    verifyNoMoreInteractions      -- ❌ CZERWONE                 │
│                                                                 │
│  Ale wynik (total) sie NIE zmienil!                             │
│  Testy lamia sie na refaktor, a nie na zmiane kontraktu.        │
│  To jest definicja KRUCHYCH testow.                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## PRZED: Architektura testow (interaction-based na transformacie)

```
┌─────────────────────────────────────────────────────────────────┐
│  FeeCalculatorTest                                              │
│                                                                 │
│  DiscountPolicy discountMock = mock(DiscountPolicy.class);      │
│  SurchargePolicy surchargeMock = mock(SurchargePolicy.class);   │
│  FeeCalculator sut = new FeeCalculator(discountMock, surchargeMock);
│                                                                 │
│  ┌───────────────┐     ┌──────────────────┐                    │
│  │  Test method  │────>│  sut.calculate() │                    │
│  └───────┬───────┘     └────────┬─────────┘                    │
│          │                      │                               │
│          │   when(...).thenReturn(12.50)  ❌ fake wartosc       │
│          │                      │                               │
│          │              ┌───────▼────────┐                      │
│          │              │  discountMock   │ ❌ nie liczy rabatu  │
│          │              └───────┬────────┘                      │
│          │              ┌───────▼────────┐                      │
│          │              │ surchargeMock   │ ❌ nie liczy narzutu │
│          │              └───────┬────────┘                      │
│          │                      │                               │
│          │  verify(discountMock)      ❌ sprawdza CZY wywolano  │
│          │  verify(surchargeMock)     ❌ sprawdza CZY wywolano  │
│          │  verifyNoMoreInteractions  ❌ kruche                 │
│          ▼                      ▼                               │
│  assertThat(result.total())     Testuje ARYTMETYKE              │
│  == 237.50                      (base - 12.50 + 0)             │
│                                 NIE logike biznesowa!            │
└─────────────────────────────────────────────────────────────────┘

Problem: Test weryfikuje ze FeeCalculator umie odejmowac i dodawac.
         NIE weryfikuje ze DiscountPolicy poprawnie liczy 5% dla lojalnych.
         NIE weryfikuje ze SurchargePolicy poprawnie nalicza cold chain 15%.
```

---

## PO: Architektura testow (output-based na transformacie)

```
┌─────────────────────────────────────────────────────────────────┐
│  FeeCalculatorTest                                              │
│                                                                 │
│  DiscountPolicy realDiscount = new DiscountPolicy();            │
│  SurchargePolicy realSurcharge = new SurchargePolicy();         │
│  FeeCalculator sut = new FeeCalculator(realDiscount, realSurcharge);
│                                                                 │
│  ┌───────────────┐     ┌──────────────────┐                    │
│  │  Test method  │────>│  sut.calculate() │                    │
│  └───────┬───────┘     └────────┬─────────┘                    │
│          │                      │                               │
│          │              ┌───────▼────────┐                      │
│          │              │ realDiscount    │ ✅ liczy prawdziwie  │
│          │              └───────┬────────┘                      │
│          │              ┌───────▼────────┐                      │
│          │              │ realSurcharge   │ ✅ liczy prawdziwie  │
│          │              └───────┬────────┘                      │
│          │                      │                               │
│          │  ZERO verify()       ✅ brak weryfikacji interakcji  │
│          ▼                      ▼                               │
│  assertThat(result.total())     Testuje CALA TRANSFORMATE       │
│  == 237.50                      (base - prawdziwy rabat         │
│                                  + prawdziwy narzut)            │
│                                                                 │
│  assertThat(result.discount())  ✅ mozna tez sprawdzic skladowe │
│  assertThat(result.surcharge()) ✅ bez mockow                   │
└─────────────────────────────────────────────────────────────────┘

Zysk: Test weryfikuje WYNIK calej transformaty.
      Refaktor wewnetrzny NIE lamie testow.
      Bugi w DiscountPolicy/SurchargePolicy SA wykrywane.
```

---

## Przyklad: Test PO (output-based)

```java
class FeeCalculatorTest {

    // ✅ Prawdziwe instancje -- to czyste funkcje, mozna je uruchomic
    DiscountPolicy discountPolicy = new DiscountPolicy();
    SurchargePolicy surchargePolicy = new SurchargePolicy();
    FeeCalculator sut = new FeeCalculator(discountPolicy, surchargePolicy);

    @Test
    void loyal_customer_gets_5_percent_discount() {
        var products = List.of(
            new Product("p1", new BigDecimal("100.00"), 2, false, false),
            new Product("p2", new BigDecimal("50.00"), 1, false, false)
        );
        var context = new PricingContext(true, false);  // loyal=true

        var result = sut.calculate(products, context);

        // ✅ Output-based: sprawdzam WYNIK, nie interakcje
        assertThat(result.baseAmount()).isEqualByComparingTo("250.00");
        assertThat(result.discount()).isEqualByComparingTo("12.50");  // 5% of 250
        assertThat(result.surcharge()).isEqualByComparingTo("0.00");
        assertThat(result.total()).isEqualByComparingTo("237.50");
        // ZERO verify() -- nie obchodzi mnie JAK policzyl, obchodzi mnie CO wyszlo
    }

    @Test
    void cold_chain_product_with_express_delivery() {
        var products = List.of(
            new Product("p1", new BigDecimal("80.00"), 1, true, false)
        );
        var context = new PricingContext(false, true);  // express=true

        var result = sut.calculate(products, context);

        // ✅ Weryfikuje prawdziwa logike surcharge (15% cold chain + 9.99 express)
        assertThat(result.surcharge()).isEqualByComparingTo("21.99");
        assertThat(result.total()).isEqualByComparingTo("101.99");
    }
}
```

---

## Krok 4: Raport koncowy

### FeeCalculatorTest

| Wymiar | Wartosc |
|--------|---------|
| **Tests** | FeeCalculator (+ DiscountPolicy, SurchargePolicy) |
| **Problem class** | Transformata (caly graf -- FeeCalculator + obie policy) |
| **Current strategy** | Interaction-based (mocks + verify) |
| **Recommended strategy** | Output-based (real instances, assert on output) |
| **Verdict** | **MISMATCH** |

---

### Podsumowanie smelli

| Smell | Ile wystapien | Waga |
|-------|---------------|------|
| Mock na czystej funkcji | 2 (DiscountPolicy, SurchargePolicy) | Wysoka -- zbedna komplikacja |
| Verify na pure function | 5 (3x verify + 1x times(1) + 1x verifyNoMoreInteractions) | Wysoka -- kruche testy |
| Hardcoded stub values | 4 (thenReturn z magicznymi liczbami) | Srednia -- testy nie chronia przed bugami w policy |

---

### Dlaczego to jest problem?

```
┌──────────────────────────────────────────────────────────────┐
│                    MACIERZ OCHRONY                            │
│                                                              │
│  Scenariusz                      PRZED (mock)  PO (real)     │
│  ─────────────────────────────── ───────────── ──────────    │
│  Bug w DiscountPolicy            ❌ nie wykryje  ✅ wykryje   │
│  Bug w SurchargePolicy           ❌ nie wykryje  ✅ wykryje   │
│  Bug w FeeCalculator (arytm.)    ✅ wykryje      ✅ wykryje   │
│  Refaktor wewnetrzny             ❌ zlamie test  ✅ przejdzie │
│  Zmiana kontraktu (output)       ✅ wykryje      ✅ wykryje   │
│                                                              │
│  Ochrona przed regresja:  PRZED: 2/5   PO: 5/5             │
│  Odpornosc na refaktor:   PRZED: 0/1   PO: 1/1             │
└──────────────────────────────────────────────────────────────┘
```

---

### Rekomendacja

1. **Usun mocki** -- zastap `mock(DiscountPolicy.class)` przez `new DiscountPolicy()`
2. **Usun wszystkie verify()** -- kontrakt transformaty to OUTPUT, nie interakcje
3. **Testuj wynik end-to-end** -- podaj wejscie, sprawdz FeeResult
4. **Opcjonalnie**: dodaj osobne testy DiscountPolicy i SurchargePolicy jesli maja zlozona logike (tu maja -- bulk discount, loyalty, cold chain, hazmat, express). Ale nawet bez osobnych testow, test FeeCalculatora z realnymi policy pokrywa ta logike.

**Zasada**: Jesli zaleznosc jest czysta funkcja (brak stanu, brak efektow ubocznych, brak kosztu) -- **uruchom ja zamiast mockowac**. Mock na czystej funkcji to koszt bez zysku.
