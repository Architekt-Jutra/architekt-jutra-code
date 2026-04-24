# Demo: Accounting Archetype Mapper na wymaganiach CO₂

## Wymagania wejściowe (prompt)

> Każdy produkt w naszym katalogu ma ślad węglowy. Dostawcy raportują emisje na komponent. Klient widzi sumaryczny ślad na etykiecie. Firma ma roczny limit emisji z certyfikatu EU ETS. Przekroczenie = kara. Można dokupić uprawnienia na giełdzie. Niewykorzystane uprawnienia z Q1 przechodzą na Q2, ale wygasają z końcem roku. Firma chce wiedzieć w każdym momencie: ile uprawnień zostało, skąd się wzięły, i ile zużyła produkcja w danym okresie.

---

## Fit Test

Pytanie: *„Czy mogę zapytać 'ile uprawnień emisyjnych ma firma X?' i dostać sensowną liczbę z historią transakcji?"*

**Tak.** Odpowiedź: np. 12 450 tCO₂e, z historią: roczna alokacja z EU ETS, zakupy na giełdzie, zużycie per partia produkcyjna, carry-over kwartalny, wygaśnięcie roczne.

| Sygnał | Obecny? |
|--------|---------|
| firma gromadzi / zużywa N jednostek | Tak — alokacja EU ETS, zakupy (gromadzenie); produkcja (zużycie) |
| saldo nie powinno spaść poniżej zera | Tak sugerowane — przekroczenie = kara |
| grant / expire / transfer | Tak — roczna alokacja, wygaśnięcie roczne, carry-over Q→Q |
| wiele źródeł tej samej wartości | Tak — certyfikat EU ETS vs kupione na giełdzie |

**Wynik: pasuje.** Kontynuujemy.

## Wartość domenowa

**EMISSION_ALLOWANCE** — mierzone w **tonach ekwiwalentu CO₂ (tCO₂e)**. Reprezentuje prawo do emisji gazów cieplarnianych. Jedna jednostka = prawo do emisji 1 tony CO₂e.

---

## Pytania pogłębiające — runda 1 (standardowe decyzje)

### Pytanie: Czy saldo może spaść poniżej zera?

> **Odpowiedź: Pozwól na debet.** Firma może przekroczyć limit — ujemne saldo oznacza karę do uregulowania. Księga rejestruje przekroczenie.

### Pytanie: Czy firma może sprzedać nadwyżkę uprawnień innej firmie?

> **Odpowiedź: Można sprzedać.** Firma może sprzedać nadwyżkę na giełdzie — transakcja zmniejszająca saldo, zwiększająca przychód.

### Pytanie: Które uprawnienia zużywać pierwsze (certyfikat EU ETS vs kupione)?

> **Odpowiedź: To zależy.** Strategia alokacji jest zmienna — decyduje dział finansowy per kwartał.
>
> → Skill traktuje to jako **zmienną politykę**: księga przyjmuje `allocation_strategy` jako parametr z zewnątrz. Nie modeluje logiki decyzyjnej.

### Pytanie: Czy korekta błędnie zaraportowanej emisji może być antydatowana?

> **Odpowiedź: Tak, antydatuj.** Korekta obowiązuje od momentu błędu — historyczne raporty będą prawidłowe. `applied_at` może być w przeszłości.

---

## Pytania pogłębiające — runda 2 (z luk)

### Pytanie: Czy uprawnienia kupione na giełdzie mają te same reguły wygasania co z certyfikatu?

> **Odpowiedź: Te same reguły.** Wszystkie uprawnienia wygasają z końcem roku kalendarzowego.

### Pytanie: Czy kara za przekroczenie jest automatyczna czy tylko raportowana?

> **Odpowiedź: Tylko raportuje.** System informuje o przekroczeniu, ale kara jest procesem zewnętrznym (regulacyjnym). Księga nie modeluje kary.

### Pytanie: Czy zużycie uprawnień rejestrowane per produkt/partia czy sumarycznie per firma?

> **Odpowiedź: Per partia/produkt.** Każda partia produkcyjna zużywa uprawnienia proporcjonalnie do emisji — pełna śledzenność do produktu.

### Pytanie: Czy księga ma być append-only?

> **Odpowiedź: Append-only.** Pełna niemodyfikowalność. Korekta = nowy wpis odwracający.

---

## Model wynikowy

# Accounting Archetype Model: Emission Allowances (EU ETS)

## Domain Value

**EMISSION_ALLOWANCE** — tony ekwiwalentu CO₂ (tCO₂e), canonical unit. Represents the right to emit 1 tonne of CO₂ equivalent.

## Concept Mapping

