# nof1kit

Design, monitor, and analyze single-case (N-of-1) intensive longitudinal
studies in R.

Single-case (N-of-1) designs ask whether a treatment works for *this*
person.

R is well stocked for analyzing that kind of data (`scan`,
`SingleCaseES`). Everything before the analysis is usually a pile of
one-off scripts: shuffle the conditions until the sequence looks right,
keep the day-to-assignment map in a spreadsheet, eyeball a compliance
number at the end.

Mistakes made there don’t crash anything. They sit in the data and wait
for a reviewer to find them.

nof1kit covers that stretch. It draws the schedule, tells you what the
design can actually detect, hands it to the phone, and checks what comes
back.

## What it does

``` r

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

A few things it does differently, and why:

#### The randomization is exactly what your preregistration says it is

Balanced counts with short runs turn out to be hard to draw fairly. In a
70-day design with `max_run = 2`, fewer than one shuffle in a million
qualifies, so people redraw until something fits or settle for
alternating blocks, and both quietly change the design without anyone
deciding to.
[`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md)
counts the valid ways forward from each partial sequence and samples in
proportion, so every admissible schedule has the same chance of being
yours. Put the seed in the preregistration and anyone can bring it back.

#### Compliance, counted the way you’d defend it to a reviewer

A prompt answered three times is one answered prompt, and an entry that
shows up at midnight for a 3 p.m. prompt is data but not an on-time
answer.
[`compliance()`](https://haomeng797-ship-it.github.io/nof1kit/reference/compliance.md)
counts the prompts answered inside their window and reports the rest
separately, so nothing is thrown away and nothing is counted twice. On
the study bundled here, that reading and the usual records-over-prompts
one land about three points apart. Neither is wrong; they answer
different questions, and it helps to know which one you are reporting.

#### `sim_power()` tells you when a design would fool you

Daily measurements from one person are autocorrelated, and what that
does to your inference depends on the schedule you picked. Each
simulated study is analysed twice, with and without an AR(1) error
structure, so you can see the gap before committing to anything. With
the alternating schedules
[`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md)
produces, ignoring the dependence costs you some power; with a design
that runs control for the first half and treatment for the second, it
costs you the conclusion. At `phi = 0.7`, plain OLS calls a nonexistent
effect significant about 40% of the time.

## Scope

nof1kit stays out of the analysis itself. Once the data are read,
checked, and the compliance is known, `lme4`, `nlme`, and `brms` already
do that job better than a reimplementation here ever would. The missing
piece was getting to that point cleanly, and that is the piece this
package tries to be.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("haomeng797-ship-it/nof1kit")
```

## Getting started

``` r

vignette("nof1kit")
```

The vignette runs the whole lifecycle on data from a real 70-day study,
included in the package.

## Related

- [melatonin-ema-logger](https://github.com/haomeng797-ship-it/melatonin-ema-logger):
  iOS collection tools that read the schedules this package writes
- [n-of-1-melatonin-study](https://github.com/haomeng797-ship-it/n-of-1-melatonin-study):
  the study whose data ship with this package

## Contributing

See
[CONTRIBUTING.md](https://haomeng797-ship-it.github.io/nof1kit/CONTRIBUTING.md).
Bug reports and feature requests go to the [issue
tracker](https://github.com/haomeng797-ship-it/nof1kit/issues).

## License

MIT. See
[LICENSE.md](https://haomeng797-ship-it.github.io/nof1kit/LICENSE.md).
