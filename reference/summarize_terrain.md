# Summarize terrain metrics by polygon zones

Computes summary statistics for raster metrics inside polygons, buffers,
or corridor features.

## Usage

``` r
summarize_terrain(
  metrics,
  zones,
  fun = c("mean", "sd", "min", "max", "median"),
  na.rm = TRUE,
  exact = FALSE,
  ...
)

summarize_terrain_by_zone(
  metrics,
  zones,
  fun = c("mean", "sd", "min", "max", "median"),
  na.rm = TRUE,
  exact = FALSE,
  ...
)
```

## Arguments

- metrics:

  A metric raster stack.

- zones:

  Polygon zones as `sf`,
  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html),
  or a local vector path.

- fun:

  Summary functions. Supported values are `"mean"`, `"sd"`, `"min"`,
  `"max"`, `"median"`, `"sum"`, and `"count"`.

- na.rm:

  Logical. Remove missing values before summarizing.

- exact:

  Logical. If `TRUE`, use `exactextractr` for exact raster-polygon
  intersections and coverage-fraction-weighted summaries. The optional
  package must be installed. Weighted `count` is an effective cell count
  and weighted `sum` is a coverage-fraction-weighted cell-value sum.

- ...:

  Additional arguments passed to extraction functions.

## Value

A tibble with zone identifiers, zone attributes, and wide summary
columns named `metric_function`.

## Details

`summarize_terrain()` does not assume specific zones, depth ranges, or
ecological labels. For distance-sensitive summaries, use zones and
rasters in a projected CRS. With `exact = TRUE`, positive
`coverage_fraction` values weight means, population standard deviations,
sums, counts, and medians. Minimum and maximum are evaluated over
intersected cells with positive coverage. The resulting exact mean is
area-weighted when raster cells have equal area in the working CRS.

## See also

[`summarize_depth_bands()`](https://el-cordero.github.io/blueterra/reference/summarize_depth_bands.md),
[`extract_terrain_points()`](https://el-cordero.github.io/blueterra/reference/extract_terrain_points.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
zones <- terra::vect(blueterra_example("zones"))
summarize_terrain(terrain, zones)
#> # A tibble: 3 × 23
#>   site_id site_name  feature_type source_name width_m height_m angle_deg zone_id
#>   <chr>   <chr>      <chr>        <chr>         <dbl>    <dbl>     <dbl>   <int>
#> 1 hitw    Hole-in-t… sampling_re… Hole In th…     300      300         0       1
#> 2 hoyo    El Hoyo    sampling_re… Hoyo Terra…     300      400       135       2
#> 3 slope   Slope Clip analysis_ex… Slope_clip…     NaN      NaN       NaN       3
#> # ℹ 15 more variables: slope_deg_mean <dbl>, slope_deg_sd <dbl>,
#> #   slope_deg_min <dbl>, slope_deg_max <dbl>, slope_deg_median <dbl>,
#> #   bpi_3x3_mean <dbl>, bpi_3x3_sd <dbl>, bpi_3x3_min <dbl>, bpi_3x3_max <dbl>,
#> #   bpi_3x3_median <dbl>, bpi_11x11_mean <dbl>, bpi_11x11_sd <dbl>,
#> #   bpi_11x11_min <dbl>, bpi_11x11_max <dbl>, bpi_11x11_median <dbl>
```
