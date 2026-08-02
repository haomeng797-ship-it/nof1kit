# Simulation-based power for an N-of-1 design

Estimates the power to detect a treatment effect in a single-case design
by simulating studies of the given length, analyzing each one, and
recording how often the effect is detected.

## Usage

``` r
sim_power(
  n_days = 70,
  effect = 0.5,
  sd = 1,
  phi = 0,
  max_run = 2L,
  alpha = 0.05,
  n_sims = 500L,
  schedule = NULL,
  seed = NULL
)
```

## Arguments

- n_days:

  Study length in days.

- effect:

  True treatment effect, in the same units as `sd`. Use 0 to estimate
  the false positive rate.

- sd:

  Residual standard deviation of the outcome (its marginal SD, not the
  innovation SD).

- phi:

  Lag-1 autocorrelation of the errors, in `[0, 1)`. Daily mood and
  affect measures commonly fall between 0.2 and 0.5.

- max_run:

  Maximum run of identical consecutive conditions in the generated
  schedules.

- alpha:

  Significance level.

- n_sims:

  Number of simulated studies.

- schedule:

  Optional fixed condition vector (0/1) of length `n_days`. When given,
  every simulation uses it instead of drawing a new one.

- seed:

  Optional seed for reproducibility.

## Value

An object of class `nof1_power`: a list with `power`, `power_ols`,
`n_days`, `effect`, `phi`, `alpha`, `n_sims`, and `n_failed`
(simulations where the AR(1) fit did not converge and were dropped).

## Details

Closed-form power formulas assume independent observations. Daily
measurements from one person are not independent: today's mood is
correlated with yesterday's. Positive autocorrelation means each new day
carries less information than a genuinely new observation would, so the
effective sample size is smaller than the number of days.

This function therefore analyses each simulated study two ways, and
reports both. `power` comes from a model with AR(1) errors, which
accounts for the dependence. `power_ols` comes from ordinary least
squares, which ignores it.

The direction in which OLS goes wrong depends on the schedule, which is
why design and analysis cannot be chosen separately. Under the rapidly
alternating schedules that
[`design_schedule()`](https://haomeng797-ship-it.github.io/nof1kit/reference/design_schedule.md)
produces, a slowly drifting AR(1) error is nearly orthogonal to the
condition sequence: the drift cancels across adjacent days, the true
variance of the effect estimate is smaller than independence implies,
and OLS is therefore conservative. It loses power but does not produce
false positives.

Under a schedule that changes slowly, the opposite happens. A design
that runs control for the first half and treatment for the second is
nearly collinear with any drift, so autocorrelation is readily mistaken
for an effect. In simulations at `phi = 0.7`, such a design rejects a
true null about 40 percent of the time at a nominal 5 percent level.
Pass `schedule` to see this for a sequence you are considering.

Set `effect = 0` to get the false positive rate instead of power.

Each simulated study gets a freshly drawn randomization schedule under
the same run constraint, so the estimate reflects the design rather than
one particular sequence. Supply `schedule` to hold the sequence fixed
instead.

## Examples

``` r
# Power to detect a half-SD effect over 70 days, with moderate autocorrelation
sim_power(n_days = 70, effect = 0.5, phi = 0.3, n_sims = 100, seed = 1)
#> Power over 70 days, effect 0.50 SD, phi 0.30, alpha 0.05
#>   AR(1) model : 0.680
#>   OLS         : 0.510
#>   Ignoring the dependence is conservative here by 0.170.

# With no effect, `power` is the false positive rate
sim_power(n_days = 70, effect = 0, phi = 0.5, n_sims = 100, seed = 1)
#> False positive rate over 70 days, effect 0.00 SD, phi 0.50, alpha 0.05
#>   AR(1) model : 0.080
#>   OLS         : 0.000
#>   Ignoring the dependence is conservative here by 0.080.
```
