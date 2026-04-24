# Podejście 3: Konkretny cel — obejścia pozasystemowe

**Prompt**: "Zbierz informacje o tym, jak systemy eventowe radzą sobie z sytuacjami, w których ludzie obchodzą oficjalny proces rezerwacji — blokują zasoby nieformalnie, tworzą obejścia, rezerwują poza systemem."

**Źródła**: Web research — fokus na systemy eventowe i rezerwacyjne, wyłącznie wątek obejść ludzkich

---

## 1. Eventbrite — mechanizm "Holds" jako formalizacja nieformalnych blokad

Eventbrite posiada dedykowaną funkcję **holds** (blokad), która bezpośrednio adresuje problem znany z historii Sebastiana — handlowcy blokujący miejsca "na telefon" dla VIP-ów.

**Jak to działa:**
- Utworzenie holdu **wycofuje bilety ze sprzedaży** — nie są widoczne dla kupujących, ale pozostają w systemie jako zarezerwowane
- Holdy można nazwać (np. "VIP klient X", "Rezerwacja telefoniczna"), co daje audytowalność
- Bilety z holdu można później: (a) wydać konkretnym osobom przez access code, (b) sprzedać bezpośrednio przez aplikację organizatora, (c) przenieść jako manual order
- Holdy można przenosić między sobą (transfer seats from one hold to another)
- Usunięcie holdu natychmiast zwraca bilety do puli sprzedażowej

**Związek z historią Sebastiana:**
Handlowcy blokowali miejsca "na telefon" — Eventbrite formalizuje tę praktykę przez named holds. Zamiast nieformalnej notatki "zarezerwowane dla pana Kowalskiego", system ma oficjalny mechanizm blokady z nazwą, który jest widoczny dla wszystkich i wpływa na rzeczywistą dostępność. Kluczowe: hold zmniejsza widoczną pojemność, więc nie powstaje rozbieżność między "system pokazuje dostępność" a rzeczywistością.

