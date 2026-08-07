# print methods -----------------------------------------------------------

test_that("print.nof1_compliance reports the rate and off-window records", {
  d <- data.frame(timestamp = as.POSIXct(
    c("2026-02-18 09:30:00", "2026-02-18 23:59:00"), tz = "UTC"))
  cp <- compliance(d, start_date = "2026-02-18", n_days = 1,
                   times = c("09:00", "15:00"))
  out <- capture.output(print(cp))
  expect_true(any(grepl("Compliance: 50.0%", out, fixed = TRUE)))
  expect_true(any(grepl("1 record fell outside", out, fixed = TRUE)))
})

test_that("compliance before the first prompt prints a sensible message", {
  d <- data.frame(timestamp = as.POSIXct(character(), tz = "UTC"))
  cp <- compliance(d, start_date = "2026-02-18", n_days = 7,
                   times = "09:00",
                   through = as.POSIXct("2026-02-18 00:10:00", tz = "UTC"))
  expect_true(is.na(cp$rate))
  out <- capture.output(print(cp))
  expect_true(any(grepl("No prompts have occurred yet", out, fixed = TRUE)))
})

test_that("print.nof1_power labels a null simulation as a false positive rate", {
  p <- sim_power(n_days = 30, effect = 0, phi = 0.4, n_sims = 20, seed = 7)
  out <- capture.output(print(p))
  expect_true(any(grepl("False positive rate", out, fixed = TRUE)))
})

test_that("print.nof1_power reports the direction of the OLS gap", {
  p <- sim_power(n_days = 40, effect = 0.6, phi = 0.5, n_sims = 40, seed = 3)
  out <- capture.output(print(p))
  expect_true(any(grepl("AR\\(1\\) model", out)))
  gap_line <- grepl("conservative", out)
  if (abs(p$power_ols - p$power) >= 0.02) expect_true(any(gap_line))
})

test_that("print.nof1_validation prints both the clean and the flagged case", {
  clean <- data.frame(
    timestamp = as.POSIXct("2026-02-18 09:00:00", tz = "UTC") + 3600 * (0:4),
    study_day = rep(1L, 5), mood = c(10, 20, 30, 40, 50))
  v <- validate_ema(clean, ranges = list(mood = c(0, 100)), n_days = 70)
  out <- capture.output(print(v))
  expect_true(any(grepl("All checks passed", out, fixed = TRUE)))

  bad <- clean
  bad$mood[2] <- 250
  v2 <- validate_ema(bad, ranges = list(mood = c(0, 100)), n_days = 70)
  out2 <- capture.output(print(v2))
  expect_true(any(grepl("out_of_range", out2, fixed = TRUE)))
  expect_true(any(grepl("issue", out2)))
})

# input validation ---------------------------------------------------------

test_that("design_schedule rejects impossible designs", {
  expect_error(design_schedule(n_days = 1, seed = 1), "at least the number")
  expect_error(design_schedule(n_days = 10, max_run = 0, seed = 1),
               "`max_run` must be at least 1")
})

test_that("read_ema fails clearly on missing or malformed files", {
  expect_error(read_ema(file.path(tempdir(), "no-such-file.csv")),
               "File not found")
  bad <- tempfile(fileext = ".csv")
  writeLines("just one line no commas", bad)
  expect_error(read_ema(bad), "did not parse|No `timestamp` column")
})

# read_ema edge paths ------------------------------------------------------

test_that("read_ema renames a custom timestamp column", {
  f <- tempfile(fileext = ".csv")
  write.csv(data.frame(datetime = "2026-02-18 10:00:00", mood = 50), f,
            row.names = FALSE)
  d <- read_ema(f, timestamp_col = "datetime")
  expect_true("timestamp" %in% names(d))
  expect_s3_class(d$timestamp, "POSIXct")
})

test_that("read_ema warns on unparseable timestamps", {
  f <- tempfile(fileext = ".csv")
  write.csv(data.frame(timestamp = c("2026-02-18 10:00:00", "not a time")), f,
            row.names = FALSE)
  expect_warning(d <- read_ema(f), "could not be parsed")
  expect_identical(sum(is.na(d$timestamp)), 1L)
})

test_that("validate_ema reports missing required columns", {
  d <- data.frame(timestamp = as.POSIXct("2026-02-18 10:00:00", tz = "UTC"))
  v <- validate_ema(d, required = c("mood"), n_days = 70)
  expect_true("missing_column" %in% v$issues$check)
})

test_that("sim_power counts non-converging fits instead of failing", {
  p <- sim_power(n_days = 20, effect = 0, sd = 0, phi = 0.5, n_sims = 3, seed = 1)
  expect_identical(p$n_failed, 3L)
  out <- capture.output(print(p))
  expect_true(any(grepl("did not converge", out, fixed = TRUE)))
})
