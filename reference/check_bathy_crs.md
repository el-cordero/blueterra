# Check raster CRS for geomorphometry

Reports whether a bathymetric or elevation raster has a CRS and whether
that CRS appears to be geographic longitude/latitude.

## Usage

``` r
check_bathy_crs(x, require_projected = FALSE, warn_lonlat = TRUE)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- require_projected:

  Logical. If `TRUE`, error when the CRS is missing or
  longitude/latitude.

- warn_lonlat:

  Logical. If `TRUE`, warn when the raster is lon/lat.

## Value

A tibble with CRS status fields.

## Details

Many terrain metrics can be calculated on any numeric grid, but metric
interpretation is usually strongest in projected coordinate systems with
linear units. Buffers, distances, slope, surface-area ratios, and focal
windows are all scale-sensitive.

## See also

[`prepare_bathy()`](https://el-cordero.github.io/blueterra/reference/prepare_bathy.md),
[`project_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
check_bathy_crs(bathy)
#> # A tibble: 1 × 4
#>   has_crs is_lonlat is_projected crs                                            
#>   <lgl>   <lgl>     <lgl>        <chr>                                          
#> 1 TRUE    FALSE     TRUE         "PROJCRS[\"NAD83 / Puerto Rico & Virgin Is.\",…
```
