# Extract terrain cells in isobath corridors

Extracts raster cell values under corridor polygons.

## Usage

``` r
extract_isobath_corridors(metrics, corridors, ...)
```

## Arguments

- metrics:

  A metric raster stack.

- corridors:

  Corridor polygons from
  [`make_isobath_corridors()`](https://el-cordero.github.io/blueterra/reference/make_isobath_corridors.md)
  or another polygon source.

- ...:

  Additional arguments passed to
  [`terra::extract()`](https://rspatial.github.io/terra/reference/extract.html).

## Value

A tibble with corridor identifiers and extracted raster values.

## See also

[`summarize_isobath_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_isobath_terrain.md),
[`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
corridors <- make_isobath_corridors(bathy, depths = -50, width = 5)
extract_isobath_corridors(terrain, corridors)
#> # A tibble: 84 × 8
#>       ID level contour_value depth_label corridor_id slope_deg bpi_3x3 bpi_11x11
#>    <int> <dbl>         <dbl>       <dbl>       <int>     <dbl>   <dbl>     <dbl>
#>  1     1   -50           -50         -50           1      47.5  -3.02       17.2
#>  2     1   -50           -50         -50           1      48.0  -1.54       19.5
#>  3     1   -50           -50         -50           1      48.0  -2.90       25.0
#>  4     1   -50           -50         -50           1      45.9  -1.01       25.7
#>  5     1   -50           -50         -50           1      46.0  -0.596      25.8
#>  6     1   -50           -50         -50           1      48.0  -0.940      26.1
#>  7     1   -50           -50         -50           1      46.2   1.64       31.1
#>  8     1   -50           -50         -50           1      43.9  -0.331      29.8
#>  9     1   -50           -50         -50           1      44.3  -0.943      27.5
#> 10     1   -50           -50         -50           1      44.2  -0.577      26.7
#> # ℹ 74 more rows
```
