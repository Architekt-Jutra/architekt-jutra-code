# Cross-Source Verification

## Methodology

Porownanie findings z 3 kategorii zrodel:
- **internal-transcript**: obejscia FitBox (1 transkrypcja, 6 obejsc)
- **industry-practices**: praktyki cateringu dietetycznego/meal prep (15+ zrodel web)
- **food-delivery-patterns**: wzorce platform food delivery (15+ zrodel web)

---

## Verification Matrix

### Obejscie #1: Google Sheets na zmiany po cutoffie

| Aspekt | Internal | Industry | Food Delivery | Zgodnosc |
|--------|----------|----------|---------------|----------|
| Problem istnieje | Tak -- 15-20 dziennie | Tak -- znany anti-pattern "rigid cutoff without amendment window" | Tak -- wszystkie platformy maja ten sam problem | **Zgodne** |
| Mechanizm obejscia | Google Sheets + email | Brak danych o obejsciach (branzy dokumentuja rozwiazania, nie obejscia) | Cancel-and-reorder (Wolt, Glovo) jako oficjalny workaround | Czesciowo -- obejscia roznia sie formem |
| Rozwiazanie branzowe | N/A | Hard cutoff (5-7 dni) + delayed firing (Olo) + self-service zmian | State-based modification gates | **Zgodne** -- branza stosuje forcing functions |

**Confidence**: High (90%). Problem jest uniwersalny. FitBox stosuje shadow system (Google Sheets), branza stosuje forcing functions (cutoff + delayed firing).

---

### Obejscie #2: WhatsApp na pauzy

| Aspekt | Internal | Industry | Food Delivery | Zgodnosc |
|--------|----------|----------|---------------|----------|
| Problem istnieje | Tak -- system nie odejmuje pauz od razu | CaterZen: real-time cascade updates | Brak bezposredniego odpowiednika (food delivery nie ma pauz) | Czesciowo -- inny model biznesowy |
| Rozwiazanie branzowe | N/A | Real-time cascade: zmiana statusu propaguje do list produkcyjnych, manifest dostawy, faktur | N/A | Jednokierunkowe -- brak danych o obejsciach, tylko rozwiazania |

**Confidence**: Medium (70%). Problem specyficzny dla modelu subskrypcyjnego (pauzy). Rozwiazanie (real-time cascade) potwierdzone w CaterZen, ale brak danych o tym jak inne firmy radzily sobie z tym problemem przed wdrozeniem.

---

### Obejscie #3: Reczna synchronizacja alergenow

| Aspekt | Internal | Industry | Food Delivery | Zgodnosc |
|--------|----------|----------|---------------|----------|
| Problem istnieje | Tak -- 1-2 dniowa rozbieznosc, near-miss z tahini | Tak -- "human memory as allergen database" to znany anti-pattern | Tak -- Uber Eats wymaga jawnej deklaracji per alergen od restauracji | **Zgodne** |
| Powaznosc | Critical (bezpieczenstwo zywnosci) | Critical -- regulacje FDA 2026 wymagaja cyfrowej trasowalnosci | Critical -- Uber Eats traktuje alergeny jako funkcje bezpieczenstwa | **Zgodne** |
| Rozwiazanie branzowe | N/A | Profile allergenowe na poziomie klienta (CaterZen, CertiStar), real-time sync POS | Allergen data as system property + real-time sync (Squizify, Lavu, FoodDocs) | **Zgodne** -- branza odchodzi od pamieci ludzkiej |

**Confidence**: High (90%). Najsilniejsza zgodnosc miedzy zrodlami. Problem jest uniwersalny, rozwiazanie (systemowe zarzadzanie alergenami) jest standardem branzowym.

---

### Obejscie #4: Zamiany tras na parkingu

| Aspekt | Internal | Industry | Food Delivery | Zgodnosc |
|--------|----------|----------|---------------|----------|
| Problem istnieje | Tak -- ~50% tras zamienianych | Nowoczesne systemy (Upper, Onfleet) wspieraja reassignment na poziomie systemu | **Zadna** duza platforma nie wspiera swap miedzy kierowcami | **Zgodne** -- "parking lot swap" to anti-pattern |
| Motywacja | Kierowcy znaja teren lepiej niz algorytm | Algorytmy uwzgledniaja traffic + access patterns | DoorDash: DeepRed + MIP solver; Uber Eats: sensor-informed dispatch | Zgodne -- rozwiazanie to lepszy algorytm, nie reczne zamiany |
| Konsekwencje | Bledne ETA, brak trasowalnosci | N/A | Completion rate 90% jako forcing function (DoorDash); GPS tracking | **Zgodne** -- platformy zapobiegaja temu penaltiami |

**Confidence**: High (85%). FitBox ma anti-pattern, ktory nie ma odpowiednika w zadnej duzej platformie food delivery -- zamiany tras to operacja systemowa, nie parkingowa.

---

### Obejscie #5: Nadprodukcja przez opoznione zmiany

