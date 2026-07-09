# Build a stack of terrain metrics

Computes selected metrics and returns them as a named raster stack.

## Usage

``` r
derive_metric_stack(
  x,
  metrics = "default",
  scales = NULL,
  units = c("degrees", "radians"),
  neighbors = 8,
  positive_depth = NULL,
  filename = "",
  overwrite = FALSE,
  progress = TRUE
)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- metrics:

  Character vector of metrics, or `"default"`.

- scales:

  Optional BPI/TPI window sizes used when multiscale BPI is requested.

- units:

  Slope and aspect units, `"degrees"` or `"radians"`.

- neighbors:

  Neighborhood passed to
  [`terra::terrain()`](https://rspatial.github.io/terra/reference/terrain.html).

- positive_depth:

  Optional logical documenting the input sign convention. Metric values
  are not sign-flipped unless a specific function says so.

- filename:

  Optional output raster path.

- overwrite:

  Logical. Allow overwriting `filename`.

- progress:

  Logical. Reserved for long-running workflows.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

`"default"` currently expands to bathymetry, slope, aspect, northness,
eastness, hillshade, roughness, TRI, TPI, fine BPI, broad BPI,
curvature, and surface-area ratio. All metrics are derived locally from
the supplied raster.

## See also

[`derive_terrain()`](https://el-cordero.github.io/blueterra/reference/derive_terrain.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
derive_metric_stack(bathy, metrics = "default")
#> class       : SpatRaster
#> size        : 90, 190, 13  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> sources     : laparguera_slope_bathy.tif
#>               memory (12 layers)
#> varnames    : laparguera_slope_bathy
#>               laparguera_slope_bathy
#>               laparguera_slope_bathy
#>               laparguera_slope_bathy
#>               laparguera_slope_bathy
#>               ...
#> names       :       bathy, slope_deg, aspect_deg, northness,  eastness, hillshade, ...
#> min values  : -427.298889,  0.053986,   1.268198,        -1, -0.999884, -0.402363, ...
#> max values  :  -15.878815, 71.446951, 359.559683,   0.99997,  0.999856,     0.749, ...
```
