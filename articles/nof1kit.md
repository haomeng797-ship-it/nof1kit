# Running an N-of-1 study end to end

``` r

library(nof1kit)
```

A single-case (N-of-1) experiment has a lifecycle: design a
randomization schedule, work out what it can detect, collect data
against it, check what came back, and analyze it. Packages for
single-case analysis are plentiful. The earlier stages are usually
hand-rolled, which is where the errors live.

This vignette walks the whole lifecycle on a real study: 70 days, three
prompts a day, melatonin randomized nightly. The data shipped with the
package are the ones actually collected.

## 1. Design

[`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md)
produces a balanced sequence with a cap on how many identical days may
run consecutively. Long runs of the same condition confound the
intervention with time, so a run-length constraint is standard practice
in N-of-1 designs. The seed is required, not optional: a preregistered
schedule has to be reproducible from what is written in the
preregistration.

``` r

sched <- design_schedule(n_days = 70, max_run = 2, seed = 20260218)
head(sched, 12)
#>    day condition
#> 1    1         1
#> 2    2         0
#> 3    3         0
#> 4    4         1
#> 5    5         1
#> 6    6         0
#> 7    7         1
#> 8    8         1
#> 9    9         0
#> 10  10         0
#> 11  11         1
#> 12  12         0
```

The sampling is exact rather than by rejection. For a balanced 70-day
design with `max_run = 2`, fewer than one permutation in a million
satisfies the constraint, so drawing until one fits is not workable.
Instead the number of valid completions from each intermediate state is
counted by dynamic programming, and the sequence is drawn day by day in
proportion to those counts. The result is a uniform draw over all valid
schedules: no admissible sequence is more likely than any other. That is
a stronger property than blocked randomization, which restricts the
sample space in ways that are rarely stated.

[`check_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/check_schedule.md)
reports what a reviewer, or a preregistration reader, would want to see.

``` r

check_schedule(sched)
#> $counts
#> cond
#>  0  1 
#> 35 35 
#> 
#> $max_run
#> [1] 2
#> 
#> $run_table
#> 
#>  1  2 
#> 30 20 
#> 
#> $alternations
#> [1] 49
#> 
#> $lag1_autocor
#> [1] -0.4201681
```

Balanced counts, no run longer than two, and a negative lag-1
autocorrelation, which is what the run cap buys: the sequence alternates
more than chance would.

## 2. How much can this design actually detect

Power formulas assume independent observations. Daily measurements from
one person are not: today’s mood is correlated with yesterday’s, so each
new day carries less information than a genuinely new observation would.

