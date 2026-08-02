# Check EMA records for the problems that actually occur

Runs the integrity checks a single-case dataset needs before analysis:
values outside their declared range, duplicated timestamps, missing
values in required columns, records falling outside the study period,
and timestamps that failed to parse.

## Usage

``` r
validate_ema(data, ranges = NULL, required = "timestamp", n_days = NULL)
```

## Arguments

- data:

  A data frame from
  [`read_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/read_ema.md).

- ranges:

  Named list of `c(min, max)` giving the valid range of each measured
  variable, e.g. `list(mood = c(0, 100))`. Columns not listed are not
  range-checked.

- required:

  Character vector of columns that must not be missing.

- n_days:

  Optional study length. When given, records with a `study_day` outside
  `1:n_days` are flagged.

## Value

An object of class `nof1_validation`: a list with `n_records`,
`n_issues`, and a data frame `issues` with columns `check`, `row`,
`column`, and `detail`. `n_issues == 0` means every check passed.

## Details

The result is returned as data, not printed. Reports are one way to
consume it; a preregistered pipeline that halts on failure is another.

## Examples

``` r
d <- data.frame(
  timestamp = as.POSIXct(c("2026-02-18 09:00:00", "2026-02-18 09:00:00"), tz = "UTC"),
  mood = c(72, 140),
  study_day = c(1L, 1L)
)
v <- validate_ema(d, ranges = list(mood = c(0, 100)))
v
#> EMA validation: 2 records
#> 2issues found
#> 
#>   duplicate_timestamp    1
#>   out_of_range           1
#> 
#> See $issues for row-level detail.
```