| Domain Concept | Accounting Archetype | Notes |
|----------------|---------------------|-------|
| Uprawnienie emisyjne | Domain Value (EMISSION_ALLOWANCE) | Jednostka: tCO₂e |
| Certyfikat EU ETS (roczna alokacja) | Pool account (ets_allocation_pool) | Źródło: regulator, roczne |
| Uprawnienia kupione na giełdzie | Pool account (market_purchased_pool) | Źródło: giełda, płatne |
| Produkcja towaru (emisja) | Consumption transaction | Per partia produkcyjna |
| Ślad węglowy komponentu (od dostawcy) | Parametr transakcji konsumpcji | Ilość tCO₂e per komponent → sumowane na partię |
| Zakup uprawnień na giełdzie | Purchase transaction | Zwiększa market_purchased_pool |
| Sprzedaż nadwyżki na giełdzie | Sale transaction | Zmniejsza saldo, generuje przychód |
| Carry-over Q→Q | Wewnętrzny — wartość po prostu żyje na koncie | Nie wymaga transakcji, bo uprawnienia nie wygasają kwartalnie |
| Wygaśnięcie roczne | Expiration transaction | Przenosi resztę na konto strat |
| Korekta błędnej emisji | Reversal / correction transaction | applied_at w przeszłości |
| Roczny limit emisji (cap) | Zewnętrzny parametr | Nie modelowany w księdze — system raportuje przekroczenie |
| Kara za przekroczenie | Zewnętrzny proces | Poza księgą — proces regulacyjny |
| Etykieta CO₂ na produkcie | Read model / query | Sumuje ślad komponentów — nie jest konceptem księgowym |

## Unmapped Concepts

- **Kara za przekroczenie limitu** — proces regulacyjny zewnętrzny wobec księgi. System raportuje przekroczenie, ale kara nie jest transakcją w księdze.
- **Etykieta CO₂ na produkcie** — to query/read model agregujący ślady komponentów. Nie jest wartością, która się kumuluje.
- **Roczny cap** — parametr regulacyjny, nie koncept księgowy. Księga wie ile zostało, system porównuje z capem.

## Accounts

| Account | Type | Unit | Negative Balance Policy | Description |
|---------|------|------|------------------------|-------------|
| ets_allocation_pool | Pool | tCO₂e | block | Roczna alokacja z certyfikatu EU ETS. Zasilana raz do roku. |
| market_purchased_pool | Pool | tCO₂e | block | Uprawnienia dokupione na giełdzie. Zasilana per zakup. |
| company_emission_balance | Asset | tCO₂e | allow (debet = przekroczenie) | Saldo firmy — widok sumaryczny. Ujemne = przekroczenie limitu. |
| production_consumption | Expense | tCO₂e | allow | Rejestruje zużycie per partia produkcyjna. Cel: audyt i raportowanie. |
| expired_allowances | Expense | tCO₂e | allow | Rejestruje uprawnienia, które przepadły z końcem roku. |
| sale_revenue | Revenue | tCO₂e | allow | Rejestruje uprawnienia sprzedane na giełdzie. |
| ets_source | Pool | tCO₂e | allow | Konto-źródło regulatora (counterpart dla alokacji). |
| market_source | Pool | tCO₂e | allow | Konto-źródło giełdy (counterpart dla zakupów). |

## Transactions & Entries

### annual_ets_allocation
**Trigger**: Początek roku — regulator przyznaje pulę uprawnień z certyfikatu EU ETS
**Reversible**: No (korekta przez admin_adjustment)

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | ets_allocation_pool | Credit | N tCO₂e | 1 stycznia roku | Zasilenie puli |
| 2 | ets_source | Debit | N tCO₂e | 1 stycznia roku | Counterpart regulatora |

### market_purchase
**Trigger**: Firma kupuje uprawnienia na giełdzie EU ETS
**Reversible**: Conditional (w oknie rozliczeniowym giełdy)

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | market_purchased_pool | Credit | N tCO₂e | Data zakupu | Zasilenie puli kupionych |
| 2 | market_source | Debit | N tCO₂e | Data zakupu | Counterpart giełdy |

### production_emission
**Trigger**: Wyprodukowanie partii towaru — suma śladów komponentów od dostawców
**Reversible**: Conditional (korekta danych dostawcy → emission_correction)

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | production_consumption | Debit | X tCO₂e | Data produkcji partii | Rejestruje emisję per partia |
| 2 | [source pool per allocation_strategy] | Credit | X tCO₂e | Data produkcji partii | Zużywa uprawnienia wg strategii |

**Metadata per wpis**: batch_id, product_id, component_breakdown (jakie komponenty złożyły się na sumę)

### market_sale
**Trigger**: Firma sprzedaje nadwyżkę uprawnień na giełdzie
**Reversible**: Conditional (w oknie rozliczeniowym giełdy)

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | sale_revenue | Debit | N tCO₂e | Data sprzedaży | Rejestruje przychód |
| 2 | [source pool] | Credit | N tCO₂e | Data sprzedaży | Zmniejsza pulę uprawnień |

