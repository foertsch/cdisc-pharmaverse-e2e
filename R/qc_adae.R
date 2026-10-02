# Independent QC for the ADAE dose-at-onset variables, written in plain dplyr
# from EX without admiral. The pharmaverseadam reference ADAE (1.3.0) was built
# with the admiral 1.4 template, before admiral 1.5.0 generalized the DOSEON /
# DOSEU derivation and dropped the bundled `ex_single` dataset (NEWS #3101,
# #3060), so for these variables the reference cannot be the QC target.

# EX records with a valid dose: active dose > 0, or placebo at dose 0.
qc_valid_ex <- function(ex) {
  ex |>
    dplyr::filter(EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", EXTRT))) |>
    dplyr::mutate(EXSTDT = as.Date(EXSTDTC), EXENDT = as.Date(EXENDTC)) |>
    dplyr::filter(!is.na(EXSTDT))
}

#' Dose at onset: the dose of the latest EX interval that contains the AE start date
#'
#' @param adae ADAE (needs USUBJID, AESEQ, ASTDT).
#' @param ex SDTM EX.
#' @return USUBJID, AESEQ, DOSEON (NA when the AE started outside every interval).
qc_derive_doseon <- function(adae, ex) {
  on_dose <- adae |>
    dplyr::filter(!is.na(ASTDT)) |>
    dplyr::select(USUBJID, AESEQ, ASTDT) |>
    dplyr::inner_join(qc_valid_ex(ex), by = "USUBJID", relationship = "many-to-many") |>
    dplyr::filter(EXSTDT <= ASTDT, is.na(EXENDT) | ASTDT <= EXENDT) |>
    dplyr::slice_max(EXSTDT, n = 1, with_ties = FALSE, by = c(USUBJID, AESEQ)) |>
    dplyr::select(USUBJID, AESEQ, DOSEON = EXDOSE)
  adae |>
    dplyr::select(USUBJID, AESEQ) |>
    dplyr::left_join(on_dose, by = c("USUBJID", "AESEQ"))
}

#' Date of last dose on or before the AE start, for once-daily (QD) dosing
#'
#' Inside a dosing interval the last dose is the AE day itself; after an interval
#' ends it is the interval end date.
#'
#' @inheritParams qc_derive_doseon
#' @return USUBJID, AESEQ, LDOSEDT.
qc_derive_ldosedt <- function(adae, ex) {
  stopifnot(all(ex$EXDOSFRQ == "QD"))
  last_dose <- adae |>
    dplyr::filter(!is.na(ASTDT)) |>
    dplyr::select(USUBJID, AESEQ, ASTDT) |>
    dplyr::inner_join(
      dplyr::filter(qc_valid_ex(ex), !is.na(EXENDT)),
      by = "USUBJID", relationship = "many-to-many"
    ) |>
    dplyr::filter(EXSTDT <= ASTDT) |>
    dplyr::summarise(LDOSEDT = max(pmin(ASTDT, EXENDT)), .by = c(USUBJID, AESEQ))
  adae |>
    dplyr::select(USUBJID, AESEQ) |>
    dplyr::left_join(last_dose, by = c("USUBJID", "AESEQ"))
}
