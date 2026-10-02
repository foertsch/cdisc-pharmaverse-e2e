# Output: KMG01, Kaplan-Meier plot of time to first dermatologic event,
#         safety population, by actual treatment
# Input:  adtte (PARAMCD TTDE)
# Layout: TLG catalog KMG01 (tern::g_km), with pairwise Cox hazard ratios vs placebo
library(tern)
library(dplyr)

adtte <- readRDS(file.path("outputs", "adam", "adtte.rds"))

arms <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")
anl <- adtte %>%
  filter(PARAMCD == "TTDE", SAFFL == "Y") %>%
  mutate(
    is_event = CNSR == 0,
    TRTA = factor(TRTA, levels = arms)
  )

plot <- g_km(
  df = anl,
  variables = list(tte = "AVAL", is_event = "is_event", arm = "TRTA"),
  xlab = "Days since first dose",
  ylab = "Proportion without dermatologic event",
  ylim = c(0, 1),
  annot_coxph = TRUE,
  control_coxph_pw = control_coxph(ties = "efron", pval_method = "log-rank"),
  # place the annotations in empty space: HR box between the placebo and dosed
  # curves, legend bottom-left below the early drop
  control_annot_coxph = control_coxph_annot(x = 0.72, y = 0.61),
  legend_pos = c(0.13, 0.17),
  title = "Time to First Dermatologic Event, Safety Population",
  footnotes = paste(
    "Censored at end of study (death date for subjects who died).",
    "HR: unadjusted pairwise Cox model vs placebo (Efron ties); p-value: log-rank."
  )
)

ggplot2::ggsave(file.path("outputs", "tlf", "kmg01_ttde.png"), plot, width = 10, height = 7, dpi = 150)
