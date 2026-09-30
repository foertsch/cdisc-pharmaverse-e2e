# Read a built ADaM dataset from outputs/adam/ (test_dir() runs from tests/testthat/).
read_adam <- function(name) {
  readRDS(file.path(getOption("e2e_root"), "outputs", "adam", paste0(name, ".rds")))
}

# Drop variable labels so a value comparison is not masked by metadata differences.
strip_labels <- function(data) {
  for (v in names(data)) attr(data[[v]], "label") <- NULL
  data
}
