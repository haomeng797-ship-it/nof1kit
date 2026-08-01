make_csv <- function(lines) {
  f <- tempfile(fileext = ".csv")
  writeLines(lines, f)
  f
}

test_that("read_ema parses ISO 8601 with and without Z", {
  f <- make_csv(c(
    "timestamp,mood",
    "2026-02-18T09:00:00Z,72",
    "2026-02-18T15:00:00,65"
  ))
  d <- read_ema(f)
  expect_s3_class(d$timestamp, "POSIXct")
  expect_false(anyNA(d$timestamp))
  expect_equal(nrow(d), 2)
})

test_that("read_ema derives study_day from start_date", {
  f <- make_csv(c(
    "timestamp,mood",
    "2026-02-18T09:00:00Z,72",
    "2026-02-20T09:00:00Z,65"
  ))
  d <- read_ema(f, start_date = "2026-02-18")
  expect_equal(d$study_day, c(1L, 3L))
})

test_that("read_ema returns records in time order", {
  f <- make_csv(c(
    "timestamp,mood",
    "2026-02-19T09:00:00Z,60",
    "2026-02-18T09:00:00Z,70"
  ))
  d <- read_ema(f)
  expect_true(all(diff(as.numeric(d$timestamp)) > 0))
})

test_that("read_ema errors informatively on a missing timestamp column", {
  f <- make_csv(c("time,mood", "2026-02-18T09:00:00Z,72"))
  expect_error(read_ema(f), "timestamp")
})

test_that("validate_ema is silent when the data are clean", {
  d <- data.frame(
    timestamp = as.POSIXct(c("2026-02-18 09:00:00", "2026-02-18 15:00:00"), tz = "UTC"),
    mood = c(72, 65), study_day = c(1L, 1L)
  )
  v <- validate_ema(d, ranges = list(mood = c(0, 100)), n_days = 70)
  expect_s3_class(v, "nof1_validation")
  expect_equal(v$n_issues, 0)
})

test_that("validate_ema catches each kind of problem", {
  d <- data.frame(
    timestamp = as.POSIXct(c("2026-02-18 09:00:00", "2026-02-18 09:00:00", NA), tz = "UTC"),
    mood = c(72, 140, 50),
    study_day = c(1L, 1L, 999L)
  )
  v <- validate_ema(d, ranges = list(mood = c(0, 100)), n_days = 70)
  kinds <- unique(v$issues$check)
  expect_true("out_of_range" %in% kinds)
  expect_true("duplicate_timestamp" %in% kinds)
  expect_true("unparsed_timestamp" %in% kinds)
  expect_true("outside_study_period" %in% kinds)
})

test_that("compliance counts each prompt once, not each record", {
  # three records all inside the same 09:00 window
  d <- data.frame(timestamp = as.POSIXct(
    c("2026-02-18 09:10:00", "2026-02-18 09:20:00", "2026-02-18 09:30:00"),
    tz = "UTC"))
  cp <- compliance(d, start_date = "2026-02-18", n_days = 1,
                   times = c("09:00", "15:00", "21:00"),
                   through = as.POSIXct("2026-02-18 22:00:00", tz = "UTC"))
  expect_equal(cp$n_answered, 1)      # not 3
  expect_equal(cp$n_expected, 3)
  expect_equal(cp$rate, 1/3)
})

test_that("compliance excludes records outside every window", {
  d <- data.frame(timestamp = as.POSIXct(
    c("2026-02-18 09:10:00", "2026-02-18 13:00:00"), tz = "UTC"))
  cp <- compliance(d, start_date = "2026-02-18", n_days = 1,
                   times = c("09:00", "15:00"), window = 3,
                   through = as.POSIXct("2026-02-18 20:00:00", tz = "UTC"))
  expect_equal(cp$n_answered, 1)
  expect_equal(cp$n_off_window, 1)    # the 13:00 one belongs to no window
})

test_that("compliance does not penalise prompts that have not happened", {
  d <- data.frame(timestamp = as.POSIXct("2026-02-18 09:10:00", tz = "UTC"))
  cp <- compliance(d, start_date = "2026-02-18", n_days = 70,
                   times = c("09:00", "15:00", "21:00"),
                   through = as.POSIXct("2026-02-18 10:00:00", tz = "UTC"))
  expect_equal(cp$n_expected, 1)      # only the 09:00 prompt has occurred
  expect_equal(cp$rate, 1)
})

test_that("compliance handles a study that has not started", {
  d <- data.frame(timestamp = as.POSIXct(character(0), tz = "UTC"))
  cp <- compliance(d, start_date = "2026-03-01", n_days = 70,
                   times = "09:00",
                   through = as.POSIXct("2026-02-18 10:00:00", tz = "UTC"))
  expect_true(is.na(cp$rate))
})
