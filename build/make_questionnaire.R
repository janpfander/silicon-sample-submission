## make_questionnaire.R — write survey/questionnaire.txt (plain-text instrument)
##
## A label-and-values rendering of the survey: every Tier-1 item as
##   [qualtrics_label]  <question text>
##     Values/Slider: <response options>
## plus the 17 condition labels and the 16 intervention stimulus texts.
##
## Reads codebook.csv (run make_codebook.R first) and the stimulus texts from the
## main study repo at build time, then bakes them in so the submission repo is
## self-contained. Run from repo root:  Rscript build/make_questionnaire.R
suppressPackageStartupMessages(library(tidyverse))
source("scripts/submission_spec.R")

cb <- read_csv("codebook.csv", show_col_types = FALSE)

interventions_csv <- path.expand("~/git/llm_predictions_megastudy/data/interventions.csv")
if (!file.exists(interventions_csv))
  stop("Stimulus source not found: ", interventions_csv,
       "\nEdit the path in build/make_questionnaire.R.", call. = FALSE)
stim <- read_csv(interventions_csv, show_col_types = FALSE) |>
  mutate(title = str_trim(title)) |>
  filter(tag != "LLM-chatbot", title != "Value similarity")

## numeric codes for the coded demographic items (from clean_submission.R)
demo_codes <- list(
  gender = "1=Male | 2=Female | 3=Other",
  race   = "1=White / Caucasian | 2=Black / African American | 3=Hispanic / Latino | 4=Asian / Asian American | 5=Other",
  education = "1=Less than high school | 2=High school diploma / GED | 3=Some college or Associate's | 4=Bachelor's | 5=Master's / Professional | 6=Doctorate / Ph.D.",
  income = "1=Less than $30,000 | 2=$30,000–55,999 | 3=$56,000–99,999 | 4=$100,000–167,999 | 5=$168,000 or more",
  party  = "1=Republican | 2=Democrat | 3=Independent | 4=Other"
)

rule <- strrep("=", 70)
out  <- c(
  "SILICON SAMPLE BENCHMARK — SURVEY INSTRUMENT (text rendering)",
  "",
  "Variable labels are in [brackets]. Unless noted, outcome items are 0-100 sliders.",
  "Each respondent sees exactly ONE condition (see CONDITIONS at the end).",
  "This text mirrors survey.qsf; see codebook.csv for the cleaned target names.",
  ""
)

item_block <- function(label, question, values) {
  c(sprintf("[%s]  %s", label, question),
    sprintf("    %s", values), "")
}

# condition
out <- c(out, rule, "CONDITION", rule, "",
         item_block("condition",
                    "Experimental condition assigned to the respondent",
                    paste("Values:", paste(sst$conditions, collapse = " | "))))

# demographics (moderators)
out <- c(out, rule, "DEMOGRAPHICS (moderators)", rule, "")
demo <- cb |> filter(outcome == "moderator", !is.na(qualtrics_label))
for (i in seq_len(nrow(demo))) {
  lab <- demo$qualtrics_label[i]
  vals <- if (!is.null(demo_codes[[lab]])) demo_codes[[lab]] else demo$response_options[i]
  out <- c(out, item_block(lab, demo$question_text[i], paste("Values:", vals)))
}

# outcome items (measured), grouped by their outcome
out <- c(out, rule, "OUTCOME ITEMS", rule, "")
items <- cb |> filter(section == "A. Measured items", outcome != "moderator")
for (oc in unique(items$outcome)) {
  out <- c(out, paste0("# ", oc), "")
  blk <- items |> filter(outcome == oc)
  for (i in seq_len(nrow(blk)))
    out <- c(out, item_block(blk$qualtrics_label[i], blk$question_text[i],
                             paste("Slider:", blk$response_options[i])))
}

# stimulus texts
out <- c(out, rule, "CONDITIONS — stimulus texts (16 interventions; control = neutral filler)", rule, "")
for (i in seq_len(nrow(stim)))
  out <- c(out, paste0("### ", stim$title[i]), "", stim$content[i], "")

dir.create("survey", showWarnings = FALSE)
writeLines(out, "survey/questionnaire.txt")
cat("Wrote survey/questionnaire.txt —", nrow(items), "outcome items,",
    nrow(demo), "demographics,", nrow(stim), "stimulus texts\n")
