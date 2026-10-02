adae <- read_adam("adae")
ae <- pharmaversesdtm::ae
ex <- pharmaversesdtm::ex
ref <- pharmaverseadam::adae
keys <- c("STUDYID", "USUBJID", "AESEQ")
dose_vars <- c("DOSEON", "DOSEU", "LDOSEDTM")
qc_dir <- file.path(getOption("e2e_root"), "outputs", "qc")

# Structure ----

test_that("ADAE has one record per SDTM AE record", {
  expect_equal(nrow(adae), nrow(ae))
  expect_equal(nrow(dplyr::distinct(adae[keys])), nrow(adae))
})

# Independent QC against the pharmaverseadam reference ----

test_that("values match the reference on every shared variable except dose at onset", {
  common <- setdiff(intersect(names(adae), names(ref)), dose_vars)
  res <- qc_compare(
    strip_labels(adae[common]), strip_labels(ref[common]), keys,
    name = "adae_values", report_dir = qc_dir
  )
  expect_true(res$match, info = paste("see", res$report))
})

test_that("variable differences are the SDTM drift plus the dermatologic query", {
  # ARMNRS, ACTARMUD: new in pharmaversesdtm 1.5.0 DM (see test-adsl.R).
  # BRTHDTC: in this repo's ADSL (and pharmaverseadam::adsl), but the reference
  #   ADAE was built from an ADSL without it.
  # CQ01NAM, AOCC01FL: study-specific dermatologic query added for ADTTE.
  gaps <- qc_variable_gaps(adae, ref)
  expect_setequal(gaps$only_in_prod, c("ARMNRS", "ACTARMUD", "BRTHDTC", "CQ01NAM", "AOCC01FL"))
  expect_length(gaps$only_in_ref, 0)
})

# Dose at onset: independent derivation from EX ----

test_that("DOSEON matches an independent derivation from EX", {
  # as.vector() drops the EXDOSE variable label, which both derivations carry
  expect_equal(as.vector(adae$DOSEON), as.vector(qc_derive_doseon(adae, ex)$DOSEON))
})

test_that("LDOSEDTM matches an independent derivation from EX", {
  expect_equal(as.Date(adae$LDOSEDTM), qc_derive_ldosedt(adae, ex)$LDOSEDT)
})

test_that("the reference DOSEON is outdated for 295 records (admiral 1.4 template)", {
  # pharmaverseadam 1.3.0 predates admiral 1.5.0's generalized DOSEON derivation
  # (NEWS #3101). If this count changes, the reference was rebuilt: re-check.
  ind <- qc_derive_doseon(adae, ex)
  joined <- dplyr::left_join(ind, ref[c("USUBJID", "AESEQ", "DOSEON")], by = c("USUBJID", "AESEQ"),
                             suffix = c(".ind", ".ref"))
  expect_equal(sum(!mapply(identical, joined$DOSEON.ind, joined$DOSEON.ref)), 295)
})

# Dermatologic customized query ----

test_that("AOCC01FL flags one first treatment-emergent dermatologic event per subject", {
  flagged <- adae[adae$AOCC01FL %in% "Y", ]
  expect_true(all(flagged$TRTEMFL == "Y" & flagged$CQ01NAM == "DERMATOLOGIC EVENTS"))
  expect_equal(nrow(flagged), dplyr::n_distinct(flagged$USUBJID))

  derm_teae <- adae[adae$TRTEMFL %in% "Y" & adae$CQ01NAM %in% "DERMATOLOGIC EVENTS", ]
  earliest <- derm_teae |>
    dplyr::arrange(USUBJID, ASTDT, AESEQ) |>
    dplyr::distinct(USUBJID, .keep_all = TRUE)
  expect_setequal(paste(flagged$USUBJID, flagged$AESEQ), paste(earliest$USUBJID, earliest$AESEQ))
})
