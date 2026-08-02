# Changelog

## nof1kit 0.1.0

First release.

- [`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md):
  exact uniform sampling of balanced, run-constrained randomization
  schedules by dynamic programming, reproducible from a required seed.
- [`check_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/check_schedule.md):
  design diagnostics (counts, run lengths, alternations, lag-1
  autocorrelation).
- [`write_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/write_schedule.md):
  JSON export in the format read by the companion mobile collection
  tools.
- [`sim_power()`](https://haomeng797-ship-it.github.io/nof1kit/reference/sim_power.md):
  simulation-based power and false-positive rates under AR(1) errors,
  analysed with and without the dependence, for both randomized and
  user-supplied schedules.
- [`read_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/read_ema.md):
  tidy import of EMA exports (CSV or JSON), with a study-day index
  derived from the start date and an error when a file’s own index
  disagrees with the calendar.
- [`validate_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/validate_ema.md):
  structured integrity checks, including day indices that have drifted
  out of step with the calendar.
- [`compliance()`](https://haomeng797-ship-it.github.io/nof1kit/reference/compliance.md):
  prompt-level compliance against response windows, with off-window
  records reported separately.
- Vignette running the full lifecycle on the bundled 70-day study.
