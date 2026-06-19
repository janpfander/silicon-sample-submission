## Verification for the collaborator materials: schema parity + validator behaviour.
## Run from repo root:  Rscript build/test_materials.R   (or: make test)
suppressPackageStartupMessages({ library(tidyverse); library(jsonlite); library(digest) })
source("scripts/submission_spec.R")
source("scripts/clean_submission.R")
source("scripts/check_submission.R")

pass <- 0L; fail <- 0L
expect <- function(cond, msg) {
  if (isTRUE(cond)) { pass <<- pass + 1L } else { fail <<- fail + 1L; cat("  FAIL:", msg, "\n") }
}

## ---- 1. Schema parity: clean_submission reproduces clean_common formulas ----
cat("== parity ==\n")
raw <- read_csv("examples/example_raw_T1.csv", show_col_types = FALSE)
cl  <- clean_submission(raw)

# funding reverse-code
expect(all(cl$funding_perceptions == 100 - as.numeric(raw$funding_5)), "funding reverse-code")
# trust composite nesting
sub <- (as.numeric(raw$trust_competent_1) + as.numeric(raw$trust_intelligent_1) + as.numeric(raw$trust_qualified_1)) / 3
expect(all(abs(cl$trust_competence_1 - as.numeric(raw$trust_competent_1)) < 1e-9), "trust item rename")
tm <- rowMeans(cbind(
  rowMeans(cbind(as.numeric(raw$trust_competent_1), as.numeric(raw$trust_intelligent_1), as.numeric(raw$trust_qualified_1))),
  rowMeans(cbind(as.numeric(raw$trust_honest_1), as.numeric(raw$trust_ethical_1), as.numeric(raw$trust_sincere_1))),
  rowMeans(cbind(as.numeric(raw$trust_concerned_1), as.numeric(raw$trust_improve_1), as.numeric(raw$trust_considerate_1))),
  rowMeans(cbind(as.numeric(raw$trust_feedback_1), as.numeric(raw$trust_transparent_1), as.numeric(raw$trust_attention_1)))
))
expect(all(abs(cl$trust_multidimensional - tm) < 1e-9), "trust_multidimensional nesting")
# behavior_mean na.rm
expect(all(!is.na(cl$behavior_mean)), "behavior_mean computed")
# newsletter 1->1, 2->0
expect(all(cl$newsletter_signup == if_else(as.numeric(raw$newsletter) == 1, 1L, 0L)), "newsletter binary map")
# age_band boundaries (4 bins matching clean_common)
ab <- tibble(year_birth = c(2008, 1997, 1982, 1967, 1900),  # ages 18,29,44,59,126
             condition = "control", profile_id = "x") |>
  bind_cols(raw[1, setdiff(names(raw), c("year_birth","condition","profile_id"))])
ab <- clean_submission(ab)
expect(identical(as.character(ab$age_band), c("18-29","18-29","30-44","45-59","60+")), "age_band cut points")
# demographic passthrough (already-labelled input)
rl <- raw; rl$gender <- "Female"
expect(all(clean_submission(rl)$gender == "Female"), "demographic label passthrough")

## ---- 2. Validator on a good submission ----
cat("== validator: good submission ==\n")
td <- file.path(tempdir(), "good"); dir.create(td, showWarnings = FALSE, recursive = TRUE)
fn <- "vienna_T1_primary_v1.csv"
write_csv(read_csv("predictions/example-team_T1_primary_v1.csv", show_col_types = FALSE), file.path(td, fn))
meta <- list(team_id = "vienna", team_name = "WU Behavioral Clones Lab",
             contact = "name@institution.edu", tier = 1L, entry = "primary",
             approach_family = "per-respondent simulation, single model",
             models = list("gpt-4o-mini-2024-07-18"),
             registration_doi = "10.5281/zenodo.0000000",
             disclosure_class = "A", escrow_doi = NA,
             prediction_files = list(list(file = fn,
               sha256 = digest(file = file.path(td, fn), algo = "sha256"))),
             coverage = list(interventions = 16L, outcomes = 13L),
             blinding_attestation = TRUE)
write_json(meta, file.path(td, "metadata.json"), auto_unbox = TRUE, null = "null", pretty = TRUE)
r <- check_submission("metadata.json", dir = td)
expect(!any(r$status == "FAIL"), "good submission has no FAILs")

