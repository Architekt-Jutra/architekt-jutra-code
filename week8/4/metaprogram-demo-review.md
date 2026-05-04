# Demo metaprogram-classifier: Architektoniczne review w firmie logistycznej

## Kontekst

Firma logistyczna TransRoute. Zespół pracuje nad nowym modułem optymalizacji tras. Architektoniczne review przed wejściem w implementację. Czworo uczestników.

## Transkrypcja

**Bartek (prowadzący review, staff engineer)**: OK, zaczynamy. Dziś chcę, żebyśmy przeszli przez propozycję modułu optymalizacji tras. Mamy godzinę. Ewa, zacznij — co mamy na stole?

**Ewa (tech lead, autorka propozycji)**: Dobra, w skrócie: obecny algorytm to brute-force na grafie, O(n!) dla n kierowców. Przy 30 kierowcach już się nie mieści w SLA. Propozycja: zamieniamy na heurystykę — nearest-neighbor z 2-opt improvement. Czas spada z minut do sekund. Trade-off: wynik nie jest optymalny, ale w benchmarkach jest w 95% przypadków w granicach 8% optimum.

**Bartek**: Jasne. Przemku, masz pytania?

**Przemek (senior backend, 12 lat doświadczenia)**: Mam. Ewa, ten 2-opt — jak zachowuje się na grafach z ograniczeniami czasowymi? Bo my mamy okna dostawy. Nearest-neighbor nie uwzględnia okien, więc startowa trasa może być tak zła, że 2-opt nie zdąży jej naprawić. Poza tym — skąd te benchmarki? Na jakich danych? Bo jak to były losowe punkty na płaszczyźnie, to nie ma nic wspólnego z naszą topologią Warszawy, gdzie most Łazienkowski potrafi dodać 40 minut.

**Ewa**: Benchmarki z paperu Lin & Kernighan, plus nasze testy na danych z ostatniego kwartału. Mogę Ci wysłać repo z testami.

**Przemek**: Wyślij, sam zobaczę.

**Bartek**: Zanim wejdziemy głębiej w algorytm — Ewa, powiedziałaś, że brute-force nie mieści się w SLA przy 30 kierowcach. A przy 20?

**Ewa**: Przy 20 mieści się, ale na styk. I biznes chce skalować do 50 w Q3.

**Bartek**: Marta, z Twojej strony — jak to wygląda od produktu?

**Marta (product owner)**: Ja się cieszę, że w ogóle to ruszamy, bo klienci narzekają na opóźnienia od pół roku. Dla mnie kluczowe jest to, żeby kierowcy dostawali trasy w ciągu minuty po zalogowaniu, bo teraz czekają 5-7 minut i dzwonią do supportu. Chcę wiedzieć: kiedy będzie gotowe i czy klienci zobaczą różnicę?

**Bartek**: Ewa, timeline?

**Ewa**: Dwa sprinty na algorytm, jeden na integrację z obecnym systemem dispatchu. Wejście na produkcję w 6 tygodni.

**Bartek**: Przemku, widzisz ryzyka techniczne?

**Przemek**: Widzę. Po pierwsze — integracja z dispatcherem. Obecny kontrakt zakłada, że algorytm zwraca posortowaną listę punktów. Nowy algorytm zwraca sekwencję segmentów z estymowanymi czasami. To jest breaking change w API. Czy ktoś policzył, ile klientów integracji to dotknie?

**Ewa**: Trzy integracje. Fleet Manager, Mobile App i raportowanie BI.

**Przemek**: No i każda z nich parsuje odpowiedź inaczej. Fleet Manager pewnie sobie poradzi, ale BI pobiera dane batchowo nocą i nie mam pojęcia, co się stanie, jak format się zmieni. Testowaliśmy to?

**Ewa**: Jeszcze nie.

**Przemek**: No właśnie. I jeszcze jedno — rollback. Jeśli nowy algorytm na produkcji zacznie generować trasy, które są gorsze niż brute-force, bo na przykład topologia Warszawy jest na tyle specyficzna, że heurystyka nie daje tych 92% — jak wracamy? Czy mamy feature flag? Czy będziemy trzymać oba algorytmy równolegle przez jakiś czas?

**Bartek**: Ewa, dobry punkt. Jaki masz plan na rollback?

**Ewa**: Feature flag, standardowo. Oba algorytmy działają, przełączamy per klient.

**Bartek**: OK. Marta, pytanie do Ciebie — czy jest opcja, żeby wejść z tym na dwóch-trzech klientach najpierw, zamiast od razu na wszystkich?

**Marta**: Tak, mamy trzech klientów, którzy zgodzili się na beta. Mogę to zorganizować w tydzień.

**Bartek**: Świetnie. To podsumowuję: algorytm wygląda solidnie, ale mamy trzy otwarte ryzyka — okna czasowe w heurystyce, breaking change w API dispatcha, i brak testów na topologii Warszawy. Ewa, czy do następnego tygodnia możesz przygotować: benchmark na naszych realnych danych z oknami czasowymi, listę zmian w kontrakcie API, i plan migracji dla trzech integracji? Przemku, czy możesz przejrzeć repo z benchmarkami, jak Ewa wyśle? Marta, zorganizuj tych trzech beta klientów. Spotykamy się za tydzień. Pytania?

**Przemek**: Jedno jeszcze. Ten plan migracji dla BI — ja bym chciał to zobaczyć zanim cokolwiek wejdzie na produkcję. Bo jak BI zacznie dostawać corrupted data, to raportowanie kwartalne leci, a to jest ten sam raport, który idzie do zarządu.

**Bartek**: Zanotowane. Ewa, uwzględnij. Coś jeszcze? Nie? To zamykamy.

**Marta**: Dzięki! Wreszcie się rusza.

**Przemek**: *(nic nie mówi)*