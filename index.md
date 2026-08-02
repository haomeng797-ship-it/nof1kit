# nof1kit

Design, monitor, and analyze single-case (N-of-1) intensive longitudinal
studies in R.

Single-case (N-of-1) designs ask whether a treatment works for *this*
person. R is well stocked for analyzing that kind of data (`scan`,
`SingleCaseES`), but everything before the analysis is usually a pile of
one-off scripts: shuffle the conditions until the sequence looks right,
keep the day-to-assignment map in a spreadsheet, eyeball a compliance
number at the end. Mistakes made there don’t crash anything. They sit
quietly in the data and wait for a reviewer to find them.

nof1kit covers that stretch. It draws the randomization schedule, tells
you what the design can actually detect, hands the schedule to the
phone, and checks what comes back.

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

**The randomization is exactly what your preregistration says it is.**
Sequences with balanced counts and short runs are surprisingly hard to
draw fairly: in a balanced 70-day design with `max_run = 2`, fewer than
one shuffle in a million qualifies, so redrawing until one fits would
take forever, and settling for alternating blocks quietly changes the
design without anyone deciding to.
[`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md)
instead counts the valid ways forward from every partial sequence and
samples in proportion, so every admissible schedule has exactly the same
chance of being yours. Put the seed in the preregistration and anyone
can regenerate it.

**Compliance is counted the way you’d want to defend it to a reviewer.**
If a prompt got answered three times, that’s one answered prompt, and if
an entry shows up at midnight for a 3 p.m. prompt, it’s still data, it
just isn’t an on-time answer.
[`compliance()`](https://haomeng797-ship-it.github.io/nof1kit/reference/compliance.md)
counts the scheduled prompts that were answered inside their window and
reports everything else separately, so nothing is thrown away and
nothing is double-counted. On the study that ships with the package,
this reading and the usual records-divided-by-prompts one come out about
three points apart. Neither is wrong; they answer different questions,
and it helps to know which one you’re reporting.

**[`sim_power()`](https://haomeng797-ship-it.github.io/nof1kit/reference/sim_power.md)
tells you when a design would fool you.** Daily measurements from one
person are autocorrelated, and what that does to your inference depends
on the schedule. Each simulated study is analysed twice, with and
without an AR(1) error structure, so you can see the gap for your own
design before committing to it. With the alternating schedules
[`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md)
produces, ignoring the dependence just costs you some power. With a
design that runs control for the first half and treatment for the
second, it costs you the conclusion: at `phi = 0.7`, plain OLS calls a
nonexistent effect significant roughly 40% of the time.

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
