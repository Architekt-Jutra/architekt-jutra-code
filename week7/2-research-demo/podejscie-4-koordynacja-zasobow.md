# Podejście 4: Konkretny cel — koordynacja wielu zasobów

**Prompt**: "Zbierz informacje o tym, jak systemy zarządzania zasobami rozwiązują problem jednoczesnej dostępności wielu typów zasobów — np. gdy wydarzenie wymaga jednocześnie sali, sprzętu i osoby."

**Źródła**: Web research — fokus na systemy zarządzania zasobami, wyłącznie wątek koordynacji wielu typów zasobów jednocześnie

---

## 1. Planowanie sal operacyjnych (healthcare) — chirurg + sala + sprzęt jako atomowy pakiet

Planowanie operacji to jeden z najbardziej zbadanych problemów koordynacji wielu zasobów jednocześnie. W literaturze naukowej jest znany jako **MESS — Multi-resource constrained Elective Surgical Scheduling**.

**Problem**: Każda operacja wymaga jednoczesnej dostępności sali operacyjnej (OR), chirurga, anestezjologa, pielęgniarek, sprzętu medycznego i łóżka pooperacyjnego (NOR bed). Brak któregokolwiek zasobu uniemożliwia przeprowadzenie zabiegu — identycznie jak w historii Sebastiana, gdzie szkolenie zostało odwołane z powodu uszkodzonego aparatu, mimo wolnych miejsc i dostępnej sali.

**Jak to rozwiązują**:
- **Jednoczesna alokacja**: System musi rozwiązać trzy problemy alokacji naraz — kolejność pacjentów, wybór sali i łóżka, oraz dobór personelu medycznego (chirurg, anestezjolog, pielęgniarki). Nie da się tego robić sekwencyjnie — optymalizacja jednego zasobu niezależnie prowadzi do konfliktów z pozostałymi.
- **Zintegrowane planowanie**: Badania pokazują, że generowanie harmonogramów sekwencyjnie (najpierw sale, potem chirurdzy, potem pielęgniarki) nie gwarantuje minimalnych nadgodzin i optymalnego wykorzystania zasobów. Dopiero jednoczesne planowanie wszystkich zasobów daje pożądany kompromis.
- **Ograniczenia sprzętowe**: Modele alokacji uwzględniają dostępność specjalistycznego sprzętu w salach operacyjnych oraz poziom biegłości chirurgów — analogia do wymogu aparatu do nagrania szkolenia u Sebastiana.
- **Operacje kooperacyjne**: Gdy operacja wymaga wielu chirurgów jednocześnie, złożoność rośnie wykładniczo — bo wpływa na harmonogramy wielu osób naraz.

**Odniesienie do problemu Sebastiana**: Szkolenie = operacja. Sala szkoleniowa = sala operacyjna. Trener = chirurg. Sprzęt (aparat) = sprzęt medyczny. Problem jest strukturalnie identyczny: brak jednego elementu z "pakietu zasobów" uniemożliwia przeprowadzenie wydarzenia. Rozwiązanie z medycyny — **nigdy nie planuj zasobów sekwencyjnie, zawsze jako pakiet**.

