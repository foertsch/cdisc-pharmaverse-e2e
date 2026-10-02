# Build every dataset and output in dependency order, then run independent QC.
#   Rscript run_all.R
#
# Each program runs in its own R process, the way separate study programs
# would, so no object leaks from one program into the next. (A fresh
# environment inside one session is not enough: admiral evaluates captured
# expressions in the global environment, so program-local helpers go missing.)

programs <- c(
  file.path("adam", "adsl.R"),
  file.path("adam", "adae.R"),
  file.path("adam", "adtte.R"),
  file.path("tlf", "kmg01_ttde.R"),
  file.path("tlf", "coxt02_ttde.R")
)

for (dir in file.path("outputs", c("adam", "qc", "tlf"))) dir.create(dir, showWarnings = FALSE, recursive = TRUE)

rscript <- file.path(R.home("bin"), "Rscript")
for (prog in programs) {
  message("Running ", prog)
  status <- system2(rscript, prog)
  if (status != 0) stop(prog, " failed with exit status ", status, call. = FALSE)
}

# Figure shown in the README
file.copy(
  file.path("outputs", "tlf", "kmg01_ttde.png"), file.path("docs", "figures", "kmg01_ttde.png"),
  overwrite = TRUE
)

# Full-dataset comparison reports against the pharmaverseadam reference. The
# tests classify every difference; these reports are for reading.
source(file.path("R", "qc.R"))

qc <- list(
  qc_compare(
    prod = readRDS(file.path("outputs", "adam", "adsl.rds")),
    ref = pharmaverseadam::adsl,
    keys = c("STUDYID", "USUBJID"),
    name = "adsl"
  ),
  qc_compare(
    prod = readRDS(file.path("outputs", "adam", "adae.rds")),
    ref = pharmaverseadam::adae,
    keys = c("STUDYID", "USUBJID", "AESEQ"),
    name = "adae"
  )
)

for (res in qc) {
  message(sprintf("QC %-6s %s  (report: %s)", res$name, if (res$match) "MATCH" else "DIFFERS", res$report))
}
message("Differences are classified in tests/testthat/: run Rscript tests/testthat.R")
