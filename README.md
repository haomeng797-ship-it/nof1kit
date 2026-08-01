# nof1kit

Design, monitor, and analyze single-case (N-of-1) intensive longitudinal
studies in R.

`nof1kit` covers the parts of an N-of-1 study that existing single-case
analysis packages leave to hand-rolled scripts: generating preregistrable
randomization schedules under run-length constraints, exporting them to a
mobile data-collection layer, validating incoming EMA records, and
monitoring compliance.

## What works today

```r
# a balanced 70-day two-condition schedule, no more than 2 identical
# days in a row, reproducible from the preregistered seed
sched <- design_schedule(n_days = 70, max_run = 2, seed = 20260218)
check_schedule(sched)          # counts, runs, alternations, lag-1 autocor
write_schedule(sched, "schedule.json")   # drops into the iOS Shortcuts logger
```

Schedules are drawn *uniformly over all valid sequences* by dynamic
programming, not by rejection or blocking, so the randomization is exactly
what the preregistration says it is.

The JSON output is the format consumed by the
[iOS Shortcuts EMA logger](https://github.com/haomeng797-ship-it/melatonin-ema-logger)
used to run a 70-day randomized N-of-1 study at 92.9% compliance
([companion repo](https://github.com/haomeng797-ship-it/n-of-1-melatonin-study)).

## Roadmap

- `validate_ema()`: range, duplicate, and missingness checks on raw records
- `compliance_report()`: one-command Quarto monitoring report
- analysis wrappers: AR(1), mixed models, TOST equivalence
- a vignette reproducing the melatonin study end to end

## Installation

Not yet on CRAN. Install the development version:

```r
# install.packages("remotes")
remotes::install_github("haomeng797-ship-it/nof1kit")
```
