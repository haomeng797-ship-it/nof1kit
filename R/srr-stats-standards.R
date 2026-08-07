#' srr_stats
#'
#' rOpenSci statistical software standards for nof1kit.
#' Category: **EDA and Summary Statistics**, alongside the General Standards.
#'
#' nof1kit is design-and-quality-control software for single-case (N-of-1)
#' studies. Its statistical content sits in three places: exact uniform
#' sampling from the set of run-constrained balanced sequences, simulation
#' of the operating characteristics of a design under serially correlated
#' errors, and summary statistics on the records a study returns
#' (`check_schedule()`, `validate_ema()`, `compliance()`).
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstats {G1.0} Primary references are given in the `@references` sections
#'   of `design_schedule()` (Edgington 1980, on randomization tests for
#'   single-subject experiments) and in the package's JOSS paper, which also
#'   cites Kravitz & Duan (2014), Vohra et al. (2015, the CENT extension) and
#'   Shiffman et al. (2008) for the EMA measurement model.
#' @srrstats {G1.2} A Life Cycle Statement is given in `CONTRIBUTING.md`:
#'   the package is stable and maintained, the interface is considered
#'   settled, and future work is additive rather than breaking.
#' @srrstats {G1.3} Statistical terms used in the interface are defined where
#'   they appear: "run" and `max_run` in `design_schedule()`, lag-1
#'   autocorrelation and the distinction between innovation and marginal SD in
#'   `sim_power()`, and the prompt-level definition of compliance (as against
#'   records-over-prompts) in the Details of `compliance()`.
#' @srrstats {G1.4} All exported functions are documented with roxygen2.
#' @srrstats {G1.4a} Internal functions carry roxygen documentation ending in
#'   `@noRd`; see `sample_constrained()` and `parse_timestamp()`.
#' @srrstats {G1.5} The vignette runs the full lifecycle on the bundled study
#'   data and reproduces every quantitative claim made about the package,
#'   including the design-dependent behaviour of OLS under AR(1) errors.
#'
#' @srrstats {G2.1} Types are asserted before use: `compliance()` requires a
#'   data frame carrying `timestamp`, and `read_ema()` errors when the named
#'   timestamp column is absent rather than silently returning character data.
#' @srrstats {G2.1a} `@param` entries state the expected type of every input,
#'   including that `times` is character in `"HH:MM"` form and `ranges` is a
#'   named list of length-2 numeric vectors.
#' @srrstats {G2.2} Parameters that must be scalar (`n_days`, `max_run`,
#'   `seed`, `phi`, `window`) are used in scalar contexts and validated by the
#'   comparisons that guard them.
#' @srrstats {G2.4a} Condition indices and day numbers are produced with
#'   explicit `as.integer()`/`L` literals rather than being left as doubles.
#' @srrstats {G2.15} Aggregations over possibly-missing values pass `na.rm`
#'   explicitly (`sim_power()` when averaging rejection indicators,
#'   `compliance()` when locating the last observed timestamp).
#'
#' @srrstats {G3.0} No floating-point equality comparisons are made. Schedule
#'   conditions are compared as integers, and timestamp membership in a
#'   response window is a half-open interval comparison rather than equality.
#'
#' @srrstats {G4.0} `write_schedule()` writes to the path it is given and the
#'   documented examples use `tempfile(fileext = ".json")`; the JSON format is
#'   fixed by the mobile collection layer rather than inferred from a suffix.
#'
#' @srrstats {G5.0} Tests use the bundled 70-day study (`melatonin_ema.csv`),
#'   a real data set with known properties, in addition to constructed cases.
#' @srrstats {G5.1} That data set ships in `inst/extdata` and is reachable via
#'   `system.file()`, so users can rerun every test and example.
#' @srrstats {G5.2} Error and warning behaviour is tested explicitly in
#'   `test-print-and-edges.R`.
#' @srrstats {G5.2a} Each `stop()` and `warning()` message in the package is
#'   distinct in wording, so a test can identify which condition fired.
#' @srrstats {G5.2b} Tests trigger each condition and match on its message:
#'   the required-seed error, the `n_days`/`max_run` feasibility errors, the
#'   missing-file and unparseable-file errors, the unparseable-timestamp
#'   warning, and the `phi` and `schedule`-length errors of `sim_power()`.
#' @srrstats {G5.8} Edge conditions are tested.
#' @srrstats {G5.8b} Unsupported types: `read_ema()` on a file that does not
#'   parse into a table, and on a string no date parser can read, are both
#'   tested.
#'
#' @srrstats {EA1.0} The target audience is stated in the README and the
#'   vignette: researchers running single-case or N-of-1 studies who need the
#'   design and data-quality steps that come before analysis.
#' @srrstats {EA1.1} The kinds of data are documented as intensive
#'   longitudinal records from one participant, one row per prompt response,
#'   with a timestamp and any number of numeric or binary outcome columns.
#' @srrstats {EA1.2} The questions the software helps explore are stated in
#'   the README: whether a randomization is what the preregistration claims,
#'   what a design can detect, whether returned records are internally
#'   consistent, and what proportion of scheduled prompts were answered on
#'   time.
#' @srrstats {EA1.3} Each function's `@param` entries identify the input it
#'   accepts; `read_ema()` is the documented entry point that produces the
#'   data frame the others consume.
#' @srrstats {EA2.6} `read_ema()` preserves all columns it does not touch and
#'   passes vector data through regardless of additional attributes; only the
#'   timestamp column is converted.
#' @srrstats {EA4.0} Return types are stable: `read_ema()` returns a data
#'   frame, and the three summary functions return lists with fixed element
#'   names, classed for printing.
#' @srrstats {EA4.2} Every returned object has a `print` method giving a
#'   sensible default view; these are tested in `test-print-and-edges.R`.
#' @srrstats {EA6.0} Return values are tested for their characteristics.
#' @srrstats {EA6.0a} Classes are checked (`expect_s3_class()` on the POSIXct
#'   timestamp and on the returned objects).
#' @srrstats {EA6.0b} Dimensions of the returned tables are checked, including
#'   that `compliance()$prompts` has one row per scheduled prompt.
#' @srrstats {EA6.0c} Column names of returned tables are checked.
#' @srrstats {EA6.0e} Single-valued returns are compared with a tolerance.
#'
#' @noRd
NULL

