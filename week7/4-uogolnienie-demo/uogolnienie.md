# Prompt

Masz blok wymagań domenowych. Użyj uogólnienia jako techniki szukania modułów — znajdź różne koncepty, które w danym procesie zachowują się identycznie.

Szukaj po czasownikach, nie rzeczownikach ("rezerwuję salę", "rezerwuję trenera" — ten sam mechanizm → kandydat do wspólnej abstrakcji). Testuj efektem w kontekście konsumenta, nie przyczyną u źródła — urlop i awaria to różne procesy, ale oba powodują niedostępność, więc w kontekście dostępności to jedno.

Daj: tabelę uogólnień z techniką (uogólnienie / wyabstrahowanie / zmiana reprezentacji), listę modułów z kluczowym pytaniem każdego.

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

## Mapa modułów (wynikająca z uogólnień)

### Dostępność Zasobów (uogólniony)

**Kluczowe pytanie**: "Czy zasób X jest dostępny w czasie T?"

- Operuje na: ReservableResource, UnavailabilityPeriod
- Komendy: block(resourceId, timeRange), unblock(resourceId, timeRange)
- Zdarzenia: ResourceBlocked, ResourceUnblocked

### Zapisy na Szkolenie (uogólniony w warstwie slotów)

**Kluczowe pytanie**: "Czy w edycji E jest wolny slot i mogę go zająć?"

- Operuje na: SlotClaim, pojemność edycji
- Komendy: claimSlot(editionId, quantity, ttl), releaseSlot(editionId, claimId), adjustCapacity(editionId, delta)
- Zdarzenia: SlotClaimed, SlotReleased, CapacityAdjusted
