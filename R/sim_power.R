#' Simulation-based power for an N-of-1 design
#'
#' Estimates the power to detect a treatment effect in a single-case design by
#' simulating studies of the given length, analyzing each one, and recording how
#' often the effect is detected.
#'
#' @details
#' Closed-form power formulas assume independent observations. Daily measurements
#' from one person are not independent: today's mood is correlated with
#' yesterday's. Positive autocorrelation means each new day carries less
#' information than a genuinely new observation would, so the effective sample
#' size is smaller than the number of days.
#'
#' This function therefore analyses each simulated study two ways, and reports
#' both. `power` comes from a model with AR(1) errors, which accounts for the
#' dependence. `power_ols` comes from ordinary least squares, which ignores it.
#'
#' The direction in which OLS goes wrong depends on the schedule, which is why
#' design and analysis cannot be chosen separately. Under the rapidly
#' alternating schedules that [design_schedule()] produces, a slowly drifting
#' AR(1) error is nearly orthogonal to the condition sequence: the drift cancels
#' across adjacent days, the true variance of the effect estimate is smaller than
#' independence implies, and OLS is therefore conservative. It loses power but
#' does not produce false positives.
#'
#' Under a schedule that changes slowly, the opposite happens. A design that runs
#' control for the first half and treatment for the second is nearly collinear
#' with any drift, so autocorrelation is readily mistaken for an effect. In
#' simulations at `phi = 0.7`, such a design rejects a true null about 40 percent
#' of the time at a nominal 5 percent level. Pass `schedule` to see this for a
#' sequence you are considering.
#'
#' Set `effect = 0` to get the false positive rate instead of power.
#'
#' Each simulated study gets a freshly drawn randomization schedule under the
#' same run constraint, so the estimate reflects the design rather than one
#' particular sequence. Supply `schedule` to hold the sequence fixed instead.
#'
#' @param n_days Study length in days.
#' @param effect True treatment effect, in the same units as `sd`. Use 0 to
#'   estimate the false positive rate.
#' @param sd Residual standard deviation of the outcome (its marginal SD, not
#'   the innovation SD).
#' @param phi Lag-1 autocorrelation of the errors, in `[0, 1)`. Daily mood and
#'   affect measures commonly fall between 0.2 and 0.5.
#' @param max_run Maximum run of identical consecutive conditions in the
#'   generated schedules.
#' @param alpha Significance level.
#' @param n_sims Number of simulated studies.
#' @param schedule Optional fixed condition vector (0/1) of length `n_days`. When
#'   given, every simulation uses it instead of drawing a new one.
#' @param seed Optional seed for reproducibility.
#'
#' @return An object of class `nof1_power`: a list with `power`, `power_ols`,
#'   `n_days`, `effect`, `phi`, `alpha`, `n_sims`, and `n_failed` (simulations
#'   where the AR(1) fit did not converge and were dropped).
#'
#' @examples
#' # Power to detect a half-SD effect over 70 days, with moderate autocorrelation
#' # (n_sims is kept small here; use the default 500 for a real planning run)
#' sim_power(n_days = 70, effect = 0.5, phi = 0.3, n_sims = 40, seed = 1)
#'
#' # With no effect, `power` is the false positive rate
#' sim_power(n_days = 70, effect = 0, phi = 0.5, n_sims = 40, seed = 1)
#'
#' @srrstats {G5.8c} All-identical fields: `sim_power()` with `sd = 0`
#'   produces degenerate fits, which are counted in `n_failed` and reported,
#'   rather than erroring.
#' @srrstats {G2.0} Lengths are asserted where a mismatch would be silent:
#'   `sim_power()` rejects a `schedule` whose length is not `n_days`, and
#'   `compliance()` requires a `timestamp` column rather than positional input.
#' @srrstats {G2.0a} Expected lengths are stated in the `@param` entries, e.g.
#'   `schedule` in `sim_power()` is documented as a vector of length `n_days`.
#' @export
sim_power <- function(n_days = 70,
                      effect = 0.5,
                      sd = 1,
                      phi = 0,
                      max_run = 2L,
                      alpha = 0.05,
                      n_sims = 500L,
                      schedule = NULL,
                      seed = NULL) {

  if (phi < 0 || phi >= 1) {
    stop("`phi` must be in [0, 1).", call. = FALSE)
  }
  if (!is.null(schedule) && length(schedule) != n_days) {
    stop("`schedule` must have length `n_days`.", call. = FALSE)
  }
  if (!is.null(seed)) set.seed(seed)

  hit_ar  <- logical(n_sims)
  hit_ols <- logical(n_sims)
  failed  <- 0L

  for (i in seq_len(n_sims)) {
    x <- if (is.null(schedule)) {
      sample_constrained(n_days, 2L, max_run) - 1L   # 0/1
    } else {
      schedule
    }

    # AR(1) errors with marginal SD equal to `sd`. arima.sim's `sd` is the
    # innovation SD, so it has to be scaled down by sqrt(1 - phi^2).
    e <- if (phi == 0) {
      stats::rnorm(n_days, 0, sd)
    } else {
      as.numeric(stats::arima.sim(list(ar = phi), n = n_days,
                                  sd = sd * sqrt(1 - phi^2)))
    }
    y <- effect * x + e

    # Ignoring the dependence
    p_ols <- tryCatch({
      summary(stats::lm(y ~ x))$coefficients["x", "Pr(>|t|)"]
    }, error = function(e) NA_real_)
    hit_ols[i] <- !is.na(p_ols) && p_ols < alpha

    # Accounting for it. Name the regressor explicitly: arima() takes the
    # coefficient name from whatever it is passed, so an unnamed vector makes
    # the coefficient impossible to look up reliably.
    xr <- matrix(x, ncol = 1L, dimnames = list(NULL, "trt"))
    fit <- tryCatch(
      stats::arima(y, order = c(1L, 0L, 0L), xreg = xr),
      error = function(e) NULL, warning = function(w) NULL
    )
    se <- if (is.null(fit)) NA_real_ else sqrt(diag(fit$var.coef))["trt"]
    if (is.null(fit) || is.na(fit$coef["trt"]) || is.na(se) || se <= 0) {
      failed <- failed + 1L
      hit_ar[i] <- NA
    } else {
      z <- fit$coef["trt"] / se
      hit_ar[i] <- abs(z) > stats::qnorm(1 - alpha / 2)
    }
  }

  structure(
    list(
      power     = mean(hit_ar, na.rm = TRUE),
      power_ols = mean(hit_ols),
      n_days    = n_days,
      effect    = effect,
      sd        = sd,
      phi       = phi,
      alpha     = alpha,
      n_sims    = n_sims,
      n_failed  = failed
    ),
    class = "nof1_power"
  )
}

#' @export
print.nof1_power <- function(x, ...) {
  label <- if (x$effect == 0) "False positive rate" else "Power"
  cat(sprintf("%s over %d days, effect %.2f SD, phi %.2f, alpha %.2f\n",
              label, x$n_days, x$effect / x$sd, x$phi, x$alpha))
  cat(sprintf("  AR(1) model : %.3f\n", x$power))
  cat(sprintf("  OLS         : %.3f\n", x$power_ols))
  if (x$phi > 0 && !is.na(x$power)) {
    gap <- x$power_ols - x$power
    if (abs(gap) >= 0.02) {
      dir <- if (gap < 0) "conservative" else "anti-conservative"
      cat(sprintf("  Ignoring the dependence is %s here by %.3f.\n",
                  dir, abs(gap)))
    }
  }
  if (x$n_failed > 0) {
    cat(sprintf("  %d of %d AR(1) fits did not converge and were dropped\n",
                x$n_failed, x$n_sims))
  }
  invisible(x)
}
