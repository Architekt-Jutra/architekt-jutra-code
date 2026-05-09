# kg-incidents — benchmark NASDE

Benchmark NASDE do zadań diagnostyki incydentów na grafie wiedzy AJ.
Aktualnie jedno zadanie (`cascading-shared-dependency`), dwa warianty:

- `with-mcp` — baseline: tylko MCP catalog/metrics/traces/changes.
- `with-mcp-kg` — dodatkowo MCP `aj-knowledge-graph` (wariant domyślny).

To README jest roboczą instrukcją uruchamiania benchmarku — wykonaj kroki
po kolei.

## 1. Zainstaluj CLI NASDE (jednorazowo)

Wymagany Python 3.13 i [uv](https://docs.astral.sh/uv/).

```bash
uv tool install nasde-toolkit --python 3.13
nasde --version
```

Następnie zainstaluj skille autorskie dla Claude Code:

```bash
nasde install-skills
```

Dokumentacja upstream: [NoesisVision/nasde-toolkit](https://github.com/NoesisVision/nasde-toolkit).

## 2. Wyeksportuj token OAuth Claude Code

Benchmark uruchamia warianty Claude i potrzebuje tokenu uwierzytelniającego.
Najprostsza ścieżka to token OAuth z subskrypcji Claude Code (bez kosztów
per-token) — CLI `claude` zapisał go już podczas logowania, więc wystarczy
go odczytać do zmiennej środowiskowej:

**macOS** (Keychain):

```bash
export CLAUDE_CODE_OAUTH_TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w | python3 -c "import sys,json;print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])")
```

**Linux** (plik z poświadczeniami):

```bash
export CLAUDE_CODE_OAUTH_TOKEN=$(python3 -c "import json;print(json.load(open('$HOME/.claude/.credentials.json'))['claudeAiOauth']['accessToken'])")
```

**Windows** — zobacz [`export_oauth_token.ps1`](https://github.com/NoesisVision/nasde-toolkit/blob/main/scripts/export_oauth_token.ps1)
w repo nasde-toolkit (Windows credential manager API nie sprowadza się do
jednej linijki).

Jeśli wolisz rozliczenie per-token, ustaw `ANTHROPIC_API_KEY` zamiast tego
i pomiń ten krok.

Jest też skill `nasde-benchmark-runner`, który opakowuje to wszystko —
zainstaluj go przez `nasde install-skills` i pozwól Claude Code prowadzić
uruchomienie. Skill jest jeszcze dopracowywany.

## 3. Uruchom benchmark

**Zawsze uruchamiaj z katalogu `tools/kg-incidents/`.** Ścieżki sandbox
files w `variants/*/harbor_config.json` są rozwiązywane względem
**bieżącego katalogu shellu** (a nie katalogu z flagi `-C`), więc
uruchomienie z innego miejsca kończy się błędem
`FileNotFoundError: sandbox_files: source 'variants/.../CLAUDE.md' ...`.

```bash
cd tools/kg-incidents

# Wariant domyślny (with-mcp-kg)
nasde run -C .

# Wybrany wariant
nasde run --variant with-mcp -C .
nasde run --variant with-mcp-kg -C .
```

Aby uruchamiać oba warianty równolegle, przydziel Docker Desktopowi
**co najmniej 8 GB** pamięci (zalecane 16 GB dla zapasu) — każdy
kontener Claude Code zużywa ~2–4 GB. Z odpowiednią ilością pamięci
można puścić je jednocześnie:

```bash
nasde run --variant with-mcp -C . &
nasde run --variant with-mcp-kg -C . &
wait
```

## 4. Przejrzyj wyniki

Artefakty z każdego runa lądują w `jobs/<timestamp>__<wariant>__<suffix>/`
(katalog jest gitignorowany). Najszybciej obejrzeć je w przeglądarce
Harbor — **uruchom z katalogu `tools/kg-incidents/`**:

```bash
cd tools/kg-incidents
nasde harbor view jobs/<timestamp>__<wariant>__<suffix>
```

Surowe pliki, jeśli wolisz grepować bezpośrednio:

```bash
cat jobs/<ts>/result.json | python3 -m json.tool      # podsumowanie joba
cat jobs/<ts>/<trial>/verifier/test-stdout.txt        # wyjście test.sh
cat jobs/<ts>/<trial>/assessment_eval.json            # oceny LLM-as-a-Judge
```

### Porównanie wariantów

Po uruchomieniu więcej niż jednego wariantu poproś agenta o zestawienie
side-by-side, np.:

> Zestaw wyniki ostatnich runów obu wariantów (`with-mcp` i `with-mcp-kg`)
> z katalogu `tools/kg-incidents/jobs/` w tabelkę: reward, sumaryczna
> ocena, oceny per wymiar, czas wykonania, tokeny wejścia/wyjścia.
> Na końcu krótki komentarz — który wariant wypadł lepiej i dlaczego.

Przykładowy wynik (poglądowy — Twoje liczby będą inne):

| Metryka                   | with-mcp (baseline) | with-mcp-kg (KG) |
|---------------------------|:-------------------:|:----------------:|
| Reward (verifier)         | 1.0                 | 1.0              |
| Ocena sumaryczna          | 80 / 100            | **92 / 100**     |
| Root cause accuracy       | 25 / 25             | 25 / 25          |
| Diagnostic path efficiency| 20 / 25             | **25 / 25**      |
| Fix scoping               | 20 / 25             | **25 / 25**      |
| Escalation awareness      | 15 / 25             | **17 / 25**      |
| Czas wykonania            | 5:10                | **4:30**         |
| Tokeny wejście / wyjście  | 360k / 6.0k         | 410k / 6.5k      |

> **Komentarz:** with-mcp-kg trawersował krawędzie własności i
> współdzielonego datastore'a wprost w grafie, więc szybciej postawił
> właściwą hipotezę i ominął dwa fałszywe tropy, na które dał się złapać
> baseline. Nieco więcej tokenów wejściowych (zapytania do grafu), ale
> krótszy czas i czystszy ciąg przyczynowy w raporcie.
