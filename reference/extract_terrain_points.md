# Extract terrain values at points

Extracts raster values at point locations.

## Usage

``` r
extract_terrain_points(metrics, points, method = "bilinear", ...)
```

## Arguments

- metrics:

  A metric raster stack.

- points:

  Points as `sf`,
  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html),
  or a local vector path.

- method:

  Extraction method passed to
  [`terra::extract()`](https://rspatial.github.io/terra/reference/extract.html).

- ...:

  Additional arguments passed to
  [`terra::extract()`](https://rspatial.github.io/terra/reference/extract.html).

## Value

A tibble with point attributes and raster values.

## See also

[`sample_terrain_cells()`](https://el-cordero.github.io/blueterra/reference/sample_terrain_cells.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
zones <- terra::vect(blueterra_example("zones"))
pts <- terra::centroids(zones)
extract_terrain_points(bathy, pts)
#> # A tibble: 3 × 8
#>   site_id site_name  feature_type source_name width_m height_m angle_deg bathy_m
#>   <chr>   <chr>      <chr>        <chr>         <dbl>    <dbl>     <dbl>   <dbl>
#> 1 hitw    Hole-in-t… sampling_re… Hole In th…     300      300         0   -60.7
#> 2 hoyo    El Hoyo    sampling_re… Hoyo Terra…     300      400       135   -81.2
#> 3 slope   Slope Clip analysis_ex… Slope_clip…     NaN      NaN       NaN  -384. 
```
