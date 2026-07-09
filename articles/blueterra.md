# Get started with blueterra

``` r

library(blueterra)
library(terra)
```

`blueterra` works from bathymetric and elevation rasters already
available to the analyst. The package keeps the workflow close to
`terra`: rasters remain `SpatRaster` objects, sampling zones and
transects remain `SpatVector` objects, and extracted values become
ordinary tables for summaries and models.

![Study-area context for the example data along the southwest Puerto
Rico shelf
margin.](../reference/figures/study-area-pr-southwest-shelf-margin.png)

The examples use reduced bathymetry and sampling rectangles from
Hole-in-the-Wall, El Hoyo, and a broader slope clip along the southwest
Puerto Rico shelf margin near La Parguera, Puerto Rico. The files are
compact, but they retain real relief, depth gradients, slope breaks, and
sampling geometry.

## Read Example Data

``` r

hitw <- read_bathy(blueterra_example("hitw"))
hoyo <- read_bathy(blueterra_example("hoyo"))
slope <- read_bathy(blueterra_example("slope"))
rectangles <- terra::vect(blueterra_example("sampling_rectangles"))

hitw_rect <- rectangles[rectangles$site_id == "hitw", ]
hoyo_rect <- rectangles[rectangles$site_id == "hoyo", ]

bathy_info(hitw)
#> # A tibble: 1 × 13
#>   layer    nrow  ncol ncell    xmin   xmax   ymin   ymax  xres  yres   min   max
#>   <chr>   <dbl> <dbl> <dbl>   <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 bathy_m    75    75  5625 137474. 1.38e5 2.06e5 2.06e5  4.00  4.00 -269. -16.6
#> # ℹ 1 more variable: crs <chr>
rectangles[, c("site_id", "site_name", "feature_type")]
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 3, 3  (geometries, attributes)
#> extent      : 134960.3, 138741.2, 204155.7, 205950.2  (xmin, xmax, ymin, ymax)
#> source      : laparguera_sampling_rectangles.gpkg
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> names       : site_id        site_name       feature_type
#> type        :   <chr>            <chr>              <chr>
#> values      :    hitw Hole-in-the-Wall sampling_rectangle
#>                  hoyo          El Hoyo sampling_rectangle
#>                 slope       Slope Clip    analysis_extent
```