### year_end_expiration
**Trigger**: 31 grudnia — scheduled job
**Reversible**: No

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | expired_allowances | Debit | remaining tCO₂e | 31 grudnia | Rejestruje stratę |
| 2 | ets_allocation_pool | Credit | remaining tCO₂e | 31 grudnia | Zeruje pulę ETS |
| 3 | expired_allowances | Debit | remaining tCO₂e | 31 grudnia | Rejestruje stratę |
| 4 | market_purchased_pool | Credit | remaining tCO₂e | 31 grudnia | Zeruje pulę kupionych |

### emission_correction
**Trigger**: Dostawca poprawia dane o śladzie komponentu — korekta błędnej emisji
**Reversible**: N/A (jest już odwróceniem)

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | production_consumption | Credit | delta tCO₂e | **Data oryginalnej produkcji** | Odwraca błędne zużycie |
| 2 | [source pool] | Debit | delta tCO₂e | **Data oryginalnej produkcji** | Zwraca uprawnienia |

**Uwaga**: `applied_at` w przeszłości (antydatowanie) — `created_at` = teraz. Historyczne raporty będą prawidłowe.

### admin_adjustment
**Trigger**: Ręczna korekta admina (np. błąd w alokacji, regulacyjna zmiana)
**Reversible**: Yes → kolejny admin_adjustment odwracający

| Entry | Account | Direction | Amount | applied_at | Notes |
|-------|---------|-----------|--------|-----------|-------|
| 1 | [target account] | Debit/Credit | N tCO₂e | Per decyzja admina | Może antydatować |
| 2 | [counterpart] | Credit/Debit | N tCO₂e | Per decyzja admina | Bilansowanie |

## Validity Rules

| Account | Valid From | Valid To | On Expiry |
|---------|-----------|---------|-----------|
| ets_allocation_pool | 1 stycznia roku alokacji | 31 grudnia roku alokacji | year_end_expiration — reszta → expired_allowances |
| market_purchased_pool | Data zakupu | 31 grudnia roku zakupu | year_end_expiration — reszta → expired_allowances |

## Allocation Strategy

**Zmienna polityka** — strategia alokacji jest przekazywana z zewnątrz jako parametr `allocation_strategy`. Księga nie decyduje, która pula jest zużywana pierwsza. Dział finansowy ustala strategię per kwartał.

Możliwe wartości parametru:
1. `ets_first` — najpierw certyfikat EU ETS, potem kupione
2. `purchased_first` — najpierw kupione, potem certyfikat
3. `fifo` — najstarsze uprawnienia niezależnie od źródła
4. `proportional` — proporcjonalnie z obu pul

Księga otrzymuje `allocation_strategy` i mechanicznie ją egzekwuje.

## Reversal Rules

| Transaction | Reversal Trigger | Reversible? | Constraint |
|-------------|-----------------|-------------|------------|
| annual_ets_allocation | N/A | No | Korekta przez admin_adjustment |
| market_purchase | Anulowanie transakcji giełdowej | Conditional | W oknie rozliczeniowym giełdy |
| production_emission | Korekta danych dostawcy | Conditional | Przez emission_correction z antydatowaniem |
| market_sale | Anulowanie transakcji giełdowej | Conditional | W oknie rozliczeniowym giełdy |
| year_end_expiration | N/A | No | Wygasłe uprawnienia nie wracają |
| emission_correction | N/A | No | Jest już odwróceniem |
| admin_adjustment | Kolejny admin_adjustment | Yes | Referencja do oryginalnej transakcji |

## Implementation Notes

- **Append-only ledger** — żadne wpisy nie są edytowane ani usuwane. Każda korekta to nowy wpis.
- **Ujemne saldo dozwolone** na `company_emission_balance` — ujemne saldo = przekroczenie limitu. System generuje alert/raport, ale kara jest procesem zewnętrznym.
- **Allocation strategy jako parametr zewnętrzny** — księga nie zawiera logiki „który pool najpierw". Otrzymuje strategię i wykonuje. (A) — potwierdzone przez użytkownika jako zmienna polityka.
- **Antydatowanie dozwolone** dla korekt emisji — `applied_at` w przeszłości, `created_at` zawsze = now. (A)
- **Granulacja per partia** — każda transakcja production_emission zawiera metadata: batch_id, product_id, component_breakdown. (A)
- **Roczny cap** nie jest modelowany w księdze — to parametr zewnętrzny, system porównuje saldo z capem i raportuje. (R — wymagania mówią „przekroczenie = kara", ale kara jest zewnętrzna)
- **Assumption (X, low impact)**: Jednostka jest zawsze tCO₂e, nie modelujemy konwersji między gazami cieplarnianymi (to odpowiedzialność warstwy raportującej)
- **Assumption (X, low impact)**: Admin adjustment nie ma limitu kwotowego — zakładamy, że autoryzacja admina jest weryfikowana w warstwie aplikacyjnej
