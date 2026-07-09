# CRAN comments

## Test environments

* Local macOS, R 4.5.3

## R CMD check results

0 errors | 0 warnings | 2 notes

The notes are:

* New submission.
* Local HTML manual validation skipped because the installed system `tidy`
  executable is older than the version required by current R checks.

`devtools::check(args = "--as-cran")` completed with 0 errors, 0 warnings, and
0 notes in the local development environment.

## Data note

Examples, tests, and vignettes use small synthetic raster and polygon data
bundled under `inst/extdata`.
