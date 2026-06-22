#!/usr/bin/env Rscript
## Entry point: clean a raw Tier-1 survey export into the target schema.
## With no argument it reads the single CSV you placed in raw_data_deposit/.
##   make clean                          |     Rscript scripts/clean.R
##   make clean INPUT=path/to/raw.csv    |     Rscript scripts/clean.R path/to/raw.csv [output.csv]
.a    <- commandArgs(FALSE)
.dir  <- dirname(normalizePath(sub("^--file=", "", .a[grep("^--file=", .a)])))
.root <- dirname(.dir)
suppressPackageStartupMessages(library(jsonlite))
source(file.path(.dir, "lib", "clean_lib.R"))

args <- commandArgs(trailingOnly = TRUE)

## Resolve the input: an explicit path, or auto-discover it in raw_data_deposit/.
input <- if (length(args) >= 1) args[1] else {
  deposit <- file.path(.root, "raw_data_deposit")
  csvs <- list.files(deposit, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  if (length(csvs) == 0L)
    stop("No CSV found in raw_data_deposit/. Put your raw Qualtrics export there and re-run, ",
         "or pass a path: Rscript scripts/clean.R <raw_export.csv>", call. = FALSE)
  if (length(csvs) > 1L)
    stop("Multiple CSVs in raw_data_deposit/:\n  ", paste(basename(csvs), collapse = "\n  "),
         "\nLeave only one, or name it explicitly: make clean INPUT=raw_data_deposit/<file>.csv",
         call. = FALSE)
  csvs[1]
}

out <- if (length(args) >= 2) args[2] else {
  mp <- file.path(.root, "metadata.json")
  team <- if (file.exists(mp)) tryCatch(fromJSON(mp)$team_id, error = function(e) NULL) else NULL
  file.path(.root, "predictions",
            if (is.null(team)) "cleaned_T1.csv" else sprintf("%s_T1_primary_v1.csv", team))
}
clean_submission(input, out)
