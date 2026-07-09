# Estimate mean surface orientation from a bathymetric raster

Estimates the mean aspect direction of a raster surface and converts
that compass bearing to the line-angle convention used by
[`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md).

## Usage

``` r
estimate_surface_orientation(
  bathy,
  area = NULL,
  orientation_weight = c("slope", "none"),
  min_slope = 0,
  return = c("transect_angle", "bearing", "both")
)
```

## Arguments

- bathy:

  A single-layer bathymetric or elevation raster, or a raster input
  accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- area:

  Optional polygon area used to crop and mask `bathy` before estimating
  orientation.

- orientation_weight:

  Weighting method. `"slope"` weights aspect components by slope
  magnitude; `"none"` averages finite aspect cells equally.

- min_slope:

  Minimum slope in degrees retained when `orientation_weight = "slope"`.

- return:

  Return type: `"transect_angle"` for the mathematical line angle used
  by
  [`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md),
  `"bearing"` for the mean compass aspect, or `"both"` for a tibble
  containing both values and the number of cells used.

## Value

A numeric angle for `"transect_angle"` or `"bearing"`, or a tibble with
`bearing_deg`, `transect_angle_deg`, `orientation_weight`, `min_slope`,
and `n_orientation_cells` when `return = "both"`.

## Details

Aspect is treated as a compass bearing where northness is `cos(aspect)`
and eastness is `sin(aspect)`. Mean circular components are converted to
a compass bearing with `atan2(eastness, northness)`. Transect lines are
undirected, so the line angle is normalized to `[0, 180)`. A
south-facing mean aspect near 180 degrees therefore produces a transect
angle near 90 degrees.

## See also

[`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md),
[`derive_aspect()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md),
[`derive_slope()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("hitw"))
zones <- terra::vect(blueterra_example("zones"))
hitw <- zones[zones$site_id == "hitw", ]
estimate_surface_orientation(bathy, hitw)
#> [1] 94.69969
```
