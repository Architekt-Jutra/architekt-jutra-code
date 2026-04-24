# Internal Transcript Findings: Workarounds in FitBox Order System

**Source**: `materials/research-demo/historia-agnieszki.md`
**Research Question**: Jakie obejscia stosuja ludzie w cateringu FitBox wobec oficjalnego systemu zamowien -- kto omija system, jak, dlaczego, i jakie to rodzi konsekwencje.
**Layers**: Big Picture, Modeling

---

## Workaround #1: Google Sheets for Post-Cutoff Order Changes

**Actor**: Monika (obsuga klienta)
**Mechanism**: Manual entry in Google Sheets + email to kitchen
**Motivation**: System enforces 48h cutoff for order changes; customers call wanting next-day changes
**Frequency**: 15-20 per day
**Severity**: High (operational + information quality)

### Evidence

> "Klienci dzwonia, zeby zmienic posilek na jutro, a system pozwala na zmiany tylko 48 godzin wczesniej. Wiec ja wpisuje te zmiany recznie w arkuszu Google i wysylam mailem do kuchni. Dziennie mam z 15-20 takich telefonow."
> -- Monika, obsuga klienta

### Consequences

1. **Shadow data source**: Google Sheets becomes a parallel source of truth alongside the official system. Kitchen must check two places.
2. **Timing mismatch with production**: Changes arrive at unpredictable times (sometimes 22:00), but production lists print at 3:30 AM. Changes arriving after print are lost.
3. **Customer complaints loop**: Wrong meal produced -> customer calls Monika -> Monika handles reklamacja -> more load on obsuga klienta.

### Broken Invariant

`system_orders_at_3:30 == actual_production_list` -- FALSE. The Google Sheet contains orders that diverge from the system state.

---

## Workaround #2: WhatsApp for Pause Notifications

**Actor**: Monika -> Tomek (obsuga klienta -> szef kuchni)
**Mechanism**: WhatsApp message instead of system update
**Motivation**: System does not immediately remove paused customers from production list (waits for next "billing cycle")
**Frequency**: Not quantified, but described as recurring
**Severity**: Medium-High (waste + operational)

### Evidence

> "Klient jedzie na urlop, pauzuje na tydzien. Ale system nie odejmuje go z listy produkcyjnej od razu, tylko od nastepnego 'cyklu rozliczeniowego'. Wiec ja czasem produkuje posilki dla kogos, kto jest na Malediwach. Dowiaduje sie o tym jak Monika mi pisze na WhatsAppie 'nie rob jutro dla Kowalskiej, jest na urlopie'. To powinno byc w systemie, a nie na WhatsAppie."
> -- Tomek, szef kuchni

### Consequences

1. **Overproduction**: Meals produced for customers who paused = wasted food and labor cost.
2. **Informal channel dependency**: Critical production information travels via WhatsApp instead of the system of record.
3. **No audit trail**: WhatsApp messages are not logged, searchable, or verifiable.

### Broken Invariant

`production_list == active_customers_only` -- FALSE. Paused customers remain on production list until next billing cycle.

---

## Workaround #3: Manual Allergen Synchronization Across Modules

**Actor**: Kasia (dietetyczka)
**Mechanism**: Manual update of ingredient database in a separate module after recipe changes
**Motivation**: Changing a recipe in one module does not automatically update allergen labels in the ingredient database module
**Frequency**: Weekly (during menu updates), with 1-2 day lag
**Severity**: Critical (food safety)

### Evidence

> "Ja co tydzien aktualizuje jadlospisy -- zmieniam skladniki, proporcje, czasem caly przepis. I to wpisuje w system. Ale etykiety z alergenami generuja sie z bazy skladnikow, a baza nie zawsze jest aktualna. Znaczy -- ja zmieniam przepis, ale zeby zaktualizowac baze skladnikow, musze wejsc w osobny modul i tam pozmieniac. Czasem mi sie to rozjedzie o dzien czy dwa."
> -- Kasia, dietetyczka

> "Miesiac temu byl przypadek, ze klientka z alergia na orzechy dostala posilek, w ktorym byla pasta tahini, a tahini w starej bazie nie bylo oznaczone jako alergen orzechowy. Nic sie nie stalo, bo klientka sprawdzila zanim zjadla i zadzwonila. Ale moglo sie stac."
> -- Kasia, dietetyczka

