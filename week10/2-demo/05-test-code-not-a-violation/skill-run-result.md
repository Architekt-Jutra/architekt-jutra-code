# Linguistic Boundary Verifier -- Testy nie sa naruszeniem

## Architektura: kod produkcyjny jest czysty

```
┌─────────────────────────────────────────────────────────┐
│              Calculation Engine (uogolnienie)            │
│                                                         │
│  src/FootprintCalculator.java:                          │
│   component.requiresColdChainSurcharge()     ✅ generic │
│   component.coldChainSurchargeFactor()       ✅ generic │
│   contextParameters.get("requiredPrecision") ✅ generic │
│                                                         │
│  test/FootprintCalculatorTest.java:                     │
│   "pielmieni-500g", "jogurt-grecki-400g"     📖 story  │
│   "co2-transport-scope1", "GHG Protocol V2"  📖 story  │
│   "plyn-fairy-900ml", "lody-waniliowe-1l"    📖 story  │
│                                                         │
│  Testy opowiadaja historyjki -- to NIE jest wyciek      │
└────────────────────────────┬────────────────────────────┘
                             │ generyczne API (OHS)
              ┌──────────────┴──────────────┐
              │                             │
   ┌──────────▼──────────┐      ┌──────────▼──────────┐
   │   Product Catalog   │      │   Emission Factors   │
   │  MROZONKI, NABIAJ   │      │  GHG_PROTOCOL_V2    │
   │  pielmieni, jogurt  │      │  Scope 1/2/3        │
   └─────────────────────┘      └──────────────────────┘
```

---

**Wywolanie**: `linguistic-boundary-verifier calculation-engine product-catalog emission-factors`
**Moduly**: `calculation-engine`, `product-catalog`, `emission-factors`

---

## Faza 1: Odkrywanie i Parsowanie

| Modul | Rola | Slownictwo |
|-------|------|------------|
| **Calculation Engine** | Uogolnienie — oblicza kg CO2 z komponentow. Nie wie dla jakiego produktu. | Component, Calculator, Validity, Applicability, ContextParameter, FootprintResult |
| **Product Catalog** | Specyficzny — produkty, kategorie (MROZONKI, NABIAJ, ELEKTRONIKA, CHEMIA). | Produkt, Kategoria, SKU, Cena, WymagaChlodzenia |
| **Emission Factors** | Specyficzny — wspolczynniki emisji, zakresy, Protokol GHG, audytorzy. | WspolczynnikEmisji, Zakres, ProtokolGHG, Audytor |

Relacje: oba moduly specyficzne sa konsumentami OHS Engine'a. Jezyk plynie OD Engine'a DO konsumentow. Terminy konsumentow NIE MOGA pojawiac sie w Engine.

-> Faza 2

---

## Faza 2: Wykrywanie Naruszen

### Skanowanie kodu produkcyjnego (`src/`)

Grep terminow z Product Catalog (`MROZONKI`, `NABIAJ`, `Kategoria`, `Produkt`, `CHEMIA`, `ELEKTRONIKA`, `OWOCE`, `pielmieni`, `jogurt`, `lody`, `plyn`) w `calculation-engine/src/`:

| Plik | Wynik |
|------|-------|
| `src/FootprintCalculator.java` | **0 trafien** |

Grep terminow z Emission Factors (`GHG_PROTOCOL`, `SCOPE_1`, `SCOPE_2`, `SCOPE_3`, `Audytor`, `WspolczynnikEmisji`, `Zakres`, `ProtokolGHG`) w `calculation-engine/src/`:

| Plik | Wynik |
|------|-------|
| `src/FootprintCalculator.java` | **0 trafien** |

**Wynik skanowania kodu produkcyjnego: ZERO naruszen.** FootprintCalculator uzywa wylacznie generycznych terminow: `Component`, `requiresColdChainSurcharge()`, `coldChainSurchargeFactor()`, `contextParameters`, `FootprintResult`. Nie zna nazw produktow, kategorii, protokolow ani zakresow emisji.

---

### Skanowanie kodu testowego (`test/`) -- pominiete per regula

Grep tych samych terminow w `calculation-engine/test/`:

