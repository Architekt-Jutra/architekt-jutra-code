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

## Dyskusja: Trener jako zasób
### Czy Trener nie jest zasobem?

> **Pytanie**: A czy Trener nie jest zasobem?

Trener **jest zasobem** w tym samym sensie co sala i sprzęt — ma ograniczoną dostępność i jego brak może zablokować realizację szkolenia.

W obecnym modelu Zarządzanie Zasobami ma tylko Salę i Sprzęt, a Trener jest traktowany osobno w Planowaniu Edycji. To niespójność — jeśli uszkodzony aparat blokuje szkolenie, to niedostępny trener (choroba, urlop) robi dokładnie to samo.

Dwa podejścia:

1. **Trener jako zasób w Zarządzanie Zasobami** — sala, sprzęt i trener to po prostu różne typy zasobów z kalendarzem dostępności. Decyzja go/no-go w Realizacji odpytuje jeden kontekst o wszystkie zasoby.
2. **Trener zostaje osobno** — jeśli trener to nie tylko "zasób do zarezerwowania", ale ma kompetencje, preferencje, negocjuje terminy. Wtedy jest bardziej aktorem niż zasobem.

Kluczowe pytanie: czy trener w tym systemie jest bliżej sali (rezerwuję slot) czy bliżej handlowca (podejmuje decyzje)?

### A co jeśli i jedno, i drugie?

> **Pytanie**: A co jeśli i jedno, i drugie?

Wtedy Trener żyje w dwóch kontekstach z różnym znaczeniem:

- **Osoby / Party** — Trener jako aktor: kompetencje, preferencje, negocjuje terminy, może odmówić
- **Zarządzanie Zasobami** — Trener jako slot w kalendarzu: dostępny/niedostępny w danym terminie, rezerwowany jak sala

To klasyczny przypadek gdzie **jedno słowo oznacza dwie rzeczy** w zależności od kontekstu. W Party "Trener Kowalski ma certyfikat X i preferuje szkolenia online". W Zasobach "Slot trenera 15-16 kwietnia jest zajęty".

Integracja: Party jest źródłem prawdy o tym **kim** jest trener. Zasoby trzymają projekcję tego, co potrzebują — kalendarz dostępności. Event `TrenerNiedostępny` z Zasobów działa identycznie jak `SprzętNiedostępny` i blokuje edycję.

### Co jeszcze mogłoby być zasobem, a nie jest wymienione?

> **Pytanie**: Co jeszcze mogłoby być zasobem, a nie jest wymienione w tekście?

Patrząc na domenę — wszystko, czego brak blokuje lub degraduje szkolenie, jest zasobem:

| Kandydat na zasób | Dlaczego? |
|---|---|
| **Materiały szkoleniowe** | Wydrukowane podręczniki, zestawy ćwiczeń, kity laboratoryjne — jeśli nie dotarły z drukarni, szkolenie się nie odbędzie albo będzie niepełne |
| **Licencje na oprogramowanie** | Szkolenie IT wymaga np. 15 licencji na narzędzie — jeśli jest ich 10, nie pomieścisz 15 uczestników |
| **Stanowiska / laptopy** | Szkolenie warsztatowe wymaga stanowiska na osobę — to taki sam ograniczony slot jak miejsce na sali |
| **Catering** | Zamówiony z wyprzedzeniem, ma deadline anulacji — jeśli zamówiony na 15 osób, warunkowe zwiększenie do 20 wymaga zmiany zamówienia |
| **Tłumacz** | Przy szkoleniach międzynarodowych — ograniczona dostępność, rezerwowany jak trener |

Wzorzec jest ten sam co przy trenerze: **jeśli brak X-a może zablokować realizację szkolenia, to X jest zasobem**, nawet jeśli organizatorzy o nim myślą jako o "logistyce", a nie o "zasobie".

Pytanie do domeny: które z tych rzeczy faktycznie blokowały lub degradowały szkolenia w przeszłości? To najlepszy test — nie modelować na zapas, tylko to, co realnie powoduje problemy.
