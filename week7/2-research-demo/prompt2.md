## Prompt

> Zgłoszony problem brzmiał: „mamy chaos w zapisach na szkolenia i często brakuje fizycznie miejsc, mimo że system pokazuje dostępność".
> Na początku zacząłem zbierać informacje. Przejrzałem dokumentację, raporty z systemu oraz porozmawiałem z działem obsługi klienta, organizatorami i trenerami. W trakcie rozmów wyszły rzeczy, których nie było w żadnym systemie. Handlowcy blokowali miejsca „na telefon" dla klientów VIP. Organizatorzy czasami zwiększali liczbę miejsc „warunkowo", jeśli widzieli duże zainteresowanie. Dodatkowo pojawił się nowy wątek: szkolenie nie zależało tylko od sali i miejsc, ale też od dostępności sprzętu – np. aparatu do nagrania szkolenia. W jednym przypadku szkolenie zostało odwołane, bo aparat był uszkodzony, mimo że były wolne miejsca i dostępna sala. To była wiedza, której wcześniej nie było nigdzie formalnie zapisana.
> Następnie rozrysowałem proces zapisu na szkolenie, zaznaczyłem hotspoty, opisałem scenariusze w postaci user stories i przygotowałem model: szkolenie, sala, miejsce, rezerwacja, blokada, sprzęt. Stworzyłem też diagram pokazujący zależności między tymi elementami.
> Dopiero po zestawieniu wszystkich elementów zauważyłem, że problem nie dotyczy tylko „miejsc na szkolenie", tylko zarządzania różnymi typami zasobów, które są potrzebne do jego realizacji. Sala, miejsca, sprzęt nagraniowy – wszystkie te elementy podlegały podobnym regułom: mogły być rezerwowane, blokowane, zwalniane albo wyłączane z użycia (np. w przypadku awarii). Uogólniłem to do jednego pojęcia: „zasób", który ma swój stan i podlega alokacji. Dzięki temu architektura była rozszerzalna, przyjmowała w łatwy sposób kolejne typy zasobów. Dzięki temu trenera mogłem potraktować jako … zasób. Pojedyncze źródło prawdy zachować spójność i skalowalność.
> przeanalizuj mi ten problem

---

# Analiza problemu: system zapisów na szkolenia

## Etapy poznawcze

### 1. Zbieranie (Research/Gather)

Informacje z dokumentacji, systemu, rozmów. Kluczowe: wiedza ukryta (tacit knowledge) wyszła dopiero z rozmów — blokady VIP, warunkowe zwiększanie miejsc, zależność od sprzętu. Żadne źródło pojedynczo nie dawało pełnego obrazu.

### 2. Transformacja

Rozrysowanie procesu, hotspoty, user stories, model. Tu nastąpiło przejście od "co ludzie mówią" do "jak to działa naprawdę".

### 3. Synteza (uogólnienie)

Kluczowy moment: sala, miejsca, sprzęt, trener -> **zasób**. To nie było w żadnym źródle. Powstało przez dostrzeżenie wspólnego zachowania: rezerwuj, blokuj, zwolnij, wyłącz.

**Uwaga**: Zasada "uogólniaj zachowanie, nie tożsamość" pochodzi z context-distillera — jednego z 6 pryncypiów destylacji kontekstów.

---

## Klasa problemu

**Resource Contention** — rywalizacja o ograniczone zasoby.

Sygnały:
- Wiele podmiotów walczy o te same zasoby (handlowcy, organizatorzy, system)
- Zasoby mają stany (dostępny, zarezerwowany, zablokowany, wyłączony)
- Kluczowa reguła spójności: szkolenie wymaga jednoczesnej dostępności WSZYSTKICH zasobów
- Nieformalne praktyki (blokady "na telefon") to obejścia braku modelu rywalizacji

---

## Wzorzec uogólnienia — dlaczego działa

Sala, miejsce, sprzęt, trener — różnią się tożsamością, ale zachowują się identycznie:

| Operacja | Sala | Miejsce | Sprzęt | Trener |
|----------|------|---------|--------|--------|
| Zarezerwuj | tak | tak | tak | tak |
| Zablokuj | tak | tak | tak | tak |
| Zwolnij | tak | tak | tak | tak |
| Wyłącz z użycia | tak (remont) | nie | tak (awaria) | tak (L4) |

Nie mówimy "trener = sala". Mówimy: "trener i sala podlegają tym samym regułom alokacji".

---

## Ukryta wiedza — co nie było w systemie i dlaczego

| Ukryta wiedza | Dlaczego nie była w systemie |
|---------------|------------------------------|
| Blokady VIP "na telefon" | Nieformalna praktyka handlowców — system nie przewidywał rezerwacji warunkowych |
| Warunkowe zwiększanie miejsc | Decyzja organizatora poza systemem — brak modelu elastycznej pojemności |
| Zależność od sprzętu | Nikt nie traktował sprzętu jako zasobu szkolenia — był "oczywisty" |
| Trener jako zasób | Kognitywny opór — "trener to nie zasób, to człowiek" |

Każda z tych rzeczy to **decyzja domenowa**, która nie została podjęta jawnie. System milcząco zakładał: "szkolenie = sala + miejsca" i ignorował resztę.

---

## Reguła krytyczna (invariant agregatu)

> Szkolenie może się odbyć tylko wtedy, gdy **wszystkie** wymagane zasoby są dostępne jednocześnie.

Szkolenie jako agregat musi weryfikować spójność zestawu zasobów przy każdej operacji (zapis, blokada, odwołanie). Bez tego masz dokładnie opisany problem: system mówi "są miejsca", ale brakuje kamery.

---

## Wnioski

1. **Problem zgłoszony != problem rzeczywisty** — zgłoszono "chaos w zapisach", a problemem było brak modelu zasobów
2. **Wiedza ukryta wymaga rozmów** — dokumentacja i system nie wystarczą, trzeba rozmawiać z ludźmi
3. **Uogólnienie nie jest oczywiste** — wymaga doświadczenia i umiejętności zobaczenia wspólnego zachowania za różnymi bytami
4. **Brak modelu -> obejścia** — blokady "na telefon" to objaw, nie przyczyna

---

## Użyte koncepty (skille maister)

- **problem-class-classifier** — klasyfikacja do Resource Contention
- **context-distiller** — uogólnienie sala/miejsce/sprzęt/trener -> zasób (zasada: uogólniaj zachowanie, nie tożsamość)
- **aggregate-designer** — szkolenie jako agregat z invariantem jednoczesnej dostępności zasobów