# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `adam/adsl.R`: ADSL from the admiral 1.5.0 template, output redirected to `outputs/adam/`
- `R/qc.R`: `qc_compare()` (diffdf against a reference build, plain-text report) and `qc_variable_gaps()`
- `run_all.R`: runs each program in its own R process, then QC
- `tests/testthat/test-adsl.R`: structure, derivation-rule and reference-QC tests for ADSL; label test skipped until the metadata stage
- CI: build + tests + QC-report artifact, and a lintr job