> Źródło: [Create and manage holds - Eventbrite Help Center](https://www.eventbrite.com/help/en-us/articles/779653/how-to-create-and-manage-holds/), [Inventory & Holds Management - Eventbrite Blog](https://www.eventbrite.com/blog/inventory-holds-management/)

---

## 2. Hotelowe "courtesy holds" i "tentative reservations" — wzorzec rezerwacji z timeoutem

Branża hotelarska od lat boryka się z identycznym problemem — recepcjoniści i agenci tworzą rezerwacje "na telefon" bez gwarancji. Wypracowane rozwiązanie to **rezerwacja tymczasowa z automatycznym wygaśnięciem**.

**Courtesy hold (np. Holland America Line, Royal Caribbean):**
- Rezerwacja bez wpłaty, ważna 24-48 godzin
- Jeśli nie zostanie potwierdzona płatnością — automatycznie anulowana
- Zasób wraca do puli bez interwencji człowieka

**Oracle OPERA PMS — formalne typy rezerwacji:**
System hotelowy Oracle OPERA definiuje rezerwacje na dwóch poziomach wpływu na inwentarz:
- **Definite (potwierdzone)** — natychmiast odejmowane z dostępności (np. gwarantowane kartą kredytową)
- **Tentative (wstępne)** — domyślnie NIE odejmowane z dostępności, chyba że operator włączy opcję "Include Tentatives"
- Każdy typ może mieć automatyczne anulowanie po X dniach (Auto Mass Cancel) jeśli nie wpłynie karta/depozyt

**Związek z historią Sebastiana:**
Handlowiec blokuje miejsce na szkolenie telefonicznie — to klasyczny "courtesy hold". Problem Sebastiana polega na tym, że ta blokada nie istnieje w systemie. Hotelowe PMS-y rozwiązują to przez jawny status "tentative" z timeoutem. Rezerwacja ISTNIEJE w systemie (jest widoczna), ale ma datę wygaśnięcia. Organizator widzi prawdziwy obraz: "8 miejsc potwierdzonych, 3 tentative (wygasają za 48h)".

> Źródła: [Reservation Types - Oracle OPERA PMS](https://docs.oracle.com/cd/E53533_01/opera_5_05_00_core_help/reservation_types.htm), [Courtesy Hold - Holland America Line](https://www.hollandamerica.com/en/us/faq/booking/courtesy-hold-reservation), [Royal Caribbean temporary hold](https://www.royalcaribbeanblog.com/2023/07/12/spotted-royal-caribbean-adds-ability-place-temporary-hold-new-cruise-booking)

---

## 3. Hotelowe "allotment blocks" z cutoff date — wzorzec dla "warunkowego zwiększania pojemności"

W historii Sebastiana organizatorzy czasami zwiększali liczbę miejsc "warunkowo, jeśli widzieli duże zainteresowanie". Branża hotelowa ma na to formalny mechanizm — **allotment block z cutoff date i attrition clause**.

**Jak to działa:**
- Hotel blokuje pulę pokoi (np. 50) dla grupy/eventu po wynegocjowanej cenie
- Ustala **cutoff date** (zwykle 14-30 dni przed eventem) — termin, do którego goście muszą zarezerwować
- Po cutoff date niezarezerwowane pokoje wracają do ogólnej puli
- **Attrition clause**: grupa może zwolnić do ~20% bloku bez kary; powyżej — płaci penalty (nawet jeśli hotel sprzedał pokoje komuś innemu)
- Revenue manager monitoruje "pickup pace" — tempo rezerwacji vs historia — i decyduje, czy warto trzymać blok czy zwolnić pokoje do sprzedaży otwartej

**Związek z historią Sebastiana:**
Organizator "warunkowo zwiększa liczbę miejsc" — to nieformalna wersja allotment management. W formalnym systemie wyglądałoby to tak: organizator tworzy "blok warunkowy" na dodatkowe 5 miejsc z cutoff date (np. 7 dni przed szkoleniem). Jeśli do tego czasu nie ma wystarczającej liczby zgłoszeń — blok automatycznie się zamyka. System śledzi "pickup pace" i ostrzega organizatora. Nie ma niespodzianek typu "system pokazuje 5 miejsc, ale organizator obiecał je komuś".

> Źródła: [Hotel Attrition Guide - Canary Technologies](https://www.canarytechnologies.com/post/hotel-attrition), [Allotment - HelloShift](https://www.helloshift.com/hotel-term/allotment), [Room Block Management - EventsAir](https://www.eventsair.com/blog/hotel-room-room-block-management), [Cut-off Dates - Stova](https://stova.io/successful-room-block-management-part-3-cut-off-dates/)

---

## 4. Soft booking vs. hard booking — wzorzec z resource management

Systemy zarządzania zasobami (Runn, Productive.io) wprowadzają rozróżnienie **soft booking** vs. **hard booking**, które bezpośrednio adresuje problem nieformalnych rezerwacji.

**Soft booking:**
- Wstępne przypisanie zasobu, które NIE jest potwierdzone
- Widoczne w systemie, ale oznaczone jako niepewne
- Pozwala na planowanie "what-if" — co jeśli ten klient potwierdzi?
- Nie blokuje zasobu na stałe — inni widzą, że jest "miękko zajęty"

**Hard booking:**
- Potwierdzone, nieodwołalne przypisanie
- Zasób jest zablokowany i niedostępny dla innych

**Związek z historią Sebastiana:**
Handlowiec dzwoni: "Zarezerwuj 3 miejsca dla klienta VIP". Bez systemu soft bookings — albo blokuje na twardo (i miejsca znikają), albo "pamięta" nieformalnie (i system pokazuje fałszywą dostępność). Soft booking rozwiązuje ten dylemat: miejsca są oznaczone jako "wstępnie zarezerwowane", widoczne dla wszystkich, ale z jasnym statusem "niepotwierdzony". Organizator widzi prawdziwy obraz: "12 hard, 3 soft, 5 wolnych".

> Źródło: [Soft Booking Resources - Runn](https://www.runn.io/blog/soft-booking-resources), [Tentative Bookings - Productive.io](https://help.productive.io/en/articles/8582323-tentative-bookings)

---

## 5. ROLLER — tentative bookings z automatycznym wygaśnięciem

Platforma ROLLER (zarządzanie atrakcjami/eventami) oferuje **tentative bookings** — mechanizm wprost zaprojektowany do obsługi rezerwacji telefonicznych i nieformalnych.

**Jak to działa:**
- Operator tworzy rezerwację wstępną (tentative) z ustalonym okresem ważności
- Gość ma określony czas na dokonanie płatności
- Jeśli termin minie bez płatności — rezerwacja automatycznie się anuluje
- Zwolnione miejsca wracają do sprzedaży bez interwencji człowieka

**Związek z historią Sebastiana:**
To jest dokładnie mechanizm, którego brakuje w systemie szkoleniowym. Handlowiec dzwoni z blokadą "na telefon" — system powinien pozwolić mu utworzyć tentative booking z timeoutem (np. 72h). Klient albo potwierdzi i zapłaci, albo rezerwacja wygaśnie. Nie ma ryzyka "phantom seats" — miejsc zablokowanych nieformalnie, które nigdy nie zostaną potwierdzone.

> Źródło: [Tentative Bookings - ROLLER](https://mysupport.roller.software/hc/en-us/articles/8406072578447-Streamline-booking-processes-with-tentative-bookings)

---

## 6. Ghost bookings i speculative reservations — problem rezerwacji "na wszelki wypadek"

Branża hotelarska zidentyfikowała zjawisko **ghost bookings** — rezerwacji, które nigdy nie miały szansy się zmaterializować.

**Przyczyny:**
- Podróżni rezerwują w kilku hotelach jednocześnie, porównując opcje, i zapominają anulować
- Rezerwacje spekulatywne — "zarezerwuję na wszelki wypadek, jak się potwierdzi lot/wiza"
- Łatwość rezerwacji online zachęca do "hedgingu" — rezerwowania z intencją anulowania
- Brak kary za anulowanie eliminuje motywację do rezygnacji

**Skutki:**
- Pokój stoi pusty (utracony przychód + koszty przygotowania)
- Zniekształcone prognozy obłożenia
- Fałszywy obraz "sold out" blokujący prawdziwych gości

**Rozwiązania:**
- Wymóg karty kredytowej/depozytu przy rezerwacji (redukuje no-shows do ~5%)
- Automatyczne przypomnienia SMS/email przed check-in
- Elastyczne opcje cenowe (refundowalna vs. nierefundowalna stawka)
- Pre-check-in online jako wymóg potwierdzenia

**Związek z historią Sebastiana:**
Handlowiec blokuje 3 miejsca "na telefon" dla klienta, który "prawdopodobnie przyjdzie". To jest ghost booking w czystej postaci. Rozwiązanie z branży hotelowej: wymagaj minimalnego zobowiązania (choćby maila potwierdzającego) lub ustaw automatyczne wygaśnięcie. System szkoleniowy mógłby wprowadzić regułę: blokada telefoniczna wymaga potwierdzenia emailem w ciągu 48h, inaczej wygasa.

> Źródło: [Ghost booking: How to reduce no show hotel bookings - SiteMinder](https://www.siteminder.com/r/no-show-hotel/)

---

## 7. PeopleSoft Enterprise Learning — "reserved seats" i "overbooking percentage"

Oracle PeopleSoft ELM (Enterprise Learning Management) — system zarządzania szkoleniami korporacyjnymi — ma wbudowane mechanizmy na oba obejścia z historii Sebastiana.

**Reserved seats (zarezerwowane miejsca):**
- Administrator może zarezerwować miejsca dla departamentu lub organizacji BEZ wskazywania konkretnych osób
- Tylko administrator może zapisać kogoś na zarezerwowane miejsce
- Miejsca zarezerwowane są odseparowane od ogólnej puli — nie pojawiają się jako "wolne"

**Overbooking percentage (procent nadmiarowy):**
- System pozwala ustawić procent overbookingu (np. 10%)
- Przy max enrollment = 20 i overbooking = 10%, system przyjmie do 22 zapisów
- Powyżej limitu (z uwzględnieniem overbookingu) uruchamia się waitlist
- Waitlist ma własny limit pojemności

**Związek z historią Sebastiana:**
- Handlowcy blokują miejsca "na telefon" dla VIP-ów — PeopleSoft formalizuje to jako "reserved seats" przypisane do działu handlowego, widoczne w systemie, niepomniejszające puli ogólnej w mylący sposób
- Organizatorzy "warunkowo zwiększają liczbę miejsc" — PeopleSoft formalizuje to jako overbooking percentage. Zamiast nieformalnej decyzji "dostawimy krzesło", system ma jawny parametr: szkolenie na 20 osób z 10% overbookingiem = max 22. Przejrzyste dla wszystkich.

> Źródło: [SPD 9.2 ELM Training Administration - Oracle PeopleSoft](https://www.in.gov/spd/files/9-2-User-Guide-FINAL.pdf)

---

## 8. Wzorzec architektoniczny: Two-Phase Reservation (soft lock + hard booking)

Na poziomie projektowania systemów istnieje uznany wzorzec **dwufazowej rezerwacji**, który bezpośrednio modeluje przejście od nieformalnej blokady do formalnej rezerwacji.

**Faza 1 — Soft lock (blokada tymczasowa):**
- Użytkownik inicjuje rezerwację — system tworzy tymczasową blokadę na zasobie
- Blokada ma TTL (time-to-live), np. 5-20 minut (w systemach online) lub 48-72 godziny (w systemach z rezerwacją telefoniczną)
- Implementacja: klucz w Redis z TTL lub rekord w bazie z expiration timestamp
- Zasób jest widocznie "w trakcie rezerwacji" — inni widzą zmniejszoną dostępność

**Faza 2 — Hard booking (potwierdzenie):**
- Użytkownik potwierdza (płatność, email, podpis) — soft lock zamienia się w pełną rezerwację
- Jeśli timeout minie bez potwierdzenia — soft lock znika automatycznie, zasób wraca do puli

**Związek z historią Sebastiana:**
Cały problem Sebastiana to brak fazy 1 w systemie. Handlowcy tworzą "soft locks" poza systemem (notatka, telefon, pamięć). System nie wie o tych blokadach, więc pokazuje fałszywą dostępność. Rozwiązanie: wprowadzić jawną fazę "soft lock" do systemu szkoleniowego — handlowiec tworzy blokadę w systemie z timeoutem, system pokazuje prawdziwy stan: "15 potwierdzonych, 3 w trakcie rezerwacji (wygasają za 48h), 2 wolne".

> Źródła: [Design Hotel Booking System - System Design Handbook](https://www.systemdesignhandbook.com/guides/design-hotel-booking-system/), [Concurrency Strategies in Reservation Systems - Medium](https://medium.com/devbulls/concurrency-strategies-in-multi-user-reservation-systems-b8142dea1bc8)

---

## 9. Zależności sprzętowe — resource scheduling z conflict detection

Problem Sebastiana dotyczył nie tylko miejsc, ale i sprzętu (aparat do nagrywania). Systemy rezerwacyjne adresują to przez **multi-resource booking z automatycznym wykrywaniem konfliktów**.

**Jak to działa w nowoczesnych systemach:**
- Rezerwacja eventu/szkolenia wymaga jednoczesnego zarezerwowania WSZYSTKICH zależnych zasobów (sala + sprzęt + trener)
- System sprawdza dostępność wszystkich zasobów w real-time przed potwierdzeniem
- Jeśli którykolwiek zasób jest niedostępny — rezerwacja nie przechodzi, użytkownik widzi, KTÓRY zasób blokuje
- Platformy takie jak Schedule.it, YAROOMS, CloudGym Manager traktują pokoje i sprzęt jako równorzędne "resources" w jednym systemie

**Związek z historią Sebastiana:**
Szkolenie odwołane, bo aparat był uszkodzony — mimo wolnych miejsc i dostępnej sali. To klasyczny brak multi-resource dependency. W systemie Sebastiana "szkolenie" prawdopodobnie zależy tylko od "sali" i "miejsc". Aparat nie jest modelowany jako wymagany zasób. Rozwiązanie: każde szkolenie ma listę wymaganych zasobów (sala, projektor, aparat, trener), a system nie pozwala potwierdzić szkolenia bez dostępności WSZYSTKICH.

> Źródła: [Resource Management Software - Schedule.it](https://www.scheduleit.com/), [How to Prevent Double Bookings - YAROOMS](https://www.yarooms.com/blog/how-to-prevent-double-bookings-in-meeting-and-conference-rooms), [Facility & Resource Booking - CloudGym Manager](https://www.cloudgymmanager.com/facility-resource-booking-rooms-courts-equipment-reservations-that-work/)

---

## Podsumowanie: wzorce absorpcji obejść

| Obejście z historii Sebastiana | Wzorzec z branży | Mechanizm |
|---|---|---|
| Handlowiec blokuje miejsca "na telefon" | Eventbrite Holds, Hotel Courtesy Hold, Two-Phase Reservation | Named hold z timeoutem — blokada widoczna w systemie, automatycznie wygasa |
| Blokada dla VIP bez formalnej rezerwacji | PeopleSoft Reserved Seats, Soft Booking | Pula zarezerwowana dla działu/grupy, oddzielona od ogólnej dostępności |
| Organizator "warunkowo" zwiększa miejsca | Hotel Allotment Block, PeopleSoft Overbooking % | Jawny parametr nadmiarowy z cutoff date i automatycznym zwolnieniem |
| Rezerwacje, które się nie materializują | Ghost Booking mitigation, Courtesy Hold timeout | Wymóg potwierdzenia + automatyczne wygaśnięcie = zasób nie "gnije" |
| Brak sprzętu blokuje szkolenie | Multi-Resource Booking z conflict detection | Szkolenie = bundle zasobów; brak dowolnego = brak potwierdzenia |

**Kluczowy wniosek**: Dojrzałe systemy rezerwacyjne nie walczą z obejściami — **absorbują je do oficjalnego procesu**. Zamiast zabraniać handlowcowi blokady telefonicznej, dają mu narzędzie do tworzenia formalnej blokady tymczasowej. Zamiast zabraniać organizatorowi zwiększania miejsc, dają mu parametr overbookingu z automatycznym limitem. Obejście staje się feature'em.