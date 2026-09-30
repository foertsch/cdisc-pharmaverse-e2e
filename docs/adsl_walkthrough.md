# ADSL walkthrough

What every variable in `adam/adsl.R` is, where it comes from, and what rule builds it, with the numbers from this study (CDISC pilot, `pharmaversesdtm` 1.5.0, admiral 1.5.0). Read it next to the program.

## What ADSL is

The Subject-Level Analysis Dataset: one row per subject, 306 here. Every other ADaM dataset merges ADSL variables in (treatment, population flags, dates), so an error here shows up in every table. It holds four kinds of content:

- **Demographics** carried from DM
- **Treatment variables**: planned and actual arm, first and last dose
- **Milestones**: disposition, randomization, death, last known alive
- **Population flags and groupings** used to filter and stratify every analysis

## Inputs

| SDTM domain | What it holds | Used for |
|---|---|---|
| DM | one row per subject: demographics, arms, reference dates | the backbone of ADSL |
| EX | dosing records, one per exposure interval | treatment dates, SAFFL |
| DS | disposition events and protocol milestones | end of study, screen failure, randomization |
| AE | adverse events | cause of death, last known alive |
| LB | lab results | last known alive |

`convert_blanks_to_na()` runs first on every domain. SAS stores missing text as blanks, which arrive in R as `""`; R code expects `NA`. Skip it and every `is.na()` check below silently misses the blanks.

## 1. Carried from DM unchanged (27 variables)

`STUDYID`, `USUBJID`, `SUBJID`, `SITEID`, the SDTM reference dates (`RFSTDTC`, `RFENDTC`, `RFXSTDTC`, `RFXENDTC`, `RFICDTC`, `RFPENDTC`), `DTHDTC`, `DTHFL`, `BRTHDTC`, `AGE`, `AGEU`, `SEX`, `RACE`, `ETHNIC`, `ARMCD`, `ARM`, `ACTARMCD`, `ACTARM`, `COUNTRY`, `DMDTC`, `DMDY`, plus `ARMNRS` and `ACTARMUD` (new in this `pharmaversesdtm` release, see README). `DOMAIN` is dropped at the end (`DOMAIN = NULL`) because it is an SDTM-only variable.

## 2. Treatment

| Variable | Rule | This study |
|---|---|---|
| `TRT01P` | planned treatment = `DM.ARM` | |
| `TRT01A` | actual treatment = `DM.ACTARM` | **12 subjects planned High Dose received Low Dose** |
| `TRTSDTM`, `TRTSTMF` | first EX record (ordered by start datetime, then `EXSEQ`) with a valid dose and a start date. Time missing in `EXSTDTC`, so it is imputed to 00:00:00 and the flag records it (`H` = imputed from the hour down) | 254 subjects, all `TRTSTMF = "H"` |
| `TRTEDTM`, `TRTETMF` | last EX record by end datetime, same dose filter. End time imputed to 23:59:59 (`time_imputation = "last"`) | 252 subjects |
| `TRTSDT`, `TRTEDT` | dates from the two datetimes | |
| `TRTDURD` | `TRTEDT - TRTSDT + 1` (both days count) | 1 to 212 days, median 132; missing for 54 |

**Valid dose** means `EXDOSE > 0`, or `EXDOSE == 0` with `PLACEBO` in `EXTRT`. The placebo clause matters: all 226 placebo records have dose 0. Without it, 86 placebo subjects would have no treatment dates and drop out of the safety population.

**Planned vs actual.** Safety analyses usually use actual treatment (`TRT01A`: what the subject received). Efficacy analyses on the randomized population use planned treatment (`TRT01P`: what they were randomized to). The 12 High → Low subjects land in different columns of a safety table and an efficacy table.

**Why 54 missing durations and not 52.** 52 screen failures were never dosed. Two treated subjects (`01-705-1018` placebo, `01-705-1382` high dose) have a single EX record with no `EXENDTC`, so they have a start date and no end date.

## 3. Disposition and milestones (from DS)

| Variable | Rule | This study |
|---|---|---|
| `SCRFDT` | `DSSTDTC` of the disposition event `SCREEN FAILURE` | 52 |
| `EOSDT` | `DSSTDTC` of the disposition event that is not a screen failure | 254 |
| `EOSSTT` | `COMPLETED` → COMPLETED; `SCREEN FAILURE` → missing; any other reason → DISCONTINUED; no disposition record at all → ONGOING | 110 completed, 144 discontinued (92 of them for adverse events), 52 missing, 0 ongoing |
| `FRVDT` | `DSSTDTC` of the other event `FINAL RETRIEVAL VISIT` | 36 |
| `RANDDT` | `DSSTDTC` of the protocol milestone `RANDOMIZED` | 254 |

