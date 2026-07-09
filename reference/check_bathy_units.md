# Check bathymetry value conventions

Summarizes raster value ranges and records the intended depth convention
when supplied by the user.

## Usage

``` r
check_bathy_units(x, units = NULL, positive_depth = NULL)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- units:

  Optional character label for vertical units, such as `"m"`.

- positive_depth:

  Optional logical. Use `TRUE` when larger positive values mean deeper
  water, `FALSE` when bathymetry is stored as negative elevation, or
  `NULL` when unknown.

## Value

A tibble with value range and convention fields.

## Details

This function does not infer or alter scientific meaning. It reports the
observed range and the user-supplied convention so downstream workflows
can be explicit.

## See also

[`set_depth_positive()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md),
[`set_depth_negative()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md)

## Examples

``` r
check_bathy_units(blueterra_example("bathy"), units = "m", positive_depth = FALSE)
#> # A tibble: 1 × 5
#>   layer     min   max units positive_depth
#>   <chr>   <dbl> <dbl> <chr> <lgl>         
#> 1 bathy_m -427. -15.9 m     FALSE         
```
