# Isobath corridors

``` r

library(blueterra)
```

Isobath corridors summarize terrain along depth horizons. They are
useful when observations are collected along contours or when terrain
structure needs to be compared at equivalent depths while retaining
along-contour variability.

``` r

bathy <- read_bathy(blueterra_example("hitw"))
prepared <- prepare_bathy(bathy, depth_range = c(-220, -25), smooth = TRUE)
terrain <- derive_terrain(
  prepared,
  metrics = c("slope", "bpi", "curvature", "surface_area_ratio")
)
```

The example bathymetry stores depth as negative elevation, so contour
depths are passed as negative values.

``` r

isobaths <- extract_isobaths(prepared, depths = c(-50, -80, -120))
isobaths[, c("contour_value", "depth_label")]
#> class       : SpatVector
#> geometry    : lines
#> dimensions  : 3, 2  (geometries, attributes)
#> extent      : 137476.2, 137772, 205669.4, 205756.6  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> names       : contour_value depth_label
#> type        :         <num>       <num>
#> values      :           -50         -50
#>                         -80         -80
#>                        -120        -120
```

``` r

plot_bathy(
  prepared,
  contours = TRUE,
  contour_interval = 25,
  vectors = isobaths,
  vector_color = "black",
  title = "Isobaths Over Hillshaded Bathymetry"
)
```

![Isobaths over hillshaded
bathymetry.](isobath-corridors_files/figure-html/isobath-map-1.png)

Buffers are measured in map units, so the raster should use a projected
CRS. The example raster is projected; other rasters should be
reprojected explicitly when needed.

``` r

corridors <- make_isobath_corridors(
  prepared,
  depths = c(-50, -80, -120),
  width = 20
)
corridors[, c("contour_value", "depth_label", "corridor_id")]
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 3, 3  (geometries, attributes)
#> extent      : 137456.2, 137792, 205649.4, 205776.5  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> names       : contour_value depth_label corridor_id
#> type        :         <num>       <num>       <int>
#> values      :           -50         -50           1
#>                         -80         -80           2
#>                        -120        -120           3
```

``` r

plot_isobath_corridors(
  corridors,
  prepared,
  isobaths = isobaths,
  background_contours = FALSE,
  title = "Isobath Corridors and Source Isobaths"
)
```

![Isobath corridors over hillshaded
bathymetry.](isobath-corridors_files/figure-html/corridor-map-1.png)

The black lines are the source isobaths. The corridor polygons buffer
those depth horizons and define the terrain extraction zones used in the
summary.

## Extract and Summarize Terrain

``` r

cells <- extract_isobath_corridors(terrain, corridors)
head(cells)
#> # A tibble: 6 × 10
#>      ID level contour_value depth_label corridor_id slope_deg bpi_3x3 bpi_11x11
#>   <int> <dbl>         <dbl>       <dbl>       <int>     <dbl>   <dbl>     <dbl>
#> 1     1   -50           -50         -50           1        NA      NA        NA
#> 2     1   -50           -50         -50           1        NA      NA        NA
#> 3     1   -50           -50         -50           1        NA      NA        NA
#> 4     1   -50           -50         -50           1        NA      NA        NA
#> 5     1   -50           -50         -50           1        NA      NA        NA
#> 6     1   -50           -50         -50           1        NA      NA        NA
#> # ℹ 2 more variables: curvature <dbl>, surface_area_ratio <dbl>

summary <- summarize_isobath_terrain(terrain, corridors)
summary[, c("contour_value", "slope_deg_mean", "bpi_3x3_mean", "curvature_mean")]
#> # A tibble: 3 × 4
#>   contour_value slope_deg_mean bpi_3x3_mean curvature_mean
#>           <dbl>          <dbl>        <dbl>          <dbl>
#> 1           -50           45.0       0.150          0.0154
#> 2           -80           45.6       0.418         -1.27  
#> 3          -120           61.6       0.0736        -0.214
```

The summary compares terrain structure at the selected depth horizons.
BPI values should be interpreted using the raster’s stored vertical
convention.
