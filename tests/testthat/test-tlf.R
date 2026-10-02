tlf_path <- function(file) file.path(getOption("e2e_root"), "outputs", "tlf", file)

arms <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")
adsl <- read_adam("adsl")
anl <- read_adam("adtte") |>
  dplyr::filter(PARAMCD == "TTDE") |>
  dplyr::mutate(EVENT = 1 - CNSR, TRTA = factor(TRTA, levels = arms), SEX = factor(SEX))

# KMG01 ----

test_that("the Kaplan-Meier figure is written", {
  expect_gt(file.size(tlf_path("kmg01_ttde.png")), 0)
})

test_that("the analysis population is the safety population by actual arm", {
  saf <- adsl[adsl$SAFFL == "Y", ]
  expect_equal(
    as.vector(table(anl$TRTA)),
    as.vector(table(factor(saf$TRT01A, levels = arms)))
  )
})

# COXT02 ----

test_that("Cox table hazard ratios and CIs match an independent survival::coxph fit", {
  res <- rtables::as_result_df(readRDS(tlf_path("coxt02_ttde.rds")))
  arm_rows <- match(arms[-1], res$row_name)
  cell <- function(col, n) vapply(res[[col]][arm_rows], function(x) as.numeric(unlist(x)), numeric(n))
  hr_table <- cell("STUDYID", 1)
  ci_table <- t(cell("STUDYID._[[2]]_.", 2))

  fit <- survival::coxph(survival::Surv(AVAL, EVENT) ~ TRTA + AGE + SEX, data = anl, ties = "efron")
  terms <- paste0("TRTA", arms[-1])
  expect_equal(unname(hr_table), unname(exp(stats::coef(fit))[terms]), tolerance = 1e-8)
  expect_equal(unname(ci_table), unname(exp(stats::confint(fit))[terms, ]), tolerance = 1e-8)
})

test_that("the proportional-hazards assumption is not rejected", {
  zph <- readRDS(tlf_path("coxt02_ttde_ph_check.rds"))
  expect_gt(zph$table["GLOBAL", "p"], 0.05)
})