> Źródła: [Multi-resource constrained elective surgical scheduling (Nature)](https://www.nature.com/articles/s41598-025-87867-y), [Comprehensive review on OR scheduling (Springer)](https://link.springer.com/article/10.1007/s12351-024-00884-z), [Enhancing OR Efficiency (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC11476208/)

---

## 2. Planowanie załóg lotniczych — samolot + pilot + slot czasowy jako zunifikowany zasób

Problem **crew scheduling** w liniach lotniczych to kolejny klasyczny przykład koordynacji wielu typów zasobów jednocześnie.

**Problem**: Każdy lot wymaga samolotu (aircraft assignment), załogi (crew pairing/rostering) i slotu czasowego, przy jednoczesnym spełnieniu regulacji FAA, umów zbiorowych, wymagań konserwacyjnych samolotu i limitów czasu pracy załogi.

**Jak to rozwiązują**:
- **Dekompozycja na podproblemy**: Tradycyjnie problem dzielono na: (1) crew pairing — łączenie lotów w sekwencje dla załóg, (2) crew rostering — przypisanie konkretnych osób do sekwencji. Ale to podejście sekwencyjne ignoruje zależności między zasobami i prowadzi do nieoptymalnych rozwiązań.
- **Podejście zintegrowane**: Nowsze badania pokazują, że jednoczesna optymalizacja przydziału samolotów i załóg daje oszczędności kosztowe rzędu ~2% — co przy skali linii lotniczych to setki milionów dolarów. Kluczowa lekcja: **sekwencyjne rozwiązywanie podproblemów ignoruje zależności między zasobami**.
- **Multi-objective optimization**: Systemy optymalizują jednocześnie wiele celów — minimalizację kosztów, równomierne obciążenie załóg, zgodność z regulacjami.

**Odniesienie do problemu Sebastiana**: Linia lotnicza nie może "polecieć samolotem bez pilota" ani "wysłać pilota bez samolotu". Dokładnie tak samo szkolenie nie może się odbyć bez sali, trenera i sprzętu jednocześnie. Lekcja z lotnictwa: **zależności między zasobami muszą być modelowane explicite, a nie zakładane implicite**.

> Źródła: [Airline crew scheduling: models and algorithms (ScienceDirect)](https://www.sciencedirect.com/science/article/pii/S2192437620300820), [Airline scheduling optimization (Oxford Academic)](https://academic.oup.com/iti/article/doi/10.1093/iti/liad026/7459776), [Integrated aircraft and crew scheduling (ScienceDirect)](https://www.sciencedirect.com/science/article/pii/S0969699725000171)

---

## 3. Systemy MRP/MRP II w produkcji — Bill of Resources jako wzorzec "receptury zasobowej"

Systemy **Manufacturing Resource Planning (MRP II)** to historycznie pierwszy dojrzały wzorzec koordynacji wielu typów zasobów.

**Problem**: Produkcja wyrobu wymaga jednoczesnej dostępności surowców (BOM — Bill of Materials), maszyn, operatorów, narzędzi i czasu na linii produkcyjnej. Brak jednego komponentu blokuje całą produkcję.

**Jak to rozwiązują**:
- **Bill of Materials (BOM)**: Definiuje "recepturę" — listę wszystkich komponentów potrzebnych do wyprodukowania wyrobu. Każdy komponent ma wymaganą ilość i czas dostawy.
- **Bill of Resources (BOR)**: Rozszerza BOM o zasoby niematerialne — podaje ile godzin na każdym krytycznym zasobie (maszynie, stanowisku) jest potrzebne do wyprodukowania danego wyrobu.
- **Capacity Requirements Planning (CRP)**: Szczegółowe sprawdzanie zdolności produkcyjnych na podstawie planowanych zleceń, istniejących prac w toku (WIP), danych o marszrutach (routing) oraz zdolności i czasów realizacji na wszystkich stanowiskach.
- **Routing (marszruta)**: Definiuje sekwencję operacji i wymagane zasoby na każdym etapie.
- **Wykrywanie konfliktów**: Podstawowe systemy MRP wykrywają konflikty zasobowe (np. dwa zlecenia na tej samej maszynie w tym samym czasie), ale wymagają ręcznego rozwiązania. Zaawansowane systemy MRP II robią to automatycznie.

**Odniesienie do problemu Sebastiana**: BOM/BOR to dokładnie to, czego brakuje w systemie zapisów na szkolenia. Szkolenie powinno mieć swoją "recepturę zasobową": sala (typ, pojemność) + trener (kompetencje) + sprzęt (aparat, projektor). Bez takiej formalnej definicji, system nie wie, że brak aparatu = brak możliwości przeprowadzenia szkolenia. **MRP II daje gotowy wzorzec: każde "zlecenie" (szkolenie) ma przypisaną "recepturę" (bill of resources) i system weryfikuje dostępność WSZYSTKICH zasobów z receptury**.

> Źródła: [What is MRP (SAP)](https://www.sap.com/resources/what-is-material-resource-planning-mrp), [MRP II (Siemens)](https://www.sw.siemens.com/en-US/technology/manufacturing-resource-planning-mrp-ii/), [MRP II (Wikipedia)](https://en.wikipedia.org/wiki/Manufacturing_resource_planning), [MRP II (Cambridge IFM)](https://www.ifm.eng.cam.ac.uk/research/dstools/mrp-ii/)

---

## 4. Systemy eventowe — koordynacja venue + sprzęt AV + personel

Systemy zarządzania wydarzeniami (venue management) to najbliższy analogon problemu Sebastiana.

**Problem**: Wydarzenie wymaga jednoczesnej rezerwacji sali (z odpowiednią konfiguracją), sprzętu AV (projektor, mikrofony, kamery), cateringu i personelu (technik AV, obsługa).

**Jak to rozwiązują**:
- **Resource packages / Event templates**: Systemy pozwalają tworzyć predefiniowane pakiety zasobów — np. "szkolenie standardowe" = sala + projektor + flipchart + mikrofon. Przy rezerwacji system automatycznie sprawdza dostępność CAŁEGO pakietu.
- **Filtrowanie po zasobach**: Użytkownik szuka dostępnych sal filtrując po wymaganych zasobach (pojemność, sprzęt, konfiguracja). System pokazuje tylko te terminy, gdy WSZYSTKIE wymagane zasoby są jednocześnie dostępne.
- **Real-time inventory tracking**: Śledzenie sprzętu AV, mebli, dekoracji w czasie rzeczywistym z przypisaniem do konkretnych wydarzeń.
- **Staff scheduling zintegrowany z wydarzeniami**: Przypisywanie personelu (techników, obsługi) do wydarzeń z uwzględnieniem dostępności, zmian i certyfikacji.
- **Buffer time**: Automatyczne dodawanie czasu buforowego między rezerwacjami na przygotowanie i sprzątanie — co rozwiązuje problem "sala jest dostępna w systemie, ale fizycznie jeszcze trwa poprzednie wydarzenie".

**Odniesienie do problemu Sebastiana**: To jest niemal 1:1 jego problem. System eventowy z pakietami zasobów rozwiązałby sytuację z aparatem — szkolenie miałoby zdefiniowany pakiet "sala + trener + aparat do nagrań", i system nie pozwoliłby na rezerwację, gdyby aparat był niedostępny lub uszkodzony. **Kluczowa lekcja: zasoby nie mogą być zarządzane w izolacji — muszą być powiązane w pakiety i sprawdzane atomowo**.

> Źródła: [EventPro Venue Management](https://www.eventpro.net/venue-management-software.html), [Momentus Event & Venue Management](https://gomomentus.com/), [Event Booking Software (AltexSoft)](https://www.altexsoft.com/blog/event-booking-venue-management/)

---

## 5. Formalny wzorzec: Resource-Constrained Scheduling (RCPSP) i Constraint Satisfaction

Problem koordynacji wielu zasobów jednocześnie ma formalną definicję w badaniach operacyjnych.

**RCPSP (Resource-Constrained Project Scheduling Problem)**:
- Każde zadanie (activity) ma określony czas trwania i nie może być przerwane.
- Każde zadanie wymaga **r(j,k) jednostek zasobu typu k** podczas całego czasu realizacji.
- Każdy typ zasobu k ma ograniczoną pojemność **R(k)** w dowolnym punkcie czasu.
- Problem: przypisz czasy rozpoczęcia wszystkim zadaniom, respektując precedencje i ograniczenia zasobowe.
- RCPSP jest problemem NP-trudnym — nie istnieje algorytm wielomianowy gwarantujący optymalne rozwiązanie.

**Constraint Programming (CP) jako podejście rozwiązywalne**:
- CP jest szczególnie dobrze dopasowane do problemów harmonogramowania dzięki ekspresywności języka i wyspecjalizowanym mechanizmom propagacji ograniczeń.
- Obsługuje trzy typy zasobów: **unary resources** (maszyny — zasób używany przez jedno zadanie naraz), **cumulative resources** (zasoby o pojemności > 1), **reservoirs** (zasoby zużywalne).
- Automatyczne wykrywanie konfliktów: zapobiega podwójnej rezerwacji zasobów i pomaga utrzymać odpowiednie proporcje zasobów do zadań.

**Odniesienie do problemu Sebastiana**: Sala szkoleniowa to **unary resource** (jedno szkolenie naraz). Miejsca w sali to **cumulative resource** (pojemność N osób). Aparat do nagrań to **unary resource** (jeden aparat, jedno szkolenie naraz). Trener to **unary resource**. Problem Sebastiana to klasyczny RCPSP — każde szkolenie wymaga jednoczesnej dostępności zasobów wielu typów. Formalizm RCPSP daje gotowe narzędzia do modelowania i rozwiązywania tego problemu.

> Źródła: [RCPSP (Hexaly)](https://www.hexaly.com/templates/resource-constrained-project-scheduling-problem-rcpsp), [Constraint-Based Scheduling (Le Pape, ILOG)](https://www.math.unipd.it/~mpini/fse-doc/scheduling/lepape.pdf), [RCPSP (Ghent University)](https://www.projectmanagement.ugent.be/research/project_scheduling/rcpsp)

---

## Synteza: wzorce wspólne dla wszystkich domen

Analiza pięciu domen (medycyna, lotnictwo, produkcja, eventy, badania operacyjne) ujawnia powtarzające się wzorce:

### Wzorzec 1: "Receptura zasobowa" (Bill of Resources)

Każde wydarzenie/operacja/lot musi mieć **explicite zdefiniowaną listę wymaganych zasobów** — nie może to być wiedza domyślna w głowach organizatorów. W przypadku Sebastiana: brak formalnej definicji, że szkolenie wymaga aparatu, doprowadził do odwołania wydarzenia.

| Domena | Nazwa wzorca | Przykład |
|--------|-------------|---------|
| Produkcja (MRP) | Bill of Materials / Bill of Resources | Wyrób X = 3 szt. komponentu A + 2h maszyny B + 1 operator |
| Medycyna | Resource bundle | Operacja Y = sala OR + chirurg + anestezjolog + sprzęt laparoskopowy |
| Lotnictwo | Flight resource set | Lot Z = samolot typu A320 + kapitan + pierwszy oficer + slot |
| Eventy | Event template / Resource package | Szkolenie = sala 20-os. + projektor + aparat + trener |

### Wzorzec 2: Atomowa walidacja dostępności

Sprawdzanie dostępności musi być **atomowe** — albo WSZYSTKIE zasoby z receptury są dostępne, albo rezerwacja jest niemożliwa. Sprawdzanie po kolei (najpierw sala, potem trener, potem sprzęt) prowadzi do sytuacji Sebastiana: "system pokazuje dostępność" (sali), ale szkolenie i tak się nie może odbyć (bo brak aparatu).

### Wzorzec 3: Zintegrowane planowanie zamiast sekwencyjnego

Wszystkie badane domeny konwergują do jednego wniosku: **sekwencyjne planowanie zasobów (najpierw A, potem B, potem C) daje gorsze wyniki niż jednoczesne**. W lotnictwie: jednoczesna optymalizacja samolotów i załóg daje ~2% oszczędności. W medycynie: sekwencyjne generowanie harmonogramów nie gwarantuje minimalnych nadgodzin.

### Wzorzec 4: Zasób jako obiekt pierwszoklasowy ze stanem

We wszystkich systemach zasób ma stan (dostępny / zarezerwowany / uszkodzony / w konserwacji). W przypadku Sebastiana aparat był "uszkodzony", ale system o tym nie wiedział — bo sprzęt nie był modelowany jako zasób ze stanem. Systemy eventowe śledzą stan sprzętu AV w czasie rzeczywistym.

### Wzorzec 5: Wykrywanie konfliktów zamiast optymistycznego zakładania

Dojrzałe systemy (MRP II, OR scheduling, venue management) aktywnie **wykrywają konflikty** (dwa szkolenia na ten sam aparat, przekroczenie pojemności sali) zamiast czekać, aż problem ujawni się w dniu wydarzenia. System Sebastiana nie wykrywał konfliktu "sala dostępna, ale aparat uszkodzony", bo aparat nie był częścią modelu.

---

## Implikacje dla systemu zapisów na szkolenia Sebastiana

Na podstawie zebranych informacji, system Sebastiana powinien:

1. **Zdefiniować "recepturę zasobową" dla każdego typu szkolenia** — explicite lista: sala (typ, pojemność) + trener (kompetencje) + sprzęt (lista elementów). Wzorzec z MRP II: Bill of Resources.

2. **Modelować sprzęt jako zasób pierwszoklasowy** — aparat do nagrań, projektor, flipchart — każdy element ze stanem (dostępny/uszkodzony/zarezerwowany) i kalendarzem dostępności. Wzorzec z systemów eventowych.

3. **Walidować dostępność atomowo** — przy zapisie sprawdzać WSZYSTKIE zasoby z receptury jednocześnie. Jeśli aparat jest uszkodzony — blokować zapis, mimo wolnych miejsc. Wzorzec z planowania sal operacyjnych.

4. **Traktować szkolenie jako RCPSP** — każde szkolenie to zadanie wymagające jednoczesnej dostępności zasobów wielu typów o ograniczonej pojemności. Sala = unary resource, miejsca = cumulative resource, trener = unary resource, sprzęt = unary resource.
