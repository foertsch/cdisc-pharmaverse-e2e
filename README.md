# cdisc-pharmaverse-e2e

[![CI](https://github.com/foertsch/cdisc-pharmaverse-e2e/actions/workflows/ci.yml/badge.svg)](https://github.com/foertsch/cdisc-pharmaverse-e2e/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-release-blue?logo=r)](https://www.r-project.org/)

A clinical reporting pipeline in R, built end to end on the public CDISC pilot study with the [pharmaverse](https://pharmaverse.org/) packages: SDTM in, ADaM datasets out, then tables, listings and figures (TLFs) and an interactive review app. Every dataset is checked against an independent reference build, the way a QC programmer checks double-programmed output.

This is a learning project. The data is the public CDISC pilot (CDISCPILOT01) as shipped in `pharmaversesdtm`, not real patient data.

## Status

| Stage | Output | Tools | QC |
|---|---|---|---|
| ADaM | ADSL | admiral | values match `pharmaverseadam::adsl` on all 55 shared variables; labels pending |
| ADaM | ADAE, ADLB, ADTTE | admiral | planned |
| Metadata | specs, labels, XPT | metacore, metatools, xportr | planned |
| Tables | demographics, AE summary, lab grade shift | rtables, tern | planned |
| Figures | Kaplan-Meier, subgroup forest plot, mean lab over time, individual patient trajectories | tern | planned |
| Figures | eDISH liver-safety plot (peak ALT vs peak bilirubin, ×ULN) | ggplot2 | planned |
| App | safety + efficacy review, patient profiles | teal, teal.modules.clinical | planned |

## Quick start

```bash
# from the repo root
Rscript run_all.R          # build datasets into outputs/adam/, QC reports into outputs/qc/
Rscript tests/testthat.R   # structure checks, derivation rules, QC against the reference
```

Packages: `admiral`, `pharmaversesdtm`, `pharmaverseadam`, `diffdf`, `dplyr`, `lubridate`, `stringr`, `testthat` (all on CRAN).

## How it is organised

- `adam/`: one program per dataset, in the style of a study programming area. Each runs in its own R process (`run_all.R`), so nothing leaks between programs.
- `R/qc.R`: `qc_compare()` wraps `diffdf` to compare a production dataset against its reference by key variables and writes a plain-text report.
- `tests/testthat/`: three layers per dataset. Structure (one record per subject, all subjects present), derivation rules (for ADSL: treatment dates ordered, `TRTDURD` inclusive, `SAFFL` = Y exactly for treated subjects, screen failures excluded), and QC against the reference.

## Walkthroughs

- [ADSL](docs/adsl_walkthrough.md): every variable, its SDTM source, the rule that builds it, and the counts in this study

## QC findings so far

**ADSL** (306 subjects, 254 treated, 52 screen failures). Values are identical to the reference on every shared variable. Two classes of difference remain, both explained:

1. **Upstream SDTM drift.** `pharmaversesdtm` 1.5.0 added `ARMNRS` and `ACTARMUD` to DM. The reference ADSL (`pharmaverseadam` 1.3.0) was built from an earlier DM without them, so they appear only in this build.
2. **Labels.** The reference labels all 55 variables; this build carries only the 29 labels inherited from SDTM. Labels belong to the dataset specification and are applied in the metadata stage.

## Credits

ADaM programs start from the admiral templates (`admiral::use_ad_template()`, Apache 2.0, F. Hoffmann-La Roche AG and GlaxoSmithKline LLC). Changes from a template are marked `# CHANGED:` in the program.