[`bathy_info()`](https://el-cordero.github.io/blueterra/reference/bathy_info.md)
is a first check on raster dimensions, value range, resolution, extent,
and CRS. These fields affect slope, focal-window metrics, buffers, and
distance along transects.

## Prepare the Bathymetry

The example rasters store bathymetry as negative elevation.
[`prepare_bathy()`](https://el-cordero.github.io/blueterra/reference/prepare_bathy.md)
preserves that convention unless a conversion is requested explicitly.

``` r

prepared <- prepare_bathy(
  hitw,
  depth_range = c(-220, -25),
  smooth = TRUE,
  smooth_window = 3
)

check_bathy_units(prepared, units = "m", positive_depth = FALSE)
#> # A tibble: 1 × 5
#>   layer     min   max units positive_depth
#>   <chr>   <dbl> <dbl> <chr> <lgl>         
#> 1 bathy_m -218. -27.2 m     FALSE
range(terra::values(prepared), na.rm = TRUE)
#> [1] -217.94669  -27.22529
```

``` r

plot_bathy(
  prepared,
  contours = TRUE,
  contour_interval = 25,
  vectors = hitw_rect,
  title = "Hole-in-the-Wall Bathymetry",
  subtitle = "Hillshade, contours, and sampling rectangle"
)
```

![Hole-in-the-Wall bathymetry with hillshade, contours, and sampling
rectangle.](blueterra_files/figure-html/map-1.png)

Hillshade is used here as visual relief. It helps the reader see
escarpments and local relief, but it is not a predictor unless the
analyst explicitly derives and includes it.

## Derive Metrics and Process Groups

Terrain metrics describe different aspects of the same bathymetric
surface. Slope and aspect describe local orientation; northness and
eastness convert aspect to linear components; TRI and rugosity describe
local relief variability; BPI describes relative position; curvature
summarizes local surface bending.

``` r

terrain <- derive_terrain(
  prepared,
  metrics = c(
    "slope", "aspect", "northness", "eastness", "tri", "rugosity",
    "bpi", "curvature", "surface_area_ratio"
  )
)

names(terrain)
#>  [1] "slope_deg"          "aspect_deg"         "northness"         
#>  [4] "eastness"           "tri"                "rugosity_vrm_3x3"  
#>  [7] "bpi_3x3"            "bpi_11x11"          "curvature"         
#> [10] "surface_area_ratio"
assign_process_groups(terrain)
#> # A tibble: 10 × 7
#>    metric        metric_standard label process_group description source_function
#>    <chr>         <chr>           <chr> <chr>         <chr>       <chr>          
#>  1 slope_deg     slope_deg       Slope slope_gradie… Local slop… derive_slope   
#>  2 aspect_deg    aspect_deg      Aspe… orientation   Local down… derive_aspect  
#>  3 northness     northness       Nort… orientation   Cosine tra… derive_northne…
#>  4 eastness      eastness        East… orientation   Sine trans… derive_eastness
#>  5 tri           tri             Terr… seafloor_rug… Local terr… derive_tri     
#>  6 rugosity_vrm… rugosity_vrm_3… Vect… seafloor_rug… Vector rug… derive_rugosity
#>  7 bpi_3x3       bpi_3x3         Fine… seafloor_pos… Fine-scale… derive_bpi     
#>  8 bpi_11x11     bpi_11x11       Broa… seafloor_pos… Broad-scal… derive_bpi     
#>  9 curvature     curvature       Curv… curvature     Laplacian-… derive_curvatu…
#> 10 surface_area… surface_area_r… Surf… surface_stru… Approximat… derive_surface…
#> # ℹ 1 more variable: matched <lgl>
summarize_process_groups(terrain)
#> # A tibble: 6 × 3
#>   process_group     n_metrics metrics                        
#>   <chr>                 <int> <chr>                          
#> 1 curvature                 1 curvature                      
#> 2 orientation               3 aspect_deg, northness, eastness
#> 3 seafloor_position         2 bpi_3x3, bpi_11x11             
#> 4 seafloor_rugosity         2 tri, rugosity_vrm_3x3          
#> 5 slope_gradient            1 slope_deg                      
#> 6 surface_structure         1 surface_area_ratio
```

``` r

plot_metric_stack(terrain[[c("slope_deg", "tri", "bpi_3x3", "curvature")]])
```

![Metric stack showing slope, TRI, BPI, and
curvature.](blueterra_files/figure-html/metric-stack-1.png)

Process groups keep related derivatives together. They are
interpretation categories for terrain form, not direct measurements of
currents, sediment transport, habitat condition, or ecological response.

## Summarize Sampling Rectangles

Sampling rectangles provide a compact example of zone-based extraction.
Each polygon is treated as a spatial sampling frame, and summary
statistics are calculated from raster cells inside that frame.

``` r

zone_summary <- summarize_terrain(
  terrain,
  hitw_rect,
  fun = c("mean", "sd", "min", "max")
)

zone_summary[, c("site_id", "site_name", "slope_deg_mean", "bpi_3x3_mean")]
#> # A tibble: 1 × 4
#>   site_id site_name        slope_deg_mean bpi_3x3_mean
#>   <chr>   <chr>                     <dbl>        <dbl>
#> 1 hitw    Hole-in-the-Wall           50.9      0.00568
```

## Transects and Cross-Sections

Transects convert the raster surface into profiles. When `bathy` is
supplied,
[`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md)
can estimate a terrain-oriented line angle from local aspect instead of
requiring the analyst to choose a fixed direction by hand.

``` r

orientation <- estimate_surface_orientation(prepared, hitw_rect)
transects <- make_transects(hitw_rect, spacing = 75, bathy = prepared)
cross_sections <- sample_transects(transects, prepared, n = 12)

orientation
#> [1] 94.61515
unique(as.data.frame(transects)[, c("angle_deg", "angle_source", "mean_aspect_deg")])
#>   angle_deg angle_source mean_aspect_deg
#> 1  94.61515      surface        175.3849
head(cross_sections[, c("transect_id", "distance", "bathy_m")])
#> # A tibble: 6 × 3
#>   transect_id distance bathy_m
#>   <chr>          <dbl>   <dbl>
#> 1 1_1              0     NaN  
#> 2 1_1             27.4   NaN  
#> 3 1_1             54.7   NaN  
#> 4 1_1             82.1  -197. 
#> 5 1_1            109.    -94.8
#> 6 1_1            137.    -71.8
```

``` r

plot_transects(
  prepared,
  transects,
  color_by = "transect_id",
  show_legend = FALSE,
  contour_interval = 25,
  title = "Terrain-Oriented Transects"
)
```

![Terrain-oriented transects over hillshaded
bathymetry.](blueterra_files/figure-html/transect-map-1.png)

``` r

plot_cross_sections(
  cross_sections,
  value_col = "bathy_m",
  show_legend = TRUE,
  mean_profile = TRUE,
  normalize_distance = TRUE,
  title = "Bathymetric Cross-Sections"
)
#> Warning: Removed 7 rows containing missing values or values outside the scale range
#> (`geom_line()`).
```

![Bathymetric cross-section profiles with bathy_m on the
y-axis.](blueterra_files/figure-html/cross-section-plot-1.png)

The y-axis is explicitly set to `bathy_m`. This prevents transect
metadata such as width, angle, or offset from being mistaken for the
raster value.

## Isobath Corridors

Isobath corridors summarize terrain along depth horizons. The source
isobaths are shown in black so the reader can see which contour each
corridor buffers.

``` r

isobaths <- extract_isobaths(prepared, depths = c(-50, -80, -120))
corridors <- make_isobath_corridors(prepared, depths = c(-50, -80, -120), width = 20)

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
summarize_isobath_terrain(terrain, corridors)[, c("contour_value", "slope_deg_mean", "bpi_3x3_mean")]
#> # A tibble: 3 × 3
#>   contour_value slope_deg_mean bpi_3x3_mean
#>           <dbl>          <dbl>        <dbl>
#> 1           -50           45.0       0.150 
#> 2           -80           45.6       0.418 
#> 3          -120           61.6       0.0736
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

![Isobath corridors over hillshaded bathymetry with source isobaths in
black.](blueterra_files/figure-html/corridor-map-1.png)

## PCA and Model-Ready Tables

Cell samples and extracted summaries can be sent directly into
exploratory models. PCA is useful for checking whether terrain metrics
form separable gradients across sites or sampling frames.

``` r

hoyo_prepared <- prepare_bathy(hoyo, depth_range = c(-220, -25), smooth = TRUE)
hoyo_metrics <- derive_terrain(hoyo_prepared, metrics = c("slope", "tri", "bpi", "curvature"))

hitw_cells <- sample_terrain_cells(
  terrain[[c("slope_deg", "tri", "bpi_3x3", "curvature")]],
  size = 45,
  method = "regular"
)
hitw_cells$site <- "Hole-in-the-Wall"

hoyo_cells <- sample_terrain_cells(
  hoyo_metrics[[c("slope_deg", "tri", "bpi_3x3", "curvature")]],
  size = 45,
  method = "regular"
)
hoyo_cells$site <- "El Hoyo"

comparison <- rbind(hitw_cells, hoyo_cells)
pca <- terrain_pca(
  comparison,
  vars = c("slope_deg", "tri", "bpi_3x3", "curvature")
)

pca$variance
#> # A tibble: 4 × 3
#>   component proportion cumulative
#>   <chr>          <dbl>      <dbl>
#> 1 PC1         0.734         0.734
#> 2 PC2         0.234         0.968
#> 3 PC3         0.0323        1.000
#> 4 PC4         0.000144      1
pca_axis_labels(pca)
#>                               PC1                               PC2 
#> "PC1 (73.4%; bpi_3x3, curvature)"     "PC2 (23.4%; slope_deg, tri)"
```

``` r

plot_process_pca(
  pca,
  color_col = "site",
  title = "Terrain PCA"
)
```

![Terrain PCA with site-colored points and loading labels in the axis
text.](blueterra_files/figure-html/pca-plot-1.png)