> "System nie ma zadnego mechanizmu, ktory by blokowal zmiane przepisu bez aktualizacji alergenow. Ja to robie z pamieci. Jak mam duzo zmian w tygodniu, moge przeoczyc."
> -- Kasia, dietetyczka

### Consequences

1. **Food safety risk**: 1-2 day window where allergen data is incorrect. Near-miss incident with tahini/tree nut allergy already occurred.
2. **Human memory as validation**: No system-level forcing function; Kasia's memory is the only safeguard.
3. **Cascading misinformation**: Monika reads allergen data from system to answer customer calls -- provides incorrect data without knowing it.

### Cascading Effect (Monika)

> "Klienci, ktorzy maja alergie, czesto dzwonia zeby potwierdzic sklad. Ja wtedy otwieram system i czytam co tam jest. Ale jak Kasia mowi, ze to bywa nieaktualne... to ja podaje klientowi zle informacje i nawet o tym nie wiem."
> -- Monika, obsuga klienta

### Broken Invariant

`recipe_ingredients == allergen_label_ingredients` -- FALSE during 1-2 day synchronization window. No forcing function prevents this divergence.

---

## Workaround #4: Parking Lot Route Swaps by Drivers

**Actor**: Marek (logistyka) / Kierowcy (Janek, Pawel, et al.)
**Mechanism**: Drivers swap assigned routes among themselves on the parking lot before departure
**Motivation**: System-generated routes ignore real-world knowledge (gate codes, building access patterns, traffic)
**Frequency**: ~50% of routes swapped daily
**Severity**: High (information quality + customer trust)

### Evidence

> "Kierowcy po tygodniu znaja swoje rejony lepiej niz algorytm, wiec zamieniaja sie trasami miedzy soba na parkingu. W systemie jest Janek na Mokotowie, a w rzeczywistosci jedzie tam Pawel, bo Pawel zna kody do bram."
> -- Marek, logistyka

> "Klient dzwoni do Moniki: 'gdzie moja paczka?', Monika patrzy w system, widzi ze Janek jest na Ursynowie, mowi klientowi 'kierowca jest 20 minut od pana' -- a tak naprawdzo Pawel jest za rogiem."
> -- Marek, logistyka

> "Ja daje klientom ETY na podstawie systemu, a system klamie, bo kierowcy sie zamienili. Klienci mysla, ze jestesmy niekompetentni."
> -- Monika, obsuga klienta

### Consequences

1. **False ETA information**: System-reported driver location is wrong in ~50% of cases.
2. **Customer trust erosion**: Customers receive incorrect delivery estimates, perceive company as incompetent.
3. **No traceability**: If a delivery problem occurs, system records show the wrong driver.

### Broken Invariant

`system_driver_assignment == actual_driver_on_route` -- FALSE in ~50% of cases.

---

## Workaround #5: Overproduction Due to Delayed Order Changes

