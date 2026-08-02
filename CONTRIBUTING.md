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
