# Independent QC: compare a production dataset against a reference build of the
# same dataset (here pharmaverseadam) by key variables, using diffdf.

#' Compare a production dataset against its reference
#'
#' @param prod Production dataset (built in this repo).
#' @param ref Reference dataset (e.g. `pharmaverseadam::adsl`).
#' @param keys Character vector of key variables that identify one record.
#' @param name Dataset name, used for the report file.
#' @param report_dir Directory for the plain-text diffdf report.
#' @return A list: `name`, `match` (TRUE when diffdf finds no issues),
#'   `report` (path to the written report), `diff` (the diffdf object).
qc_compare <- function(prod, ref, keys, name, report_dir = file.path("outputs", "qc")) {
  stopifnot(is.data.frame(prod), is.data.frame(ref), all(keys %in% names(prod)))
  report <- file.path(report_dir, paste0(name, "_diffdf.txt"))
  diff <- diffdf::diffdf(
    base = ref,
    compare = prod,
    keys = keys,
    suppress_warnings = TRUE,
    file = report
  )
  list(name = name, match = !diffdf::diffdf_has_issues(diff), report = report, diff = diff)
}

#' Variables that differ between production and reference, in either direction
#'
#' @param prod,ref Datasets to compare.
#' @return A list of `only_in_prod` and `only_in_ref` variable names.
qc_variable_gaps <- function(prod, ref) {
  list(
    only_in_prod = setdiff(names(prod), names(ref)),
    only_in_ref = setdiff(names(ref), names(prod))
  )
}
