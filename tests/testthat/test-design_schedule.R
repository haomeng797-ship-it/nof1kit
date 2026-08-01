test_that("schedule respects balance and run constraints", {
  s <- design_schedule(n_days = 70, max_run = 2, seed = 42)
  expect_s3_class(s, "nof1_schedule")
  expect_equal(nrow(s), 70)
  expect_equal(unname(as.vector(table(s$condition))), c(35, 35))
  expect_lte(max(rle(as.character(s$condition))$lengths), 2)
})

test_that("same seed reproduces the same schedule", {
  a <- design_schedule(n_days = 70, seed = 20260218)
  b <- design_schedule(n_days = 70, seed = 20260218)
  expect_identical(a$condition, b$condition)
})

test_that("odd n_days yields near-balance", {
  s <- design_schedule(n_days = 71, seed = 1)
  counts <- as.vector(table(s$condition))
  expect_lte(abs(diff(counts)), 1)
})

test_that("seed is required", {
  expect_error(design_schedule(n_days = 10), "seed")
})

test_that("impossible constraints error out", {
  # a single condition cannot satisfy any finite run cap
  expect_error(
    design_schedule(n_days = 3, conditions = 0L, max_run = 2L, seed = 7),
    "No schedule satisfies"
  )
})

test_that("max_run = 1 forces perfect alternation", {
  s <- design_schedule(n_days = 10, max_run = 1L, seed = 5)
  expect_equal(max(rle(as.character(s$condition))$lengths), 1)
})

test_that("check_schedule reports what design_schedule promised", {
  s <- design_schedule(n_days = 70, max_run = 2, seed = 42)
  chk <- check_schedule(s)
  expect_lte(chk$max_run, 2)
  expect_equal(sum(chk$counts), 70)
})

test_that("write_schedule round-trips through the logger JSON format", {
  s <- design_schedule(n_days = 10, seed = 3)
  tmp <- tempfile(fileext = ".json")
  write_schedule(s, tmp)
  back <- jsonlite::read_json(tmp)
  expect_equal(length(back), 10)
  expect_equal(unlist(back, use.names = FALSE), s$condition)
  expect_equal(names(back), as.character(1:10))
})
