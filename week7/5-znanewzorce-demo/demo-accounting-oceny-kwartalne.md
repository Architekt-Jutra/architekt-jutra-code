# Demo: Accounting Archetype Mapper na wymaganiach, które NIE pasują

## Wymagania wejściowe (prompt)

> Co kwartał manager ocenia pracownika w 5 kategoriach na skali 1–5. Oceny z czterech kwartałów składają się na ocenę roczną. Pracownik widzi historię ocen. HR generuje raport porównawczy zespołu. Manager może zmienić ocenę do 14 dni po wystawieniu, potem jest zamrożona. Średnia ocen wpływa na bonus roczny.

---

## Fit Test

Pytanie: *„Czy mogę zapytać 'ile oceny ma pracownik X?' i dostać sensowną liczbę z historią transakcji?"*

**Nie.** To pytanie nie ma sensu. Pracownik nie „ma" ilości oceny, która się kumuluje albo jest zużywana. Naturalne pytanie brzmi: „Jaka jest ocena pracownika X w Q3 w kategorii Y?" — a to jest pytanie o stan/pomiar, nie o saldo.

| Sygnał | Obecny? |
|--------|---------|
| użytkownik zarabia / wydaje / gromadzi N jednostek | Nie — pracownik nie zarabia ani nie wydaje punktów oceny |
| saldo nie może spaść poniżej zera | Nie — nie ma salda; oceny są na stałej skali 1–5 |
| grant / refund / expire / transfer | Nie — ocen nie przyznaje się, nie zwraca, nie przenosi |
| ticket przechodzi ze stanu do stanu | Bliżej — ocena ma stany: edytowalna → zamrożona |
| dokument ma wersje | Tak — ocena może być zmieniona w ciągu 14 dni, potem jest zamrożona |

**Kluczowe powody odrzucenia:**

- **Oceny się nie kumulują** — 4 w Q1 i 3 w Q2 nie oznacza, że masz „7 oceny". To dwa oddzielne pomiary.
- **Oceny nie są zużywane** — użycie oceny do obliczenia bonusu nie „wydaje" jej ani nie zmniejsza salda.
- **Brak historii transakcji w sensie księgowym** — „historia ocen" to historia wersji snapshotów, nie ledger debetów i kredytów.
- **Średnia to agregacja pomiarów**, nie saldo wyliczone z wpisów. Uśredniasz snapshoty, nie sumujesz transakcje.
- **14-dniowe okno edycji to maszyna stanów** (edytowalna → zamrożona), nie mechanizm odwracalności. Po 14 dniach ocena jest zablokowana — nie odwrócona wpisem korygującym, po prostu niemodyfikowalna.

## Wynik: ❌ Nie pasuje

Archetyp księgowy wymaga zasobu, który się kumuluje, jest zużywany i może być odpytany jako saldo z historią transakcji. Ta domena to **wersjonowany pomiar okresowy (periodic snapshot)**, ponieważ:

- Naturalne pytanie to „jaka jest ocena pracownika X?" — nie „ile oceny ma pracownik X?"
- Oceny to dyskretne pomiary na stałej skali (1–5), nie wartość przepływająca między kontami
- Ocena roczna to agregacja (średnia) niezależnych pomiarów, nie saldo z wpisów debet/kredyt
- Edycja w ciągu 14 dni + zamrożenie to cykl życia dokumentu (draft → frozen), nie mechanizm odwracalności
- Nic nie jest zużywane, transferowane ani nie wygasa jako wartość

**Skill zatrzymał się tutaj. Nie próbuje mapować. Stop.**

---
