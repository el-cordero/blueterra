# Derive individual terrain metrics

Convenience wrappers around `terra` terrain functions and lightweight
geomorphometry formulas.

## Usage

``` r
derive_slope(
  x,
  units = c("degrees", "radians"),
  neighbors = 8,
  filename = "",
  overwrite = FALSE
)

derive_aspect(
  x,
  units = c("degrees", "radians"),
  neighbors = 8,
  filename = "",
  overwrite = FALSE
)

derive_northness(x, neighbors = 8, filename = "", overwrite = FALSE)

derive_eastness(x, neighbors = 8, filename = "", overwrite = FALSE)

derive_hillshade(
  x,
  angle = 45,
  direction = 315,
  neighbors = 8,
  filename = "",
  overwrite = FALSE
)

derive_roughness(x, filename = "", overwrite = FALSE)

derive_tri(x, filename = "", overwrite = FALSE)

derive_tpi(x, filename = "", overwrite = FALSE)

derive_rugosity(x, window = 3, neighbors = 8, filename = "", overwrite = FALSE)

derive_curvature(x, filename = "", overwrite = FALSE)

derive_surface_area_ratio(x, neighbors = 8, filename = "", overwrite = FALSE)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- units:

  Units for slope or aspect: `"degrees"` or `"radians"`.

- neighbors:

  Neighborhood size passed to
  [`terra::terrain()`](https://rspatial.github.io/terra/reference/terrain.html).

- filename:

  Optional output raster path.

- overwrite:

  Logical. Allow overwriting `filename`.

- angle:

  Illumination angle for hillshade.

- direction:

  Illumination direction for hillshade.

- window:

  Odd integer focal-window size for local metrics.

## Value

A single-layer
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
except where documented otherwise.

## Details

Functions preserve the input raster sign. For example, slope depends on
the magnitude of local gradients, while BPI/TPI interpretation depends
on whether the raster stores elevation-like values or positive depth.

`derive_rugosity()` computes a vector-ruggedness-measure-style index
from local slope and aspect vectors. Its focal means use available
derivative cells, including partial focal support adjacent to a
derivative boundary or missing data, but the outermost cells can remain
missing because slope and aspect themselves require neighbouring
elevation values.

`derive_curvature()` computes a four-neighbor Laplacian-style index. It
is not plan, profile, mean, or Gaussian curvature, is not scaled by cell
dimensions, and is consequently strongly resolution-dependent.
`derive_surface_area_ratio()` is a slope-secant approximation,
`1 / cos(slope)`, rather than a triangulated or directly measured
benthic surface area. It clamps near-zero cosine values to avoid
pathological ratios at extreme slopes.

## See also

[`derive_terrain()`](https://el-cordero.github.io/blueterra/reference/derive_terrain.md),
[`derive_bpi()`](https://el-cordero.github.io/blueterra/reference/derive_bpi.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
derive_slope(bathy)
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        : slope_deg
#> min value   :  0.053986
#> max value   : 71.446951
derive_northness(bathy)
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        : northness
#> min value   :        -1
#> max value   :   0.99997
```
