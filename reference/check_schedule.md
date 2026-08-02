# Diagnose a randomization schedule

Reports the design properties a reviewer (or a preregistration reader)
would want to see: condition counts, run-length distribution, number of
alternations, and the lag-1 autocorrelation of the condition sequence.

## Usage

``` r
check_schedule(schedule)
```

## Arguments

- schedule:

  A `nof1_schedule` from
  [`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md),
  or any data frame with `day` and `condition` columns.

## Value

A list with elements `counts`, `max_run`, `run_table`, `alternations`,
and `lag1_autocor`.

## Examples

``` r
sched <- design_schedule(n_days = 70, seed = 20260218)
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
