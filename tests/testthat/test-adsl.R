adsl <- read_adam("adsl")
dm <- pharmaversesdtm::dm
ref <- pharmaverseadam::adsl
keys <- c("STUDYID", "USUBJID")

# Structure ----

test_that("ADSL has one record per subject and every DM subject", {
  expect_equal(nrow(adsl), dplyr::n_distinct(adsl$USUBJID))
  expect_setequal(adsl$USUBJID, dm$USUBJID)
})

test_that("ADSL carries the core subject-level variables", {
  core <- c(
    keys, "SUBJID", "SITEID", "AGE", "SEX", "RACE", "ARM", "TRT01P", "TRT01A",
    "TRTSDT", "TRTEDT", "TRTDURD", "SAFFL", "EOSSTT", "AGEGR1", "RACEGR1"
  )
  expect_true(all(core %in% names(adsl)))
})

# Derivation rules ----

test_that("treatment dates are ordered and duration is inclusive of both days", {
  treated <- adsl[!is.na(adsl$TRTSDT) & !is.na(adsl$TRTEDT), ]
  expect_true(all(treated$TRTSDT <= treated$TRTEDT))
  expect_equal(treated$TRTDURD, as.numeric(treated$TRTEDT - treated$TRTSDT) + 1)
})

test_that("SAFFL is Y exactly for subjects with a treatment start date", {
  expect_setequal(unique(adsl$SAFFL), c("Y", "N"))
  expect_equal(adsl$SAFFL == "Y", !is.na(adsl$TRTSDT))
})

test_that("screen failures are not in the safety population and have no end-of-study status", {
  sf <- adsl[adsl$ARM == "Screen Failure", ]
  expect_gt(nrow(sf), 0)
  expect_true(all(sf$SAFFL == "N"))
  expect_true(all(is.na(sf$EOSSTT)))
})

# Independent QC against the pharmaverseadam reference ----

test_that("values match the reference build on every shared variable", {
  common <- intersect(names(adsl), names(ref))
  res <- qc_compare(
    strip_labels(adsl[common]), strip_labels(ref[common]), keys,
    name = "adsl_values", report_dir = file.path(getOption("e2e_root"), "outputs", "qc")
  )
  expect_true(res$match, info = paste("see", res$report))
})

test_that("variable differences are only the known upstream SDTM drift", {
  # pharmaversesdtm 1.5.0 DM added ARMNRS and ACTARMUD; the reference ADSL
  # (pharmaverseadam 1.3.0) was built from an earlier DM without them.
  gaps <- qc_variable_gaps(adsl, ref)
  expect_setequal(gaps$only_in_prod, c("ARMNRS", "ACTARMUD"))
  expect_length(gaps$only_in_ref, 0)
})

test_that("variable labels match the reference", {
  skip("labels come from the dataset spec: applied in Weekend 2 (metacore/metatools)")
})
