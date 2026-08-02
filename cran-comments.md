# Resubmission

This is a resubmission. The automatic pre-test flagged two issues, both fixed:

* README.md linked to CONTRIBUTING.md and LICENSE.md, which are not shipped
  in the tarball. Those links now point to the files on GitHub.
* The sim_power() examples exceeded the time limit on the check machines.
  They now run 40 simulations instead of 100 (with a comment pointing users
  at the default of 500 for real planning runs).

The word flagged in the DESCRIPTION, EMA, is the standard acronym for
ecological momentary assessment and is expanded in the text.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release, so the incoming feasibility check reports
  "New submission". No other notes.

## Test environments

* local: macOS (aarch64), R 4.5.2
* GitHub Actions: ubuntu-latest (devel, release, oldrel-1),
  windows-latest (release), macos-latest (release)
