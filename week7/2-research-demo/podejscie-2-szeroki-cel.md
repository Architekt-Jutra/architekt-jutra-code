# Podejście 2: Szeroki cel bez kryterium odrzucenia

**Prompt**: "Zbierz informacje o tym, jak inne systemy rozwiązują problemy podobne do tych z historii Sebastiana."

**Źródła**: Web research — wiele domen, szeroki zakres

---

## Problemy Sebastiana — przypomnienie

Historia Sebastiana opisuje kilka powiązanych problemów:

1. **Rozbieżność między stanem systemowym a fizyczną rzeczywistością** — system pokazuje dostępność, ale fizycznie brakuje miejsc
2. **Nieformalne rezerwacje** — handlowcy blokują miejsca "na telefon" dla VIP-ów, poza systemem
3. **Warunkowe zwiększanie pojemności** — organizatorzy dynamicznie dodają miejsca przy dużym zainteresowaniu
4. **Zależność od sprzętu** — szkolenie wymaga nie tylko sali i miejsc, ale też np. aparatu do nagrywania
5. **Wiedza ukryta (tacit knowledge)** — procesy, które funkcjonują, ale nie są nigdzie zapisane

Poniżej zebrano informacje z wielu domen — od hoteli po chmurę obliczeniową — pokazując, jak różne branże mierzą się z analogicznymi wyzwaniami.

---

## 1. Hotelarstwo — overbooking i synchronizacja kanałów

**Związek z historią Sebastiana**: Rozbieżność między systemem a rzeczywistością, nieformalne rezerwacje

### Główne rozwiązania

- **Channel Manager** — synchronizacja dostępności pokoi w czasie rzeczywistym między wszystkimi kanałami sprzedaży (Booking, Expedia, strona hotelu). Gdy rezerwacja wpada z jednego kanału, natychmiast aktualizuje się stan we wszystkich pozostałych.
- **PMS (Property Management System)** jako single source of truth — jedno centralne miejsce przechowywania informacji o dostępności.
- **Pre-blocking pokoi dla VIP-ów** — hotele formalnie blokują konkretne pokoje w systemie, przypisując im numer i specjalne wymagania. To formalizuje to, co u Sebastiana handlowcy robili "na telefon".
- **Statystyczny overbooking** — hotele celowo przyjmują więcej rezerwacji niż mają pokoi, bazując na historycznych danych o no-show rate. Utrzymują kilka pokoi "w rezerwie" na wypadek problemów.
- **Big data i predykcja** — analiza historycznych danych o rezerwacjach i anulacjach pozwala na dokładne oszacowanie poziomu overbookingu.

### Kluczowa lekcja

Główną przyczyną overbookingu hotelowego jest **opóźnienie w aktualizacji inventory** — liczba dostępnych pokoi nie jest aktualizowana wystarczająco szybko po dokonaniu rezerwacji. Ryzyko rośnie w okresach intensywnego ruchu.

