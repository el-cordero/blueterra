# Custom metrics and process groups

``` r

library(blueterra)
library(terra)
```

Many terrain analyses use project-specific variables. `blueterra`
supports custom raster metrics when they share the same grid geometry as
the metric stack they extend. Custom process groups then document how
those layers should be organized and interpreted.

## Base Metrics

``` r

bathy <- read_bathy(blueterra_example("hitw"))
prepared <- prepare_bathy(bathy, depth_range = c(-220, -25), smooth = TRUE)

metrics <- derive_terrain(
  prepared,
  metrics = c("slope", "tri", "bpi", "curvature")
)

names(metrics)
#> [1] "slope_deg" "tri"       "bpi_3x3"   "bpi_11x11" "curvature"
```

## Expression-Based Metrics

Quoted expressions are evaluated with raster layers available by name.
Character strings are not evaluated as code.

``` r

slope_tri <- derive_custom_metric(
  metrics,
  name = "slope_tri_index",
  expression = quote(slope_deg * tri)
)

slope_tri
#> class       : SpatRaster
#> size        : 37, 75, 1  (nrow, ncol, nlyr)
#> resolution  : 3.996743, 3.996743  (x, y)
#> extent      : 137474.2, 137774, 205626.5, 205774.3  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_hitw_bathy
#> name        : slope_tri_index
#> min value   :       11.522078
#> max value   :     1759.994854
```

## Function-Based Metrics

Functions are useful when a metric requires several operations or
parameters. The function must return a single-layer
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
on the same grid.

``` r

relief_position <- derive_custom_metric(
  metrics,
  name = "relief_position_index",
  fun = function(r, bpi_weight = 2) {
    out <- r[["tri"]] + bpi_weight * abs(r[["bpi_3x3"]])
    names(out) <- "relief_position_index"
    out
  },
  bpi_weight = 1.5
)

relief_position
#> class       : SpatRaster
#> size        : 37, 75, 1  (nrow, ncol, nlyr)
#> resolution  : 3.996743, 3.996743  (x, y)
#> extent      : 137474.2, 137774, 205626.5, 205774.3  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_hitw_bathy
#> name        : relief_position_index
#> min value   :              1.158563
#> max value   :             26.458204
```

## Add Layers to a Stack

``` r

extended <- add_metric_layers(metrics, slope_tri, relief_position)
names(extended)
#> [1] "slope_deg"             "tri"                   "bpi_3x3"              
#> [4] "bpi_11x11"             "curvature"             "slope_tri_index"      
#> [7] "relief_position_index"
```

