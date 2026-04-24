# Actor Map: Research Findings by Stakeholder

## How to Use This Document

Each section presents the same research findings tailored to a specific stakeholder's perspective, priorities, and language. Share the relevant section with each person.

---

### Monika (Obsluga klienta)

**Optimizes for**: Szybka i poprawna odpowiedz klientowi
**Presentation style**: Operacyjna lista problemow z perspektywy kontaktu z klientem

| # | Finding | Source | Why It Matters (to her) |
|---|---------|--------|--------------------------|
| 1 | Branzy cateringowa i food delivery stosuja self-service zmian przez app/web -- klient sam zmienia zamowienie, nie dzwoni | industry-practices, food-delivery | 15-20 telefonow dziennie o zmiany zamowien mogloby zniknac, gdyby klienci mieli self-service z odpowiednim oknem zmian |
| 2 | Wszystkie platformy food delivery blokuja modyfikacje po akceptacji zamowienia -- Monika nie powinna moc wpisywac zmian po cutoffie | food-delivery (DoorDash, Uber Eats) | Arkusz Google jest shadow systemem -- branzy wymusza cutoff systemowo, nie polega na dyscyplinie ludzkiej |
| 3 | Dane o alergenach, ktore Monika podaje klientom przez telefon, moga byc nieaktualne o 1-2 dni | internal-transcript (#3) | Monika podaje informacje z systemu nie wiedzac, ze sa nieaktualne -- ryzyko prawne i zdrowotne |
| 4 | System pokazuje innego kierowce niz rzeczywisty w ~50% przypadkow -- ETA ktore Monika podaje sa bledne | internal-transcript (#4) | Klienci mysla ze firma jest niekompetentna, a Monika nie ma mozliwosci podania poprawnych danych |
| 5 | CaterZen propaguje zmiany statusu klienta (pauzy) w real-time do wszystkich dokumentow | industry-practices | WhatsApp na pauzy nie byloby potrzebne, gdyby system automatycznie aktualizowal listy produkcyjne |

**Declarative conclusions relevant to this actor**:
- "klienci w ogole nie korzystaja z aplikacji mobilnej -- 90% zamowien przychodzi przez strone albo przez telefon" (Monika) -- **Unsupported**. Jesli aplikacja mobilna jest faktycznie uzywana, Monika moze nie widziec tych zamowien.

---

### Tomek (Szef kuchni)

**Optimizes for**: Jeden punkt prawdy o produkcji na 3:30 rano
**Presentation style**: Lista problemow z perspektywy produkcji

| # | Finding | Source | Why It Matters (to him) |
|---|---------|--------|--------------------------|
| 1 | Olo stosuje "delayed firing" -- zamowienie przyjete, ale nie wyslane do kuchni az do momentu produkcji. Zmiany przed firing window nie psuja listy. | industry-practices | Rozwiazuje problem: "to co widze o 3:30 jest FINALNE". System powinien zamrazac zamowienia przed 3:30, nie po. |
| 2 | CaterZen: zmiana headcount rano -> automatycznie aktualizuje prep sheets, manifesty dostawy, faktury | industry-practices | Eliminuje problem: zmiana w arkuszu Google po wydrukowaniu listy. System powinien kaskadowo aktualizowac wszystko. |
| 3 | HelloFresh rozroznia "GF z preferencji" vs "celiakia" -- celiac wymaga pelnej separacji, preferencja nie | food-delivery | Tomek traci 1h dziennie na over-treatment. Dystynkcja medical/preference w systemie pozwolilaby traktowac 20-24 zamowien standardowo. |
| 4 | GoPrep: configurable cutoff per pozycja (np. indyk 72h, standardowe 24h) + auto-generowane prep sheets | industry-practices | Rozne pozycje menu moga miec rozne cutoff -- bardziej granularne niz jeden 48h cutoff dla wszystkiego. |
| 5 | WhatsApp na pauzy to shadow system -- system powinien odejmowac klienta z listy produkcyjnej natychmiast, nie od nastepnego cyklu rozliczeniowego | internal-transcript (#2) | Tomek produkuje posilki dla klientow na Malediwach, bo system ich nie usunol. |

**Declarative conclusions relevant to this actor**:
- "z tego pewnie tylko 5-6 to prawdziwe celiaki. Reszta to lifestyle" (Tomek) -- **Partially supported**. Podzial celiac/lifestyle jest potwierdzony branzowo, ale proporcja 20-25% to estimate Tomka bez danych. Warto zweryfikowac z ankieta klientow.

---

### Kasia (Dietetyczka)

**Optimizes for**: Poprawnosc danych o alergenach i skladnikach
**Presentation style**: Analiza ryzyka bezpieczenstwa zywnosci

| # | Finding | Source | Why It Matters (to her) |
|---|---------|--------|--------------------------|
| 1 | Branza odchodzi od "pamiec ludzka jako baza alergenow" -- systemy POS (Squizify, Lavu, FoodDocs) synchronizuja dane o alergenach w real-time | food-delivery, industry-practices | Kasia jest jedynym safeguardem na poprawnosc alergenow. Branza wymaga systemowego wymuszenia, nie polegania na pamieci. |
| 2 | CertiStar przetwarza 170+ alergenow (nie tylko top 8/14). Profile alergenowe na poziomie klienta, nie zamowienia. | industry-practices | Eliminuje problem z tahini -- system powinien automatycznie oznaczyc tahini jako alergen orzechowy. |
| 3 | Near-miss z tahini/orzechami to incydent krytyczny -- 1-2 dniowe okno rozbieznosci miedzy przepisem a etykieta alergenu | internal-transcript (#3) | Nastepny incydent moze nie skonczyc sie dobrze. System powinien blokowac zmiane przepisu bez aktualizacji alergenow (forcing function). |
| 4 | Uber Eats wymaga od restauracji jawnej deklaracji "moge/nie moge" per alergen -- restauracja musi swiadomie zadeklarowac | food-delivery | Model "opt-in" -- Kasia musialoby jawnie potwierdzic, ze aktualizowala alergeny po zmianie przepisu. |
| 5 | Shift-synchronized updates -- kazda zmiana serwuje dane alergenowe aktualne na poczatku zmiany, nie na moment ostatniej aktualizacji | food-delivery (POS systems) | Eliminuje problem z 1-2 dniowym lagiem. Dane alergenowe sa zawsze aktualne per zmiana. |

**Declarative conclusions relevant to this actor**:
- Brak deklaratywnych konkluzji bezposrednio dotyczacych Kasi. Jej wypowiedzi w transkrypcji sa poparte faktami (incydent z tahini, opis procesu aktualizacji).

---

### Marek (Logistyka)

**Optimizes for**: Dostawy na czas z poprawnymi trasami
**Presentation style**: Porownanie z praktykami branzowymi

| # | Finding | Source | Why It Matters (to him) |
|---|---------|--------|--------------------------|
| 1 | Zadna duza platforma food delivery nie wspiera zamiany tras miedzy kierowcami -- trasy sa przypisywane algorytmicznie i sledzane GPS | food-delivery (DoorDash, Uber Eats) | "Zamiany na parkingu" to anti-pattern bez odpowiednika w branzy. Rozwiazanie: systemowe reassignment. |
| 2 | DoorDash: 90% completion rate jako forcing function -- kierowcy ktory czesto rezygnuja z tras sa deaktywowani | food-delivery | Mechanizm dyscyplinujacy -- kierowcy nie moga swobodnie odrzucac/zamieniac tras bez konsekwencji. |
| 3 | Upper, Onfleet wspieraja real-time driver reassignment na poziomie systemu | industry-practices | Jezeli Pawel zna kody do bram na Mokotowie, system powinien przypisac go tam -- nie kierowcy powinni to negocjowac na parkingu. |
| 4 | DoorDash DeepRed + MIP solver optymalizuje trasy z uwzglednieniem traffic -- algorytm moze byc lepszy niz lokalna wiedza kierowcow | food-delivery | Argument Marka "kierowcy znaja teren lepiej niz algorytm" moze nie trzymac, jesli algorytm uwzgledni lokalne czynniki (kody, bramy, korki). |
| 5 | Identity binding -- zamowienie jest wiazane z konkretnym kierowca dla liability i sledzenia | food-delivery | Gdy kierowcy zamieniaja sie, nie wiadomo kto jest odpowiedzialny za dostarczone zamowienie. Brak trasowalnosci. |

**Declarative conclusions relevant to this actor**:
- "Kierowcy zamieniaja sie moze w polowie przypadkow" (Marek) -- **Partially supported**. Marek jest najblizej sytuacji, ale sam przyznaje niepewnosc. Rzeczywisty zakres moze byc 30-70%. Bez danych GPS nie mozna zweryfikowac.

---

### Agnieszka (Wlascicielka)

**Optimizes for**: Priorytetyzacja problemow, decyzja co naprawiac najpierw
**Presentation style**: Podsumowanie wykonawcze z priorytetami

| # | Finding | Source | Why It Matters (to her) |
|---|---------|--------|--------------------------|
| 1 | **Priorytet #1: Alergeny** -- near-miss z tahini to incydent krytyczny. Branza wymaga systemowego zarzadzania alergenami, nie polegania na pamieci jednej osoby. Ryzyko prawne i zdrowotne. | internal + industry + food-delivery | Jesli nastepny incydent skonczy sie hospitalizacja, firma ponosi odpowiedzialnosc prawna. |
| 2 | **Priorytet #2: Cutoff + produkcja** -- 15-20 zmian dziennie przez Google Sheets + nadprodukcja = koszty materialow + pracy + reklamacje. Branzy rozwiazuje to hard cutoff + delayed firing. | internal + industry | Mozliwe do zmierzenia: ile kosztuje nadprodukcja + reklamacje dziennie? |
| 3 | **Priorytet #3: Trasy** -- ~50% tras zamienianych = bledne ETA = utrata zaufania klientow. Ale brak natychmiastowego ryzyka zdrowotnego. | internal + food-delivery | Wazne dla customer retention, ale nizsze ryzyko niz alergeny i produkcja. |
| 4 | Uniwersalny wzorzec branzowy: "punkt bez powrotu" -- kazdy system ma moment, po ktorym zmiany sa systemowo zablokowane. FitBox nie ma takiego mechanizmu. | food-delivery (DoorDash, Uber Eats, HelloFresh, Wolt, Glovo) | FitBox potrzebuje jednego fundamentalnego mechanizmu: systemowo wymuszanego cutoffa z odpowiednim oknem na zmiany. |
| 5 | **Monika jest punktem zbieznosci** -- absorbuje konsekwencje WSZYSTKICH obejsc (bledne ETA, bledne alergeny, reklamacje z nadprodukcji). Jest jednoczesnie tworczynia obejscia #1 i ofiara obejsc #3, #4, #5. | internal-transcript | Obciazenie Moniki rosnie z kazda zmiana. Jesli Monika odejdzie, caly shadow system (Google Sheets, WhatsApp) upada. |
| 6 | Regulacje (FDA 2026, EU RASFF) ida w kierunku cyfrowej trasowalnosci -- reczne procesy nie spelnia wymagan | industry-practices | Czas dziala na niekorzysc -- im pozniej, tym trudniej dostosowac sie do regulacji. |

**Declarative conclusions relevant to this actor**:
- "klienci w ogole nie korzystaja z aplikacji mobilnej -- 90% zamowien przychodzi przez strone albo przez telefon" (Monika) -- **Unsupported**. Decyzja o inwestycji w mobile app powinna byc oparta na danych, nie na wrażeniu. Warto sprawdzic analytics.
- "Kierowcy zamieniaja sie moze w polowie przypadkow" (Marek) -- **Partially supported**. Skala problemu z trasami zalezy od tego ile faktycznie wynosi -- warto wlaczyc GPS tracking zeby zmierzyc.

**Recommended actions**:
1. Natychmiast: audit procesu alergenowego -- ile zmian przepisow w ostatnich 30 dniach vs ile aktualizacji bazy skladnikow (zmierzyc lag)
2. Krotkoterminowo: wprowadzic forcing function na alergeny (system blokuje zmiane przepisu bez aktualizacji skladnikow)
3. Srednoterminowo: wdrozyc systemowy cutoff z delayed firing window (eliminuje Google Sheets i nadprodukcje)
4. Dlugoterminowo: systemowe przypisanie i sledzenie tras (eliminuje parking lot swaps)
