# nof1kit

<!-- badges: start -->
[![R-CMD-check](https://github.com/haomeng797-ship-it/nof1kit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/haomeng797-ship-it/nof1kit/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/nof1kit)](https://CRAN.R-project.org/package=nof1kit)
<!-- badges: end -->

Single-case (N-of-1) designs ask whether a treatment works for *this* person,
rather than for the average of two hundred people who are not them.

Running one is a slow commitment. You randomize a condition across days, answer
a few prompts every day for two or three months, and only at the end find out
whether the design could have detected anything at all. Almost none of that is
tooled. The schedule gets shuffled in a script until it looks acceptable, the
day-to-condition map lives in a spreadsheet, compliance is a number someone
works out afterwards.

Mistakes made in those steps don't throw errors. They sit in the data and wait.

While writing this package's vignette, `validate_ema()` turned up an
inconsistency in my own 70-day dataset that I had never noticed: one study day
covering two calendar dates, quietly shifting the index for the last month of the study. Every routine
check had passed. The values were in range, no timestamps were duplicated,
nothing was missing, and every day number sat inside 1 to 70. The only way to
see it was to hold the index up against the timestamps, which nothing had ever
done.

nof1kit is the tooling for the part of a single-case study that comes before the
analysis: drawing the schedule, working out what the design can detect, handing
it to whatever collects the data, and checking what comes back.

## What it does

```r
# Design: balanced, run-constrained, reproducible from the preregistered seed
sched <- design_schedule(n_days = 70, max_run = 2, seed = 20260218)
check_schedule(sched)                    # counts, runs, alternations, autocorrelation
write_schedule(sched, "schedule.json")   # straight onto the collection device

# Plan: how much power does this design actually have
sim_power(n_days = 70, effect = 0.5, phi = 0.4)

# Data back
ema <- read_ema("export.csv", start_date = "2026-02-18")
validate_ema(ema, ranges = list(mood = c(0, 100)), n_days = 70)
compliance(ema, start_date = "2026-02-18", n_days = 70,
           times = c("09:00", "15:00", "21:00"))
```

#### Before you spend three months on it

An N-of-1 study is a two- or three-month commitment, so two things are worth
settling before day one.

Is the randomization actually random? Balanced sequences with short runs are
rarer than they look: in a 70-day design with `max_run = 2`, fewer than one
shuffle in a million qualifies. Most scripts deal with this by redrawing until
something fits, or by alternating blocks. Either way the sampling distribution
changes, usually without being reported. `design_schedule()` samples the constrained set exactly, so every
admissible schedule is equally likely, and the seed in your preregistration is
enough to bring the whole thing back.

And can the study detect anything? `sim_power()` simulates it both ways, with
and without the day-to-day correlation that daily measures always have. How much
that correlation costs you depends on the schedule. An alternating one costs a
little power; a first-half, second-half design can hand you a result that isn't
there. At a lag-1 correlation of 0.7, plain OLS flags a nonexistent effect about
40% of the time.

#### While it runs

`write_schedule()` writes the schedule as plain JSON, and the companion phone
tools read that file directly. The instrument that collects the data never
touches the randomization, which is one less way to unblind a study by
accident.

The other thing you find out while it runs is whether the prompts are actually
being answered, and that turns out to depend on what you count. A prompt
answered three times is still one answered prompt, and an entry that arrives at
midnight for a 3 p.m. prompt is data, but not an on-time answer. `compliance()`
counts prompts answered inside their window and keeps the rest visible off to
the side. On the study bundled with the package, this number and the usual
records-divided-by-prompts number sit about three points apart. Neither is
wrong. It just helps to know which one you're reporting.

#### When the data come back

`read_ema()` reads whatever the phone exported and returns a data frame with
real timestamps and a study-day index. `validate_ema()` then goes looking for
the quiet problems: values out of range, repeated timestamps, missing fields,
and a day index that no longer matches the calendar.

That last check is the one that caught the problem in my own data, and it caught
it months after the fact. Run while the study is still going, the same check
flags the problem on the day it appears, while it is still a five-minute fix
rather than a month of mislabelled records.

## Scope

The package is small on purpose. It covers the steps that are easy to get almost
right, where nothing breaks at the time and the cost turns up months later.

nof1kit stays out of the analysis itself. Once the data are read, checked, and
the compliance is known, `lme4`, `nlme`, and `brms` already do that job better
than a reimplementation here ever would. The missing piece was getting to that
point cleanly, and that is the piece this package tries to be.

## Installation

```r
# install.packages("remotes")
remotes::install_github("haomeng797-ship-it/nof1kit")
```

## Getting started

```r
vignette("nof1kit")
```

The vignette runs the whole lifecycle on data from a real 70-day study, included
in the package.

## Related

- [melatonin-ema-logger](https://github.com/haomeng797-ship-it/melatonin-ema-logger):
  iOS collection tools that read the schedules this package writes
- [n-of-1-melatonin-study](https://github.com/haomeng797-ship-it/n-of-1-melatonin-study):
  the study whose data ship with this package

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and feature requests go to
the [issue tracker](https://github.com/haomeng797-ship-it/nof1kit/issues).

## License

MIT. See [LICENSE.md](LICENSE.md).
