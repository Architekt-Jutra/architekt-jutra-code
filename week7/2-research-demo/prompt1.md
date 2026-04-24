## Prompt

> Zgłoszony problem brzmiał: „mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność".
> Na początku zacząłem zbierać informacje. Przejrzałem dokumentację, raporty z systemu oraz porozmawiałem z działem obsługi klienta, organizatorami i trenerami. W trakcie rozmów wyszły rzeczy, których nie było w żadnym systemie. Handlowcy blokowali miejsca „na telefon" dla klientów VIP. Organizatorzy czasami zwiększali liczbę miejsc „warunkowo", jeśli widzieli duże zainteresowanie. Dodatkowo pojawił się nowy wątek: szkolenie nie zależało tylko od sali i miejsc, ale też od dostępności sprzętu – np. aparatu do nagrania szkolenia. W jednym przypadku szkolenie zostało odwołane, bo aparat był uszkodzony, mimo że były wolne miejsca i dostępna sala. To była wiedza, której wcześniej nie było nigdzie formalnie zapisana.
> Następnie rozrysowałem proces zapisu na szkolenie, zaznaczyłem hotspoty, opisałem scenariusze w postaci user stories i przygotowałem model: szkolenie, sala, miejsce, rezerwacja, blokada, sprzęt. Stworzyłem też diagram pokazujący zależności między tymi elementami.
> Dopiero po zestawieniu wszystkich elementów zauważyłem, że problem nie dotyczy tylko „miejsc na szkolenie", tylko zarządzania różnymi typami zasobów, które są potrzebne do jego realizacji. Sala, miejsca, sprzęt nagraniowy – wszystkie te elementy podlegały podobnym regułom: mogły być rezerwowane, blokowane, zwalniane albo wyłączane z użycia (np. w przypadku awarii). Uogólniłem to do jednego pojęcia: „zasób", który ma swój stan i podlega alokacji. Dzięki temu architektura była rozszerzalna, przyjmowała w łatwy sposób kolejne typy zasobów. Dzięki temu trenera mogłem potraktować jako … zasób. Pojedyncze źródło prawdy zachować spójność i skalowalność.
> przeanalizuj mi ten problem

---

# Analiza problemu: system zapisów na szkolenia

## Kontekst

Zgłoszony problem: „mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność".

Odkrycia z fazy zbierania informacji:
- Handlowcy blokowali miejsca „na telefon" dla klientów VIP
- Organizatorzy warunkowo zwiększali liczbę miejsc przy dużym zainteresowaniu
- Realizacja szkolenia zależała nie tylko od sali i miejsc, ale też od sprzętu (np. aparat do nagrań)
- Zaproponowana generalizacja: wszystkie elementy (sala, miejsca, sprzęt, trener) jako „zasób" z operacjami rezerwuj/blokuj/zwolnij/wyłącz

## Co poszło dobrze

**Odkrycie ukrytej wiedzy (tacit knowledge)** — najcenniejsza część. System formalny nie odzwierciedlał rzeczywistości: blokady „na telefon", warunkowe zwiększanie pojemności, zależność od sprzętu. To klasyczny objaw — system modeluje tylko "happy path", a realna złożoność żyje w głowach ludzi i nieformalnych procesach.

**Podejście od problemu, nie od rozwiązania** — dobrze, że zaczęło się od rozmów z ludźmi, nie od diagramu klas.

## Co wymaga krytycznego spojrzenia

### 1. Generalizacja "zasób" — zbyt wczesna i zbyt szeroka

To jest główny punkt, który budzi wątpliwości. Sala, miejsce, sprzęt nagraniowy i trener **wyglądają** podobnie (rezerwacja, blokada, zwolnienie), ale **zachowują się** różnie:

- **Miejsce** — jest fungible (jedno miejsce = drugie miejsce). Liczy się ilość, nie konkretna instancja.
- **Sala** — jest konkretna, ma atrybuty (pojemność, lokalizacja, wyposażenie). Nie jest zamienna.
- **Sprzęt** — ma stan techniczny, może ulec awarii, wymaga serwisu. Ma lifecycle, którego sala nie ma.
- **Trener** — ma kompetencje, dostępność czasową, preferencje, urlopy, stawki. Jest **osobą**, nie zasobem w sensie fizycznym.

Uogólnienie ich do jednego interfejsu `Zasób` z operacjami `rezerwuj/blokuj/zwolnij/wyłącz` to **premature abstraction**. Reguły biznesowe są różne:
- Trenera nie "wyłączasz z użycia" jak aparat — trener idzie na urlop albo odmawia.
- Warunkowe zwiększenie pojemności dotyczy miejsc, nie sprzętu.
- Blokada VIP dotyczy miejsca na szkoleniu, nie sali.

Wspólny interfejs wymusza albo upraszczanie (gubisz reguły), albo rozrastanie się abstrakcji (`if type == trainer then...`), co niszczy sens generalizacji.

### 2. Brakujący element — co jest agregatem?

Opis mówi o modelu: szkolenie, sala, miejsce, rezerwacja, blokada, sprzęt. Ale nie mówi o **granicach spójności**. Kluczowe pytanie: **co jest jednostką, która chroni niezmiennik "nie można zarezerwować więcej niż jest dostępne"?**

Jeśli to `Szkolenie` jest agregatem, to powinno ono znać swoje zasoby i pilnować spójności. Jeśli zasoby są niezależne — potrzebujesz koordynacji (saga/process manager), bo rezerwacja szkolenia to de facto **rezerwacja wielu zasobów atomowo**.

### 3. Problem nie brzmi "zarządzanie zasobami" — brzmi "realizowalność szkolenia"

Prawdziwy niezmiennik to: **szkolenie może się odbyć wtedy i tylko wtedy, gdy wszystkie wymagane warunki są spełnione jednocześnie**. To nie jest problem alokacji zasobów — to problem **koordynacji dostępności** z regułą "all-or-nothing".

To sugeruje inny model:
- `Szkolenie` definiuje **wymagania realizacji** (sala z pojemnością X, sprzęt Y, trener z kompetencją Z)
- Sprawdzenie realizowalności to **query** po wielu bounded contexts
- Rezerwacja to **saga**, która alokuje wszystko albo nic

### 4. Nieformalne procesy wymagają decyzji, nie modelowania

Blokady VIP i warunkowe zwiększanie pojemności to **decyzje biznesowe**, nie anomalie do zamodelowania. Trzeba odpowiedzieć:
- Czy blokada VIP ma być wspierana przez system? Jeśli tak — to jawna reguła z limitem i timeout.
- Czy warunkowe zwiększanie pojemności to feature czy nadużycie? Jeśli feature — potrzebna jest reguła (kto może, kiedy, o ile).

Modelowanie tego bez decyzji biznesowej prowadzi do systemu, który formalizuje chaos zamiast go eliminować.

## Podsumowanie

| Aspekt | Ocena |
|---|---|
| Odkrycie ukrytej wiedzy | Mocne |
| User stories i scenariusze | Dobre podejście |
| Generalizacja do "zasobu" | Zbyt wczesna — różne reguły = różne modele |
| Granice spójności (agregaty) | Brak w opisie |
| Koordynacja all-or-nothing | Nie zaadresowana |
| Decyzje biznesowe vs modelowanie | Pomieszane |

## Rekomendacja

Zamiast uogólniać w dół (wspólna abstrakcja "zasób"), warto uogólnić **w górę** — pojęcie "realizowalności szkolenia" jako orkiestracja wielu niezależnych kontekstów, z których każdy rządzi się własnymi regułami.
