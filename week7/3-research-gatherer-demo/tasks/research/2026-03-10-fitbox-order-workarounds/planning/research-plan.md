# Research Plan: Obejscia systemu zamowien FitBox

## Research Overview

**Research Question**: Jakie obejscia stosuja ludzie w cateringu FitBox wobec oficjalnego systemu zamowien -- kto omija system, jak, dlaczego, i jakie to rodzi konsekwencje. Jak systemy cateringowe i food delivery radza sobie z obejsciami procesu zamowien. Poza zakresem: problemy z wydajnością strony WWW, ceny konkurencji.

**Research Type**: Mixed (wewnetrzna analiza transkrypcji + zewnetrzne badanie praktyk branzowych)

**Sub-questions**:
1. Jakie konkretne obejscia systemu zamowien stosuja pracownicy FitBox?
2. Kto (jaki aktor) stosuje kazde obejscie i jaka jest jego motywacja?
3. Jakie konsekwencje operacyjne, jakosciowe i bezpieczenstwa zywnosciowego rodza te obejscia?
4. Jakie mechanizmy (cutoff rules, forcing functions, walidacje) stosuja systemy cateringowe i food delivery, zeby zapobiegac obejsciom procesow zamowien?
5. Jakie wzorce obejsc sa uniwersalne w branzy food delivery / diet catering?

---

## Scope

### In Scope
- Obejscia systemu zamowien FitBox zidentyfikowane w transkrypcji spotkania
- Aktorzy stosujacy obejscia: Monika (obsluga klienta), Tomek (szef kuchni), Kasia (dietetyczka), Marek (logistyka), kierowcy
- Motywacje kazdego aktora do stosowania obejsc
- Mechanizmy obejsc (arkusze Google, WhatsApp, zamiany tras na parkingu, reczne procesy)
- Konsekwencje: operacyjne (bledne ETA, nadprodukcja), bezpieczenstwo zywnosci (alergeny), jakosc informacji (klient dostaje bledne dane)
- Praktyki branzowe w cateringu dietetycznym i food delivery wobec obejsc procesow zamowien
- Mechanizmy systemowe zapobiegajace obejsciom (cutoff rules, walidacje, forcing functions)

### Out of Scope
- Problemy z wydajnoscia strony internetowej FitBox
- Konkurencja cenowa (FreshMeal, obnizki cen)
- Projektowanie rozwiazan technicznych dla FitBox
- Personalizacja diet (analityka kombinatoryczna)
- Implementacja systemu zamowien

### Source Restrictions
- Zrodlo wewnetrzne: wylacznie `historia-agnieszki.md`
- Zrodla zewnetrzne: artykuly branzowe, case studies, dokumentacja systemow cateringowych, blogi branzowe food delivery/meal prep

---

## Success Criteria

### Concrete Deliverables
- [ ] Minimum 3 odrebne obejscia z FitBox, kazde opisane: aktor, mechanizm, motywacja, konsekwencja
- [ ] Minimum 3 zewnetrzne przyklady jak branza radzi sobie z obejsciami procesow zamowien
- [ ] Cross-source verification miedzy zrodlami wewnetrznymi i zewnetrznymi (czy obejscia FitBox odpowiadaja znanym wzorcom branzowym)

### Information Quality Requirements
- Kazde obejscie poparte cytatem z transkrypcji (zrodlo wewnetrzne)
- Kazdy przyklad branzowy z podaniem zrodla (URL, nazwa systemu, case study)
- Cross-verification: co najmniej 2 obejscia FitBox zderzone z praktykami branzowymi

---

## Actors

| Actor | Rola w FitBox | Optimizes For | Information Needs | Presentation Style |
|-------|--------------|---------------|-------------------|-------------------|
| Monika | Obsluga klienta | Szybka i poprawna odpowiedz klientowi | Ktore informacje w systemie sa niewiarygodne, jakie obejscia generuja bledne dane dla klienta | Operacyjna lista problemow z perspektywy kontaktu z klientem |
| Tomek | Szef kuchni | Jeden punkt prawdy o produkcji na 3:30 rano | Ktore obejscia powoduja rozbieznosc miedzy systemem a rzeczywista produkcja | Lista problemow z perspektywy produkcji |
| Kasia | Dietetyczka | Poprawnosc danych o alergenach i skladnikach | Gdzie procesy reczne (pamiec) zastepuja walidacje systemowe i jakie to rodzi ryzyka | Analiza ryzyka bezpieczenstwa zywnosci |
| Marek | Logistyka | Dostawy na czas z poprawnymi trasami | Jak systemy radza sobie z rozbieznoscia miedzy planowanymi a rzeczywistymi trasami | Porownanie z praktykami branzowymi |
| Agnieszka | Wlascicielka | Priorytetyzacja problemow, decyzja co naprawiac najpierw | Pelny obraz obejsc, ich waga, konsekwencje, i co branza robi inaczej | Podsumowanie wykonawcze z priorytetami |

### Per-Actor Output Sections
Raport z badan powinien umozliwiac filtrowanie findings per aktor -- kazde obejscie powinno miec oznaczonego aktora i kategorie konsekwencji.

