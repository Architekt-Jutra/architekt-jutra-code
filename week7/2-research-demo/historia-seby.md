# Historia Seby

## Problem

Zgłoszony problem brzmiał: *„mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność”*.

## Zbieranie informacji

Na początku zacząłem zbierać informacje. Przejrzałem dokumentację, raporty z systemu oraz porozmawiałem z działem obsługi klienta, organizatorami i trenerami.

W trakcie rozmów wyszły rzeczy, których nie było w żadnym systemie:
- Handlowcy blokowali miejsca „na telefon” dla klientów VIP.
- Organizatorzy czasami zwiększali liczbę miejsc „warunkowo”, jeśli widzieli duże zainteresowanie.
- Pojawił się nowy wątek: szkolenie nie zależało tylko od sali i miejsc, ale też od dostępności sprzętu – np. aparatu do nagrania szkolenia.

W jednym przypadku szkolenie zostało odwołane, bo aparat był uszkodzony, mimo że były wolne miejsca i dostępna sala. To była wiedza, której wcześniej nie było nigdzie formalnie zapisana.

## Modelowanie

Następnie rozrysowałem proces zapisu na szkolenie, zaznaczyłem hotspoty, opisałem scenariusze w postaci user stories i przygotowałem model: szkolenie, sala, miejsce, rezerwacja, blokada, sprzęt. Stworzyłem też diagram pokazujący zależności między tymi elementami.

## Uogólnienie — pojęcie „zasobu”

Dopiero po zestawieniu wszystkich elementów zauważyłem, że problem nie dotyczy tylko „miejsc na szkolenie”, tylko zarządzania różnymi typami zasobów, które są potrzebne do jego realizacji.

Sala, miejsca, sprzęt nagraniowy – wszystkie te elementy podlegały podobnym regułom: mogły być rezerwowane, blokowane, zwalniane albo wyłączane z użycia (np. w przypadku awarii). Uogólniłem to do jednego pojęcia: **„zasób”**, który ma swój stan i podlega alokacji. Dzięki temu:
- Architektura była rozszerzalna — przyjmowała w łatwy sposób kolejne typy zasobów.
- Trenera mogłem potraktować jako… zasób.
- Pojedyncze źródło prawdy pozwalało zachować spójność i skalowalność.

## Nowy model

Z tego wszystkiego wyniknęła nowa struktura modelu: zamiast osobno zarządzać miejscami, salą i sprzętem, wprowadziliśmy spójny model zasobu z operacjami typu „zarezerwuj”, „zablokuj”, „zwolnij”, „wyłącz z użycia”.

Pojawiła się też kluczowa reguła: **szkolenie może się odbyć tylko wtedy, gdy wszystkie wymagane zasoby są dostępne jednocześnie**. Tego modelu nie było w żadnym źródle – powstał dopiero poprzez uogólnienie i połączenie informacji z różnych rozmów i przypadków oraz z mojego doświadczenia.

---

> **Uwaga** — tak, historia celowo, z powodów dydaktycznych, nie jest spójna i nigdy nie miała być (widziałeś/aś spójną historię architekta w przyrodzie?)