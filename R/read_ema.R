#' Read EMA records into a tidy data frame
#'
#' Reads the CSV or JSON produced by a mobile collection tool and returns a
#' data frame with parsed timestamps and a study-day index, ready for
#' [validate_ema()] and [compliance()].
#'
#' The expected columns are `timestamp` plus whatever was measured. Only
#' `timestamp` is required. If `start_date` is supplied (or the file already
#' carries a `study_day` column) a `study_day` index is attached, counting from
#' 1 on the first day of the study.
#'
#' @param path Path to a `.csv` or `.json` file.
#' @param start_date Date (or something [as.Date()] accepts) on which the study
#'   began. Used to compute `study_day` when the file does not already have it.
#' @param tz Time zone to interpret timestamps in. Defaults to `"UTC"`, which
#'   matches the ISO 8601 output of the companion app.
#' @param timestamp_col Name of the column holding the timestamp. Real files
#'   call it many things (`datetime`, `time`, `recorded_at`); give the name here
#'   and it is renamed to `timestamp` on the way in.
#'
#' @return A data frame with `timestamp` as `POSIXct`, `study_day` as integer
#'   when derivable, and all other columns unchanged.
#'
#' @examples
#' f <- system.file("extdata", "example_ema.csv", package = "nof1kit")
#' if (nzchar(f)) head(read_ema(f))
#'
#' @srrstats {G2.6} `read_ema()` accepts the timestamp column as character,
#'   factor, or POSIXct and normalizes it through `parse_timestamp()` before
#'   any other routine sees it.
#' @srrstats {G2.8} All downstream functions receive a data frame with a
#'   POSIXct `timestamp`; `read_ema()` is the single conversion point.
#' @srrstats {G2.9} `read_ema()` issues a warning naming the number of
#'   timestamps that could not be parsed, so information lost in conversion is
#'   reported rather than silently propagated as `NA`.
#' @srrstats {G2.4} The one type conversion the package performs is explicit
#'   and happens in a single place, `parse_timestamp()`, which turns character
#'   or factor timestamps into POSIXct.
#' @export
read_ema <- function(path, start_date = NULL, tz = "UTC",
                     timestamp_col = "timestamp") {
  if (!file.exists(path)) {
    stop("File not found: ", path, call. = FALSE)
  }

  ext <- tolower(tools::file_ext(path))
  dat <- switch(
    ext,
    csv  = utils::read.csv(path, stringsAsFactors = FALSE),
    json = jsonlite::fromJSON(path, simplifyDataFrame = TRUE),
    stop("Unsupported file type: .", ext, ". Use .csv or .json.", call. = FALSE)
  )

  if (!is.data.frame(dat)) {
    stop("The file did not parse into a table of records.", call. = FALSE)
  }
  if (!timestamp_col %in% names(dat)) {
    stop("No `", timestamp_col, "` column found. Columns present: ",
         paste(names(dat), collapse = ", "),
         "\nUse timestamp_col = to point at the right one.", call. = FALSE)
  }
  if (timestamp_col != "timestamp") {
    names(dat)[names(dat) == timestamp_col] <- "timestamp"
  }

  dat$timestamp <- parse_timestamp(dat$timestamp, tz = tz)

  if (anyNA(dat$timestamp)) {
    n <- sum(is.na(dat$timestamp))
    warning(n, " timestamp", if (n > 1) "s" else "",
            " could not be parsed and are NA.", call. = FALSE)
  }

  if (!is.null(start_date)) {
    start <- as.Date(start_date)
    derived <- as.integer(as.Date(dat$timestamp, tz = tz) - start) + 1L

    if (is.null(dat$study_day)) {
      dat$study_day <- derived
    } else {
      # A study_day column that disagrees with the calendar means the index and
      # the timestamps are telling different stories, and every downstream
      # analysis has to pick one. Fail loudly rather than silently trusting the
      # file, which is what makes this class of error survive to publication.
      existing <- suppressWarnings(as.integer(dat$study_day))
      disagree <- which(!is.na(existing) & !is.na(derived) & existing != derived)
      if (length(disagree)) {
        first <- disagree[1]
        stop(
          sprintf(
            paste0("`study_day` in the file disagrees with the calendar for %d of %d records.\n",
                   "  First at row %d: %s is day %s in the file, day %s counting from %s.\n",
                   "  Resolve which index is correct, or drop start_date to accept the file's."),
            length(disagree), nrow(dat), first,
            format(dat$timestamp[first], "%Y-%m-%d"),
            existing[first], derived[first], format(start)),
          call. = FALSE
        )
      }
    }
  }

  dat[order(dat$timestamp), , drop = FALSE]
}

#' Parse ISO 8601 timestamps, with or without a trailing Z
#' @noRd
parse_timestamp <- function(x, tz = "UTC") {
  if (inherits(x, "POSIXct")) return(x)
  x <- as.character(x)
  # Try ISO 8601 with zone designator first, then without.
  out <- as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = tz)
  fallback <- is.na(out) & !is.na(x)
  if (any(fallback)) {
    out[fallback] <- as.POSIXct(x[fallback], format = "%Y-%m-%dT%H:%M:%S", tz = tz)
  }
  fallback <- is.na(out) & !is.na(x)
  if (any(fallback)) {
    # as.POSIXct() errors on strings it cannot read at all, so parse these
    # one at a time and let the failures come back as NA for the caller to
    # count and warn about.
    parsed <- vapply(
      x[fallback],
      function(s) {
        tryCatch(as.numeric(as.POSIXct(s, tz = tz)),
                 error = function(e) NA_real_)
      },
      numeric(1),
      USE.NAMES = FALSE
    )
    out[fallback] <- as.POSIXct(parsed, origin = "1970-01-01", tz = tz)
  }
  out
}
