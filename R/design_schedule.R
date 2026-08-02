#' Generate a randomized N-of-1 intervention schedule
#'
#' Produces a day-by-day condition sequence for a single-case experimental
#' study, under the restricted randomization commonly needed in N-of-1
#' designs: balanced condition counts and a cap on how many consecutive
#' days the same condition may repeat.
#'
#' @details
#' Sampling is exact, not by rejection. The number of valid completions
#' from every intermediate state (remaining counts, current run) is counted
#' by dynamic programming, and the sequence is then drawn day by day with
#' probability proportional to those counts. The result is a uniform draw
#' over the set of *all* schedules that satisfy the constraints, so no
#' valid schedule is more probable than any other.
#'
#' Naive rejection sampling is not workable here: for a balanced 70-day
#' two-condition design with `max_run = 2`, fewer than one permutation in a
#' million satisfies the run constraint.
#'
#' @param n_days Integer. Length of the study in days.
#' @param conditions Vector of condition labels. Defaults to `c(0L, 1L)`
#'   (control / treatment), matching the schedule format used by the
#'   companion iOS Shortcuts logger.
#' @param max_run Integer. Maximum allowed run of identical consecutive
#'   conditions. Defaults to 2.
#' @param seed Integer. Required. The seed makes the schedule reproducible
#'   and is intended to be reported in the preregistration.
#'
#' @return An object of class `nof1_schedule`: a data frame with columns
#'   `day` and `condition`, with the generating parameters stored as
#'   attributes.
#'
#' @examples
#' sched <- design_schedule(n_days = 70, max_run = 2, seed = 20260218)
#' head(sched)
#' check_schedule(sched)
#'
#' @export
design_schedule <- function(n_days,
                            conditions = c(0L, 1L),
                            max_run = 2L,
                            seed) {
  if (missing(seed)) {
    stop("`seed` is required: a preregistered schedule must be reproducible.",
         call. = FALSE)
  }
  if (n_days < length(conditions)) {
    stop("`n_days` must be at least the number of conditions.", call. = FALSE)
  }
  if (max_run < 1L) {
    stop("`max_run` must be at least 1.", call. = FALSE)
  }

  set.seed(seed)
  idx <- sample_constrained(n_days, length(conditions), max_run)

  out <- data.frame(day = seq_len(n_days), condition = conditions[idx])
  attr(out, "conditions") <- conditions
  attr(out, "max_run")    <- max_run
  attr(out, "seed")       <- seed
  class(out) <- c("nof1_schedule", class(out))
  out
}

#' Draw one balanced, run-constrained sequence of condition indices
#'
#' Exact uniform sampling over the constrained set, by counting valid
#' completions with dynamic programming and then sampling forward in
#' proportion to those counts. Does not touch the seed, so it is safe to call
#' inside a simulation loop.
#'
#' @param n_days Length of the sequence.
#' @param k Number of conditions.
#' @param max_run Maximum run of identical consecutive values.
#' @return Integer vector of condition indices in `1:k`.
#' @noRd
sample_constrained <- function(n_days, k, max_run) {
  counts <- rep(n_days %/% k, k) + (seq_len(k) <= n_days %% k)

  # Dynamic programming: n_valid(counts, last, run) = number of valid ways
  # to finish the sequence. Memoised on the state.
  memo <- new.env(hash = TRUE, parent = emptyenv())
  n_valid <- function(cnt, last, run) {
    if (sum(cnt) == 0L) return(1)
    key <- paste(c(cnt, last, run), collapse = ",")
    hit <- memo[[key]]
    if (!is.null(hit)) return(hit)
    total <- 0
    for (j in seq_len(k)) {
      if (cnt[j] == 0L) next
      if (j == last) {
        if (run < max_run) {
          nxt <- cnt; nxt[j] <- nxt[j] - 1L
          total <- total + n_valid(nxt, j, run + 1L)
        }
      } else {
        nxt <- cnt; nxt[j] <- nxt[j] - 1L
        total <- total + n_valid(nxt, j, 1L)
      }
    }
    memo[[key]] <- total
    total
  }

  if (n_valid(counts, 0L, 0L) == 0) {
    stop("No schedule satisfies these constraints. ",
         "Loosen `max_run` or change `conditions`.", call. = FALSE)
  }

  # Forward sampling, each day proportional to the number of valid
  # completions after that choice.
  seq_idx <- integer(n_days)
  cnt <- counts; last <- 0L; run <- 0L
  for (d in seq_len(n_days)) {
    w <- numeric(k)
    for (j in seq_len(k)) {
      if (cnt[j] == 0L) next
      if (j == last) {
        if (run < max_run) {
          nxt <- cnt; nxt[j] <- nxt[j] - 1L
          w[j] <- n_valid(nxt, j, run + 1L)
        }
      } else {
        nxt <- cnt; nxt[j] <- nxt[j] - 1L
        w[j] <- n_valid(nxt, j, 1L)
      }
    }
    j <- sample.int(k, 1L, prob = w)
    run  <- if (j == last) run + 1L else 1L
    last <- j
    cnt[j] <- cnt[j] - 1L
    seq_idx[d] <- j
  }
  seq_idx
}
