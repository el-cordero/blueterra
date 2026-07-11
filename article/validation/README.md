# Numerical and functional verification

These scripts load the repository source with `pkgload::load_all()` and write
machine-readable results to `article/validation/results/`. They test software
behavior, not physical-process, ecological, or survey-quality validity.

Run from the package root:

```r
Rscript article/validation/run_analytical_validation.R
Rscript article/validation/run_wrapper_agreement.R
Rscript article/validation/run_functional_verification.R
```

The suite records 28 analytical checks, 22 direct upstream-wrapper comparisons,
and 21 synthetic functional checks. The first script uses projected synthetic
surfaces with 1 m cells and tolerances tied to the reference magnitude and
floating-point scale. The second reconstructs the same `terra` calls used by
the wrappers, so those comparisons are upstream-call agreement rather than
independent cross-implementation validation. The third script tests the
blueterra-specific spatial products.

## Coverage

- Planar slope, aspect, northness, eastness, roughness, TRI, TPI, and
  slope-secant surface-area behavior;
- square and annular BPI, including focal-cell inclusion, non-square-cell
  annulus geometry, projected-CRS protection, partial focal support, and
  zero-variance normalized `NA` behavior;
- VRM-style rugosity and the unscaled four-neighbor Laplacian-style index;
- known polygon and depth-band summaries, including exact
  coverage-fraction-weighted summaries;
- transect direction, spacing, clipping, count, and orientation-resultant
  metadata;
- synthetic isobath location, corridor geometry, nominal width, and
  independent-overlap behavior; and
- custom-layer geometry rejection and unmatched metric-catalog behavior.

## Edge and missing-value policy

`terra::terrain()` derivatives have an outer missing ring on complete rasters.
The four-neighbor Laplacian-style index inherits the same focal-support limit.
BPI uses available valid cells in partial focal windows; a missing focal cell
remains missing. VRM-style rugosity can also use partial normal-vector support,
but slope/aspect derivative boundaries can remain unavailable. These policies
are recorded in the row-level validation outputs.

Generated CSV and RDS files retain evaluated domains, edge treatment,
missing-value behavior, reference expectation, maximum error, tolerance, and
pass/fail status. The clean-environment tag audit is separate under
`article/reproducibility/`.
