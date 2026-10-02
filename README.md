# cdisc-pharmaverse-e2e

[![CI](https://github.com/foertsch/cdisc-pharmaverse-e2e/actions/workflows/ci.yml/badge.svg)](https://github.com/foertsch/cdisc-pharmaverse-e2e/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-release-blue?logo=r)](https://www.r-project.org/)

A clinical reporting pipeline in R, built end to end on the public CDISC pilot study with the [pharmaverse](https://pharmaverse.org/) packages: SDTM in, ADaM datasets out, then tables, listings and figures (TLFs) and an interactive review app. Every dataset is checked against an independent reference build, the way a QC programmer checks double-programmed output.

This is a learning project. The data is the public CDISC pilot (CDISCPILOT01, xanomeline transdermal patch in mild to moderate Alzheimer's disease) as shipped in `pharmaversesdtm`, not real patient data.

<p align="center">
  <img src="docs/figures/kmg01_ttde.png" alt="Kaplan-Meier plot of time to first dermatologic event by actual treatment, safety population" width="850">
</p>
<p align="center"><em>KMG01: time to first dermatologic event, safety population (tern::g_km).</em></p>

## Status

| Stage | Output | Tools | QC |
|---|---|---|---|
| ADaM | ADSL | admiral | values match `pharmaverseadam::adsl` on all 55 shared variables; labels pending |
| ADaM | ADAE (+ dermatologic customized query) | admiral | values match `pharmaverseadam::adae` except dose at onset, where an independent derivation from EX confirms this build (see findings) |
| ADaM | ADTTE: time to first dermatologic event | admiral `derive_param_tte()` | independent double programming in plain dplyr: identical for all 254 subjects |
| Figure | Kaplan-Meier (KMG01) | tern | analysis population checked against ADSL |
| Table | multivariable Cox regression (COXT02) + proportional-hazards check | tern, survival | hazard ratios and CIs match an independent `survival::coxph()` fit to 1e-8 |
| ADaM | ADLB | admiral | planned |
| Metadata | specs, labels, XPT | metacore, metatools, xportr | planned |
| Tables | demographics, AE summary, lab grade shift | rtables, tern | planned |
| Figures | subgroup forest plot, mean lab over time, individual patient trajectories | tern | planned |
| Figure | eDISH liver-safety plot (peak ALT vs peak bilirubin, ×ULN) | ggplot2 | planned |
| App | safety + efficacy review, patient profiles | teal, teal.modules.clinical | planned |

## Quick start

```bash
# from the repo root
Rscript run_all.R          # datasets into outputs/adam/, TLFs into outputs/tlf/, QC reports into outputs/qc/
Rscript tests/testthat.R   # structure checks, derivation rules, QC against references and independent derivations
```

Packages: `admiral`, `pharmaversesdtm`, `pharmaverseadam`, `tern`, `rtables`, `survival`, `ggplot2`, `diffdf`, `dplyr`, `lubridate`, `stringr`, `testthat` (all on CRAN).

## How it is organised

- `adam/`, `tlf/`: one program per dataset or output, in the style of a study programming area. Each runs in its own R process (`run_all.R`), so nothing leaks between programs.
- `R/qc.R`: `qc_compare()` wraps `diffdf` to compare a dataset against its reference by key variables and writes a plain-text report.
- `R/qc_adae.R`, `R/qc_adtte.R`: independent QC derivations in plain dplyr, written from the specification without admiral, for variables where no trustworthy reference exists.
- `tests/testthat/`: per dataset, structure (record counts, keys), derivation rules, and QC against the reference or the independent derivation. Every known difference from a reference is asserted and explained in a comment, so a new difference fails the build.

## Walkthroughs

- [ADSL](docs/adsl_walkthrough.md): every variable, its SDTM source, the rule that builds it, and the counts in this study
- [ADTTE and survival analysis](docs/adtte_walkthrough.md): the dermatologic-event endpoint, censoring, Kaplan-Meier, Cox model and proportional-hazards check

## QC findings so far

**ADSL** (306 subjects, 254 treated, 52 screen failures). Values are identical to the reference on every shared variable. Two explained differences:

1. **Upstream SDTM drift.** `pharmaversesdtm` 1.5.0 added `ARMNRS` and `ACTARMUD` to DM. The reference ADSL (`pharmaverseadam` 1.3.0) was built from an earlier DM without them.
2. **Labels.** The reference labels all 55 variables; this build carries only the 29 labels inherited from SDTM. Labels belong to the dataset specification and are applied in the metadata stage.

**ADAE** (1,191 records). Values are identical on every shared variable except `DOSEON`, `DOSEU` and `LDOSEDTM`. The reference has `DOSEON` missing for 295 records where the subject was on drug at onset (e.g. subject 01-701-1146: an AE on 2013-06-10, inside an 81 mg dosing interval running 2013-06-04 to 2013-06-26). admiral 1.5.0 generalized the dose-at-onset derivation and dropped the bundled `ex_single` dataset (NEWS #3101, #3060); `pharmaverseadam` 1.3.0 was built before that. An independent derivation from EX in plain dplyr agrees with this build on all 1,191 records for both `DOSEON` and the last-dose date. A reference build is a check, not ground truth.

**ADTTE / Cox.** `tern::summarize_coxreg()` defaults to exact ties while `survival::coxph()` and the KM annotation default to Efron, so a table and figure left at defaults disagree. Both are set to Efron explicitly.

## Credits

ADSL and ADAE programs start from the admiral templates (`admiral::use_ad_template()`, Apache 2.0, F. Hoffmann-La Roche AG and GlaxoSmithKline LLC). Changes from a template are marked `# CHANGED:`. The TTDE endpoint definition follows the CDISC pilot as specified in [R Consortium submissions pilot 3](https://github.com/RConsortium/submissions-pilot3-adam); no code is copied from it.