`derive_vars_merged()` is the workhorse here: look up one record per subject in another dataset (`filter_add` picks which records, `order` + `mode` pick first or last if several remain), then copy the chosen values across.

## 4. Death

| Variable | Rule | This study |
|---|---|---|
| `DTHDT`, `DTHDTF` | `DM.DTHDTC` as a date. A partial date may be imputed down to the month (`highest_imputation = "M"`, to the first day or month); `DTHDTF` flags the imputation | 3 deaths, all complete dates, so no flag |
| `DTHADY` | study day of death: `DTHDT - TRTSDT + 1` | 61, 175, 12 |
| `LDDTHELD` | days from last dose to death: `DTHDT - TRTEDT`, no +1 | 2, 0, 1 |
| `DTHCAUS`, `DTHDOM` | first match of: an AE with `AEOUT = "FATAL"` (cause = `AEDECOD`), then a DS death record whose `DSTERM` contains "DEATH DUE TO". AE wins because it is listed first | all 3 from AE: sudden death, completed suicide, myocardial infarction |
| `DTHCGR1` | AE → ADVERSE EVENT; progressive disease or relapse → PROGRESSIVE DISEASE; else OTHER | 3 × ADVERSE EVENT |
| `LDDTHGR1`, `DTH30FL`, `DTHA30FL` | death ≤ 30 or > 30 days after the **last** dose | all 3 ≤ 30 |
| `DTHB30FL` | death ≤ 30 days after the **first** dose | 1 (`01-710-1083`, 11 days) |

Two day-count conventions sit side by side here. A study day has no day 0 (the first dose is day 1), so `DTHADY` adds one. Elapsed days since last dose do not (`add_one = FALSE`). A subject who dies on the day of their last dose has `LDDTHELD = 0`.

`derive_vars_extreme_event()` is the second workhorse: build candidate records from several sources, then keep the first or last per subject. The order of `events` sets the priority on ties.

## 5. Last known alive (`LSTALVDT`)

The latest of AE start dates, AE end dates, lab dates (partial dates imputed to the first of the month or year) and `TRTEDT`. 122 subjects have follow-up data after their last dose, so `LSTALVDT > TRTEDT`. Missing for the 52 screen failures (no dated AE or LB records).

**Finding.** For the two subjects without `TRTEDT`, every remaining source date falls before their first dose:

| USUBJID | TRTSDT | LSTALVDT |
|---|---|---|
| 01-705-1018 | 2013-07-05 | 2013-06-30 |
| 01-705-1382 | 2013-05-13 | 2013-05-09 |

A subject was alive on the day they took their first dose, so a last-known-alive date before `TRTSDT` is impossible. The template's example sources do not include exposure start dates. The reference ADSL has the same values, because it was built from the same template. Double programming from a shared template cannot catch a shared blind spot, which is why an independent QC programmer works from the specification alone.

## 6. Safety population (`SAFFL`)

Y if the subject has any EX record with a valid dose (same definition as above), else N. 254 Y, 52 N. In this study `SAFFL = "Y"` exactly when `TRTSDT` is present; the tests check that.

## 7. Groupings

| Variable | Rule | This study |
|---|---|---|
| `AGEGR1` | < 18, 18–64, > 64 | 42 aged 18–64, 264 over 64 (the trial is xanomeline in mild to moderate Alzheimer's disease, per the TS domain) |
| `RACEGR1` | White vs Non-white | 273 / 33 |
| `REGION1` | USA or Canada → `"NA"`, else RoW | all 306 USA |

**Watch `REGION1`.** `"NA"` is the text string for North America, and `is.na()` on it is FALSE. Round-trip the dataset through a CSV and it turns into a real missing value: `read.csv()` and `readr::read_csv()` both read the string `NA` as missing by default. A reviewer would ask to rename it.

## Exercises

1. **Fix `LSTALVDT`.** Add an EX start-date event to the `derive_vars_extreme_event()` call. Add a test that `LSTALVDT >= TRTSDT` wherever both exist. The reference comparison will then show two differing values: record them as a justified deviation in the README.
2. **Derive `RANDFL`.** Randomized-population flag from `RANDDT`. Check that it is Y for 254 subjects and that no screen failure has it.
3. **Test planned vs actual.** Assert that exactly 12 subjects have `TRT01P != TRT01A`, and that all 12 are High Dose → Low Dose. Then find in DM or EX what explains it.
4. **Read the ADaMIG section on ADSL** (CDISC, free with a cdiscID) and list which required ADSL variables this build does not have yet.