[`sim_power()`](https://haomeng797-ship-it.github.io/nof1kit/reference/sim_power.md)
simulates studies of the given length and analyses each one twice, with
and without an AR(1) error structure.

``` r

sim_power(n_days = 70, effect = 0.5, phi = 0.4, n_sims = 200, seed = 2)
#> Power over 70 days, effect 0.50 SD, phi 0.40, alpha 0.05
#>   AR(1) model : 0.745
#>   OLS         : 0.565
#>   Ignoring the dependence is conservative here by 0.180.
```

Ignoring the dependence costs power here, but it does not create false
positives. That is a property of the schedule, not a general fact.
Compare the same autocorrelation under a design that runs control for
the first half and treatment for the second:

``` r

sim_power(n_days = 70, effect = 0, phi = 0.7, n_sims = 200, seed = 4,
          schedule = rep(c(0, 1), each = 35))
#> False positive rate over 70 days, effect 0.00 SD, phi 0.70, alpha 0.05
#>   AR(1) model : 0.105
#>   OLS         : 0.395
#>   Ignoring the dependence is anti-conservative here by 0.290.
```

With no effect at all, ordinary least squares rejects the null in
roughly four tests out of ten, at a nominal five percent level. A slowly
changing schedule is nearly collinear with a slowly drifting error, so
the drift is readily mistaken for an effect. A rapidly alternating one
is nearly orthogonal to it, and the drift cancels across adjacent days
instead.

This is what the `max_run` constraint is protecting. It is usually
justified as avoiding confounding with time, which is true but
understates it: the constraint is what keeps the inference valid when
the residuals are dependent, which in intensive longitudinal data they
always are.

## 3. Hand the schedule to the collection tool

[`write_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/write_schedule.md)
writes the day-to-condition mapping as JSON.

``` r

f <- tempfile(fileext = ".json")
write_schedule(sched, f)
cat(substr(readLines(f), 1, 90))
#> {"1":1,"2":0,"3":0,"4":1,"5":1,"6":0,"7":1,"8":1,"9":0,"10":0,"11":1,"12":0,"13":0,"14":1,
```

That format is what the companion iOS app and Shortcut both read, so a
schedule designed here can be loaded onto a phone without an
intermediate step. Generation and execution stay separate on purpose: an
instrument that can also rewrite the randomization is an instrument that
can silently unblind a study.

## 4. Read what came back, and check it

The study data are bundled with the package. Real files rarely use the
column name you expect, so
[`read_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/read_ema.md)
takes the name of the timestamp column.

``` r

path <- system.file("extdata", "melatonin_ema.csv", package = "nof1kit")
ema <- read_ema(path, start_date = "2026-02-18", timestamp_col = "datetime")
#> Error:
#> ! `study_day` in the file disagrees with the calendar for 68 of 195 records.
#>   First at row 128: 2026-04-03 is day 44 in the file, day 45 counting from 2026-02-18.
#>   Resolve which index is correct, or drop start_date to accept the file's.
```

The file carries its own `study_day` column, and it does not match the
calendar: collection ran across 71 calendar days while the preregistered
protocol covered 70, so one study day spans two dates. The analysis was
preregistered over 70 days and indexed by `study_day`, which is the
correct scope, but a file whose index and calendar disagree is worth
surfacing rather than silently accepting.

Passing `start_date` makes the two indices meet, so the discrepancy is
raised at read time. Omitting it accepts the file’s index, and
[`validate_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/validate_ema.md)
reports it instead:

``` r

ema <- read_ema(path, timestamp_col = "datetime")

v <- validate_ema(
  ema,
  ranges = list(mood = c(0, 100), agency = c(0, 100),
                metacognition = c(0, 100), melatonin = c(0, 1)),
  n_days = 70
)
v
#> EMA validation: 195 records
#> 1issue found
#> 
#>   inconsistent_study_day 1
#> 
#> See $issues for row-level detail.
subset(v$issues, check == "inconsistent_study_day")
#>                    check row    column                                 detail
#> 1 inconsistent_study_day 125 study_day day 44 spans 2026-04-02 and 2026-04-03
```

The point of the check is that this is invisible to everything else a
pipeline usually does: the values are all in range, no timestamps are
duplicated, nothing is missing, and every `study_day` sits inside
`1:70`. An index that has drifted from the calendar is only visible if
something compares the two.

Whether the drift matters depends on the design. Here it does not,
because the analysis was preregistered over 70 study days and indexed by
`study_day` throughout. In a study indexed by date, or one where the two
were assumed interchangeable, the same drift would silently misalign a
third of the records.

The result is data, not a printed report, so a pipeline that must not
proceed on bad input can act on it:

``` r

stopifnot(v$n_issues == 0)
#> Error:
#> ! v$n_issues == 0 is not TRUE
```

## 5. Compliance, and why the definition matters

Compliance in EMA studies is usually reported as records divided by
prompts. On these data that gives:

``` r

records <- nrow(ema)
prompts <- 70 * 3
round(100 * records / prompts, 1)
#> [1] 92.9
```

[`compliance()`](https://haomeng797-ship-it.github.io/nof1kit/reference/compliance.md)
computes something different: the proportion of scheduled prompts that
received a response *inside their response window*.

``` r

cp <- compliance(
  ema,
  start_date = "2026-02-18",
  n_days = 70,
  times = c("10:00", "16:00", "22:00"),
  window = 3
)
cp
#> Compliance: 90.0%  (189 of 210 prompts answered in window)
#> 6 records fell outside every response window.
```

The two numbers differ by about three points on the same data, for two
reasons. A prompt answered three times counts once here, not three
times. And a record arriving outside every window is data, but it is not
evidence that a prompt was answered when it was asked.

Neither number is wrong. They answer different questions, and a paper
reporting “compliance” without saying which one leaves the reader unable
to tell. The prompt-level detail is available when the headline number
needs unpacking:

``` r

tapply(cp$prompts$answered, cp$prompts$time, mean)
#>     10:00     16:00     22:00 
#> 0.8428571 0.9285714 0.9285714
```

Response rates were not equal across the day. Whether the pattern is
large enough to matter is a judgement about the study, but it is the
kind of thing worth seeing before treating missingness as random.

## 6. Analysis

From here the data are ordinary. `nof1kit` deliberately stops at the
boundary of analysis: intensive longitudinal data are well served by
existing tools, and the gap this package fills is upstream of them.

``` r

library(lme4)
lmer(mood ~ melatonin + (1 | study_day), data = ema)
```

## Summary

``` r

sched <- design_schedule(n_days = 70, max_run = 2, seed = 20260218)
write_schedule(sched, "schedule.json")     # onto the phone

ema <- read_ema("export.csv", start_date = "2026-02-18")
validate_ema(ema, ranges = list(mood = c(0, 100)), n_days = 70)
compliance(ema, start_date = "2026-02-18", n_days = 70,
           times = c("09:00", "15:00", "21:00"))
```

Four functions cover design, handoff, quality control, and compliance.
What happens after that is what the rest of the R ecosystem is for.
