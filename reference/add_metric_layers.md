# Add metric layers to an existing raster stack

Combines precomputed metric rasters with an existing metric stack after
checking grid geometry.

## Usage

``` r
add_metric_layers(
  metrics,
  ...,
  names = NULL,
  overwrite = FALSE,
  check_geometry = TRUE
)
```

## Arguments

- metrics:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  metric stack or raster input accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- ...:

  One or more
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  objects or local raster paths to add.

- names:

  Optional names for the added layers.

- overwrite:

  Logical. Allow added layers to replace layers with matching names in
  `metrics`.

- check_geometry:

  Logical. Require matching CRS, extent, resolution, dimensions, and
  origin.

## Value

A combined
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

Custom metrics must be on the same raster grid as the stack they extend.
Geometry checks are enabled by default because summaries, PCA tables,
and process-group assignments assume cell-aligned layers.

## See also

[`derive_custom_metric()`](https://el-cordero.github.io/blueterra/reference/derive_custom_metric.md),
[`create_metric_catalog()`](https://el-cordero.github.io/blueterra/reference/create_metric_catalog.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
metrics <- derive_terrain(bathy, metrics = c("slope", "tri"))
index <- derive_custom_metric(metrics, "slope_tri_index", expression = quote(slope_deg * tri))
add_metric_layers(metrics, index)
#> class       : SpatRaster
#> size        : 90, 190, 3  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varnames    : laparguera_slope_bathy
#>               laparguera_slope_bathy
#>               laparguera_slope_bathy
#> names       : slope_deg,       tri, slope_tri_index
#> min values  :  0.053986,   0.08645,        0.007697
#> max values  : 71.446951, 50.076476,     3577.811514
```
