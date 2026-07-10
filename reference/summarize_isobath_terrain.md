# Summarize terrain by isobath corridor

Computes summary statistics for metric rasters inside corridor polygons.

## Usage

``` r
summarize_isobath_terrain(
  metrics,
  corridors,
  fun = c("mean", "sd", "min", "max", "median"),
  na.rm = TRUE,
  exact = FALSE,
  ...
)
```

## Arguments

- metrics:

  A metric raster stack.

- corridors:

  Corridor polygons.

- fun:

  Summary functions.

- na.rm:

  Logical. Remove missing values.

- exact:

  Logical. Use `exactextractr` when available.

- ...:

  Additional arguments passed to
  [`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md).

## Value

A tibble with one row per corridor.

## See also

[`make_isobath_corridors()`](https://el-cordero.github.io/blueterra/reference/make_isobath_corridors.md),
[`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
corridors <- make_isobath_corridors(bathy, depths = -50, width = 5)
summarize_isobath_terrain(terrain, corridors)
#> # A tibble: 1 × 20
#>   level contour_value depth_label corridor_id zone_id slope_deg_mean
#>   <dbl>         <dbl>       <dbl>       <int>   <int>          <dbl>
#> 1   -50           -50         -50           1       1           38.2
#> # ℹ 14 more variables: slope_deg_sd <dbl>, slope_deg_min <dbl>,
#> #   slope_deg_max <dbl>, slope_deg_median <dbl>, bpi_3x3_mean <dbl>,
#> #   bpi_3x3_sd <dbl>, bpi_3x3_min <dbl>, bpi_3x3_max <dbl>,
#> #   bpi_3x3_median <dbl>, bpi_11x11_mean <dbl>, bpi_11x11_sd <dbl>,
#> #   bpi_11x11_min <dbl>, bpi_11x11_max <dbl>, bpi_11x11_median <dbl>
```
