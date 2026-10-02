# Output: COXT02, multivariable Cox regression of time to first dermatologic event,
#         safety population: actual treatment adjusted for age and sex
# Input:  adtte (PARAMCD TTDE)
# Layout: TLG catalog COXT02 (tern::summarize_coxreg, multivar = TRUE). The univariate
#         COXT01 layout accepts only two arms, this study has three.
# Also:   proportional-hazards check (scaled Schoenfeld residuals, survival::cox.zph)
library(tern)
library(dplyr)

adtte <- readRDS(file.path("outputs", "adam", "adtte.rds"))

arms <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")
anl <- adtte %>%
  filter(PARAMCD == "TTDE", SAFFL == "Y") %>%
  mutate(
    EVENT = 1 - CNSR,
    TRTA = factor(TRTA, levels = arms),
    SEX = factor(SEX)
  ) %>%
  df_explicit_na()

variables <- list(time = "AVAL", event = "EVENT", arm = "TRTA", covariates = c("AGE", "SEX"))

lyt <- basic_table(
  title = "Cox Regression of Time to First Dermatologic Event, Safety Population",
  main_footer = "Model: Surv(AVAL, EVENT) ~ TRTA + AGE + SEX, Efron ties, Wald p-values. Reference arm: Placebo."
) %>%
  summarize_coxreg(variables = variables, control = control_coxreg(ties = "efron"), multivar = TRUE) %>%
  append_topleft("Effect/Covariate Included in the Model")

coxt02 <- build_table(lyt, anl)

saveRDS(coxt02, file.path("outputs", "tlf", "coxt02_ttde.rds"))
rtables::export_as_txt(coxt02, file = file.path("outputs", "tlf", "coxt02_ttde.txt"))

# Proportional-hazards assumption ----
fit <- survival::coxph(survival::Surv(AVAL, EVENT) ~ TRTA + AGE + SEX, data = anl, ties = "efron")
zph <- survival::cox.zph(fit)
writeLines(
  c(
    "Proportional-hazards check: scaled Schoenfeld residuals (survival::cox.zph)",
    "Model: Surv(AVAL, EVENT) ~ TRTA + AGE + SEX",
    "",
    capture.output(print(zph))
  ),
  file.path("outputs", "tlf", "coxt02_ttde_ph_check.txt")
)
saveRDS(zph, file.path("outputs", "tlf", "coxt02_ttde_ph_check.rds"))
