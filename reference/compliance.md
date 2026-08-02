# Compliance against scheduled prompts

Computes EMA compliance as the proportion of *scheduled prompts* that
received a response inside their response window.

## Usage

``` r
compliance(data, start_date, n_days, times, window = 3, through = NULL)
```

## Arguments

- data:

  A data frame from
  [`read_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/read_ema.md),
  containing `timestamp`.

- start_date:

  Date the study began (day 1).

- n_days:

  Study length in days.

- times:

  Character vector of prompt times in `"HH:MM"`, e.g.
  `c("09:00", "15:00", "21:00")`.

- window:

  Response window in hours. A record counts toward a prompt if it
  arrives between the prompt time and `window` hours later.

- through:

  Compute compliance as of this moment. Defaults to the last timestamp
  in the data, so a study still running is not penalised for prompts
  that have not happened yet.

## Value

An object of class `nof1_compliance`: a list with `rate`, `n_answered`,
`n_expected`, `n_off_window`, and a data frame `prompts` with one row
per scheduled prompt and a logical `answered`.

## Details

The definition matters more than the arithmetic. Compliance is often
reported as the number of records divided by the number of prompts,
which lets a participant who answers one prompt three times appear more
compliant than one who answers three prompts once. Late entries,
likewise, are data but not evidence that a prompt was answered when it
was asked.

This function therefore counts each scheduled prompt at most once, and
only when a record falls within `window` hours of it. Records outside
every window are returned separately as `n_off_window`: they are not
discarded, they are simply not evidence of compliance.

## Examples

``` r
d <- data.frame(timestamp = as.POSIXct(
  c("2026-02-18 09:30:00", "2026-02-18 15:10:00", "2026-02-19 09:05:00"),
  tz = "UTC"))
compliance(d, start_date = "2026-02-18", n_days = 2,
           times = c("09:00", "15:00", "21:00"))
#> Compliance: 75.0%  (3 of 4 prompts answered in window)
```
