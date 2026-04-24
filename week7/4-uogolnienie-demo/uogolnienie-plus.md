# Prompt

Masz blok wymagań domenowych. Użyj uogólnienia jako techniki szukania modułów — znajdź różne koncepty, które w danym procesie zachowują się identycznie.

Szukaj po czasownikach, nie rzeczownikach ("rezerwuję salę", "rezerwuję trenera" — ten sam mechanizm → kandydat do wspólnej abstrakcji). Testuj efektem w kontekście konsumenta, nie przyczyną u źródła — urlop i awaria to różne procesy, ale oba powodują niedostępność, więc w kontekście dostępności to jedno.

Gdy znajdziesz uogólnienia, zaproponuj inne koncepty spoza tekstu wymagań, które wpadałyby w to samo uogólnienie choć tekst ich nie wymienia.

Daj: tabelę uogólnień z techniką (uogólnienie / wyabstrahowanie / zmiana reprezentacji), propozycje dodatkowych konceptów per uogólnienie, listę modułów z kluczowym pytaniem każdego.

> Zgłoszony problem brzmiał: „mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność".
>
> Na początku zacząłem zbierać informacje. Przejrzałem dokumentację, raporty z systemu oraz porozmawiałem z działem obsługi klienta, organizatorami i trenerami. W trakcie rozmów wyszły rzeczy, których nie było w żadnym systemie. Handlowcy blokowali miejsca „na telefon" dla klientów VIP. Organizatorzy czasami zwiększali liczbę miejsc „warunkowo", jeśli widzieli duże zainteresowanie. Dodatkowo pojawił się nowy wątek: szkolenie nie zależało tylko od sali i miejsc, ale też od dostępności sprzętu — np. aparatu do nagrania szkolenia. W jednym przypadku szkolenie zostało odwołane, bo aparat był uszkodzony, mimo że były wolne miejsca i dostępna sala. To była wiedza, której wcześniej nie było nigdzie formalnie zapisana.

---

# Uogólnienia w domenie szkoleń

## Tabela uogólnień

| Oryginalne koncepty | Wspólne zachowanie (czasownik) | Uogólnione jako | Technika |
|---|---|---|---|
| Sala, Trener, Sprzęt (aparat) | "rezerwuję X na termin", "sprawdzam czy X jest dostępny w czasie T" | **ReservableResource** | Wyabstrahowanie (nowy koncept, którego nie było w słowniku) |
| Urlop trenera, Awaria sprzętu, Remont sali | "X jest niedostępny od-do" — efekt w kontekście konsumenta identyczny | **UnavailabilityPeriod** | Uogólnienie (usunięcie przyczyny, zostaje efekt: niedostępność + zakres dat) |
| Blokada VIP (handlowiec), Zapis uczestnika | "zajmuję slot w limicie edycji" | **SlotClaim** | Uogólnienie (usunięcie powodu zajęcia, zostaje: edycja + ile slotów + TTL) |

### Test fałszywego uogólnienia

- **ReservableResource** — czy musi wiedzieć, że sala ma pojemność, a trener certyfikaty? **Nie.** Wie tylko: resourceId, type, timeRange. Test przechodzi.
- **UnavailabilityPeriod** — czy musi wiedzieć, że urlop wymaga akceptacji przełożonego, a awaria zgłoszenia serwisowego? **Nie.** Wie tylko: resourceId, from, to. Test przechodzi.
- **SlotClaim** — czy musi wiedzieć, że blokada VIP pochodzi od handlowca, a zapis od uczestnika? **Nie.** Wie: editionId, quantity, expiresAt. Test przechodzi.

---

## Propozycje dodatkowych konceptów per uogólnienie

Skoro mamy uogólnienie, to pytanie brzmi: co jeszcze w tej domenie zachowuje się identycznie, choć tekst wymagań tego nie wymienia?

### ReservableResource — jakie inne zasoby?

| Proponowany zasób | Dlaczego wpada w to samo uogólnienie | Skąd intuicja |
|---|---|---|
| **Tłumacz** | "rezerwuję tłumacza na termin" — identyczny czasownik jak trener. Dostępność sprawdzana tak samo. | Szkolenia międzynarodowe / dla obcojęzycznych grup |
| **Samochód firmowy / transport** | "rezerwuję transport na termin" — zasób potrzebny, żeby trener dotarł na szkolenie wyjazdowe. | Szkolenia poza siedzibą firmy |
| **Licencja na oprogramowanie** | "rezerwuję licencję na termin" — szkolenie IT wymaga N stanowisk z konkretnym softem. Licencja to zasób o ograniczonej pojemności. | Szkolenia techniczne / laboratoryjne |
| **Catering / przerwa kawowa** | "rezerwuję catering na termin" — zewnętrzny dostawca ma ograniczoną przepustowość na dany dzień. | Szkolenia całodniowe |

### UnavailabilityPeriod — jakie inne niedostępności?

