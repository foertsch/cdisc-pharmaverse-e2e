# Runner: from the repo root, after the pipeline has been built.
#   Rscript run_all.R && Rscript tests/testthat.R
library(testthat)

built <- file.path("outputs", c(
  file.path("adam", c("adsl.rds", "adae.rds", "adtte.rds")),
  file.path("tlf", c("kmg01_ttde.png", "coxt02_ttde.rds", "coxt02_ttde_ph_check.rds"))
))
missing <- built[!file.exists(built)]
if (length(missing) > 0) {
  stop("not built: ", paste(missing, collapse = ", "), ". Run `Rscript run_all.R` first", call. = FALSE)
}

for (f in c("qc.R", "qc_adae.R", "qc_adtte.R")) source(file.path("R", f))
options(e2e_root = normalizePath("."))
test_dir(file.path("tests", "testthat"), reporter = "summary", stop_on_failure = TRUE)
