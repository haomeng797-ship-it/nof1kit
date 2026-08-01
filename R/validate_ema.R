#' Check EMA records for the problems that actually occur
#'
#' Runs the integrity checks a single-case dataset needs before analysis:
#' values outside their declared range, duplicated timestamps, missing values in
#' required columns, records falling outside the study period, and timestamps
#' that failed to parse.
#'
#' The result is returned as data, not printed. Reports are one way to consume
#' it; a preregistered pipeline that halts on failure is another.
#'
#' @param data A data frame from [read_ema()].
#' @param ranges Named list of `c(min, max)` giving the valid range of each
#'   measured variable, e.g. `list(mood = c(0, 100))`. Columns not listed are
#'   not range-checked.
#' @param required Character vector of columns that must not be missing.
#' @param n_days Optional study length. When given, records with a `study_day`
#'   outside `1:n_days` are flagged.
#'
#' @return An object of class `nof1_validation`: a list with `n_records`,
#'   `n_issues`, and a data frame `issues` with columns `check`, `row`,
#'   `column`, and `detail`. `n_issues == 0` means every check passed.
#'
#' @examples
#' d <- data.frame(
#'   timestamp = as.POSIXct(c("2026-02-18 09:00:00", "2026-02-18 09:00:00"), tz = "UTC"),
#'   mood = c(72, 140),
#'   study_day = c(1L, 1L)
#' )
#' v <- validate_ema(d, ranges = list(mood = c(0, 100)))
#' v
#'
#' @export
validate_ema <- function(data,
                         ranges = NULL,
                         required = "timestamp",
                         n_days = NULL) {
  stopifnot(is.data.frame(data))

  issues <- list()
  add <- function(check, row, column, detail) {
    issues[[length(issues) + 1L]] <<- data.frame(
      check = check, row = row, column = column, detail = detail,
      stringsAsFactors = FALSE
    )
  }

  # Unparseable timestamps
  if ("timestamp" %in% names(data)) {
    bad <- which(is.na(data$timestamp))
    for (i in bad) add("unparsed_timestamp", i, "timestamp", "NA after parsing")
  }

  # Values outside their declared range
  for (col in names(ranges)) {
    if (!col %in% names(data)) next
    lim <- ranges[[col]]
    v <- suppressWarnings(as.numeric(data[[col]]))
    bad <- which(!is.na(v) & (v < lim[1] | v > lim[2]))
    for (i in bad) {
      add("out_of_range", i, col,
          sprintf("%s outside [%s, %s]", format(v[i]), lim[1], lim[2]))
    }
  }

  # Missing values in required columns
  for (col in required) {
    if (!col %in% names(data)) {
      add("missing_column", NA_integer_, col, "required column absent")
      next
    }
    bad <- which(is.na(data[[col]]))
    for (i in bad) add("missing_value", i, col, "NA in required column")
  }

  # Duplicate timestamps: two records at the identical instant are almost
  # always a double submission, not two genuine measurements
  if ("timestamp" %in% names(data)) {
    dup <- which(duplicated(data$timestamp) & !is.na(data$timestamp))
    for (i in dup) {
      add("duplicate_timestamp", i, "timestamp",
          format(data$timestamp[i], "%Y-%m-%d %H:%M:%S"))
    }
  }

  # Records outside the study period
  if (!is.null(n_days) && "study_day" %in% names(data)) {
    bad <- which(!is.na(data$study_day) &
                   (data$study_day < 1 | data$study_day > n_days))
    for (i in bad) {
      add("outside_study_period", i, "study_day",
          sprintf("day %s not in 1:%s", data$study_day[i], n_days))
    }
  }

  tbl <- if (length(issues)) do.call(rbind, issues) else
    data.frame(check = character(0), row = integer(0),
               column = character(0), detail = character(0),
               stringsAsFactors = FALSE)

  structure(
    list(n_records = nrow(data), n_issues = nrow(tbl), issues = tbl),
    class = "nof1_validation"
  )
}

#' @export
print.nof1_validation <- function(x, ...) {
  cat("EMA validation:", x$n_records, "records\n")
  if (x$n_issues == 0) {
    cat("All checks passed.\n")
    return(invisible(x))
  }
  cat(x$n_issues, "issue", if (x$n_issues > 1) "s" else "", " found\n\n", sep = "")
  counts <- table(x$issues$check)
  for (nm in names(counts)) cat(sprintf("  %-22s %d\n", nm, counts[[nm]]))
  cat("\nSee $issues for row-level detail.\n")
  invisible(x)
}
