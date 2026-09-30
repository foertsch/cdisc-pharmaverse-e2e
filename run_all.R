# Build every dataset in dependency order, then run independent QC.
#   Rscript run_all.R
#
# Each program runs in its own R process, the way separate study programs
# would, so no object leaks from one program into the next. (A fresh
# environment inside one session is not enough: admiral evaluates captured
# expressions in the global environment, so program-local helpers go missing.)

programs <- c(
  file.path("adam", "adsl.R")
)

rscript <- file.path(R.home("bin"), "Rscript")
for (prog in programs) {
  message("Running ", prog)
  status <- system2(rscript, prog)
  if (status != 0) stop(prog, " failed with exit status ", status, call. = FALSE)
}

source(file.path("R", "qc.R"))

qc <- list(
  qc_compare(
    prod = readRDS(file.path("outputs", "adam", "adsl.rds")),
    ref = pharmaverseadam::adsl,
    keys = c("STUDYID", "USUBJID"),
    name = "adsl"
  )
)

for (res in qc) {
  message(sprintf("QC %-6s %s  (report: %s)", res$name, if (res$match) "MATCH" else "DIFFERS", res$report))
}
