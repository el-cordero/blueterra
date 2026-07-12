# Sample rasters along transects

Extracts raster values along transect lines at regular distances.

## Usage

``` r
sample_transects(
  transects,
  x,
  spacing = NULL,
  n = NULL,
  method = "bilinear",
  drop_na = FALSE
)

extract_cross_sections(
  transects,
  x,
  spacing = NULL,
  n = NULL,
  method = "bilinear"
)
```

## Arguments

- transects:

  Line geometry from
  [`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md)
  or another source.

- x:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  or local raster path. Multi-layer rasters are accepted when sampling
  bathymetry together with derived terrain metrics.

- spacing:

  Optional sample spacing in map units.

- n:

  Optional number of sample points per transect.

- method:

  Extraction method passed to
  [`terra::extract()`](https://rspatial.github.io/terra/reference/extract.html).

- drop_na:

  Logical. If `TRUE`, remove sample rows where all raster value columns
  are missing.

## Value

A tibble with transect identifiers, distances, coordinates, and raster
values.

## Details

If `spacing` and `n` are both `NULL`, twenty points are sampled per
transect. Distances are measured from the first line vertex and are in
map units. Transect attribute columns, including orientation metadata
created by
[`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md),
are preserved in the sampled table.

## See also

[`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md),
[`summarize_cross_sections()`](https://el-cordero.github.io/blueterra/reference/summarize_cross_sections.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
zones <- terra::vect(blueterra_example("zones"))
transects <- make_transects(zones[1, ], spacing = 100, bathy = bathy)
sample_transects(transects, bathy, n = 5)
#> # A tibble: 15 × 19
#>    site_id site_name feature_type source_name width_m height_m angle_deg zone_id
#>    <chr>   <chr>     <chr>        <chr>         <dbl>    <dbl>     <dbl> <chr>  
#>  1 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  2 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  3 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  4 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  5 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  6 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  7 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  8 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#>  9 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#> 10 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#> 11 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#> 12 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#> 13 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#> 14 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#> 15 hitw    Hole-in-… sampling_re… Hole In th…     300      300      94.3 1      
#> # ℹ 11 more variables: offset <dbl>, angle_source <chr>, mean_aspect_deg <dbl>,
#> #   orientation_weight <chr>, n_orientation_cells <int>,
#> #   orientation_resultant_length <dbl>, transect_id <chr>, distance <dbl>,
#> #   x <dbl>, y <dbl>, bathy_m <dbl>
```
