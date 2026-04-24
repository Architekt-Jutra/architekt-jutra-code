# Podejście 1: Naiwny prompt bez celu researchowego

**Prompt**: "Przeczytaj tę historię i powiedz mi, co warto wiedzieć o systemie zapisów na szkolenia."

**Źródło**: Wyłącznie historia Sebastiana (bez źródeł zewnętrznych)

---

## Co warto wiedzieć o systemie zapisów na szkolenia

### 1. Główny problem

System zapisów na szkolenia wykazywał rozbieżność między stanem wyświetlanym a stanem rzeczywistym -- system pokazywał dostępność miejsc, podczas gdy fizycznie miejsc już nie było. To prowadziło do chaosu organizacyjnego.

### 2. Źródła informacji, które okazały się kluczowe

Formalna dokumentacja i raporty systemowe nie zawierały pełnego obrazu. Dopiero rozmowy z ludźmi (dział obsługi klienta, organizatorzy, trenerzy) ujawniły nieformalne praktyki, które bezpośrednio wpływały na dostępność miejsc:

- **Handlowcy blokowali miejsca "na telefon"** dla klientów VIP -- te blokady nie były widoczne w systemie jako rezerwacje, ale realnie zajmowały miejsca.
- **Organizatorzy warunkowo zwiększali liczbę miejsc** przy dużym zainteresowaniu -- pojemność szkolenia nie była więc stała, lecz zmienna i zależna od decyzji ludzkiej.

### 3. Ukryta zależność: sprzęt

Szkolenie nie zależy wyłącznie od dostępności sali i wolnych miejsc. Pojawił się dodatkowy wymóg -- **dostępność sprzętu** (np. aparatu do nagrywania). W jednym przypadku szkolenie zostało odwołane z powodu uszkodzonego aparatu, mimo wolnych miejsc i dostępnej sali. Ta zależność nie była wcześniej nigdzie formalnie udokumentowana.

### 4. Model domeny

Na podstawie zebranych informacji powstał model obejmujący następujące elementy:

- **Szkolenie** -- główna jednostka, której dotyczy zapis
- **Sala** -- fizyczna przestrzeń, w której odbywa się szkolenie
- **Miejsce** -- jednostka pojemności w ramach sali/szkolenia
- **Rezerwacja** -- formalne zajęcie miejsca przez uczestnika
- **Blokada** -- nieformalne zajęcie miejsca (np. przez handlowca dla klienta VIP)
- **Sprzęt** -- dodatkowy zasób wymagany do realizacji szkolenia

Rozrysowano diagram zależności między tymi elementami.

### 5. Podejście analityczne

Autor zastosował następujące kroki:
1. Zebranie informacji z dokumentacji, raportów i rozmów z interesariuszami
2. Rozrysowanie procesu zapisu na szkolenie
3. Zaznaczenie hotspotów (miejsc problemowych w procesie)
4. Opisanie scenariuszy w formie user stories
5. Przygotowanie modelu i diagramu zależności

### 6. Kluczowe wnioski

- **Wiedza nieformalna** (blokady VIP, warunkowe zwiększanie miejsc, zależność od sprzętu) jest krytyczna dla zrozumienia problemu i nie wynika z analizy samego systemu.
- **Dostępność miejsca** to nie tylko kwestia "sala + wolne miejsce", ale złożony warunek uwzględniający blokady, warunkowo zmienną pojemność i dostępność sprzętu.
- **System nie odzwierciedlał rzeczywistości** -- brakowało w nim reprezentacji blokad handlowych i zależności sprzętowych, co prowadziło do fałszywego obrazu dostępności.
