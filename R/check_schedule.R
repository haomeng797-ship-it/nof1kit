#' Diagnose a randomization schedule
#'
#' Reports the design properties a reviewer (or a preregistration reader)
#' would want to see: condition counts, run-length distribution, number of
#' alternations, and the lag-1 autocorrelation of the condition sequence.
#'
#' @param schedule A `nof1_schedule` from [design_schedule()], or any data
#'   frame with `day` and `condition` columns.
#'
#' @return A list with elements `counts`, `max_run`, `run_table`,
#'   `alternations`, and `lag1_autocor`.
#'
#' @examples
#' sched <- design_schedule(n_days = 70, seed = 20260218)
#' check_schedule(sched)
#'
#' @export
check_schedule <- function(schedule) {
  cond <- schedule$condition
  runs <- rle(as.character(cond))

  # lag-1 autocorrelation on a numeric coding of the sequence
  num <- as.numeric(factor(cond))
  lag1 <- if (stats::var(num) == 0) NA_real_ else
    stats::cor(num[-length(num)], num[-1])

  list(
    counts       = table(cond),
    max_run      = max(runs$lengths),
    run_table    = table(runs$lengths),
    alternations = sum(diff(num) != 0),
    lag1_autocor = lag1
  )
}
