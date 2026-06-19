# Silicon Sample Benchmark — submission template

This repository **is** a submission to the [Silicon Sample Benchmark](https://janpfander.github.io/llm_predictions_megastudy/):
a multi-team benchmark of AI approaches for predicting the results of a behavioral megastudy on
trust in climate scientists, *before* the human data are revealed.

Clone it (or click **“Use this template”** on GitHub), drop in your predictions, edit two files, run
one check, and release it to Zenodo. The repo ships with a **random example submission** so a fresh
clone is already valid — run `make check` to see the green target state, then replace it with your own.

> The numbers in the example are random placeholders with **no real effects** — for format only.

## Quickstart

1. **Get your own copy** — “Use this template” on GitHub, or `git clone` and re-init.
2. **Build predictions** with any AI-based approach (never any human outcome data). See the survey in
   `survey/` and the variable dictionary in `codebook.csv`.
3. **Produce your file(s):**
   - **Tier 1** (individual-level): run the survey, then clean your raw export →
     `make clean INPUT=your_raw_export.csv` (writes `predictions/<team_id>_T1_primary_v1.csv`).
   - **Tier 2 / 3**: write the cell- or effect-level CSV(s) directly (see `examples/`).
4. **Edit `metadata.json`** (team, tier, models, disclosure class, …) and fill **`registration.md`**
   (the reporting checklist; ★ items must be public).
5. **Check it:** `make check` — fix anything it flags until it passes.
6. **Deposit:** release this repo to Zenodo and email the DOIs + SHA-256 hashes to the core team
   **before the prediction lock (August 30, 2026)**.

No `make`? Use `Rscript scripts/check.R` and `Rscript scripts/clean.R your_raw_export.csv`.
Requires R with `tidyverse`, `jsonlite`, `digest`.

## What you edit vs. what ships

| Path | Role |
|---|---|
| `metadata.json` | **edit** — machine-readable submission metadata |
| `registration.md` | **edit** — GUIDE-LLM-extended reporting checklist |
| `predictions/` | **edit** — your prediction file(s) (ships with the example) |
| `profiles/` | optional — drop your own `profiles.csv` here if you used custom profiles |
| `survey/` | reference — `survey.qsf` (provided on invitation) + `questionnaire.txt` |
| `codebook.csv` | reference — every variable: Qualtrics label → target label, wording, outcome |
| `examples/` | reference — example files for Tiers 1 (raw), 2, and 3 |
| `scripts/` | the engine — do not edit |
| `build/` | maintainer generators — you can ignore |

## Commands

| Command | What it does |
|---|---|
| `make check` | Verifies the required files exist; validates `metadata.json`, the file name, the SHA-256, the per-tier data structure, coverage, and value ranges. Prints **PASS / PASS-WITH-WARNINGS / FAIL**. |
| `make clean INPUT=raw.csv` | Tier-1 only: renames a raw survey export to the target schema and builds the constructed scale variables (`trust_multidimensional`, the `*_mean` composites, reverse-coded funding, `age_band`). |

## Prediction file naming

```
<team_id>_T<tier>_<primary|secondary-k>_v<n>.csv          # Tier 1 and Tier 3
<team_id>_T2_<primary|secondary-k>_v<n>_cells_main.csv    # Tier 2
<team_id>_T2_<primary|secondary-k>_v<n>_cells_moderator.csv
```

`team_id` must match `metadata.json`. Coverage: 16 interventions + control, 13 outcomes. The exact
column schema for each tier is enforced by `make check` (see `examples/` and `scripts/submission_spec.R`).

## The survey

The instrument is provided as `survey/survey.qsf` (import into Qualtrics) and as a plain-text
rendering `survey/questionnaire.txt` (every item as `[label] question` + response values, plus the
17 condition labels and the 16 intervention stimulus texts). Tier-1 runs export raw Qualtrics column
names; `make clean` maps them to the analysis schema documented in `codebook.csv`.

## More

Tiers, scoring, disclosure classes, and the full timeline are described in the
[call for participation](https://janpfander.github.io/llm_predictions_megastudy/). Questions:
see the call's Contact page.
