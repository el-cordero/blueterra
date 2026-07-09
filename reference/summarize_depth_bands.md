# Summarize terrain by depth bands

Groups raster cells into depth or elevation bands and summarizes metric
values within each band.

## Usage

``` r
summarize_depth_bands(
  bathy,
  metrics = NULL,
  breaks,
  positive_depth = NULL,
  fun = c("mean", "sd", "min", "max", "median"),
  na.rm = TRUE
)
```

## Arguments

- bathy:

  A bathymetric or elevation raster.

- metrics:

  Optional metric raster stack. If `NULL`, `bathy` is summarized.

- breaks:

  Numeric band breaks.

- positive_depth:

  Optional logical. If `TRUE`, bands are applied to absolute depth. If
  `FALSE` or `NULL`, bands are applied to stored values.

- fun:

  Summary functions.

- na.rm:

  Logical. Remove missing values.

## Value

A tibble with one row per depth band and metric.

## Details

Depth bands are sensitive to vertical sign convention. For
negative-elevation bathymetry, use negative breaks or set
`positive_depth = TRUE` with positive depth breaks.

## See also

[`depth_filter()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md),
[`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
summarize_depth_bands(bathy, breaks = c(-90, -60, -30, 0))
#> # A tibble: 3 × 8
#>   depth_band metric  n_cells  mean    sd   min   max median
#>   <chr>      <chr>     <int> <dbl> <dbl> <dbl> <dbl>  <dbl>
#> 1 [-90,-60)  bathy_m     523 -76.7  8.81 -89.9 -60.0  -78.5
#> 2 [-60,-30)  bathy_m     400 -43.7  8.58 -60.0 -30.0  -43.0
#> 3 [-30,0]    bathy_m    1733 -20.2  2.96 -30.0 -15.9  -19.6
```
