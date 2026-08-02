test_that("power is between 0 and 1 and rises with effect size", {
  small <- sim_power(n_days = 60, effect = 0.2, n_sims = 60, seed = 1)
  large <- sim_power(n_days = 60, effect = 1.0, n_sims = 60, seed = 1)
  expect_gte(small$power, 0); expect_lte(small$power, 1)
  expect_gt(large$power, small$power)
})

test_that("power rises with study length", {
  short <- sim_power(n_days = 30,  effect = 0.5, n_sims = 60, seed = 2)
  long  <- sim_power(n_days = 120, effect = 0.5, n_sims = 60, seed = 2)
  expect_gt(long$power, short$power)
})

test_that("with no effect the rate is near alpha, not near power", {
  null <- sim_power(n_days = 70, effect = 0, phi = 0, n_sims = 200, seed = 3)
  expect_lt(null$power, 0.15)
})

test_that("randomized schedules keep the false positive rate controlled", {
  # The key protective property: alternation keeps a drifting error from
  # masquerading as an effect.
  null <- sim_power(n_days = 70, effect = 0, phi = 0.7, n_sims = 150, seed = 4)
  expect_lt(null$power_ols, 0.10)
})

test_that("a block design inflates the false positive rate under drift", {
  ab <- sim_power(n_days = 70, effect = 0, phi = 0.7, n_sims = 150, seed = 5,
                  schedule = rep(c(0, 1), each = 35))
  expect_gt(ab$power_ols, 0.20)
})

test_that("phi outside [0, 1) is rejected", {
  expect_error(sim_power(phi = 1), "phi")
  expect_error(sim_power(phi = -0.1), "phi")
})

test_that("a schedule of the wrong length is rejected", {
  expect_error(sim_power(n_days = 70, schedule = c(0, 1)), "length")
})

test_that("the same seed reproduces the same estimate", {
  a <- sim_power(n_days = 50, effect = 0.5, n_sims = 40, seed = 99)
  b <- sim_power(n_days = 50, effect = 0.5, n_sims = 40, seed = 99)
  expect_equal(a$power, b$power)
})
