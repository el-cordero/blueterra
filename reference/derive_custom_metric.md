# Derive a custom metric from raster layers

Creates a single custom metric layer from an expression or a
user-supplied R function.

## Usage

``` r
derive_custom_metric(
  metrics,
  name,
  expression = NULL,
  fun = NULL,
  ...,
  overwrite = FALSE
)
```

## Arguments

- metrics:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  metric stack.

- name:

  Output layer name.

- expression:

  Optional quoted R expression evaluated with raster layers available by
  name.

- fun:

  Optional function called as `fun(metrics, ...)`. The function must
  return a single-layer
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

- ...:

  Additional arguments passed to `fun`.

- overwrite:

  Logical. Allow `name` to match an existing layer in `metrics`.

## Value

A single-layer
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
named `name`.

## Details

Expressions must be quoted, for example
`quote(slope_deg * rugosity_vrm_3x3)`. Character strings are not
evaluated. This keeps the workflow explicit and avoids treating text as
code.

## See also

[`add_metric_layers()`](https://el-cordero.github.io/blueterra/reference/add_metric_layers.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
metrics <- derive_terrain(bathy, metrics = c("slope", "tri", "bpi"))
derive_custom_metric(metrics, "slope_tri_index", expression = quote(slope_deg * tri))
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        : slope_tri_index
#> min value   :        0.007697
#> max value   :     3577.811514

relief <- derive_custom_metric(metrics, "relief_index", fun = function(r) {
  out <- r[["tri"]] + abs(r[["bpi_3x3"]])
  names(out) <- "relief_index"
  out
})
relief
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        : relief_index
#> min value   :     0.155394
#> max value   :    72.388597
```