**Actor**: Tomek (szef kuchni)
**Mechanism**: Printing production lists at 3:30 AM from system data, while Google Sheet changes arrive after print
**Motivation**: No integration between Google Sheet workaround (#1) and production system
**Frequency**: Daily ("zdarza sie codziennie")
**Severity**: High (waste + customer dissatisfaction)

### Evidence

> "Ja o tych zmianach z arkusza dowiaduje sie o roznych porach. Czasem mail przychodzi o 22, a my drukujemy listy produkcyjne o 3:30, bo o 4:00 juz ruszamy. Jak zmiana wejdzie po wydrukowaniu -- a to sie zdarza codziennie -- to produkujemy na starych danych. Efekt? Robimy posilek, ktory klient juz zmienil, i nie robimy tego, ktory zamowil. A potem Monika ma reklamacje. Kolo sie zamyka."
> -- Tomek, szef kuchni

> "Ja bym chcial jeden punkt prawdy -- to co widze w systemie o 3:30, to jest FINALNE. A nie ze ktos jeszcze o 2 w nocy cos zmienia."
> -- Tomek, szef kuchni

### Consequences

1. **Double waste**: Wrong meal produced (wasted) + correct meal not produced (customer complaint).
2. **Complaint loop**: Monika handles reklamacja caused by a workaround she herself created.
3. **No single source of truth**: Tomek's core need -- "one point of truth at 3:30" -- is fundamentally broken.

### Note

This is a **second-order consequence** of Workaround #1. The Google Sheet workaround creates a timing problem that cascades into production.

---

## Workaround #6: Over-Treatment of Gluten-Free Diets

**Actor**: Tomek (szef kuchni)
**Mechanism**: Treating ALL gluten-free orders as celiac (full separation protocol) because system does not distinguish preference from medical condition
**Motivation**: Fear of causing harm to celiac customers; no system-level differentiation
**Frequency**: 25-30 gluten-free orders/day, of which ~5-6 are actual celiac
**Severity**: Medium (operational efficiency)

### Evidence

> "System nie rozroznia 'bezglutenowa ze wzgledow preferencji' od 'bezglutenowa celiakia'. Dla kuchni to ogromna roznica -- celiakia wymaga pelnej separacji, preferencja nie. Traktuje wszystkie jak celiakie, bo sie boje. To mi zajmuje dodatkowa godzine dziennie."
> -- Tomek, szef kuchni

> "Ile mamy bezglutenowych dziennie?" -- Agnieszka
> "Jakies 25-30. Ale z tego pewnie tylko 5-6 to prawdziwe celiaki. Reszta to lifestyle." -- Tomek

### Consequences

1. **Wasted labor**: ~1 extra hour/day on unnecessary full-separation protocols for ~20-24 preference-based orders.
2. **Capacity constraint**: Unnecessary separation reduces kitchen throughput.
3. **Risk calibration impossible**: Without data, Tomek cannot optimize -- he defaults to maximum caution.

### Broken Invariant

`diet_type_label == medical_vs_preference_distinction` -- FALSE. System collapses two fundamentally different operational requirements into one label.

---

## Cross-Cutting Patterns

### Pattern A: Shadow Systems

Workarounds #1 (Google Sheets) and #2 (WhatsApp) create **shadow systems** -- parallel information channels that operate outside the official system. These shadow systems:
- Have no audit trail
- Are not synchronized with the system of record
- Create timing windows where data diverges
- Depend on individual people (Monika) as integration points

### Pattern B: Human Memory as Validation

Workarounds #3 (allergen sync) and #6 (gluten-free over-treatment) rely on **human memory** as the only safeguard:
- Kasia remembers to update allergen database after recipe changes
- Tomek remembers to treat all gluten-free as celiac
- No system-level forcing functions or validations exist

### Pattern C: Cascading Failures

Workarounds generate second-order problems:
- #1 (Google Sheets) -> #5 (overproduction) -> customer complaints -> Monika workload
- #3 (allergen sync lag) -> Monika gives wrong allergen info to customers
- #4 (route swaps) -> Monika gives wrong ETA to customers

**Monika is the convergence point** for consequences of all workarounds. She absorbs the downstream impact of every shadow process.

### Pattern D: Missing System Distinctions

Workarounds #6 (gluten-free) and #3 (allergens) share a root cause: **the system lacks granularity**. It does not model:
- Medical vs. preference dietary requirements
- Recipe-ingredient-allergen dependency chains

---

## Workaround Severity Ranking

| # | Workaround | Severity | Category | Justification |
|---|-----------|----------|----------|---------------|
| 3 | Allergen sync lag | Critical | Food safety | Near-miss incident. Potential legal liability. Human memory is only safeguard. |
| 1 | Google Sheets post-cutoff | High | Operational + Info quality | 15-20/day, causes cascading overproduction (#5) and complaint loop |
| 4 | Route swaps on parking | High | Info quality + Trust | ~50% of routes affected, false ETAs to customers |
| 5 | Overproduction from delayed changes | High | Waste + Customer | Daily occurrence, direct consequence of #1 |
| 2 | WhatsApp pause notifications | Medium-High | Waste + Operational | Overproduction for paused customers, no audit trail |
| 6 | Gluten-free over-treatment | Medium | Efficiency | 1 hour/day wasted, but safety-motivated (acceptable trade-off until system improves) |

---

## Declarative Conclusions

| # | Claim | Speaker | Timestamp | Supporting Reasons (quoted) | Unsupported? |
|---|-------|---------|-----------|----------------------------|--------------|
| 1 | "klienci w ogole nie korzystaja z aplikacji mobilnej -- 90% zamowien przychodzi przez strone albo przez telefon" | Monika | Transcript (no timestamp) | Stated as observation from daily work; no data source cited. If wrong, mobile app investment priorities change. | No hard data provided -- could be perception bias. |
| 2 | "Kierowcy zamieniaja sie moze w polowie przypadkow" | Marek | Transcript (no timestamp) | "Trudno powiedziec" -- Marek himself admits uncertainty. If actual rate is much lower, the ETA problem is less severe. | Explicitly acknowledged as estimate ("trudno powiedziec"). |
| 3 | "z tego pewnie tylko 5-6 to prawdziwe celiaki. Reszta to lifestyle" | Tomek | Transcript (no timestamp) | No data cited. Word "pewnie" (probably) signals this is an estimate. If actual celiac count is higher, over-treatment waste estimate is wrong. | Estimate -- "pewnie" qualifier. |

**Note on derived conclusions**: The severity ranking above for Workaround #4 (route swaps) uses Declarative Conclusion #2 ("~50% of routes") as input. [DERIVED FROM DECLARATIVE #2 -- confidence ceiling: same as source verdict, i.e. acknowledged estimate]. The 1-hour/day waste figure for Workaround #6 is taken directly from Tomek's claim and depends on Declarative Conclusion #3 for the celiac/lifestyle split.

---

## Rejected Information

| # | Information | Source | Rejection Reason | Re-include If |
|---|------------|--------|-----------------|---------------|
| 1 | "nasza strona internetowa laduje sie strasznie wolno, klienci sie skarza" | Monika, transcript | Website performance is explicitly out of scope per research plan | Scope expanded to include digital touchpoint quality |
| 2 | "konkurencja -- FreshMeal -- obnizyla ceny o 15%, od dwoch tygodni tracimy klientow" | Monika, transcript | Competitive pricing is explicitly out of scope per research plan | Scope expanded to include competitive landscape or churn analysis |
| 3 | "Nasz system jest jedynym takim na rynku, ktory pozwala na personalizacje diety na poziomie pojedynczego dania" | Kasia, transcript | Product uniqueness claim -- not a workaround. The combinatorial complexity she describes is a system limitation, not an obejscie. | Scope expanded to include system limitations beyond order workarounds |
| 4 | "raport z systemu grupuje inaczej niz ja potrzebuje" | Kasia, transcript | Reporting mismatch -- a system usability issue, not a workaround of the order process | Scope expanded to include reporting/analytics gaps |

---

## Actor Relevance

| Actor | Relevance | Key Takeaway |
|-------|-----------|--------------|
| Monika (Obsuga klienta) | High | Jest punktem zbieznosci konsekwencji WSZYSTKICH obejsc -- obsluguje reklamacje z nadprodukcji (#5), podaje bledne ETY (#4), podaje nieaktualne alergeny (#3). Jednoczesnie sama tworzy obejscie #1 (arkusz Google). |
| Tomek (Szef kuchni) | High | Potrzebuje "jednego punktu prawdy o 3:30" -- obecnie ma dwa zrodla (system + arkusz Google) i informacje o pauzach przez WhatsApp. Traci 1h dziennie na over-treatment bezglutenowych. |
| Kasia (Dietetyczka) | High | Jedyny safeguard na poprawnosc alergenow to jej pamiec. Near-miss z tahini pokazuje, ze system nie ma forcing function na synchronizacje przepis-skladniki-alergeny. |
| Marek (Logistyka) | High | Kierowcy omijaja system tras w ~50% przypadkow. System nie uwzglednia wiedzy lokalnej (kody do bram, korki). Brak mechanizmu raportowania rzeczywistych tras. |
| Agnieszka (Wlascicielka) | High | Priorytet #1 to alergen safety (ryzyko prawne). Nastepnie: arkusz Google + nadprodukcja (koszty + reklamacje). Trasy i pauzy to problemy operacyjne o nizszym ryzyku. |
