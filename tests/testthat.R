# Runner: from the repo root, after the pipeline has been built.
#   Rscript run_all.R && Rscript tests/testthat.R
library(testthat)

if (!file.exists(file.path("outputs", "adam", "adsl.rds"))) {
  stop("outputs/adam/adsl.rds not found: run `Rscript run_all.R` first", call. = FALSE)
}

source(file.path("R", "qc.R"))
options(e2e_root = normalizePath("."))
test_dir(file.path("tests", "testthat"), reporter = "summary", stop_on_failure = TRUE)
