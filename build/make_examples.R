## ---------------------------------------------------------------------------
## make_examples.R — generate the example submissions shipped in materials/
##
## Produces random-placeholder example files for all three tiers, all in the
## canonical schema (17 conditions, target variable names). The Tier-1 example
## is built by running a RAW (Qualtrics-named, numeric-coded) simulated export
## through materials/clean_submission.R — so this script also serves as the
## end-to-end parity test for the cleaning pipeline.
##
## Run from the repository root:  Rscript R/materials/make_examples.R
## The values are random with NO real effects; for format illustration only.
## ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(tidyverse))
source("scripts/submission_spec.R")
source("scripts/clean_submission.R")

set.seed(20260619)
n_per <- 60L                                   # rows per condition (example size)

raw <- tibble(condition = rep(sst$conditions, each = n_per)) |>
  mutate(profile_id = sprintf("p%05d", row_number()))

r_slider <- function(n) round(pmin(pmax(rnorm(n, 50, 28), 0), 100))
N <- nrow(raw)

trust_raw <- c("trust_competent_1", "trust_intelligent_1", "trust_qualified_1",
               "trust_honest_1", "trust_ethical_1", "trust_sincere_1",
               "trust_concerned_1", "trust_improve_1", "trust_considerate_1",
               "trust_feedback_1", "trust_transparent_1", "trust_attention_1")
slider_raw <- c(trust_raw, "trust_post_1", "distrust_1", "funding_5",
                paste0("policy_", 1:4, "_1"),
                "inst_trust_epa_1", "inst_trust_nasa_1", "inst_trust_noaa_1",
                "inst_trust_uni_1", "inst_trust_gov_1",
                "belief_post_1", paste0("concern_", 1:3, "_1"), "policy_general_1",
                paste0("policy_specific_", 1:7, "_1"),
                paste0("individual_", c("meat", "transport", "solar", "fly",
                                        "talk", "donate"), "_1"))

raw <- raw |>
  mutate(
    gender     = sample(1:3, N, replace = TRUE),
    year_birth = sample(1934:2006, N, replace = TRUE),
    race       = sample(1:5, N, replace = TRUE),
    education  = sample(1:6, N, replace = TRUE),
    income     = sample(1:5, N, replace = TRUE),
    party      = sample(1:4, N, replace = TRUE),
    donation   = round(runif(N, 0, 10), 1),
    newsletter = sample(c(1L, 2L), N, replace = TRUE, prob = c(0.2, 0.8))
  )
for (v in slider_raw) raw[[v]] <- r_slider(N)

dir.create("predictions", showWarnings = FALSE)
dir.create("survey", showWarnings = FALSE)
## An example raw Qualtrics export — the INPUT to `make clean`, not a submission.
raw |> write_csv("survey/example_raw_export.csv")

## --- Tier 1: clean the raw export into the target schema -------------------
## One example submission per tier ships in predictions/, named example_* .
t1 <- clean_submission(raw)
write_csv(t1, "predictions/example_T1_primary_v1.csv")

## --- Tier 2: cell-level statistics -----------------------------------------
long <- t1 |>
  mutate(across(all_of(sst$outcomes), as.numeric)) |>
  pivot_longer(all_of(sst$outcomes), names_to = "outcome", values_to = "value")

summ <- function(df, ...) {
  df |>
    group_by(...) |>
    summarise(
      mean  = mean(value, na.rm = TRUE),
      sd    = if (first(outcome) == "newsletter_signup") NA_real_ else sd(value, na.rm = TRUE),
      n_eff = sum(!is.na(value)),
      .groups = "drop"
    )
}

t2_main <- long |> summ(condition, outcome) |>
  mutate(across(c(mean, sd), ~ round(.x, 3))) |>
  select(all_of(sst$tier2_main_cols))
write_csv(t2_main, "predictions/example_T2_primary_v1_cells_main.csv")

t2_mod <- imap_dfr(sst$moderators, function(levels, m) {
  long |>
    rename(moderator_level = all_of(m)) |>
    mutate(moderator = m) |>
    summ(condition, moderator, moderator_level, outcome)
}) |>
  mutate(across(c(mean, sd), ~ round(.x, 3))) |>
  select(all_of(sst$tier2_mod_cols))
write_csv(t2_mod, "predictions/example_T2_primary_v1_cells_moderator.csv")

## --- Tier 3: effect-level (ATE vs control + a 95% prediction interval) ------
ctrl <- t2_main |> filter(condition == "control") |>
  transmute(outcome, m_ctrl = mean, sd_ctrl = sd, n_ctrl = n_eff)

t3 <- t2_main |>
  filter(condition != "control") |>
  left_join(ctrl, by = "outcome") |>
  mutate(
    ate = mean - m_ctrl,
    # variance picked per-row first, then a single sqrt (no negative-branch NaNs)
    se  = sqrt(if_else(
      outcome == "newsletter_signup",
      mean * (1 - mean) / n_eff + m_ctrl * (1 - m_ctrl) / n_ctrl,
      sd^2 / n_eff + sd_ctrl^2 / n_ctrl
    )),
    pi_lower = round(ate - 1.96 * se, 3),
    pi_upper = round(ate + 1.96 * se, 3),
    ate      = round(ate, 3)
  ) |>
  select(all_of(sst$tier3_cols))
write_csv(t3, "predictions/example_T3_primary_v1.csv")

cat("Examples written:\n",
    " survey/example_raw_export.csv — raw input for `make clean`\n",
    " predictions/example_T1_primary_v1.csv —", nrow(t1), "rows,", nlevels(t1$condition), "conditions\n",
    " predictions/example_T2_primary_v1_cells_main.csv —", nrow(t2_main), "rows\n",
    " predictions/example_T2_primary_v1_cells_moderator.csv —", nrow(t2_mod), "rows\n",
    " predictions/example_T3_primary_v1.csv —", nrow(t3), "rows\n")