## ---- 3. Broken variants each trip the right check ----
cat("== validator: broken variants ==\n")
broke <- function(mutate_fn, label) {
  bd <- file.path(tempdir(), paste0("b_", label)); dir.create(bd, showWarnings = FALSE, recursive = TRUE)
  file.copy(file.path(td, fn), file.path(bd, fn), overwrite = TRUE)
  mm <- meta
  list(dir = bd, meta = mm) |> mutate_fn()
}
# (a) bad filename
{ bd <- file.path(tempdir(),"b_name"); dir.create(bd, showWarnings=FALSE, recursive=TRUE)
  badfn <- "vienna_T1_primaryv1.csv"; file.copy(file.path(td,fn), file.path(bd,badfn), overwrite=TRUE)
  mm <- meta; mm$prediction_files <- list(list(file=badfn, sha256=digest(file=file.path(bd,badfn),algo="sha256")))
  write_json(mm, file.path(bd,"metadata.json"), auto_unbox=TRUE, null="null")
  r <- check_submission("metadata.json", dir=bd)
  expect(any(r$status=="FAIL" & grepl("filename", r$check)), "bad filename -> FAIL") }
# (b) missing column
{ bd <- file.path(tempdir(),"b_col"); dir.create(bd, showWarnings=FALSE, recursive=TRUE)
  d <- read_csv(file.path(td,fn), show_col_types=FALSE) |> select(-trust_post)
  write_csv(d, file.path(bd,fn)); mm <- meta
  mm$prediction_files <- list(list(file=fn, sha256=digest(file=file.path(bd,fn),algo="sha256")))
  write_json(mm, file.path(bd,"metadata.json"), auto_unbox=TRUE, null="null")
  r <- check_submission("metadata.json", dir=bd)
  expect(any(r$status=="FAIL" & grepl("required columns", r$check)), "missing column -> FAIL") }
# (c) illegal condition label
{ bd <- file.path(tempdir(),"b_cond"); dir.create(bd, showWarnings=FALSE, recursive=TRUE)
  d <- read_csv(file.path(td,fn), show_col_types=FALSE); d$condition[1] <- "Banana"
  write_csv(d, file.path(bd,fn)); mm <- meta
  mm$prediction_files <- list(list(file=fn, sha256=digest(file=file.path(bd,fn),algo="sha256")))
  write_json(mm, file.path(bd,"metadata.json"), auto_unbox=TRUE, null="null")
  r <- check_submission("metadata.json", dir=bd)
  expect(any(r$status=="FAIL" & grepl("condition labels", r$check)), "bad condition -> FAIL") }
# (d) sha mismatch
{ bd <- file.path(tempdir(),"b_sha"); dir.create(bd, showWarnings=FALSE, recursive=TRUE)
  file.copy(file.path(td,fn), file.path(bd,fn), overwrite=TRUE); mm <- meta
  mm$prediction_files <- list(list(file=fn, sha256=strrep("0",64)))
  write_json(mm, file.path(bd,"metadata.json"), auto_unbox=TRUE, null="null")
  r <- check_submission("metadata.json", dir=bd)
  expect(any(r$status=="FAIL" & grepl("sha256", r$check)), "sha mismatch -> FAIL") }
# (e) out-of-range value
{ bd <- file.path(tempdir(),"b_rng"); dir.create(bd, showWarnings=FALSE, recursive=TRUE)
  d <- read_csv(file.path(td,fn), show_col_types=FALSE); d$trust_post[1] <- 999
  write_csv(d, file.path(bd,fn)); mm <- meta
  mm$prediction_files <- list(list(file=fn, sha256=digest(file=file.path(bd,fn),algo="sha256")))
  write_json(mm, file.path(bd,"metadata.json"), auto_unbox=TRUE, null="null")
  r <- check_submission("metadata.json", dir=bd)
  expect(any(r$status=="WARN" & grepl("trust_post in", r$check)), "out-of-range -> WARN") }
# (f) inverted PI in Tier 3
{ bd <- file.path(tempdir(),"b_pi"); dir.create(bd, showWarnings=FALSE, recursive=TRUE)
  t3 <- read_csv("examples/example_T3.csv", show_col_types=FALSE)
  t3$pi_lower[1] <- t3$pi_upper[1] + 10
  f3 <- "vienna_T3_primary_v1.csv"; write_csv(t3, file.path(bd,f3)); mm <- meta; mm$tier <- 3L
  mm$prediction_files <- list(list(file=f3, sha256=digest(file=file.path(bd,f3),algo="sha256")))
  write_json(mm, file.path(bd,"metadata.json"), auto_unbox=TRUE, null="null")
  r <- check_submission("metadata.json", dir=bd)
  expect(any(r$status=="FAIL" & grepl("pi_lower", r$check)), "inverted PI -> FAIL") }

cat(sprintf("\n==== %d passed, %d failed ====\n", pass, fail))
if (fail > 0) quit(status = 1)
