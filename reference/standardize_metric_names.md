# Standardize or rename metric layers

Converts metric names to stable snake-case names or applies a
user-supplied dictionary.

## Usage

``` r
standardize_metric_names(x)

rename_metric_layers(x, dictionary = NULL)
```

## Arguments

- x:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
  character vector, or data frame.

- dictionary:

  Optional named character vector. Names are old metric names; values
  are new metric names.

## Value

An object of the same broad type as `x`.

## Details

Standardization is conservative and does not change raster values. Use
this helper to make layer names predictable before joining to the metric
catalog or exporting model-ready tables.

## See also

[`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md)

## Examples

``` r
standardize_metric_names(c("Slope (deg)", "Broad BPI"))
#> [1] "slope_deg" "broad_bpi"
```
