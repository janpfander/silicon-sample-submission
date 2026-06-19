## make_codebook.R — build materials/codebook.csv
## Item wordings are quoted verbatim from the fielded survey instrument
## (trust_climate_scientists/questionnaire.qmd). Run from repo root.
suppressPackageStartupMessages(library(tidyverse))

s100 <- "Slider 0–100"

## ---- Section A: measured items (raw Qualtrics -> target) -------------------
demo <- tribble(
  ~qualtrics_label, ~target_label, ~question_text, ~response_options, ~outcome,
  "gender",     "gender",     "Gender", "Male / Female / Other", "moderator",
  "year_birth", "year_birth", "Year of birth (used to derive age and age_band)", "Free numeric", "moderator",
  "race",       "race",       "Race / ethnicity", "White / Black / Hispanic / Asian / Other", "moderator",
  "education",  "education",  "Highest level of education completed", "6 categories (less than HS … Ph.D.)", "moderator",
  "income",     "income",     "Household income", "5 brackets (<$30k … ≥$168k)", "moderator",
  "party",      "party",      "Partisan identity", "Republican / Democrat / Independent / Other", "moderator"
)

trust <- tribble(
  ~qualtrics_label, ~target_label, ~question_text, ~response_options,
  "trust_competent_1",   "trust_competence_1",  "How incompetent or competent are most climate scientists?", "0 = Very incompetent … 100 = Very competent",
  "trust_intelligent_1", "trust_competence_2",  "How unintelligent or intelligent are most climate scientists?", "0 = Very unintelligent … 100 = Very intelligent",
  "trust_qualified_1",   "trust_competence_3",  "How unqualified or qualified are most climate scientists?", "0 = Very unqualified … 100 = Very qualified",
  "trust_honest_1",      "trust_integrity_1",   "How dishonest or honest are most climate scientists?", "0 = Very dishonest … 100 = Very honest",
  "trust_ethical_1",     "trust_integrity_2",   "How unethical or ethical are most climate scientists?", "0 = Very unethical … 100 = Very ethical",
  "trust_sincere_1",     "trust_integrity_3",   "How insincere or sincere are most climate scientists?", "0 = Very insincere … 100 = Very sincere",
  "trust_concerned_1",   "trust_benevolence_1", "How unconcerned or concerned are most climate scientists about people’s wellbeing?", "0 = Very unconcerned … 100 = Very concerned",
  "trust_improve_1",     "trust_benevolence_2", "How uneager or eager are most climate scientists to improve others’ lives?", "0 = Very uneager … 100 = Very eager",
  "trust_considerate_1", "trust_benevolence_3", "How inconsiderate or considerate are most climate scientists of others’ interests?", "0 = Very inconsiderate … 100 = Very considerate",
  "trust_feedback_1",    "trust_openness_1",    "How open, if at all, are most climate scientists to feedback?", "0 = Not open at all … 100 = Very open",
  "trust_transparent_1", "trust_openness_2",    "How unwilling or willing are most climate scientists to be transparent?", "0 = Very unwilling … 100 = Very willing",
  "trust_attention_1",   "trust_openness_3",    "How much or how little attention do climate scientists pay to other people's views?", "0 = Very little attention … 100 = A great deal of attention"
) |> mutate(outcome = "trust_multidimensional (item)")

single <- tribble(
  ~qualtrics_label, ~target_label, ~question_text, ~response_options, ~outcome,
  "trust_post_1", "trust_post",    "How much do you trust climate scientists?", "0 = not at all … 100 = very strongly", "trust_post",
  "distrust_1",   "distrust_post", "How much do you distrust climate scientists?", "0 = not at all … 100 = very strongly", "distrust_post",
  "funding_5",    "funding_perceptions", "Do you think the federal government is spending too much, too little or about the right amount of money on climate change research? (reverse-coded in cleaning)", "0 = far too little, 50 = about right, 100 = far too much", "funding_perceptions",
  "belief_post_1","belief_post",   "How accurate do you think this statement is? \"Human activities are causing climate change.\"", "0 = not at all accurate … 100 = extremely accurate", "belief_post",
  "policy_general_1","policy_general","How much do you oppose or support: \"The U.S. government should do more to reduce global warming\"", "0 = Strongly oppose … 100 = Strongly support", "policy_general",
  "donation",     "donation_ams",  "Of the $10 bonus, how much would you like to donate to the American Meteorological Society (AMS)?", "$0 to $10", "donation_ams",
  "newsletter",   "newsletter_signup", "Did you subscribe to the \"Talking Climate\" newsletter on the previous page? (recoded 1/0 in cleaning)", "Yes / No", "newsletter_signup"
)

inst <- tibble(
  qualtrics_label = paste0("inst_trust_", c("epa","nasa","noaa","uni","gov"), "_1"),
  target_label    = paste0("inst_trust_", c("epa","nasa","noaa","universities","federal_gov")),
  question_text   = paste0("How much do you trust the following institutions? — ",
                           c("Environmental Protection Agency (EPA)",
                             "National Aeronautics and Space Administration (NASA)",
                             "National Oceanic and Atmospheric Administration (NOAA)",
                             "Universities and colleges", "Federal government")),
  response_options = "0 = not at all … 100 = very strongly",
  outcome = "inst_trust_mean (item)"
)

