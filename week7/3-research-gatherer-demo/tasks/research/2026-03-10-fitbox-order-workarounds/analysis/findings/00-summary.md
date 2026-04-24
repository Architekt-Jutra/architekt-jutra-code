# Research Summary: Obejscia systemu zamowien FitBox

## Research Question

Jakie obejscia stosuja ludzie w cateringu FitBox wobec oficjalnego systemu zamowien -- kto omija system, jak, dlaczego, i jakie to rodzi konsekwencje. Jak systemy cateringowe i food delivery radza sobie z obejsciami procesu zamowien.

## Sources Investigated

| Category | Files | Sources |
|----------|-------|---------|
| internal-transcript | 1 | 1 transkrypcja spotkania (5 osob, ~50 wypowiedzi) |
| industry-practices | 1 | 15+ zrodel web: Factor, HelloFresh, CookUnity, Trifecta, Olo, CaterZen, Flex Catering, CloudKitchens, Upper, Onfleet, CertiStar, EveryBite |
| food-delivery-patterns | 1 | 15+ zrodel web: DoorDash, Uber Eats, HelloFresh, Wolt, Glovo, GoPrep + engineering blogi |

**Total**: 3 findings files, 30+ external sources, 1 internal source.

---

## Key Findings

### A. Obejscia w FitBox (ze zrodla wewnetrznego)

Zidentyfikowano **6 odrebnych obejsc** systemu zamowien:

| # | Obejscie | Aktor | Mechanizm | Severity |
|---|---------|-------|-----------|----------|
| 1 | Arkusz Google na zmiany po cutoffie | Monika | Google Sheets + email do kuchni | High |
| 2 | WhatsApp na pauzy klientow | Monika -> Tomek | WhatsApp zamiast systemu | Medium-High |
| 3 | Reczna synchronizacja alergenow | Kasia | Pamiec + osobny modul | **Critical** (food safety) |
| 4 | Zamiany tras na parkingu | Kierowcy/Marek | Nieformalne zamiany miedzy kierowcami | High |
| 5 | Nadprodukcja przez opoznione zmiany | Tomek | Druk list o 3:30, zmiany po druku | High |
| 6 | Over-treatment diet bezglutenowych | Tomek | Wszystkie GF jak celiakia | Medium |

**4 cross-cutting patterns**: shadow systems (Google Sheets, WhatsApp), human memory as validation, cascading failures (Monika jako punkt zbieznosci), missing system distinctions.

### B. Praktyki branzowe (ze zrodel zewnetrznych)

**9 forcing functions** zidentyfikowanych w branzy:

| Forcing Function | Zapobiega | Stosowane przez |
|-----------------|-----------|----------------|
| Hard cutoff (5-7 dni) | Poznym modyfikacjom | Factor, HelloFresh, CookUnity, Trifecta |
| Order throttling | Przeciazeniu kuchni | Olo |
| Delayed firing | Niepotrzebnym "cancel & reorder" | Olo |
| Revenue-based lead time | Zlozonym zamowieniom last-minute | Olo |
| Blackout dates | Nadmiernej sprzedazy w szczycie | CaterZen |
| Per-item lead time | Niewystarczajacemu czasowi na specjalne pozycje | Olo |
| Client profile allergens | Pominiecie alergenu przy zamowieniu | CaterZen, CertiStar |
| Dynamic route reassignment | Nieformalnym zamianom tras | Upper, Onfleet |
| Tiered allergen classification | Over-treatment (celiakia vs preferencja) | Standard branzowy |

**Uniwersalny wzorzec**: Kazda platforma food delivery ma "punkt bez powrotu" (production commitment point) -- stan zamowienia, po ktorym modyfikacje sa systemowo zablokowane.

### C. Zderzenie FitBox z branza

| Obejscie FitBox | Odpowiednik branzowy | Status |
|-----------------|---------------------|--------|
| Google Sheets po cutoffie | Hard cutoff + delayed firing | FitBox: brak forcing function -> shadow system |
| WhatsApp na pauzy | Real-time cascade updates (CaterZen) | FitBox: system nie propaguje pauz natychmiast |
| Reczna sync alergenow | Profile allergenowe + real-time sync | FitBox: pamiec ludzka zamiast systemu |
| Zamiany tras | Algorytmiczne przypisanie + GPS + kary | FitBox: brak sledzenia, kierowcy omijaja system |
| Over-treatment GF | Tiered classification (celiac vs preference) | FitBox: jedna kategoria na dwa rozne wymagania |

---

## Gaps and Uncertainties

1. **Polish market specifics**: Ograniczone dane operacyjne z polskiego rynku cateringu dietetycznego (glownie strony marketingowe, nie case studies)
2. **Route swap frequency**: Marek oszacowal na "polowe przypadkow", ale sam przyznal niepewnosc ("trudno powiedziec")
3. **Celiac/lifestyle split**: Tomek szacuje 5-6 celiakii z 25-30 bezglutenowych -- to estimate bez danych
4. **Mobile app usage**: Monika twierdzi ze 90% zamowien przychodzi przez strone/telefon -- brak twardych danych
5. **Regulatory applicability**: FDA 2026 traceability rule dotyczy rynku US, nie EU/PL -- odpowiednik w prawie EU nie zostal zbadany
6. **Transition case studies**: Brak case studies opisujacych przejscie z recznych procesow na systemy -- dostepne sa tylko opisy stanu docelowego

## Overall Confidence

**High (85%)** — wewnetrzne obejscia sa dobrze udokumentowane cytatami z transkrypcji. Praktyki branzowe potwierdzone z oficjalnej dokumentacji platform. Glowne luki dotycza danych ilosciowych z FitBox (szacunki, nie pomiary) i specyfiki polskiego rynku.
