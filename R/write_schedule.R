#' Export a schedule for the mobile data-collection layer
#'
#' Writes a schedule as JSON in the exact `{"1": 0, "2": 1, ...}` format
#' consumed by the companion iOS Shortcuts EMA logger
#' (<https://github.com/haomeng797-ship-it/melatonin-ema-logger>), so a
#' generated design can be dropped straight into an existing collection
#' pipeline.
#'
#' @param schedule A `nof1_schedule` from [design_schedule()].
#' @param path File path for the JSON output, e.g. `"schedule.json"`.
#'
#' @return The path, invisibly.
#'
#' @examples
#' sched <- design_schedule(n_days = 70, seed = 20260218)
#' tmp <- tempfile(fileext = ".json")
#' write_schedule(sched, tmp)
#'
#' @export
write_schedule <- function(schedule, path) {
  x <- as.list(stats::setNames(schedule$condition,
                               as.character(schedule$day)))
  jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = FALSE)
  invisible(path)
}
