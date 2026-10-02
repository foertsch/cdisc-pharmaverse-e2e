# Name: ADTTE
#
# Label: AE Time to First Dermatologic Event Analysis Dataset
#
# Input: adsl, adae
#
# Endpoint (CDISC pilot, as specified in R Consortium submissions pilot 3):
#   PARAMCD TTDE, time from first dose to the first treatment-emergent
#   dermatologic event (ADAE.AOCC01FL = "Y"), safety population only.
#   Subjects without an event are censored at end of study: the death date for
#   subjects who died, otherwise the end-of-study disposition date (EOSDT).
#   AVAL in days, counting the day of first dose as day 1.
library(admiral)
library(dplyr)

adsl <- readRDS(file.path("outputs", "adam", "adsl.rds"))
adae <- readRDS(file.path("outputs", "adam", "adae.rds"))

# Censoring date: death takes precedence over the disposition date ----
adsl_saf <- adsl %>%
  filter(SAFFL == "Y") %>%
  mutate(EOSCDT = if_else(!is.na(DTHDT), DTHDT, EOSDT))

# Event and censoring sources ----
derm_event <- event_source(
  dataset_name = "adae",
  filter = AOCC01FL == "Y",
  date = ASTDT,
  set_values_to = exprs(
    EVNTDESC = "DERMATOLOGIC EVENT",
    SRCDOM = "ADAE",
    SRCVAR = "ASTDT",
    SRCSEQ = AESEQ
  )
)

eos_censor <- censor_source(
  dataset_name = "adsl",
  date = EOSCDT,
  set_values_to = exprs(
    EVNTDESC = "END OF STUDY",
    CNSDTDSC = "Death date, else end-of-study disposition date",
    SRCDOM = "ADSL",
    SRCVAR = "EOSCDT"
  )
)

# Derivation ----
adtte <- derive_param_tte(
  dataset_adsl = adsl_saf,
  start_date = TRTSDT,
  event_conditions = list(derm_event),
  censor_conditions = list(eos_censor),
  source_datasets = list(adsl = adsl_saf, adae = adae),
  set_values_to = exprs(PARAMCD = "TTDE", PARAM = "Time to First Dermatologic Event (days)")
) %>%
  derive_vars_duration(
    new_var = AVAL,
    start_date = STARTDT,
    end_date = ADT
  ) %>%
  mutate(AVALU = "DAYS") %>%
  derive_vars_merged(
    dataset_add = adsl_saf,
    new_vars = exprs(
      TRTP = TRT01P, TRTA = TRT01A, AGE, AGEGR1, SEX, RACE, RACEGR1, SAFFL, TRTSDT, TRTEDT
    ),
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  arrange(USUBJID, PARAMCD)

saveRDS(adtte, file.path("outputs", "adam", "adtte.rds"))