[`add_metric_layers()`](https://el-cordero.github.io/blueterra/reference/add_metric_layers.md)
checks CRS, extent, resolution, dimensions, and origin by default. This
protects later summaries and PCA tables from mixing non-aligned rasters.

``` r

plot_metric(
  extended,
  "slope_tri_index",
  bathy = prepared,
  contours = TRUE,
  contour_interval = 25,
  title = "Custom Slope-TRI Index"
)
```

![Custom slope-TRI metric over hillshaded
bathymetry.](custom-metrics-process-groups_files/figure-html/custom-map-1.png)

## Custom Catalog Rows

Catalog rows explain what a metric is, how it was produced, which group
it belongs to, and how it should be interpreted.

``` r

custom_rows <- create_metric_catalog(
  metric = c("slope_tri_index", "relief_position_index"),
  label = c("Slope-TRI index", "Relief-position index"),
  process_group = c("custom_relief", "custom_relief"),
  description = c(
    "Product of slope and terrain ruggedness index.",
    "TRI plus weighted absolute fine-scale BPI."
  ),
  units = c("index", "index"),
  source_function = c("derive_custom_metric", "derive_custom_metric"),
  scale_sensitive = c(TRUE, TRUE),
  interpretation_notes = c(
    "Example composite terrain-form index; choose only when it follows the analysis design.",
    "Example relief-position index; weights should be justified before inference."
  )
)

custom_catalog <- extend_metric_catalog(metric_catalog(), custom_rows)
validate_metric_catalog(custom_catalog)
#> # A tibble: 52 × 9
#>    metric     label      process_group   description       units source_function
#>    <chr>      <chr>      <chr>           <chr>             <chr> <chr>          
#>  1 bathy      Bathymetry base_bathymetry Input bathymetri… inpu… as_bathy       
#>  2 hillshade  Hillshade  base_bathymetry Shaded-relief vi… rela… derive_hillsha…
#>  3 aspect_deg Aspect     seafloor_aspect Local downslope-… degr… derive_aspect  
#>  4 aspect_rad Aspect     seafloor_aspect Local downslope-… radi… derive_aspect  
#>  5 northness  Northness  seafloor_aspect Cosine transform… unit… derive_northne…
#>  6 eastness   Eastness   seafloor_aspect Sine transform o… unit… derive_eastness
#>  7 aspect_cos Northness  seafloor_aspect Project-derived … unit… external       
#>  8 aspect_sin Eastness   seafloor_aspect Project-derived … unit… external       
#>  9 slope_deg  Slope      slope_gradient  Local steepness … degr… derive_slope   
#> 10 slope_rad  Slope      slope_gradient  Local steepness … radi… derive_slope   
#> # ℹ 42 more rows
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
custom_rows
#> # A tibble: 2 × 9
#>   metric                label    process_group description units source_function
#>   <chr>                 <chr>    <chr>         <chr>       <chr> <chr>          
#> 1 slope_tri_index       Slope-T… custom_relief Product of… index derive_custom_…
#> 2 relief_position_index Relief-… custom_relief TRI plus w… index derive_custom_…
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
```

## Assign Custom Process Groups

``` r

assign_process_groups(extended, catalog = custom_catalog)
#> # A tibble: 7 × 7
#>   metric metric_standard label process_group description source_function matched
#>   <chr>  <chr>           <chr> <chr>         <chr>       <chr>           <lgl>  
#> 1 slope… slope_deg       Slope slope_gradie… Local stee… derive_slope    TRUE   
#> 2 tri    tri             Terr… seafloor_rug… Local terr… derive_tri      TRUE   
#> 3 bpi_3… bpi_3x3         Fine… seafloor_pos… Fine-scale… derive_bpi      TRUE   
#> 4 bpi_1… bpi_11x11       Broa… seafloor_pos… Broad-scal… derive_bpi      TRUE   
#> 5 curva… curvature       Curv… curvature     Laplacian-… derive_curvatu… TRUE   
#> 6 slope… slope_tri_index Slop… custom_relief Product of… derive_custom_… TRUE   
#> 7 relie… relief_positio… Reli… custom_relief TRI plus w… derive_custom_… TRUE
summarize_process_groups(extended, catalog = custom_catalog)
#> # A tibble: 5 × 3
#>   process_group     n_metrics metrics                               
#>   <chr>                 <int> <chr>                                 
#> 1 curvature                 1 curvature                             
#> 2 custom_relief             2 slope_tri_index, relief_position_index
#> 3 seafloor_position         2 bpi_3x3, bpi_11x11                    
#> 4 seafloor_rugosity         1 tri                                   
#> 5 slope_gradient            1 slope_deg
select_process_representatives(
  catalog = custom_catalog,
  metrics_available = names(extended),
  representatives = c(custom_relief = "relief_position_index")
)
#> # A tibble: 5 × 9
#>   metric                label    process_group description units source_function
#>   <chr>                 <chr>    <chr>         <chr>       <chr> <chr>          
#> 1 curvature             Curvatu… curvature     Laplacian-… inpu… derive_curvatu…
#> 2 bpi_3x3               Fine-sc… seafloor_pos… Fine-scale… inpu… derive_bpi     
#> 3 tri                   Terrain… seafloor_rug… Local terr… inpu… derive_tri     
#> 4 slope_deg             Slope    slope_gradie… Local stee… degr… derive_slope   
#> 5 relief_position_index Relief-… custom_relief TRI plus w… index derive_custom_…
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
```

Custom group names should describe terrain form or analysis design. They
should not imply a direct ecological or oceanographic process unless
that link is validated independently.

## Rename External Layers

Imported rasters often arrive with names that are readable to the
analyst but not stable enough for programmatic grouping.

``` r

standardize_metric_names(c("Slope degrees", "Fine BPI", "Relief position index"))
#> [1] "slope_degrees"         "fine_bpi"              "relief_position_index"
rename_metric_layers(
  c("slope old", "bpi old"),
  c("slope old" = "slope_deg", "bpi old" = "bpi_3x3")
)
#> [1] "slope_deg" "bpi_3x3"
```
