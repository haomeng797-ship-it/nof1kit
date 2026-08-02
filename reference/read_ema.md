# Read EMA records into a tidy data frame

Reads the CSV or JSON produced by a mobile collection tool and returns a
data frame with parsed timestamps and a study-day index, ready for
[`validate_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/validate_ema.md)
and
[`compliance()`](https://haomeng797-ship-it.github.io/nof1kit/reference/compliance.md).

## Usage

``` r
read_ema(path, start_date = NULL, tz = "UTC", timestamp_col = "timestamp")
```

## Arguments

- path:

  Path to a `.csv` or `.json` file.

- start_date:

  Date (or something [`as.Date()`](https://rdrr.io/r/base/as.Date.html)
  accepts) on which the study began. Used to compute `study_day` when
  the file does not already have it.

- tz:

  Time zone to interpret timestamps in. Defaults to `"UTC"`, which
  matches the ISO 8601 output of the companion app.

- timestamp_col:

  Name of the column holding the timestamp. Real files call it many
  things (`datetime`, `time`, `recorded_at`); give the name here and it
  is renamed to `timestamp` on the way in.

## Value

A data frame with `timestamp` as `POSIXct`, `study_day` as integer when
derivable, and all other columns unchanged.

## Details

The expected columns are `timestamp` plus whatever was measured. Only
`timestamp` is required. If `start_date` is supplied (or the file
already carries a `study_day` column) a `study_day` index is attached,
counting from 1 on the first day of the study.

## Examples

``` r
f <- system.file("extdata", "example_ema.csv", package = "nof1kit")
if (nzchar(f)) head(read_ema(f))
```
