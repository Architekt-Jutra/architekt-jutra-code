# Rejected Information

Research question: Jakie obejscia stosuja ludzie w cateringu FitBox wobec oficjalnego systemu zamowien -- kto omija system, jak, dlaczego, i jakie to rodzi konsekwencje. Jak systemy cateringowe i food delivery radza sobie z obejsciami procesu zamowien.

Scope: Obejscia systemu zamowien, aktorzy, motywacje, konsekwencje, praktyki branzowe. Wykluczone: wydajnosc strony, konkurencja cenowa, projektowanie rozwiazan technicznych.

---

## Out of Scope (Different Module/Component)

| # | Information | Source | Why Rejected | Re-include If |
|---|------------|--------|-------------|---------------|
| 1 | "nasza strona internetowa laduje sie strasznie wolno, klienci sie skarza" | Monika, transcript | Website performance -- osobna domena problemowa, nie obejscie systemu zamowien | Scope expanded to include digital touchpoint quality |
| 2 | "raport z systemu grupuje inaczej niz ja potrzebuje" | Kasia, transcript | Reporting/analytics gap -- system usability issue, nie obejscie procesu zamowien | Scope expanded to include reporting/analytics gaps |
| 3 | DoorDash microservices migration (monolith -> Kotlin + gRPC) | DoorDash Engineering Blog | Implementation architecture detail, nie wzorzec obejsc zamowien | Scope includes technical implementation recommendations |
| 4 | Uber Eats sensor data integration (accelerometers, gyroscopes) | Uber Engineering Blog | Low-level technical detail o dispatch optimization | Scope includes technical driver tracking implementation |

## Out of Scope (Different Information Layer)

| # | Information | Source | Why Rejected | Re-include If |
|---|------------|--------|-------------|---------------|
| 1 | Detailed comparison of meal prep service pricing and nutritional value | Revgear, Mealfan, CleanEatzKitchen | Pricing/nutrition comparison | Scope expanded to competitive analysis |
| 2 | Specific meal kit recipes and dietary plan details | Various meal kit review sites | Product content, nie process/system | Scope includes product design |
| 3 | Ghost kitchen infrastructure (multi-kitchen facilities, pod transport) | CloudKitchens blog | Business model detail | Scope includes ghost kitchen operational patterns |
| 4 | Multi-apping strategies (running DoorDash + Uber Eats simultaneously) | The Rideshare Guy | Driver income optimization, nie order management | Scope includes driver behavior beyond route swaps |

## Out of Scope (Competitive/Pricing)

| # | Information | Source | Why Rejected | Re-include If |
|---|------------|--------|-------------|---------------|
| 1 | "konkurencja -- FreshMeal -- obnizyla ceny o 15%, od dwoch tygodni tracimy klientow" | Monika, transcript | Competitive pricing -- explicite out of scope | Scope expanded to competitive landscape or churn analysis |
| 2 | DoorDash 2025 policy on "Most Loved" merchant incentives | DoorDash policy update | Incentive program details beyond forcing function pattern | Scope includes platform incentive design |
| 3 | Meal delivery service subscription marketing strategies | Optimum7 | Marketing focus, nie operational workflow | Scope includes go-to-market strategy |

## Out of Scope (Regulatory/Tax)

| # | Information | Source | Why Rejected | Re-include If |
|---|------------|--------|-------------|---------------|
| 1 | FDA 2026 employer meal deduction tax rules | UHY, CRI&G | Tax regulation, nie food safety or order management | Scope includes financial/tax implications |
| 2 | Grubhub outsourcing delivery to avoid minimum wage | Streetsblog NYC | Regulatory/labor issue | Scope expanded to gig economy labor practices |

## Solution Not Problem

| # | Information | Source | Why Rejected | Re-include If |
|---|------------|--------|-------------|---------------|
| 1 | "Nasz system jest jedynym takim na rynku, ktory pozwala na personalizacje diety na poziomie pojedynczego dania" | Kasia, transcript | Product uniqueness claim -- nie obejscie. Kombinatoryczna eksplozja wariantow to system limitation, nie workaround. | Scope expanded to include system limitations beyond order workarounds |

---

## Summary

- Total findings collected: **~45** (6 internal workarounds + ~25 industry findings + ~15 food delivery patterns)
- Total rejected: **14**
- Rejection rate: **~24%**
