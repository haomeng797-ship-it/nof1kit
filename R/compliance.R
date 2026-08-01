#' Compliance against scheduled prompts
#'
#' Computes EMA compliance as the proportion of *scheduled prompts* that
#' received a response inside their response window.
#'
#' @details
#' The definition matters more than the arithmetic. Compliance is often reported
#' as the number of records divided by the number of prompts, which lets a
#' participant who answers one prompt three times appear more compliant than one
#' who answers three prompts once. Late entries, likewise, are data but not
#' evidence that a prompt was answered when it was asked.
#'
#' This function therefore counts each scheduled prompt at most once, and only
#' when a record falls within `window` hours of it. Records outside every window
#' are returned separately as `n_off_window`: they are not discarded, they are
#' simply not evidence of compliance.
#'
#' @param data A data frame from [read_ema()], containing `timestamp`.
#' @param start_date Date the study began (day 1).
#' @param n_days Study length in days.
#' @param times Character vector of prompt times in `"HH:MM"`, e.g.
#'   `c("09:00", "15:00", "21:00")`.
#' @param window Response window in hours. A record counts toward a prompt if it
#'   arrives between the prompt time and `window` hours later.
#' @param through Compute compliance as of this moment. Defaults to the last
#'   timestamp in the data, so a study still running is not penalised for
#'   prompts that have not happened yet.
#'
#' @return An object of class `nof1_compliance`: a list with `rate`,
#'   `n_answered`, `n_expected`, `n_off_window`, and a data frame `prompts` with
#'   one row per scheduled prompt and a logical `answered`.
#'
#' @examples
#' d <- data.frame(timestamp = as.POSIXct(
#'   c("2026-02-18 09:30:00", "2026-02-18 15:10:00", "2026-02-19 09:05:00"),
#'   tz = "UTC"))
#' compliance(d, start_date = "2026-02-18", n_days = 2,
#'            times = c("09:00", "15:00", "21:00"))
#'
#' @export
compliance <- function(data,
                       start_date,
                       n_days,
                       times,
                       window = 3,
                       through = NULL) {
  stopifnot(is.data.frame(data), "timestamp" %in% names(data))

  ts <- data$timestamp[!is.na(data$timestamp)]
  if (is.null(through)) {
    through <- if (length(ts)) max(ts) else as.POSIXct(start_date, tz = "UTC")
  }

  tz <- attr(ts, "tzone")
  if (is.null(tz) || !nzchar(tz)) tz <- "UTC"
  start <- as.Date(start_date)

  # Every scheduled prompt from day 1 up to `through`
  grid <- expand.grid(day = seq_len(n_days), time = times,
                      stringsAsFactors = FALSE)
  grid$prompt_at <- as.POSIXct(
    paste(start + (grid$day - 1L), grid$time),
    format = "%Y-%m-%d %H:%M", tz = tz
  )
  grid <- grid[order(grid$prompt_at), , drop = FALSE]
  grid <- grid[grid$prompt_at <= through, , drop = FALSE]

  if (!nrow(grid)) {
    return(structure(
      list(rate = NA_real_, n_answered = 0L, n_expected = 0L,
           n_off_window = length(ts), prompts = grid),
      class = "nof1_compliance"))
  }

  win_secs <- window * 3600
  grid$closes_at <- grid$prompt_at + win_secs

  # A prompt is answered if any record lands in its window. Each prompt counts
  # once regardless of how many records fall inside it.
  grid$answered <- vapply(seq_len(nrow(grid)), function(i) {
    any(ts >= grid$prompt_at[i] & ts < grid$closes_at[i])
  }, logical(1))

  # Records that fall in no window at all
  in_any <- vapply(ts, function(t) {
    any(t >= grid$prompt_at & t < grid$closes_at)
  }, logical(1))

  structure(
    list(
      rate         = mean(grid$answered),
      n_answered   = sum(grid$answered),
      n_expected   = nrow(grid),
      n_off_window = sum(!in_any),
      prompts      = grid[c("day", "time", "prompt_at", "closes_at", "answered")]
    ),
    class = "nof1_compliance"
  )
}

#' @export
print.nof1_compliance <- function(x, ...) {
  if (is.na(x$rate)) {
    cat("No prompts have occurred yet.\n")
    return(invisible(x))
  }
  cat(sprintf("Compliance: %.1f%%  (%d of %d prompts answered in window)\n",
              100 * x$rate, x$n_answered, x$n_expected))
  if (x$n_off_window > 0) {
    cat(sprintf("%d record%s fell outside every response window.\n",
                x$n_off_window, if (x$n_off_window > 1) "s" else ""))
  }
  invisible(x)
}
