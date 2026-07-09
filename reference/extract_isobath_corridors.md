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
corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
extract_isobath_corridors(terrain, corridors)
#> # A tibble: 418 × 8
#>       ID level contour_value depth_label corridor_id slope_deg bpi_3x3 bpi_11x11
#>    <int> <dbl>         <dbl>       <dbl>       <int>     <dbl>   <dbl>     <dbl>
#>  1     1   -50           -50         -50           1      41.0  2.98        29.7
#>  2     1   -50           -50         -50           1      45.2 -1.51        20.7
#>  3     1   -50           -50         -50           1      47.5 -3.02        17.2
#>  4     1   -50           -50         -50           1      48.0 -1.54        19.5
#>  5     1   -50           -50         -50           1      46.5 -0.0849      23.5
#>  6     1   -50           -50         -50           1      45.3  1.59        27.5
#>  7     1   -50           -50         -50           1      45.3  0.568       26.4
#>  8     1   -50           -50         -50           1      45.6 -0.421       24.4
#>  9     1   -50           -50         -50           1      45.4  0.855       24.8
#> 10     1   -50           -50         -50           1      45.1  4.15        27.7
#> # ℹ 408 more rows
```
