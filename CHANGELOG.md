# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `adam/adae.R`: ADAE from the admiral 1.5.0 template on this repo's ADSL, plus the dermatologic customized query (`CQ01NAM`, `AOCC01FL`)
- `adam/adtte.R`: ADTTE, time to first dermatologic event (`TTDE`), safety population, censored at end of study
- `R/qc_adae.R`, `R/qc_adtte.R`: independent plain-dplyr derivations of dose at onset, last-dose date, and TTDE
- `tlf/kmg01_ttde.R`: Kaplan-Meier figure (tern `g_km`) with pairwise Cox HRs; copied to `docs/figures/` for the README
- `tlf/coxt02_ttde.R`: multivariable Cox regression table (tern `summarize_coxreg`, Efron ties) and a `cox.zph` proportional-hazards check
- Tests for ADAE, ADTTE, the Cox table (against `survival::coxph`) and the KM analysis population
- `docs/adtte_walkthrough.md`
- CI installs tern, rtables, survival, ggplot2 and uploads the TLFs with the QC reports
- `adam/adsl.R`: ADSL from the admiral 1.5.0 template, output redirected to `outputs/adam/`
- `R/qc.R`: `qc_compare()` (diffdf against a reference build, plain-text report) and `qc_variable_gaps()`
- `run_all.R`: runs each program in its own R process, then QC
- `tests/testthat/test-adsl.R`: structure, derivation-rule and reference-QC tests for ADSL; label test skipped until the metadata stage
- CI: build + tests + QC-report artifact, and a lintr job
- `docs/adsl_walkthrough.md`: variable-by-variable ADSL walkthrough with study counts, the LSTALVDT finding, and exercises
- README: figures and patient-profile stages added to the roadmap
