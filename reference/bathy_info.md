# Summarize a bathymetric or elevation raster

Returns a compact table describing raster dimensions, extent, CRS,
resolution, layer names, and value range.

## Usage

``` r
bathy_info(x)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

## Value

A tibble with one row per raster layer.

## See also

[`validate_bathy()`](https://el-cordero.github.io/blueterra/reference/validate_bathy.md),
[`check_bathy_crs()`](https://el-cordero.github.io/blueterra/reference/check_bathy_crs.md)

## Examples

``` r
bathy_info(blueterra_example("bathy"))
#> # A tibble: 1 × 13
#>   layer    nrow  ncol ncell    xmin   xmax   ymin   ymax  xres  yres   min   max
#>   <chr>   <dbl> <dbl> <dbl>   <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 bathy_m    90   190 17100 134960. 1.39e5 2.04e5 2.06e5  20.0  20.0 -427. -15.9
#> # ℹ 1 more variable: crs <chr>
```
