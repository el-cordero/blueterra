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
#> # A tibble: 84 × 12
#>       ID level contour_value depth_label corridor_id buffer_distance
#>    <int> <dbl>         <dbl>       <dbl>       <int>           <dbl>
#>  1     1   -50           -50         -50           1               5
#>  2     1   -50           -50         -50           1               5
#>  3     1   -50           -50         -50           1               5
#>  4     1   -50           -50         -50           1               5
#>  5     1   -50           -50         -50           1               5
#>  6     1   -50           -50         -50           1               5
#>  7     1   -50           -50         -50           1               5
#>  8     1   -50           -50         -50           1               5
#>  9     1   -50           -50         -50           1               5
#> 10     1   -50           -50         -50           1               5
#> # ℹ 74 more rows
#> # ℹ 6 more variables: nominal_corridor_width <dbl>, overlap_policy <chr>,
#> #   zone_id <int>, slope_deg <dbl>, bpi_3x3 <dbl>, bpi_11x11 <dbl>
```
