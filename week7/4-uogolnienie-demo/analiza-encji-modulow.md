# Analiza encji i modułów — System zapisów na szkolenia

## Prompt: "Daj listę modułów i encji"

> Zgłoszony problem brzmiał: „mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność".
>
> Na początku zacząłem zbierać informacje. Przejrzałem dokumentację, raporty z systemu oraz porozmawiałem z działem obsługi klienta, organizatorami i trenerami. W trakcie rozmów wyszły rzeczy, których nie było w żadnym systemie. Handlowcy blokowali miejsca „na telefon" dla klientów VIP. Organizatorzy czasami zwiększali liczbę miejsc „warunkowo", jeśli widzieli duże zainteresowanie. Dodatkowo pojawił się nowy wątek: szkolenie nie zależało tylko od sali i miejsc, ale też od dostępności sprzętu — np. aparatu do nagrania szkolenia. W jednym przypadku szkolenie zostało odwołane, bo aparat był uszkodzony, mimo że były wolne miejsca i dostępna sala. To była wiedza, której wcześniej nie było nigdzie formalnie zapisana.

---

## Encje

| Encja | Opis |
|-------|------|
| **Szkolenie** | Definicja szkolenia (temat, wymagania, typ) |
| **Edycja Szkolenia** | Konkretna instancja szkolenia w czasie (data, trener, sala) |
| **Sala** | Zasób fizyczny z pojemnością |
| **Miejsce** | Slot w edycji szkolenia (dostępne/zajęte) |
| **Rezerwacja** | Formalne zapisanie uczestnika |
| **Blokada** | Nieformalna rezerwacja "na telefon" przez handlowca dla VIP |
| **Sprzęt** | Zasób wymagany do realizacji (aparat, projektor) |
| **Uczestnik** | Osoba zapisana na szkolenie |
| **Trener** | Prowadzący szkolenie |
| **Handlowiec** | Osoba blokująca miejsca dla klientów |
| **Organizator** | Osoba zarządzająca edycją (może warunkowo zwiększyć pojemność) |

## Moduły / kandydaci na konteksty

### 1. Katalog Szkoleń — co oferujemy

- Szkolenie, program, wymagania sprzętowe, typ
- Kontekst stabilny, rzadko się zmienia

### 2. Planowanie Edycji — kiedy, gdzie, kto prowadzi

- Edycja Szkolenia, przypisanie Trenera, przypisanie Sali
- Tu decyzja o "warunkowym zwiększeniu pojemności" przez Organizatora
- Odpowiada na pytanie: czy edycja jest gotowa do otwarcia zapisów?

### 3. Zarządzanie Zasobami — dostępność fizyczna

- Sala (pojemność, kalendarz zajętości)
- Sprzęt (dostępność, stan techniczny)
- To tutaj powinien być widoczny uszkodzony aparat
- Kontekst odpowiada za prawdę o tym, co fizycznie jest dostępne

### 4. Zapisy (Enrollment) — rywalizacja o miejsca

- Rezerwacja, Blokada (VIP), Miejsce
- **Hotspot**: tu jest resource contention — handlowcy vs zwykli klienci vs pojemność vs sprzęt
- Blokada ma TTL (wygasa jeśli nie potwierdzona)
- To jest serce problemu zgłoszonego przez klienta

### 5. Osoby / Party — kto jest kim

- Uczestnik, Trener, Handlowiec, Organizator
- Role, dane kontaktowe
- Kontekst wspólny, referencyjny

---