policy_role <- tibble(
  qualtrics_label = paste0("policy_", 1:4, "_1"),
  target_label    = paste0("policy_role_", 1:4),
  question_text   = paste0("To what extent do you agree or disagree: — ",
    c("Climate scientists should work closely with policy makers to integrate scientific results into policy-making.",
      "Climate scientists should actively advocate for specific policies.",
      "Climate scientists should communicate their findings to policy makers.",
      "Climate scientists should be more involved in the policy-making process.")),
  response_options = "0 = Strongly disagree … 100 = Strongly agree",
  outcome = "policy_role_mean (item)"
)

concern <- tibble(
  qualtrics_label = paste0("concern_", 1:3, "_1"),
  target_label    = paste0("concern_", 1:3),
  question_text   = c("How concerned are you about climate change?",
                      "How serious a problem is climate change?",
                      "Relative to other issues facing the U.S., how important is climate change?"),
  response_options = c("0 = Not at all … 100 = Extremely", "0 = Not at all … 100 = Extremely",
                       "0 = The least important issue … 100 = The most important issue"),
  outcome = "concern_mean (item)"
)

policy_spec <- tibble(
  qualtrics_label = paste0("policy_specific_", 1:7, "_1"),
  target_label    = paste0("policy_specific_", 1:7),
  question_text   = paste0("How much do you support or oppose: — ",
    c("Raising taxes on fossil fuels (e.g., gas, oil, coal)",
      "Expanding infrastructure for public transportation",
      "Increasing the use of sustainable energy such as wind and solar energy",
      "Protecting forested and land areas",
      "Increasing taxes on carbon-intensive foods (e.g., beef and dairy products)",
      "Investing more in green jobs and businesses",
      "Introducing laws to keep waterways and oceans clean")),
  response_options = "0 = Strongly oppose … 100 = Strongly support",
  outcome = "policy_specific_mean (item)"
)

behavior <- tibble(
  qualtrics_label = paste0("individual_", c("meat","transport","solar","fly","talk","donate"), "_1"),
  target_label    = paste0("behavior_", c("meat","transport","solar","fly","talk","donate")),
  question_text   = paste0("How likely are you to engage in the following in the next 12 months? — ",
    c("Eat less meat",
      "Walk, bicycle, carpool, or take public transportation more often instead of driving by yourself",
      "Install a solar panel", "Go on less personal (non-business) air travel",
      "Talk to friends and family about the importance of climate change",
      "Donate to an environmental NGO")),
  response_options = "0 = Not likely at all … 100 = Extremely likely",
  outcome = "behavior_mean (item)"
)

section_a <- bind_rows(demo, trust, single, inst, policy_role, concern, policy_spec, behavior) |>
  mutate(section = "A. Measured items", .before = 1)

## ---- Section B: variables constructed during cleaning ---------------------
section_b <- tribble(
  ~target_label, ~question_text, ~response_options, ~outcome,
  "age_band", "Age band, cut from age = 2026 − year_birth", "18-29 / 30-44 / 45-59 / 60+", "moderator",
  "funding_perceptions", "Reverse of funding_5: 100 − funding_5 (higher = perceives funding too low / supports more funding)", s100, "funding_perceptions",
  "newsletter_signup", "Recode of newsletter: Yes→1, No→0", "0 / 1", "newsletter_signup",
  "trust_competence",  "Mean of trust_competence_1..3", s100, "trust_multidimensional (subscale)",
  "trust_integrity",   "Mean of trust_integrity_1..3", s100, "trust_multidimensional (subscale)",
  "trust_benevolence", "Mean of trust_benevolence_1..3", s100, "trust_multidimensional (subscale)",
  "trust_openness",    "Mean of trust_openness_1..3", s100, "trust_multidimensional (subscale)",
  "trust_multidimensional", "PRIMARY OUTCOME. Mean of the four trust subscales (competence, integrity, benevolence, openness)", s100, "trust_multidimensional",
  "policy_role_mean",  "Mean of policy_role_1..4", s100, "policy_role_mean",
  "inst_trust_mean",   "Mean of inst_trust_epa/nasa/noaa/universities/federal_gov", s100, "inst_trust_mean",
  "concern_mean",      "Mean of concern_1..3", s100, "concern_mean",
  "policy_specific_mean", "Mean of policy_specific_1..7", s100, "policy_specific_mean",
  "behavior_mean",     "Mean of behavior_meat/transport/solar/fly/talk/donate", s100, "behavior_mean"
) |> mutate(section = "B. Constructed during cleaning", qualtrics_label = NA_character_, .before = 1)

codebook <- bind_rows(section_a, section_b) |>
  select(section, qualtrics_label, target_label, question_text, response_options, outcome)

write_csv(codebook, "codebook.csv")
cat("Wrote codebook.csv —", nrow(codebook), "rows (",
    sum(codebook$section == "A. Measured items"), "measured,",
    sum(codebook$section == "B. Constructed during cleaning"), "constructed)\n")
