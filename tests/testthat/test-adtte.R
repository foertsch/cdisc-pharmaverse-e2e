adtte <- read_adam("adtte")
adsl <- read_adam("adsl")
adae <- read_adam("adae")
qc_dir <- file.path(getOption("e2e_root"), "outputs", "qc")

# Structure ----

test_that("ADTTE has one TTDE record per safety-population subject", {
  expect_equal(unique(adtte$PARAMCD), "TTDE")
  expect_setequal(adtte$USUBJID, adsl$USUBJID[adsl$SAFFL == "Y"])
  expect_equal(nrow(adtte), dplyr::n_distinct(adtte$USUBJID))
})

# Derivation rules ----

test_that("AVAL counts days from first dose, with the first-dose day as day 1", {
  expect_true(all(adtte$STARTDT == adtte$TRTSDT))
  expect_true(all(adtte$ADT >= adtte$STARTDT))
  expect_equal(adtte$AVAL, as.numeric(adtte$ADT - adtte$STARTDT) + 1)
})

test_that("events come from ADAE and censored records from ADSL", {
  expect_setequal(unique(adtte$CNSR), c(0L, 1L))
  expect_true(all(adtte$SRCDOM[adtte$CNSR == 0] == "ADAE"))
  expect_true(all(adtte$SRCDOM[adtte$CNSR == 1] == "ADSL"))
})

test_that("no event is dated after the subject's end of study", {
  eos <- adsl |>
    dplyr::mutate(EOSCDT = dplyr::if_else(!is.na(DTHDT), DTHDT, EOSDT)) |>
    dplyr::select(USUBJID, EOSCDT)
  events <- dplyr::inner_join(adtte[adtte$CNSR == 0, c("USUBJID", "ADT")], eos, by = "USUBJID")
  expect_true(all(events$ADT <= events$EOSCDT))
})

# Independent double programming ----

test_that("production ADTTE matches the independent derivation", {
  prod <- strip_labels(adtte[c("USUBJID", "STARTDT", "ADT", "AVAL", "CNSR", "EVNTDESC")])
  ind <- strip_labels(qc_derive_ttde(adsl, adae))
  res <- qc_compare(prod, ind, keys = "USUBJID", name = "adtte_double_programming", report_dir = qc_dir)
  expect_true(res$match, info = paste("see", res$report))
})