| # | Termin | Plik | Linia | Kontekst |
|---|--------|------|-------|----------|
| 1 | `mrozonki` | `FootprintCalculatorTest.java` | :18 | nazwa metody testowej |
| 2 | `pielmieni` | `FootprintCalculatorTest.java` | :20 | zmienna `mrozonePielmieni`, argument `"pielmieni-500g"` |
| 3 | `cold_chain` | `FootprintCalculatorTest.java` | :18 | nazwa metody testowej |
| 4 | `ghg_protocol_v2` | `FootprintCalculatorTest.java` | :35 | nazwa metody testowej |
| 5 | `Scope1` | `FootprintCalculatorTest.java` | :37 | zmienna `wspolczynnikScope1`, argument `"co2-transport-scope1"` |
| 6 | `nabiaj` | `FootprintCalculatorTest.java` | :50 | nazwa metody testowej |
| 7 | `jogurt` | `FootprintCalculatorTest.java` | :51 | zmienna `jogurtGrecki`, argument `"jogurt-grecki-400g"` |
| 8 | `mrozonki` | `FootprintCalculatorTest.java` | :50 | nazwa metody testowej (drugi raz) |
| 9 | `lody` | `FootprintCalculatorTest.java` | :57 | zmienna `lodyWaniliowe`, argument `"lody-waniliowe-1l"` |
| 10 | `chemia` | `FootprintCalculatorTest.java` | :67 | nazwa metody testowej |
| 11 | `plyn` | `FootprintCalculatorTest.java` | :68 | zmienna `plynDoNaczyn`, argument `"plyn-fairy-900ml"` |
| 12 | `cold_chain` | `FootprintCalculatorTest.java` | :50 | nazwa metody testowej (drugi raz) |
| 13 | `cold_chain` | `FootprintCalculatorTest.java` | :67 | nazwa metody testowej (trzeci raz) |
| 14 | `GHG Protocol` | `FootprintCalculatorTest.java` | :40 | komentarz w tresci testu |

**14 wystapien obcych terminow w katalogu `test/`.**

**Status: POMINIETE.** Regula "Scope: Production Code Only" -- testy sa wykluczone z weryfikacji. W testach CHCEMY uzywac specyficznego, bogatego slownictwa domenowego -- opowiadamy historyjke biznesowa.

---

> ### Dlaczego testy sa wykluczone?
>
> Test `mrozonki_z_cold_chain_dostaja_narzut_chlodzenia()` uzywa slow
> "mrozonki", "pielmieni", "cold chain" -- i to jest **poprawne**.
> Test opowiada historyjke: *"mrozone pielmieni dostaja narzut za lancuch
> chlodniczy"*. Czytelnik natychmiast rozumie scenariusz biznesowy.
>
> Gdyby test brzmial `component_with_surcharge_flag_gets_multiplied()` --
> bylby poprawny lingwistycznie, ale nieczytelny biznesowo. Stracilibysmy
> wartosc testu jako dokumentacji zachowania.
>
> **Naruszenie** to nie uzycie slowa "mrozonki" w tescie.
> **Naruszenie** to `if (category.equals("MROZONKI"))` w **kodzie produkcyjnym**
> -- bo wtedy silnik DECYDUJE na podstawie tozsamosci downstream.
>
> W tescie opowiadamy co sie dzieje. W kodzie produkcyjnym -- decydujemy.
> To roznica miedzy narracja a couplingiem.

---

## Faza 3-5: Nie dotyczy

Brak naruszen w kodzie produkcyjnym -- nie ma czego naprawiac. Fazy propozycji napraw, feedbacku i raportu koncowego sa pomijane.

---

## Werdykt

**Granice lingwistyczne: ZACHOWANE.**

Kod produkcyjny silnika jest czysto generyczny. `FootprintCalculator` operuje na `Component`, `requiresColdChainSurcharge()`, `coldChainSurchargeFactor()` i `contextParameters` -- nie zna nazw produktow, kategorii ani protokolow emisyjnych.

Testy poprawnie uzywaja specyficznego slownictwa biznesowego -- opowiadaja historyjki domenowe, nie lamia granic. 14 wystapien obcych terminow w `test/` to dokladnie to, czego chcemy: czytelne scenariusze, ktore mowia *"mrozone pielmieni z narzutem chlodzenia"* zamiast *"komponent z flaga surcharge"*.

**Wzorzec**: Granica lingwistyczna to bariera w kodzie produkcyjnym, nie w testach. Testy sa dokumentacja zachowania pisana w jezyku uzytkownika -- im bogatszy jezyk, tym lepsza dokumentacja.