| Aspekt | Internal | Industry | Food Delivery | Zgodnosc |
|--------|----------|----------|---------------|----------|
| Problem istnieje | Tak -- codziennie | Tak -- "print-and-forget production lists" to znany anti-pattern | Nie dotyczy (food delivery nie ma batch production) | Czesciowo |
| Relacja z obejsciem #1 | Bezposrednia konsekwencja arkusza Google | N/A | N/A | Wewnetrzna relacja przyczynowa |
| Rozwiazanie branzowe | N/A | Delayed firing (Olo) + real-time cascade (CaterZen) + auto-generowane prep sheets (Flex, GoPrep) | N/A | Jednokierunkowe -- rozwiazania istnieja |

**Confidence**: Medium-High (80%). Problem jest konsekwencja obejscia #1. Rozwiazania branzowe sa dostepne, ale nie ma case studies o przejsciu z recznych procesow.

---

### Obejscie #6: Over-treatment diet bezglutenowych

| Aspekt | Internal | Industry | Food Delivery | Zgodnosc |
|--------|----------|----------|---------------|----------|
| Problem istnieje | Tak -- 1h/dzien ekstra | Tak -- tiered allergen classification to standard | HelloFresh jawnie rozroznia GF preference vs celiac | **Zgodne** |
| Rozwiazanie | Brak w systemie | Tiered classification: medical (<20ppm) vs preference (labeling) | HelloFresh: "nie nadajemy sie dla celiakii" -- jawna deklaracja | **Zgodne** |

**Confidence**: High (90%). Problem jest dobrze udokumentowany i ma jednoznaczne rozwiazanie branzowe (tiered classification).

---

## Contradictions

| # | Internal Claim | External Evidence | Assessment |
|---|---------------|-------------------|------------|
| 1 | FitBox cutoff 48h | Branza US: 5-7 dni; PL: 1-2 dni | **Nie sprzecznosc, lecz roznica modelu**: 48h cutoff FitBox jest w zakresie polskiego rynku, ale krotszy niz US. Problem nie jest w dlugosci cutoffa, lecz w braku enforcing (cutoff istnieje, ale Monika go omija). |
| 2 | "kierowcy znaja teren lepiej niz algorytm" | DoorDash: DeepRed + MIP solver optymalizuje lepiej niz ludzie | **Potencjalna sprzecznosc**: W duzych platformach algorytmy sa lepsze. Ale FitBox ma 8 kierowcow i lokalne warunki (kody do bram) -- algorytm FitBox moze nie uwzgledniac tych zmiennych, wiec kierowcy moga miec racje. |

---

## Missing Information

1. Ile kosztuje FitBox nadprodukcja z obejsc #1/#5 (koszty materialow + pracy)?
2. Ile reklamacji dziennie wynika z blednych ETA (obejscie #4)?
3. Czy Kasia mialaby wiecej near-miss incydentow z alergenami, gdyby nie jej dobra pamiec?
4. Jaki jest rzeczywisty (nie szacowany) podzial celiakia vs preferencja w bazach klientow?
5. Jak wyglada regulacja EU/PL dotyczaca trasowalnosci skladnikow (odpowiednik FDA 2026)?
6. Jak polskie firmy cateringowe (Dietly, ntfy, DietaPudelkowa) operacyjnie radza sobie z problemami analogicznymi do FitBox?

---

## Declarative Conclusions

Claims stated as fact by participants. These are assessments, not verified truths.
Each is evaluated for supporting evidence found across all gathered sources.

| # | Claim | Speaker | Supporting Evidence | Corroborated By | Verdict |
|---|-------|---------|--------------------|--------------------|---------|
| 1 | "klienci w ogole nie korzystaja z aplikacji mobilnej -- 90% zamowien przychodzi przez strone albo przez telefon" | Monika | Stated as observation from daily work; no data source cited | No external corroboration found; no system analytics referenced | **Unsupported** -- brak danych. Jesli bledne, priorytetyzacja kanalow zamowien jest zla. |
| 2 | "Kierowcy zamieniaja sie moze w polowie przypadkow" | Marek | "Trudno powiedziec" -- sam przyznaje niepewnosc | Brak danych GPS ani logistycznych do weryfikacji. External: platformy food delivery nie maja tego problemu (brak odpowiednika do porownania) | **Partially supported** -- Marek jest najblizej sytuacji, ale sam przyznaje ze szacuje. Rzeczywisty zakres moze byc 30-70%. |
| 3 | "z tego pewnie tylko 5-6 to prawdziwe celiaki. Reszta to lifestyle" | Tomek | "Pewnie" -- sygnal ze to szacunek. Brak danych z systemu ani od klientow. | External: HelloFresh rozroznia te kategorie, co potwierdza ze podzial jest realny. Ale proporcja 20-25% celiac jest specyficzna dla FitBox i niesprawdzalna bez danych. | **Partially supported** -- podzial celiac/lifestyle jest potwierdzony branzowo, ale proporcja Tomka to szacunek bez danych. |

**Uncertainty inheritance note**: Severity ranking obejscia #4 (route swaps -- High) czesciowo bazuje na Declarative #2 (~50% tras). Jesli rzeczywisty zakres to np. 20%, severity mogloby byc Medium. [DERIVED FROM DECLARATIVE #2 -- confidence ceiling: Partially supported]
