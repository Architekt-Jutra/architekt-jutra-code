## Purpose

Analizuje opis domeny pod kątem bezpiecznych generalizacji między konceptami (ambiguity vs generalization) i produkuje distilled context map wspierającą dalsze modelowanie.

## ADDED Requirements

### Requirement: Dwukierunkowa analiza lingwistyczna
Skill SHALL wykryć zarówno niejednoznaczność (jedno słowo, wiele znaczeń w różnych kontekstach) jak i generalizację (wiele słów/konceptów, jedno wspólne zachowanie) w dostarczonym opisie domeny.

#### Scenario: Wejście zawiera ukrytą generalizację
- **WHEN** użytkownik dostarcza opis domeny zawierający kilka pozornie różnych encji, które reagują na te same operacje i reguły
- **THEN** skill zgłasza je jako kandydata na generalizację w sekcji "Generalizations Detected", wskazując wspólne zachowanie jako uzasadnienie

#### Scenario: Wejście nie zawiera ambiguity ani generalizacji
- **WHEN** użytkownik dostarcza opis prostego, jednoznacznego procesu bez powtarzających się wzorców zachowania
- **THEN** skill zgłasza brak fit (zgodnie z sekcją "When NOT to Use") zamiast wymuszać sztuczną generalizację

### Requirement: Tryby pracy
Skill SHALL obsługiwać dwa tryby: pełną dystylację całej domeny oraz sondę pojedynczego konceptu.

#### Scenario: Sonda pojedynczego konceptu
- **WHEN** użytkownik pyta o jeden konkretny koncept zamiast całego opisu domeny
- **THEN** skill ogranicza analizę do tego konceptu i jego bezpośrednich relacji, nie wymaga pełnego opisu domeny

### Requirement: Propozycje dodatkowych konceptów (Analysis C)
Skill SHALL proponować dodatkowe koncepty pasujące do znalezionego wzorca generalizacji, nawet jeśli nie zostały jawnie wymienione w tekście źródłowym, oznaczając je jako spekulatywne i wymagające potwierdzenia użytkownika.

#### Scenario: Analiza wykrywa wzorzec pasujący do niewymienionego konceptu
- **WHEN** wykryta generalizacja obejmuje wzorzec, do którego pasowałby koncept nieobecny w opisie wejściowym
- **THEN** skill proponuje ten koncept w sekcji "Proposed Additional Concepts" i jawnie prosi o potwierdzenie, nie dodaje go automatycznie do finalnej mapy

### Requirement: Granice generalizacji ograniczone do bounded context
Skill SHALL ograniczać proponowane generalizacje do jednego bounded context i nie przenosić ich przez granice kontekstów.

#### Scenario: Dwa koncepty z różnych bounded contexts wyglądają podobnie
- **WHEN** dwa koncepty należą do różnych bounded contexts, mimo powierzchownego podobieństwa nazw lub pól
- **THEN** skill nie łączy ich w jedną generalizację i odnotowuje granicę kontekstu jako powód rozdzielenia
