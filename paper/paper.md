---
title: 'nof1kit: Design, monitoring, and quality control for single-case (N-of-1) intensive longitudinal studies in R'
tags:
  - R
  - single-case designs
  - N-of-1 trials
  - ecological momentary assessment
  - randomization
  - research infrastructure
authors:
  - name: Miura Meng
    orcid: 0009-0004-1522-1997
    affiliation: 1
affiliations:
  - name: Graduate School of Education, University of Pennsylvania, United States
    index: 1
date: 2 August 2026
bibliography: paper.bib
---

# Summary

Single-case (N-of-1) designs answer a question that group studies cannot:
whether a treatment works for *this* person [@molenaar2004; @kravitz2014].
A typical modern N-of-1 study randomizes an intervention across days under
design constraints, collects intensive longitudinal data on a phone through
ecological momentary assessment (EMA) [@shiffman2008], and analyzes the
resulting time series.

`nof1kit` provides the infrastructure for the stages of that lifecycle that
come before analysis: generating preregistrable randomization schedules under
run-length constraints, estimating the power of a design by simulation,
handing the schedule to a mobile collection layer, validating the records that
come back, and computing compliance against the scheduled prompts. The package
ships with the complete dataset of a 70-day randomized N-of-1 study, and its
vignette runs the full lifecycle on those data.

# Statement of need

R serves the analysis of single-case data well, through packages such as
`scan` [@scan] and `SingleCaseES` [@singlecasees], and intensive longitudinal
models are well covered by the mixed-model ecosystem. Everything upstream of
analysis, however, is usually hand-rolled per study: a script that shuffles
conditions until a sequence "looks right", a spreadsheet mapping days to
assignments, an ad hoc compliance figure. Errors introduced there are the kind
that survive to publication, because nothing checks for them. Three examples,
each of which `nof1kit` addresses and demonstrates on its bundled data:

**Randomization that is not what the preregistration says.** Restricted
randomization is standard in N-of-1 designs, since long runs of one condition
confound treatment with time [@edgington1980]. But the constrained sequences
are hard to sample: for a balanced 70-day two-condition design with runs
capped at two, fewer than one permutation in a million is admissible, so
rejection sampling is unworkable and ad hoc fixes (regenerate until it fits,
alternate blocks) quietly change the design's distribution.
`design_schedule()` samples exactly, counting valid completions from each
state by dynamic programming and drawing forward in proportion, which makes
the draw uniform over all admissible sequences. "Randomized" in the
preregistration then means exactly that, and the required seed makes the
schedule reproducible from the preregistration text alone.

**Compliance figures that answer a different question than they imply.** EMA
compliance is commonly reported as records divided by scheduled prompts. That
definition lets one prompt answered three times count as three, and lets a
late entry stand in for the prompt it missed. `compliance()` instead counts
the proportion of scheduled prompts answered within a response window; extra
and off-window records are reported separately rather than discarded. On the
bundled study the two definitions disagree by about three percentage points
(92.9% versus 90.0%). Neither is wrong, but they answer different questions,
and a reader given one number cannot tell which.

**Inference whose validity depends on the schedule.** Daily observations from
one person are autocorrelated, and the consequence of ignoring that is not a
fixed bias. `sim_power()` simulates studies under a chosen design and analyzes
each one with and without an AR(1) error structure. Under the rapidly
alternating schedules the package generates, ignoring the dependence is
conservative. Under a design that runs control for the first half of the study
and treatment for the second, simulation at lag-1 autocorrelation 0.7 shows
ordinary least squares rejecting a true null roughly 40% of the time at a
nominal 5% level, because a slowly changing schedule is nearly collinear with
a slowly drifting error. The run-length constraint is usually justified as
avoiding confounding with time; the simulations show it is also what keeps
inference under dependence honest, and they let researchers quantify that for
their own design before committing to it.

Data quality checks follow the same philosophy of returning evidence rather
than verdicts. `validate_ema()` reports out-of-range values, duplicate
timestamps, missing required fields, and, notably, day indices that have
drifted out of step with the calendar, a defect present in the bundled
real-world dataset that is invisible to range checks and only surfaces when
the index is compared against the timestamps.

# Interoperability

Schedules export as plain JSON mapping study day to condition, the format read
by the package's companion mobile collection tools (an iOS Shortcuts pipeline
and a native SwiftUI application, both open source). Generation and execution
are deliberately separated: the collection instrument cannot rewrite the
randomization it administers. Reporting follows the spirit of the CENT
extension for N-of-1 trials [@vohra2015], which calls for explicit
documentation of randomization, protocol deviations, and adherence.

# Acknowledgements

The bundled dataset was collected by the author as a self-experiment; no
external funding supported this work.

# References
