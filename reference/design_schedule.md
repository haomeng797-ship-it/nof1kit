# Generate a randomized N-of-1 intervention schedule

Produces a day-by-day condition sequence for a single-case experimental
study, under the restricted randomization commonly needed in N-of-1
designs: balanced condition counts and a cap on how many consecutive
days the same condition may repeat.

## Usage

``` r
design_schedule(n_days, conditions = c(0L, 1L), max_run = 2L, seed)
```

## Arguments

- n_days:

  Integer. Length of the study in days.

- conditions:

  Vector of condition labels. Defaults to `c(0L, 1L)` (control /
  treatment), matching the schedule format used by the companion iOS
  Shortcuts logger.

- max_run:

  Integer. Maximum allowed run of identical consecutive conditions.
  Defaults to 2.

- seed:

  Integer. Required. The seed makes the schedule reproducible and is
  intended to be reported in the preregistration.

## Value

An object of class `nof1_schedule`: a data frame with columns `day` and
`condition`, with the generating parameters stored as attributes.

## Details

Sampling is exact, not by rejection. The number of valid completions
from every intermediate state (remaining counts, current run) is counted
by dynamic programming, and the sequence is then drawn day by day with
probability proportional to those counts. The result is a uniform draw
over the set of *all* schedules that satisfy the constraints, so no
valid schedule is more probable than any other.

Naive rejection sampling is not workable here: for a balanced 70-day
two-condition design with `max_run = 2`, fewer than one permutation in a
million satisfies the run constraint.

## Examples

``` r
sched <- design_schedule(n_days = 70, max_run = 2, seed = 20260218)
head(sched)
#>   day condition
#> 1   1         1
#> 2   2         0
#> 3   3         0
#> 4   4         1
#> 5   5         1
#> 6   6         0
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
#> 
```