#' NA_standards
#'
#' Standards that do not apply to this package, with reasons.
#'
#' @srrstatsNA {G1.6} No other R package implements these steps, so there is
#'   no alternative implementation to compare performance against. The nearest
#'   relatives (scan, SingleCaseES, SCDA) begin after the data are collected.
#' @srrstatsNA {G2.3, G2.3a, G2.3b} No parameter takes one of a fixed set of
#'   character values. The only character inputs are a column name, a file
#'   path, and clock times, none of which have an enumerable domain that
#'   `match.arg()` could restrict.
#' @srrstatsNA {G2.4b, G2.4c, G2.4d, G2.4e} The package performs no
#'   conversion to continuous, character or factor types. Its one conversion
#'   is character or factor to POSIXct, handled in `parse_timestamp()`.
#' @srrstatsNA {G2.5} No input is expected to be a factor, so questions of
#'   ordering do not arise. A factor timestamp column is coerced to character
#'   before parsing.
#' @srrstatsNA {G2.7} The package reads its own inputs from disk (CSV or JSON)
#'   or takes a plain data frame. Supporting further tabular classes would add
#'   dependencies without changing what the checks can do.
#' @srrstatsNA {G2.10, G2.11, G2.12} Only the timestamp column is extracted
#'   by name, and only for parsing. Other columns are carried through
#'   untouched, so list columns and columns with non-standard attributes are
#'   neither inspected nor modified.
#' @srrstatsNA {G2.14, G2.14a, G2.14b, G2.14c} Missing data are the object
#'   of measurement here rather than a nuisance to be configured away. An
#'   unanswered prompt is exactly what `compliance()` is counting, so
#'   discarding or imputing missing records would destroy the quantity the
#'   function exists to report.
#' @srrstatsNA {G2.16} No arithmetic in the package can produce `NaN` or
#'   infinite values from finite input; simulated series that fail to converge
#'   are counted in `n_failed` rather than propagated.
#' @srrstatsNA {G3.1, G3.1a} The package performs no covariance estimation.
#'   The AR(1) structure in `sim_power()` is a simulation parameter, and the
#'   fitting is delegated to `stats::arima()`.
#' @srrstatsNA {G5.3} Returned objects legitimately contain `NA`: the
#'   compliance rate is `NA` before the first prompt has occurred, and
#'   `read_ema()` returns `NA` timestamps for records it could not parse. Both
#'   are documented and tested as intended behaviour.
#' @srrstatsNA {G5.4a, G5.4b, G5.4c} There is no previous implementation of
#'   exact uniform sampling over this constrained set to test against. The
#'   substitute is testing the defining properties directly, which is stronger
#'   than agreement with a single reference implementation.
#' @srrstatsNA {G5.6, G5.6a, G5.6b} The package estimates no parameters from
#'   data. `sim_power()` reports rejection rates for a design, not estimates
#'   to be recovered.
#' @srrstatsNA {G5.7} Performance as data scale changes is not a property of
#'   this software: study length is fixed by the design, not by available data.
#' @srrstatsNA {G5.8d} There is no analogue of more columns than rows here.
#'   A single-case study has one participant by definition.
#' @srrstatsNA {G5.9, G5.9a, G5.9b} Stochastic behaviour is fully determined
#'   by an explicit seed, which `design_schedule()` requires. Results are not
#'   expected to be invariant across seeds; a different seed is a different
#'   schedule, which is the point.
#' @srrstatsNA {G5.10, G5.11, G5.11a, G5.12} The suite runs in well under
#'   a minute and needs no external assets, so there is nothing to move into
#'   an extended, flag-gated tier.
#' @srrstatsNA {EA2.0, EA2.1, EA2.2, EA2.2a, EA2.2b, EA2.3, EA2.4, EA2.5}
#'   The package performs no table joins or filter operations across
#'   tables, so there is no index-column system to maintain. Records are keyed
#'   by timestamp, and the one consistency check that involves two keys
#'   (`study_day` against the calendar) is exactly what `validate_ema()`
#'   reports rather than something it relies on.
#' @srrstatsNA {EA4.1} Numeric precision is fixed at the point of display
#'   rather than exposed as a parameter, because the returned objects carry
#'   full precision and only the print methods round.
#' @srrstatsNA {EA5.0, EA5.0a, EA5.0b, EA5.1, EA5.4, EA5.5, EA5.6, EA6.1}
#'   The package produces no graphical output. Plotting is left to
#'   the user's own tools, so questions of typeface, palette accessibility,
#'   axis units and graphical regression testing do not arise.
#' @srrstatsNA {EA5.3} The summaries returned are counts and proportions of
#'   scheduled prompts, not column-wise descriptions of a data set, so there
#'   is no per-column storage mode to report.
#' @srrstatsNA {EA6.0d} Returned tables contain only logical, integer,
#'   character and POSIXct columns, all created by the package itself, so
#'   there is no user-supplied column whose type needs asserting.
#'
#' @noRd
NULL
