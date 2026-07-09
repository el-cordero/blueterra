# CRAN comments

## Test environments

* Local macOS, R 4.5.3

## R CMD check results

0 errors | 0 warnings | 3 notes

The notes are:

* New submission.
* Local time verification was unavailable in this environment.
* Local HTML manual validation skipped because the installed system `tidy`
  executable is older than the version required by current R checks.

`devtools::check(args = "--as-cran")` completed with 0 errors, 0 warnings, and
1 environmental note about local time verification.

The built source package `blueterra_0.1.0.tar.gz` was 1,748,702 bytes
(1.749 MB), below the 9 MB package-size limit used for this release check.

## Data note

Examples, tests, and vignettes use reduced La Parguera bathymetry rasters and
sampling rectangles bundled under `inst/extdata`. Synthetic fixtures are kept
only for small numerical tests.
