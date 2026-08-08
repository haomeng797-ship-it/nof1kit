# Contributing to nof1kit

Contributions are welcome, including bug reports, feature suggestions,
and pull requests.

## Reporting a bug

Open an issue at <https://github.com/haomeng797-ship-it/nof1kit/issues>.
The most useful reports include a small reproducible example, the output
of [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html), and what
you expected to happen instead.

## Suggesting a feature

Open an issue describing the study design or workflow you are trying to
support. Concrete cases are more useful than abstract requests: the
package is meant to cover things people actually do in single-case
research.

## Pull requests

1.  Fork the repository and create a branch.
2.  Add a test in `tests/testthat/` covering the change. Every exported
    function has tests; new behaviour should too.
3.  Run `devtools::test()` and `devtools::check()` locally.
4.  Document exported functions with roxygen2 and run
    `devtools::document()`.
5.  Open the pull request describing what changed and why.

Code follows the tidyverse style guide, with one deliberate exception:
base R is preferred over dependencies unless a dependency earns its
place. Keeping the dependency footprint small matters for a package
meant to be installed on whatever machine a study happens to run on.

## Questions

Open an issue with the question label. There is no separate mailing
list.

## Code of conduct

Participation is governed by the [Contributor
Covenant](https://haomeng797-ship-it.github.io/nof1kit/CODE_OF_CONDUCT.md).

## Life cycle

nof1kit is stable and maintained. The seven exported functions and their
arguments are considered settled: the file formats they read and write
are shared with a mobile collection layer, so breaking them would break
studies already in the field. Future work is expected to be additive,
for example further quality checks in
[`validate_ema()`](https://haomeng797-ship-it.github.io/nof1kit/reference/validate_ema.md)
or further error structures in
[`sim_power()`](https://haomeng797-ship-it.github.io/nof1kit/reference/sim_power.md).
Bug reports and feature requests are welcome on the issue tracker.
