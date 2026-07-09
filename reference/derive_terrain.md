# Derive bathymetric terrain metrics

Computes one or more terrain metrics from a user-supplied bathymetric or
elevation raster.

## Usage

``` r
derive_terrain(
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
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
containing named metric layers.

## Details

Terrain metrics are scale-sensitive. Slope, curvature, rugosity, TPI,
BPI, roughness, and surface-area style metrics depend on grid
resolution, smoothing, and focal-window size. Use projected coordinate
systems when distances or slopes are interpreted in real linear units.

## See also

[`derive_metric_stack()`](https://el-cordero.github.io/blueterra/reference/derive_metric_stack.md),
[`derive_bpi()`](https://el-cordero.github.io/blueterra/reference/derive_bpi.md),
[`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
terrain <- derive_terrain(bathy, metrics = c("slope", "aspect", "bpi"))
names(terrain)
#> [1] "slope_deg"  "aspect_deg" "bpi_3x3"    "bpi_11x11" 
```