---

## Information Layers

### Big Picture
- Jakie sa glowne kategorie obejsc w FitBox (zmiany zamowien, alergeny, trasy, pauzy)?
- Dlaczego pracownicy omijaja system (ograniczenia systemu vs nawyki vs brak szkolen)?
- Jakie sa konsekwencje biznesowe (utrata klientow, ryzyko prawne, koszty nadprodukcji)?
- Jak branza cateringowa/food delivery podchodzi do problemu obejsc systemowych?

### Modeling
- Jakie shadow processes istnieja rownolegle do oficjalnego systemu (arkusz Google, WhatsApp, zamiany na parkingu)?
- Jakie invarianty sa lamane przez obejscia (np. "lista produkcyjna o 3:30 = prawda", "dane o alergenach = aktualne")?
- Jakie forcing functions lub walidacje moglyby eliminowac obejscia (cutoff rules, blokady, automatyczne synchronizacje)?
- Jakie wzorce obejsc sa uniwersalne (np. "last-mile routing override" w food delivery)?

### Implementation
- (Out of scope per research brief -- brak pytan implementacyjnych)

---

## Methodology

### Primary Approach
1. **Analiza transkrypcji** (zrodlo wewnetrzne): systematyczna ekstrakcja obejsc z transkrypcji spotkania FitBox -- identyfikacja aktorow, mechanizmow, motywacji, konsekwencji
2. **Web research** (zrodla zewnetrzne): wyszukiwanie praktyk branzowych w cateringu dietetycznym i food delivery dotyczacych zapobiegania obejsciom procesow zamowien

### Fallback Strategies
- Jesli brak materialow branzowych o cateringu dietetycznym -- rozszerzyc na ogolny food delivery (DoorDash, Uber Eats, HelloFresh)
- Jesli brak case studies -- szukac w dokumentacji systemow (ordering system design patterns, order management workarounds)

### Analysis Framework
- **Workaround taxonomy**: Klasyfikacja kazdego obejscia wg schematu: Aktor -> Mechanizm -> Motywacja -> Konsekwencja
- **Cross-source verification**: Zderzenie obejsc FitBox z praktykami branzowymi -- czy obejscie FitBox to znany wzorzec?
- **Severity assessment**: Ocena powaznosci konsekwencji (bezpieczenstwo zywnosci > operacyjne > informacyjne)

---

## Gathering Strategy

### Instances: 3

| # | Category ID | Focus Area | Tools | Output Prefix | Layers |
|---|------------|------------|-------|---------------|--------|
| 1 | internal-transcript | Systematyczna ekstrakcja obejsc z transkrypcji FitBox: identyfikacja aktorow, mechanizmow, motywacji, konsekwencji. Cytaty z transkrypcji jako evidence. | Read | internal-transcript | Big Picture, Modeling |
| 2 | industry-practices | Jak systemy cateringowe i meal-prep radza sobie z obejsciami zamowien: cutoff rules, forcing functions, walidacje, order amendment workflows. Szukac: diet catering order management, meal prep ordering system workarounds, catering order cutoff best practices. | WebSearch, WebFetch | industry-practices | Big Picture, Modeling |
| 3 | food-delivery-patterns | Wzorce z food delivery (DoorDash, Uber Eats, HelloFresh, Wolt) dotyczace: last-mile routing overrides, order modification windows, allergen management, driver route swapping. Szukac: food delivery order modification policy, delivery route optimization driver override, allergen management food delivery system. | WebSearch, WebFetch | food-delivery-patterns | Big Picture, Modeling |

### Rationale
Trzy instancje pokrywaja odrebne klasy zrodel:
- **internal-transcript**: jedno zrodlo wewnetrzne (transkrypcja) wymaga glebokie, systematycznej analizy -- kazde zdanie moze zawierac obejscie lub konsekwencje
- **industry-practices**: catering dietetyczny / meal-prep to niszowa branza -- dedykowany gatherer pozwala na skupiony web research z wlasciwymi terminami wyszukiwania
- **food-delivery-patterns**: food delivery (DoorDash, Uber Eats, HelloFresh) to duza branza z dobrze udokumentowanymi praktykami -- osobny gatherer uniknie mieszania wynikow z niszowym cateringiem

Podzial external na dwie instancje (industry-practices vs food-delivery-patterns) jest uzasadniony roznica w terminologii wyszukiwania i dostepnosci zrodel.

---

## Expected Outputs

### Per Gatherer
- `analysis/findings/internal-transcript-*.md` -- wyekstrahowane obejscia z cytatami
- `analysis/findings/industry-practices-*.md` -- praktyki branzowe z cateringu dietetycznego
- `analysis/findings/food-delivery-patterns-*.md` -- wzorce z food delivery

### Cross-Source Verification
- `analysis/findings/cross-source-verification.md` -- zderzenie obejsc FitBox z praktykami branzowymi

### Final Merged Output
- `analysis/findings/summary.md` -- podsumowanie wszystkich findings z cross-verification