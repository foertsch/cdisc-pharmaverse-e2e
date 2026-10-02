# Independent QC program for ADTTE (PARAMCD TTDE), written from the endpoint
# specification in plain dplyr, without admiral. There is no reference ADTTE for
# this study in pharmaverseadam, so this second implementation is the reference.
#
# Scope: re-derives the dermatologic customized query, the first-occurrence
# selection, the censoring rule and AVAL. It takes TRTEMFL and ASTDT from ADAE,
# which is QC'd separately against pharmaverseadam::adae.

#' Derive TTDE independently
#'
#' @param adsl ADSL (needs SAFFL, TRTSDT, DTHDT, EOSDT).
#' @param adae ADAE (needs TRTEMFL, ASTDT, AESEQ, AEDECOD, AEBODSYS).
#' @return One row per safety subject: USUBJID, STARTDT, ADT, AVAL, CNSR, EVNTDESC.
qc_derive_ttde <- function(adsl, adae) {
  derm <- grepl("APPLICATION|DERMATITIS|ERYTHEMA|BLISTER", adae$AEDECOD) |
    (adae$AEBODSYS %in% "SKIN AND SUBCUTANEOUS TISSUE DISORDERS" &
      !grepl("COLD SWEAT|HYPERHIDROSIS|ALOPECIA", adae$AEDECOD))

  first_event <- adae[derm & adae$TRTEMFL %in% "Y" & !is.na(adae$ASTDT), ] |>
    dplyr::arrange(USUBJID, ASTDT, AESEQ) |>
    dplyr::distinct(USUBJID, .keep_all = TRUE) |>
    dplyr::select(USUBJID, EVENTDT = ASTDT)

  adsl[adsl$SAFFL %in% "Y", ] |>
    dplyr::left_join(first_event, by = "USUBJID") |>
    dplyr::mutate(
      CENSDT = dplyr::if_else(!is.na(DTHDT), DTHDT, EOSDT),
      CNSR = dplyr::if_else(is.na(EVENTDT), 1L, 0L),
      ADT = dplyr::if_else(CNSR == 0L, EVENTDT, CENSDT),
      STARTDT = TRTSDT,
      AVAL = as.numeric(ADT - STARTDT) + 1,
      EVNTDESC = dplyr::if_else(CNSR == 0L, "DERMATOLOGIC EVENT", "END OF STUDY")
    ) |>
    dplyr::select(USUBJID, STARTDT, ADT, AVAL, CNSR, EVNTDESC) |>
    dplyr::arrange(USUBJID)
}