**Źródła**:
- [Hotel Overbooking Strategy | Mews](https://www.mews.com/en/blog/hotel-overbooking-strategy)
- [Hotel Overbooking: Strategy, Solutions & Policies | SiteMinder](https://www.siteminder.com/r/hotel-overbookings-pros-and-cons-strategy/)
- [Handling Hotel Overbooking 2026 Guide | eviivo](https://eviivo.com/trade-secrets/hotel-overbooking-solutions/)
- [SOP - VIP Reservations | SetupMyHotel](https://setupmyhotel.com/train-my-hotel-staff/how-to-define-sop-in-hotels/front-office-sop/826-vip-reservations-standard-procedure.html)

---

## 2. Linie lotnicze — yield management i overbooking jako strategia

**Związek z historią Sebastiana**: Rozbieżność system vs. rzeczywistość, warunkowe zwiększanie pojemności

### Główne rozwiązania

- **Virtual capacity** — linie lotnicze obliczają "wirtualną pojemność" samolotu, uwzględniając przewidywane no-show, anulacje i overbooking. To jak "warunkowe miejsca" u Sebastiana, ale sformalizowane matematycznie.
- **Modele Markowa i programowanie dynamiczne** — zaawansowane modele matematyczne (Markov Decision Process) do optymalizacji alokacji miejsc z uwzględnieniem anulacji, no-show i overbookingu.
- **Machine learning** — wytrenowane modele ML identyfikują wzorce w danych: trendy rezerwacyjne w różnych porach roku, segmenty pasażerów na podstawie historii podróży, programów lojalnościowych i preferencji.
- **Inventory module jako "dynamiczny magazynier"** — moduł zarządzający miejscami w różnych klasach rezerwacyjnych, aktualizujący dostępność w czasie rzeczywistym.
- **Voluntary Denied Boarding** — gdy dochodzi do overbookingu, najpierw prosi się pasażerów o dobrowolną rezygnację w zamian za rekompensatę.

### Kluczowa lekcja

Linie lotnicze **celowo sprzedają więcej miejsc niż fizycznie istnieje**, bo wiedzą, że pewien procent pasażerów się nie pojawi. Kluczem jest precyzja prognozy. U Sebastiana problem wynikał z odwrotnej sytuacji — system *nie wiedział* o nieformalnych rezerwacjach.

**Źródła**:
- [Airline Overbooking | AltexSoft](https://www.altexsoft.com/blog/overbooking-airlines-bumping/)
- [Dynamic Overbooking | PROS](https://pros.com/learn/white-papers/dynamic-overbooking-cancellations-and-no-shows-for-maximum-revenue/)
- [Airline Yield Management with Overbooking | INFORMS](https://pubsonline.informs.org/doi/10.1287/trsc.33.2.147)
- [Bumping & Oversales | US DOT](https://www.transportation.gov/individuals/aviation-consumer-protection/bumping-oversales)

---

## 3. Restauracje — no-show i kontrolowany overbooking

**Związek z historią Sebastiana**: Rozbieżność system vs. rzeczywistość, nieformalne blokady dla VIP-ów

### Główne rozwiązania

- **Formuła bezpiecznego overbookingu**: Safe Overbooking Rate = Historical No-Show Rate x 0.75. Przy no-show rate 10% i 50 miejscach to ok. 3-4 dodatkowe rezerwacje.
- **Automatyczne przypomnienia** 24-48h przed wizytą — redukują no-show o 30-50%.
- **Deposit / kaucja przy rezerwacji** — zniechęca do no-show.
- **Waitlist management** — automatyczna lista oczekujących, która odzyskuje 30-50% przychodów z no-show.
- **Table mapping i wizualizacja** — pokazuje dokładnie, które stoliki są zajęte, zarezerwowane lub wkrótce wolne.

### Kluczowa lekcja

Dla restauracji z 50 miejscami przy srednim rachunku 75$ i 10% no-show, to ok. **9000$/miesiąc** utraconych przychodów. Łączny koszt (z marnowanym przygotowaniem i nadmierną obsadą) jest 15-20% wyższy. Stoliki blokowane "na wszelki wypadek" dla VIP-ów (jak u Sebastiana) to powszechny problem — zapomina się o nich lub brak komunikacji.

**Źródła**:
- [Tackling Overbooking | Tableo](https://tableo.com/operations/tackling-overbooking/)
- [How to Reduce Restaurant No-Shows | EatlyPOS](https://www.eatlypos.com/blog/how-to-reduce-restaurant-no-shows-reservation-management)
- [Restaurant No-Shows | Eat App](https://restaurant.eatapp.co/blog/restaurant-no-shows)

---

## 4. Sale konferencyjne / biura — ghost bookings

**Związek z historią Sebastiana**: Nieformalne rezerwacje, rozbieżność system vs. rzeczywistość

### Główne rozwiązania

- **Auto-release po 10-15 minutach** — jeśli nikt nie zamelduje się w sali w ciągu 10-15 minut od planowanego rozpoczęcia, rezerwacja automatycznie się anuluje, a sala staje się dostępna.
- **Czujniki obecności** — fizyczne sensory wykrywające, czy ktokolwiek jest w sali. Eliminują "fantomowe rezerwacje".
- **Check-in/check-out** — wymaganie potwierdzenia obecności przy wejściu.

### Dane branżowe

Blisko **40% wszystkich zarezerwowanych sal konferencyjnych** kończy jako no-show. Typowe scenariusze:
- Spotkanie przeniesione online, ale nikt nie anulował rezerwacji sali
- Recurring meeting w kalendarzu, który dawno przestał się odbywać
- Managerowie blokujący duże sale "na wszelki wypadek" dla projektów, które nigdy nie ruszają

To jest niemal dokładne odwzorowanie problemu Sebastiana — handlowcy blokujący miejsca "na telefon" to ta sama kategoria zachowań.

**Źródła**:
- [No-Show Protection for Meeting Rooms | Archie](https://archieapp.co/blog/meeting-room-no-show-protection/)
- [The Empty Meeting Room Problem | OfficeSpace](https://www.officespacesoftware.com/blog/empty-meeting-room/)
- [Fix Meeting Room No-Shows and Ghost Bookings | YAROOMS](https://www.yarooms.com/guides/fix-meeting-room-no-shows)

---

## 5. Opieka zdrowotna — bloki operacyjne i zależności sprzętowe

**Związek z historią Sebastiana**: Zależność od sprzętu (aparat do nagrywania), wielowymiarowe ograniczenia zasobów

### Główne rozwiązania

- **Multi-constraint scheduling** — planowanie operacji uwzględnia jednocześnie: długość zabiegu, dostępność chirurga, anestezjologa, specjalistycznego sprzętu, dostawcy implantów, gotowość pacjenta, priorytet przypadków nagłych.
- **Equipment sterilization cycle** — sprzęt operacyjny musi być nie tylko dostępny, ale też wysterylizowany i sprawny. Zabiegi wymagające tego samego sprzętu muszą być rozłożone w czasie.
- **AI-driven optimization** — algorytmy optymalizujące harmonogram bloku operacyjnego z uwzględnieniem wszystkich ograniczeń jednocześnie.

### Kluczowa lekcja

Drobne luki komunikacyjne, takie jak **zaniedbanie potwierdzenia dostępności sprzętu**, mogą prowadzić do anulowania zabiegów lub zmuszenia chirurgów do czekania. To niemal identyczna sytuacja jak u Sebastiana — szkolenie anulowane, bo aparat był uszkodzony. Szpitale mierzyły się z tym wcześniej i zbudowały systemy, które traktują sprzęt jako pierwszorzędne ograniczenie harmonogramu, a nie dodatek.

**Źródła**:
- [Comprehensive Review on OR Scheduling | Springer](https://link.springer.com/article/10.1007/s12351-024-00884-z)
- [Operating Room Scheduling Best Practices | Surgi-Cal](https://surgicalendar.com/blogs/operating-room-efficiency-best-practices/)
- [Solving OR Scheduling with AI | OpMed](https://www.opmed.ai/blog-posts/solving-the-puzzle-of-or-scheduling-optimization-with-ai)
- [Enhancing OR Efficiency | PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC11476208/)

---

## 6. Personel medyczny — shift scheduling i acuity-based staffing

**Związek z historią Sebastiana**: Pojemność zależna od wielu zasobów jednocześnie (nie tylko sala, ale i ludzie)

### Główne rozwiązania

- **Acuity-based staffing** — obsada dopasowana do rzeczywistych potrzeb pacjentów (ocenianych systemem klasyfikacji), a nie do sztywnych norm.
- **Real-time staffing dashboards** — podejmowanie decyzji na podstawie aktualnych danych o dostępności personelu.
- **Regulacje minimalne** — ponad 24 stany w USA mają ustawy określające minimalne poziomy obsady pielęgniarskiej.

### Kluczowa lekcja

Pojemność systemu opieki zdrowotnej to nie tylko łóżka — to łóżka + personel + sprzęt. Analogicznie, pojemność szkolenia Sebastiana to nie tylko miejsca na sali — to miejsca + sala + trener + sprzęt do nagrywania. System musi modelować **wszystkie wymiary pojemności jednocześnie**.

**Źródła**:
- [Nurse Scheduling Through the Eyes of Nurse Leaders | Bradley](https://onlinedegrees.bradley.edu/blog/nurse-scheduling)
- [Nursing Workload, Staffing Methodologies | PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC7086229/)
- [Shiftwizard | HealthStream](https://www.healthstream.com/solution/scheduling-capacity-management/nurse-and-staff-scheduling/shiftwizard)

---

## 7. Produkcja (MRP / MRP II) — infinite vs. finite capacity

**Związek z historią Sebastiana**: System ignorujący realne ograniczenia, warunkowe zwiększanie pojemności

### Główne rozwiązania

- **MRP (Material Requirements Planning)** — tradycyjne systemy MRP zakładają **nieskończoną pojemność** (infinite capacity). Planują materiały, ale ignorują ograniczenia zasobów. To prowadzi do sytuacji, gdy plan mówi "możemy wyprodukować", ale fizycznie jest to niemożliwe.
- **MRP II** — ewolucja z lat 80., dodająca planowanie pojemności (capacity requirements planning), harmonogramowanie główne, S&OP.
- **APS (Advanced Planning Systems)** — nowoczesne systemy planujące materiały i pojemność **jednocześnie**, uznając skończoną naturę zasobów.
- **Finite capacity scheduling** — model "skończonej pojemności" uwzględniający fizyczne limity linii produkcyjnych, maszyn i pracowników.

### Kluczowa lekcja

System Sebastiana działał jak tradycyjny MRP — planował zapisy (materiały), ale ignorował realne ograniczenia (sprzęt, nieformalne blokady). Rozwiązanie to przejście na model "finite capacity", który **jednocześnie** waliduje wszystkie ograniczenia.

**Źródła**:
- [Material Requirements Planning | Wikipedia](https://en.wikipedia.org/wiki/Material_requirements_planning)
- [What is MRP? | SAP](https://www.sap.com/products/erp/what-is-mrp.html)
- [How Capacity Planning and MRP Work Together | Aligni](https://www.aligni.com/aligni-knowledge-center/how-capacity-planning-and-mrp-work-together/)
- [Manufacturing Resource Planning | Autodesk](https://www.autodesk.com/blogs/design-and-manufacturing/manufacturing-resource-planning/)

---

## 8. Wynajem samochodów — fleet management i controlled freesale

**Związek z historią Sebastiana**: Dynamiczna dostępność, zależność od stanu zasobu (samochód sprawny vs. w serwisie)

### Główne rozwiązania

- **Controlled Freesale System** — dostępność nie jest statycznym snapshotem floty, lecz **dynamiczną projekcją** aktualizowaną w czasie rzeczywistym, odzwierciedlającą interakcje między popytem, dostępnością i kanałami sprzedaży.
- **Status tracking** — śledzenie statusu pojazdu (dostępny / w wypożyczeniu / w serwisie / w transferze) w czasie rzeczywistym.
- **Vehicle category management** — zarządzanie typami pojazdów, nie konkretnym egzemplarzem. Rezerwujesz "SUV", nie "Toyota RAV4 WE12345".

### Kluczowa lekcja

Brak przewidywania i planowania inventory prowadzi do overbookingów, braków pojazdów i złej jakości obsługi w szczycie. Problem Sebastiana ze sprzętem (aparat uszkodzony) to odpowiednik samochodu w serwisie — system powinien wiedzieć o stanie technicznym zasobów.

**Źródła**:
- [Overbooking in Car Rental: Controlled Freesale | RentHub](https://www.renthubsoftware.com/en/blog/overbooking-in-car-rental-from-an-old-problem-to-a-new-competitive-advantage/)
- [Rental Car Fleet Management | FlowSense](https://www.flowsense.solutions/blog/rental-car-fleet-management-utilization)
- [Challenges in Car Rental Fleet | Yo-Rent](https://www.yo-rent.com/blog/challenges-in-managing-car-rental-fleet-and-how-rental-software-solves-them/)

---

## 9. Przestrzenie coworkingowe — booking z kontrolą dostępu

**Związek z historią Sebastiana**: Rezerwacja przestrzeni + dodatkowych zasobów, real-time availability

### Główne rozwiązania

- **Real-time capacity/occupancy status** — wyświetlanie aktualnego stanu zajętości, aby zapobiec overbookingowi.
- **Resource management beyond rooms** — zarządzanie nie tylko biurkami i salami, ale też: event spaces, phone booths, lockerami, parkingiem, sprzętem.
- **Access control integration** — system rezerwacji połączony z kontrolą dostępu. Nie masz rezerwacji = nie wejdziesz.
- **Automated blocking** — system automatycznie blokuje nowe rezerwacje po osiągnięciu pojemności.

### Kluczowa lekcja

Coworkingi modelują **zasoby wielowymiarowo** — biurko, sala, sprzęt, parking to osobne jednostki z własnymi limitami. Sebastian potrzebuje analogicznego podejścia: miejsce, sala, trener, sprzęt to osobne zasoby z niezależną dostępnością.

**Źródła**:
- [Coworks Booking Software](https://www.coworks.com/booking-software-for-coworking-space-equipment)
- [Archie Coworking Booking System](https://archieapp.co/coworking-software/booking-system)
- [Skedda Coworking Software](https://www.skedda.com/solutions/coworking-software)

---

## 10. Systemy parkingowe — sensory i fizyczna weryfikacja

**Związek z historią Sebastiana**: Rozbieżność między systemem a fizyczną rzeczywistością

### Główne rozwiązania

- **Sensory na każdym miejscu** — fizyczne czujniki na poszczególnych miejscach parkingowych potwierdzające rzeczywistą zajętość.
- **Entry/exit counting** — sensory przy wjeździe/wyjeździe śledzące ruch pojazdów.
- **AI demand prediction** — prognozowanie zapotrzebowania na parkingi i dynamiczne dostosowanie cen/obsady.
- **Automatyczne zamknięcie parkingu** — gdy dane z sensorów wskazują na pełne zapełnienie, system automatycznie zamyka parking i wyświetla informację na LED.

### Kluczowa lekcja

Systemy parkingowe to najlepszy przykład **weryfikacji fizycznej stanu** — nie polegaj na samych rezerwacjach, ale weryfikuj czujnikami, co dzieje się naprawdę. U Sebastiana brakowało takiego feedbacku — system nie miał informacji o rzeczywistym stanie sali.

**Źródła**:
- [Smart Real-Time Parking Control | PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC10747061/)
- [Elevating Parking Revenue Management with AI | Parking.net](https://www.parking.net/parking-industry-blog/parking-network/elevating-parking-revenue-management-with-ai)
- [How to Build a Real-Time Parking Availability System | Cprime](https://www.cprime.com/resources/blog/how-to-build-a-real-time-parking-availability-system/)

---

## 11. Yield Management — matematyka overbookingu

**Związek z historią Sebastiana**: Warunkowe zwiększanie pojemności, formalizacja nieformalnych decyzji

### Główne koncepcje

- **Dynamic pricing** — ceny dostosowywane w czasie rzeczywistym w oparciu o popyt.
- **Overbooking jako strategia** — celowe przyjmowanie większej liczby rezerwacji niż fizycznie dostępne zasoby, by kompensować anulacje i no-show.
- **Markov Decision Process** — modele matematyczne (programowanie dynamiczne) do optymalizacji alokacji z uwzględnieniem anulacji i no-show.
- **Genetic Algorithms** — algorytmy genetyczne jako narzędzia decyzyjne dla yield management.
- **Jednoczesna optymalizacja** — nowsze metody łączące overbooking i alokację przewyższają tradycyjne podejścia o średnio **20.2%** w przychodach netto, z jeszcze większą poprawą w sytuacjach wysokiego popytu.

### Kluczowa lekcja

To, co organizatorzy u Sebastiana robili intuicyjnie ("warunkowo zwiększam liczbę miejsc, bo widzę duże zainteresowanie"), yield management formalizuje w algorytmy i modele matematyczne. Można przekształcić nieformalną wiedzę w systemową regułę.

**Źródła**:
- [What Is Yield Management? | Stripe](https://stripe.com/resources/more/yield-management)
- [Hotel Yield Management | AltexSoft](https://www.altexsoft.com/blog/yield-management/)
- [Hotel Revenue Management: Overbooking | ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0360835219305327)

---

## 12. Event Management Software — automatyczne wykrywanie konfliktów

**Związek z historią Sebastiana**: Rezerwacja sal, sprzętu, personelu jako spójny problem

### Główne rozwiązania

- **Automatic conflict checking** — automatyczne sprawdzanie konfliktów przy rezerwacji sali i zasobów.
- **Resource tracking** — śledzenie konfiguracji sal, sprzętu, usług, personelu i inventarza w kontekście wymagań eventu.
- **Staff scheduling** — planowanie zespołów i kontraktorów z pełną widocznością dostępności i luk kadrowych.
- **Drag-and-drop rescheduling** — wizualne przesuwanie wydarzeń z automatycznym wykrywaniem konfliktów.

### Kluczowa lekcja

Systemy event management traktują rezerwację jako **wielowymiarowy problem** — sala, sprzęt, obsługa, catering to zależne zasoby, które muszą być jednocześnie dostępne. To najbliższy analogiczny system do sytuacji Sebastiana.

**Źródła**:
- [EventPro Venue Management](https://www.eventpro.net/venue-management-module.html)
- [Resolve Booking Conflicts | EMS Software](https://docs.emssoftware.com/Content/EMSforOutlook/UserGuide/ResolveBookingConflicts.htm)
- [Event & Venue Management | Momentus](https://gomomentus.com/)

---

## 13. Laboratoria naukowe — booking sprzętu o wysokiej wartości

**Związek z historią Sebastiana**: Zależność od konkretnego sprzętu, nieformalne rezerwacje

### Główne rozwiązania

- **Instrument scheduling software** — specjalistyczne oprogramowanie do rezerwacji drogiego sprzętu laboratoryjnego (mikroskopy, spektrometry, roboty).
- **AI-enabled workflow reservations** — rezerwacje uwzględniające całe workflow, nie pojedyncze instrumenty. Np. eksperyment wymaga sekwencji 3 urządzeń.
- **Lab-specific booking rules** — reguły specyficzne dla laboratorium: kto może rezerwować, kiedy, jak długo, z jakim wyprzedzeniem.
- **Maintenance tracking** — śledzenie stanu technicznego i planowanych przeglądów sprzętu.

### Kluczowa lekcja

Przed wdrożeniem specjalistycznego oprogramowania, laboratoria zarządzały drogim sprzętem przez **arkusze kalkulacyjne, kalendarze Outlook, e-maile i nieformalne kartki rejestracyjne**. To jest dokładnie problem Sebastiana — wiedza o dostępności sprzętu istnieje, ale poza systemem.

**Źródła**:
- [Calira | Smart Equipment Booking for R&D](https://clustermarket.com/)
- [LabArchives Scheduler](https://www.labarchives.com/products/scheduler)
- [How R&D Teams Use Lab Equipment Scheduling | newLab](https://newlabcloud.com/blog/lab-equipment-scheduling-software/)

---

## 14. Harmonogramowanie załóg lotniczych — constraint-based scheduling

**Związek z historią Sebastiana**: Wielowymiarowe ograniczenia (trener = pilot, sprzęt = samolot, sala = trasa)

### Główne rozwiązania

- **Crew pairing + crew assignment** — dwufazowy proces: najpierw tworzenie "par" (sekwencji lotów), potem przypisanie konkretnych osób.
- **Regulacje i ograniczenia** — maksymalny czas lotu, czas dyżuru, wymagany odpoczynek (regulacje FAA/EASA), dostępność pilotów w bazie.
- **Set partitioning** — formułowanie problemu jako "podział zbioru", gdzie zmienne decyzyjne to sekwencje lotów, nie pojedyncze loty.
- **Column generation** — zaawansowana technika optymalizacji umożliwiająca skalowanie do tysięcy lotów.

### Kluczowa lekcja

Harmonogramowanie załóg to modelowy przykład **constraint-based scheduling** — musisz jednocześnie spełnić dziesiątki ograniczeń (regulacje, dostępność, umiejętności, bazy). Problem Sebastiana jest prostszą wersją tego samego wzorca: szkolenie wymaga jednoczesnej dostępności sali, trenera, miejsc i sprzętu.

**Źródła**:
- [Airline Crew Scheduling: Models, Algorithms | ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2192437620300820)
- [Crew Scheduling | Wikipedia](https://en.wikipedia.org/wiki/Crew_scheduling)
- [Optimize Airline Crew Scheduling | Timefold](https://timefold.ai/airline-crew-scheduling)

---

## 15. Kina — seat allocation i dynamic pricing

**Związek z historią Sebastiana**: Alokacja miejsc, prognozowanie frekwencji

### Główne rozwiązania

- **Dynamic seating charts** — mapy miejsc aktualizowane w czasie rzeczywistym, zapobiegające podwójnym rezerwacjom.
- **Data-driven seat allocation** — analiza danych box office i historycznej frekwencji do decyzji o alokacji miejsc i ustalaniu cen.
- **Reserved seating premium** — klienci płacą więcej za gwarantowane miejsce, co daje kinu pewność co do frekwencji.

### Kluczowa lekcja

Reserved seating daje kinu **pewność planowania** — wiedzą, ile osób przyjdzie i ile popcornu przygotować. U Sebastiana brak takiej pewności (nieformalne rezerwacje) uniemożliwiał planowanie.

**Źródła**:
- [Data-Driven Seat Allocation | FilmGrail](https://filmgrail.com/blog/data-driven-seat-allocation-boosts-cinema-revenue/)
- [Cinema Booking Software Essentials | FilmGrail](https://filmgrail.com/blog/cinema-booking-software-essentials/)

---

## 16. Obiekty sportowe — booking z checkout sprzętu

**Związek z historią Sebastiana**: Rezerwacja przestrzeni + sprzętu jako pakiet

### Główne rozwiązania

- **Combined booking** — rezerwacja kortu + sprzętu (rakiety, piłki) w jednej transakcji.
- **Resource allocation preventing conflicts** — system zapobiegający sytuacji, gdy dwie grupy potrzebują tego samego sprzętu jednocześnie.
- **Equipment tracking** — śledzenie stanu sprzętu (klatki batting, tablice wyników, oświetlenie) i planowanie wymian.
- **Inventory management** — łączenie hal, kortów, torów, szatni, inventarza i sprzętu technicznego z konkretnymi treningami i wydarzeniami.

### Kluczowa lekcja

Obiekty sportowe modelują **zależność między przestrzenią a sprzętem** jako integralny element rezerwacji. Nie rezerwujesz kortu bez sprawdzenia, czy jest dostępny sprzęt. Sebastian powinien analogicznie traktować parę sala-sprzęt do nagrywania.

**Źródła**:
- [Sports Facility Booking System | EZbook](https://ezbook.com/sports-facility-booking/)
- [Sports Facilities Booking System | Oskaros](https://www.oskaros.com/use-cases/sports-facilities-booking-system)
- [Best Sports Facility Booking Software | SportsKey](https://sportskey.com/post/best-sports-facility-booking-software-multi-sport-complexes/)

---

## 17. Siłownie i studia fitness — waitlist i capacity management

**Związek z historią Sebastiana**: Warunkowe zwiększanie pojemności, zarządzanie nadmiarowym popytem

### Główne rozwiązania

- **Per-class capacity limits** — limity pojemności per zajęcia, automatycznie aktualizowane dla powtarzających się sesji.
- **Automated waitlist** — automatyczna lista oczekujących z natychmiastowym powiadomieniem, gdy zwolni się miejsce.
- **Instant promotion from waitlist** — automatyczne przenoszenie z listy oczekujących, gdy ktoś zrezygnuje.

### Kluczowa lekcja

W siłowniach popyt na popularne zajęcia regularnie przekracza dostępność. Zamiast nieformalnie "dokładać miejsc" (jak organizatorzy Sebastiana), system zarządza nadmiarem popytu przez formalne listy oczekujących z automatyczną promocją.

**Źródła**:
- [Gym Class Capacity & Waitlist Management](https://www.cloudgymmanager.com/gym-class-capacity-management-waitlists-class-limits-and-member-satisfaction/)
- [Check-In and Waitlists | ClassFit](https://classfit.com/check-in-and-waitlists/)
- [GymDesk Booking](https://gymdesk.com/features/booking)

---

## 18. Chmura obliczeniowa — resource overcommitment

**Związek z historią Sebastiana**: Warunkowe zwiększanie pojemności, "sprzedawanie" więcej niż fizycznie istnieje

### Główne rozwiązania

- **CPU/RAM overcommit** — celowe przydzielanie maszynom wirtualnym więcej zasobów (CPU, RAM) niż fizycznie dostępne, bazując na fakcie, że nie wszystkie VM wykorzystują pełną alokację jednocześnie.
- **Hotspot detection** — gdy suma żądań VM przekracza fizyczną pojemność hosta, powstaje "hotspot". Systemy muszą to wykrywać i migrować VM.
- **Bin packing with chance constraints** — modelowanie problemu alokacji jako wariant problemu pakowania z ograniczeniami probabilistycznymi.
- **Peak prediction** — prognozowanie szczytowego zapotrzebowania i prewencyjna relokacja zasobów.

### Kluczowa lekcja

Cloud computing formalizuje to, co organizatorzy Sebastiana robili intuicyjnie: **sprzedaje więcej zasobów niż fizycznie posiada**, bo wie, że nie wszyscy użyją pełni w tym samym momencie. Różnica: cloud robi to na podstawie modeli matematycznych, a organizatorzy na oko.

**Źródła**:
- [Overcommitment in Cloud Services | arXiv](https://arxiv.org/abs/1705.09335)
- [Overcommit CPUs on Sole-Tenant VMs | Google Cloud](https://docs.cloud.google.com/compute/docs/nodes/overcommitting-cpus-sole-tenant-vms)
- [Overcommitting Resources | Red Hat](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/5/html/virtualization/sect-virtualization-tips_and_tricks-overcommitting_with_kvm)

---

## 19. Magazyny i doki — slot booking

**Związek z historią Sebastiana**: Rezerwacja ograniczonego zasobu (dok = sala), capacity management

### Główne rozwiązania

- **Dock appointment scheduling** — ciężarówki rezerwują sloty czasowe na załadunek/rozładunek, co zapobiega zatorom.
- **Automatic capacity rules** — system automatycznie stosuje reguły dostępności i pojemności doków.
- **Real-time tracking** — śledzenie umówionych, przyjeżdżających, opóźnionych i zakończonych wizyt.
- **Labour planning integration** — model pojemności doków pozwala planować zapotrzebowanie na pracowników i sprzęt.

### Kluczowa lekcja

Dock scheduling to doskonały przykład **slot-based capacity management** — ograniczona liczba doków (jak sal szkoleniowych) musi obsłużyć zmienną liczbę ciężarówek (jak uczestników). System generuje cenną informację o wąskich gardłach i prawdziwej pojemności.

**Źródła**:
- [Dock Scheduling Software | Arrivy](https://www.arrivy.com/dock-scheduling-software/)
- [Automated Dock Scheduling | GoRamp](https://www.goramp.com/time-slot-management)
- [Dock Scheduling for High-Traffic Warehouses | C3 Solutions](https://www.c3solutions.com/dock-scheduling/)

---

## 20. Retail — phantom inventory (ghost inventory)

**Związek z historią Sebastiana**: System pokazuje dostępność, której fizycznie nie ma

### Główne rozwiązania

- **Cycle counting** — regularne audyty małych próbek inventarza, zamiast jednego dużego spisu raz w roku.
- **AI/ML inventory reconciliation** — sztuczna inteligencja porównująca dane systemowe z rzeczywistymi trendami sprzedaży, wykrywająca anomalie.
- **Root cause analysis** — systematyczne identyfikowanie przyczyn (kradzież, błędy przy przyjęciu, zwroty, uszkodzenia).

### Dane branżowe

Phantom inventory stanowi średnio **8% wszystkich strat inventarza**. Prowadzi do: niezadowolonych klientów (obiecane produkty niedostępne), zmarnowanej pracy (szukanie zaginionych przedmiotów), błędnych decyzji o uzupełnieniu zapasów, zniekształconego prognozowania sprzedaży.

### Kluczowa lekcja

Problem "phantom inventory" to niemal **identyczny wzorzec** jak u Sebastiana: system mówi, że jest 5 wolnych miejsc, ale fizycznie 3 z nich zajęte przez nieformalne rezerwacje handlowców. Retail rozwiązał to przez regularne audyty i automatyczną detekcję rozbieżności.

**Źródła**:
- [Phantom Inventory: The Silent Killer | RetailAware](https://www.retailaware.com/resources-articles/phantom-inventory)
- [Understanding Ghost Inventory | ShipBob](https://www.shipbob.com/blog/ghost-inventory/)
- [Real-Time Visibility: Solving Ghost Inventory | Lean Supply Solutions](https://www.leansupplysolutions.com/blog/real-time-visibility-solving-ghost-inventory-problem/)

---

## 21. Uczelnie — timetabling i alokacja sal

**Związek z historią Sebastiana**: Rezerwacja sal z wieloma ograniczeniami (pojemność, sprzęt, dostępność prowadzącego)

### Główne rozwiązania

- **Automated conflict detection** — automatyczne wykrywanie kolizji przy planowaniu zajęć.
- **Multi-resource optimization** — jednoczesna optymalizacja sal, wykładowców, sprzętu, grup studenckich.
- **SIS integration** — integracja z Student Information System dla aktualnych danych o zapisach.
- **Drag-and-drop z constraint checking** — wizualne planowanie z automatyczną walidacją ograniczeń.

### Kluczowa lekcja

Problemy uczelni z planowaniem sal to skala problemu Sebastiana pomnożona x100: setki sal, tysiące zajęć, dziesiątki ograniczeń. Rozwiązania: formalizacja ograniczeń + algorytmiczna optymalizacja.

**Źródła**:
- [UniTime | University Timetabling](https://www.unitime.org/)
- [Academic Course Scheduling | Coursedog](https://www.coursedog.com/products/academic-course-scheduling-software)
- [Classroom Scheduling Software | Accruent](https://www.accruent.com/products/ems/classroom-scheduling-software)

---

## 22. Maintenance scheduling — zależność produkcji od stanu sprzętu

**Związek z historią Sebastiana**: Szkolenie odwołane z powodu uszkodzonego aparatu

### Główne rozwiązania

- **Preventive maintenance scheduling** — planowanie konserwacji zanim dojdzie do awarii, aby zminimalizować nieplanowane przestoje.
- **Coordination with production** — uzgadnianie okien serwisowych z harmonogramem produkcji.
- **Equipment criticality assessment** — priorytetyzacja zadań serwisowych według krytyczności sprzętu.
- **CMMS (Computerized Maintenance Management System)** — system informatyczny do zarządzania konserwacją, śledzenia stanu sprzętu i planowania przeglądów.

### Kluczowa lekcja

Sprzęt się psuje — to fakt. Pytanie, czy system o tym wie i może się dostosować. U Sebastiana nikt nie śledzył stanu aparatu do nagrywania. W produkcji maintenance scheduling jest **integralną częścią planowania**, nie afterthoughtem.

**Źródła**:
- [6 Proven Strategies to Reduce Machine Downtime | Tractian](https://tractian.com/en/blog/reduce-machine-downtime)
- [How to Reduce Downtime in Manufacturing | RELEX](https://www.relexsolutions.com/resources/reducing-manufacturing-downtime-through-supply-chain-planning/)
- [Maintenance Scheduling 101 | Cheqroom](https://www.cheqroom.com/blog/maintenance-scheduling-101-how-to-reduce-downtime-and-extend-equipment-lifespan/)

---

## 23. Shadow IT / Shadow Processes — dlaczego ludzie omijają system

**Związek z historią Sebastiana**: Handlowcy blokujący miejsca poza systemem, wiedza tacit

### Główne rozwiązania

- **Streamlined approval processes** — uproszczenie procesów zatwierdzania, by pracownicy nie musieli szukać obejść.
- **Clear policies + communication** — jasne zasady i kanały komunikacji redukują potrzebę nieoficjalnych narzędzi.
- **User-centric system design** — projektowanie systemu tak, by oficjalna droga była **łatwiejsza** niż obejście.

### Dlaczego ludzie tworzą workaroundy

Kiedy polityki IT są niejasne lub procesy zatwierdzania trwają zbyt długo, pracownicy tworzą obejścia. Z czasem te obejścia stają się znormalizowanymi workflow. Chęć zwiększenia produktywności zachęca zespoły do omijania oficjalnych kanałów.

### Kluczowa lekcja

Handlowcy u Sebastiana nie blokują miejsc "na telefon" ze złośliwości — robią to, bo **system nie oferuje im łatwej ścieżki** do nieformalnej rezerwacji dla VIP-a. Rozwiązanie to nie "zakazanie nieformalnych rezerwacji", lecz **danie im formalnego narzędzia** do tego, co i tak robią.

**Źródła**:
- [Shadow IT: Why Employees Bypass IT | GoVirtual](https://govirtual-it.com/blog/shadow-it-why-employees-bypass-it-and-how-to-fix-it/)
- [What Is Shadow IT? | Palo Alto Networks](https://www.paloaltonetworks.com/cyberpedia/shadow-it)
- [Shadow IT | Wikipedia](https://en.wikipedia.org/wiki/Shadow_IT)

---

## 24. Camping / parki narodowe — overbooking i puste miejsca

**Związek z historią Sebastiana**: Zarezerwowane, ale fizycznie puste miejsca

### Dane z praktyki

Wielu odwiedzających parki narodowe zgłasza, że po przyjeździe do kempingu "zarezerwowanego w 100%" — **1/3 miejsc jest pustych**. Host wyjaśnia: "zostały opłacone". System Recreation.gov, obsługujący 103 000+ miejsc kempingowych, zmaga się z tym problemem na dużą skalę.

### Rozwiązania

- **Cancellation alerts** — powiadomienia o anulacjach, pozwalające innym zająć zwolnione miejsca.
- **CampScanner / Campflare** — zewnętrzne aplikacje monitorujące anulacje i udostępniające wolne miejsca.
- **Booking windows** — okna rezerwacyjne (6-13 miesięcy wcześniej) z różnymi politykami anulacji.

### Kluczowa lekcja

To ten sam wzorzec co u Sebastiana, ale na masową skalę: system pełny, fizycznie puste miejsca. Rozwiązanie? Automatyczne uwalnianie miejsc po braku potwierdzenia obecności.

**Źródła**:
- [The Challenges of Recreation.gov | National Parks Traveler](https://www.nationalparkstraveler.org/2019/09/challenges-recreationgov)
- [CampScanner](https://www.campscanner.com)
- [Campground Reservations | Yosemite NPS](https://www.nps.gov/yose/planyourvisit/camping.htm)

---

## 25. Biblioteki — study rooms + equipment checkout

**Związek z historią Sebastiana**: Rezerwacja przestrzeni ze sprzętem, limity czasowe

### Główne rozwiązania

- **Confirmation required** — rezerwacja musi być potwierdzona w ciągu godziny od otrzymania e-maila potwierdzającego (Fresno State).
- **Time limits** — maksymalny czas rezerwacji (2-4 godziny), zapobiegający blokowaniu na cały dzień.
- **Equipment bundling** — sprzęt (laptop, webcam, słuchawki, markery, maszyny do białego szumu) jako element rezerwacji sali.
- **Online reservation for equipment** — laptopy na 72-godzinne wypożyczenie wymagają rezerwacji online.

### Kluczowa lekcja

Biblioteki łączą rezerwację przestrzeni ze sprzętem jako **jeden pakiet** — sala + whiteboard markers + laptop to jedna rezerwacja. Krótkie okna czasowe i wymóg potwierdzenia zapobiegają "ghost bookings".

**Źródła**:
- [Library Booking System | Fresno State](https://library.fresnostate.edu/tech/room-booking)
- [Mazevo Room & Equipment Scheduling | Libraries](https://www.gomazevo.com/industries/libraries)
- [Equipment | UA Libraries](https://www.lib.ua.edu/using-the-library/equipment/)

---

## 26. Systemy rezerwacyjne — concurrency i locking

**Związek z historią Sebastiana**: Dwóch handlowców blokujących to samo miejsce jednocześnie

### Wzorce techniczne

- **Optimistic locking** — zakładamy rzadkie konflikty. Wielu użytkowników może jednocześnie rezerwować, ale przed zapisem system sprawdza, czy zasób nie zmienił stanu (version number check). Efektywne gdy konflikty rzadkie.
- **Pessimistic locking** — zakładamy częste konflikty. Zasób jest blokowany na czas operacji. Gwarantuje spójność, ale zmniejsza współbieżność.
- **Two-Phase Commit (2PC)** — koordynacja transakcji między wieloma zasobami (np. jednoczesna rezerwacja sali + sprzętu).

### Kluczowa lekcja

Wybór mechanizmu zależy od poziomu współbieżności. Dla systemu szkoleń Sebastiana, gdzie konflikty mogą być częste (ograniczona liczba sal i sprzętu), **pessimistic locking z timeout** może być bardziej odpowiedni. Ale kluczowe jest, że **wszystkie rezerwacje muszą przechodzić przez system** — "rezerwacja na telefon" omija jakikolwiek locking.

**Źródła**:
- [Solving Double Booking at Scale | ITNext](https://itnext.io/solving-double-booking-at-scale-system-design-patterns-from-top-tech-companies-4c5a3311d8ea)
- [Concurrency Strategies in Multi-User Reservation Systems | Medium](https://medium.com/devbulls/concurrency-strategies-in-multi-user-reservation-systems-b8142dea1bc8)
- [Race Conditions in Hotel Booking Systems | Amitav Roy](https://www.amitavroy.com/articles/race-conditions-in-hotel-booking-systems-why-your-technology-choice-matters-more-than-you-think)

---

## 27. DDD — Aggregate Design dla systemów rezerwacyjnych

**Związek z historią Sebastiana**: Modelowanie domeny (szkolenie, sala, miejsce, rezerwacja, blokada, sprzęt)

### Wzorce projektowe

- **Lean aggregates** — małe, skupione agregaty minimalizują contention przy współbieżnym dostępie.
- **Consistency boundary** — agregat definiuje granicę spójności. Np. "Room cannot have more than one booking for the same night" to niezmiennik agregatu.
- **Concurrency impact** — większe agregaty = więcej problemów z współbieżnością. "Gdy kilka żądań walczy o ten sam agregat, jedno wygra, a reszta musi czekać lub się nie powiedzie."

### Kluczowa lekcja

Model Sebastiana (szkolenie, sala, miejsce, rezerwacja, blokada, sprzęt) to klasyczny problem DDD: gdzie postawić granice agregatów? Jeśli "szkolenie" to jeden duży agregat z salą, miejscami i sprzętem, powstanie bottleneck. Lepiej: osobne agregaty z koordynacją (saga/process manager).

**Źródła**:
- [DDD Lean Aggregates | Denis Kyashif](https://deniskyashif.com/2026/04/04/domain-driven-design-lean-aggregates/)
- [DDD Aggregates: Consistency Boundary | James Hickey](https://www.jamesmichaelhickey.com/consistency-boundary/)
- [Designing DDD Aggregates | Medium](https://medium.com/@allousas/designing-ddd-aggregates-db633f1caf88)

---

## 28. Teatr / produkcje sceniczne — technical rider

**Związek z historią Sebastiana**: Formalizacja wymagań sprzętowych

### Główne rozwiązania

- **Technical rider** — formalny dokument będący częścią kontraktu, szczegółowo opisujący wymagania techniczne: oświetlenie, dźwięk, scena, rekwizyty.
- **6-week advance submission** — wymagania techniczne muszą być złożone minimum 6 tygodni przed load-in.
- **Breach = contract breach** — naruszenie technical ridera = naruszenie kontraktu.

### Kluczowa lekcja

Teatr formalizuje to, czego u Sebastiana brakowało: **jawna deklaracja wymagań sprzętowych** jako integralny element planowania. Nie "wiemy, że potrzebujemy aparatu", lecz "w kontrakcie jest zapisane, że aparat o parametrach X musi być dostępny i sprawny w dniu Y".

**Źródła**:
- [What is a Technical Rider | The Rock Factory](https://therockfactory.net/what-is-a-technical-rider-and-what-should-it-include/)
- [The Tech Rider Explained | Musosoup](https://musosoup.com/blog/the-tech-rider-explained)
- [Rider (theater) | Wikipedia](https://en.wikipedia.org/wiki/Rider_(theater))

---

## 29. Demand & Capacity Management — strategie ogólne

**Związek z historią Sebastiana**: Warunkowe zwiększanie pojemności, balansowanie popytu i podaży

### Strategie

- **Lead strategy** — zwiększanie pojemności z wyprzedzeniem, antycypując przyszły popyt.
- **Lag strategy** — zwiększanie pojemności dopiero po udowodnieniu popytu (to robili organizatorzy Sebastiana).
- **Match strategy** — stopniowe dostosowywanie pojemności w miarę zmian popytu.
- **Dynamic strategy** — ciągłe monitorowanie i dostosowywanie w czasie rzeczywistym.

### Kluczowa lekcja

Organizatorzy Sebastiana stosowali "lag strategy" — zwiększali liczbę miejsc dopiero widząc duże zainteresowanie. Problem: było to nieformalne i nieprzewidywalne. Formalizacja tej strategii (z jasnymi progami i regułami) eliminowałaby chaos.

**Źródła**:
- [Service Capacity and Demand Management | Fiveable](https://fiveable.me/operations-management/unit-11/service-capacity-demand-management/study-guide/as2VYVDECzNLPPJn)
- [Capacity Planning: Demand-Driven Management | SafetyChain](https://safetychain.com/blog/demand-driven-capacity-management)
- [Capacity Management | CIPS](https://www.cips.org/intelligence-hub/operations-management/capacity-management)

---

## Podsumowanie: Wzorce wspólne dla wszystkich domen

| Wzorzec | Domeny | Problem Sebastiana |
|---------|--------|--------------------|
| **Single source of truth** | Hotele, linie lotnicze, retail | Nieformalne rezerwacje poza systemem |
| **Multi-resource constraint checking** | Szpitale, event mgmt, uczelnie | Zależność szkolenia od sali + sprzętu + trenera |
| **Auto-release / check-in enforcement** | Sale konferencyjne, camping, biblioteki | Blokady "na telefon" bez realizacji |
| **Phantom inventory detection** | Retail, parking, camping | System pokazuje dostępność, której nie ma |
| **Formalized overbooking** | Linie lotnicze, restauracje, cloud | Warunkowe zwiększanie miejsc "na oko" |
| **Equipment lifecycle tracking** | Laboratoria, produkcja, teatr | Aparat uszkodzony, ale nikt nie wiedział |
| **Waitlist management** | Siłownie, restauracje | Brak formalnego zarządzania nadmiarem popytu |
| **Shadow process elimination** | Shadow IT, sale konferencyjne | Handlowcy omijający system |
| **Finite capacity planning** | MRP/APS, produkcja | System ignorujący realne ograniczenia |
| **Concurrency control** | Systemy rezerwacyjne, DDD | Jednoczesne konflikty przy rezerwacji |

---

## Obserwacja końcowa

Szerokie badanie bez kryterium odrzucenia daje **ogromną ilość materiału z wielu domen**. Każdy finding jest w jakimś stopniu powiązany z historią Sebastiana, ale zakres jest tak szeroki, że trudno z niego wyciągnąć konkretne, actionable wnioski bez dalszej syntezy i priorytetyzacji. To ilustruje zarówno siłę (odkrywanie nieoczywistych analogii), jak i słabość (information overload) podejścia "szerokie badanie bez filtra".