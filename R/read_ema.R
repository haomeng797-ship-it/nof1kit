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
#'
#' @return A data frame with `timestamp` as `POSIXct`, `study_day` as integer
#'   when derivable, and all other columns unchanged.
#'
#' @examples
#' f <- system.file("extdata", "example_ema.csv", package = "nof1kit")
#' if (nzchar(f)) head(read_ema(f))
#'
#' @export
read_ema <- function(path, start_date = NULL, tz = "UTC") {
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
  if (!"timestamp" %in% names(dat)) {
    stop("No `timestamp` column found. Columns present: ",
         paste(names(dat), collapse = ", "), call. = FALSE)
  }

  dat$timestamp <- parse_timestamp(dat$timestamp, tz = tz)

  if (anyNA(dat$timestamp)) {
    n <- sum(is.na(dat$timestamp))
    warning(n, " timestamp", if (n > 1) "s" else "",
            " could not be parsed and are NA.", call. = FALSE)
  }

  if (is.null(dat$study_day) && !is.null(start_date)) {
    start <- as.Date(start_date)
    dat$study_day <- as.integer(as.Date(dat$timestamp, tz = tz) - start) + 1L
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
    out[fallback] <- as.POSIXct(x[fallback], tz = tz)
  }
  out
}
