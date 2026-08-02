# Export a schedule for the mobile data-collection layer

Writes a schedule as JSON in the exact `{"1": 0, "2": 1, ...}` format
consumed by the companion iOS Shortcuts EMA logger
(<https://github.com/haomeng797-ship-it/melatonin-ema-logger>), so a
generated design can be dropped straight into an existing collection
pipeline.

## Usage

``` r
write_schedule(schedule, path)
```

## Arguments

- schedule:

  A `nof1_schedule` from
  [`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md).

- path:

  File path for the JSON output, e.g. `"schedule.json"`.

## Value

The path, invisibly.

## Examples

``` r
sched <- design_schedule(n_days = 70, seed = 20260218)
tmp <- tempfile(fileext = ".json")
write_schedule(sched, tmp)
```