| Proponowana niedostępność | Efekt w kontekście konsumenta | Proces źródłowy (specyficzny) |
|---|---|---|
| **Choroba trenera** | Identyczny jak urlop: trener niedostępny w oknie T | Zwolnienie lekarskie (nieplanowane, inny proces niż urlop) |
| **Planowy przegląd techniczny sprzętu** | Identyczny jak awaria: sprzęt niedostępny w oknie T | Harmonogram konserwacji (planowane, inny proces niż awaria) |
| **Rezerwacja sali przez inny dział** | Identyczny jak remont: sala niedostępna w oknie T | Wewnętrzny system rezerwacji (inna jednostka firmy) |
| **Wygaśnięcie licencji oprogramowania** | Licencja niedostępna do odnowienia | Proces zakupowy / odnowienie umowy |
| **Trener na innym szkoleniu** | Identyczny jak urlop: trener niedostępny w oknie T | Planowanie harmonogramu trenerów |

### SlotClaim — jakie inne roszczenia do pojemności?

| Proponowane roszczenie | Dlaczego wpada w to samo uogólnienie | Cykl życia (specyficzny) |
|---|---|---|
| **Rezerwacja grupowa (firma kupuje 10 miejsc)** | "zajmuję N slotów" — identyczny efekt na pulę jak zapis indywidualny | Umowa B2B, faktura, potencjalnie częściowa rezygnacja |
| **Miejsce dla prowadzącego / asystenta** | Slot zajęty, ale nie przez uczestnika — trener/asystent też fizycznie zajmuje miejsce | Automatyczne przy tworzeniu edycji, bez TTL |
| **Rezerwacja z listy oczekujących** | Slot zajęty warunkowo — ktoś czeka na zwolnienie i dostaje priorytet | Aktywacja przy release innego roszczenia |

---

## Mapa modułów (wynikająca z uogólnień)

### Dostępność Zasobów (uogólniony)

**Kluczowe pytanie**: "Czy zasób X jest dostępny w czasie T?"

- Operuje na: ReservableResource, UnavailabilityPeriod
- Nie zna typów zasobów, nie zna przyczyn niedostępności
- Zasilany przez moduły specyficzne, które publikują fakty niedostępności

### Pula Pojemności (uogólniony)

**Kluczowe pytanie**: "Ile wolnych slotów zostało w edycji E i mogę zająć N?"

- Operuje na: SlotClaim, limit pojemności
- Nie wie kto rości ani dlaczego — zna tylko: claim / release / adjust_limit
- Jedno źródło prawdy o wolnych miejscach (rozwiązuje chaos z wymagań)

### Trenerzy (specyficzny)

**Kluczowe pytanie**: "Kto ma jakie kwalifikacje i kiedy jest na urlopie/chorobowym?"

- Procesy: wnioskowanie o urlop, zatwierdzanie, kwalifikacje, przypisanie do tematu
- Publikuje do Dostępności: `niedostępny(trener_id, od, do)`
- Odpowiada na pytania selekcji: "kto może prowadzić szkolenie z Javy?"

### Sprzęt (specyficzny)

**Kluczowe pytanie**: "Jaki jest stan techniczny i kiedy przegląd/naprawa?"

- Procesy: zgłoszenie usterki, naprawa, przegląd planowy, specyfikacja techniczna
- Publikuje do Dostępności: `niedostępny(sprzęt_id, od, do)`
- Odpowiada na pytania selekcji: "jaki sprzęt typu kamera jest wolny?"

### Sale (specyficzny)

**Kluczowe pytanie**: "Jaka jest pojemność fizyczna i harmonogram zajętości?"

- Procesy: zarządzanie pojemnością, rezerwacje zewnętrzne, remonty
- Publikuje do Dostępności: `niedostępna(sala_id, od, do)`
- Odpowiada na pytania selekcji: "która sala pomieści 30 osób?"

### Zapisy (specyficzny)

**Kluczowe pytanie**: "Kto jest zapisany, na jakich warunkach, jaki jest status?"

- Procesy: rejestracja, potwierdzenie, płatność, rezygnacja, waitlist
- Wykonuje `claim` / `release` na Puli Pojemności
- Zarządza cyklem życia zapisu (roszczenie bez TTL, zwolnienie przy rezygnacji)

### Rezerwacje Handlowe (specyficzny)

**Kluczowe pytanie**: "Jakie blokady VIP istnieją i kiedy wygasają?"

- Procesy: blokada przez handlowca, automatyczne wygaśnięcie, konwersja na zapis
- Wykonuje `claim` / `release` na Puli Pojemności
- Zarządza cyklem życia blokady (roszczenie z TTL, automatyczne zwolnienie)

### Wykonalność Szkolenia (konsument)

**Kluczowe pytanie**: "Czy to szkolenie może się odbyć — czy wszystkie wymagane zasoby są dostępne i są wolne miejsca?"

- Odpytuje Dostępność (czy trener + sala + sprzęt wolne?) i Pulę Pojemności (czy są sloty?)
- Nie zarządza niczym — tylko sprawdza i reaguje
- Łapie scenariusz z uszkodzonym aparatem (którego brakowało w oryginalnym systemie)