# Process groups

``` r

library(blueterra)
```

Process groups keep related terrain derivatives together so
interpretation does not rest on a single high-ranking variable. The
labels are terrain-form categories. They organize surface form for
summaries and models; they are not direct measurements of currents,
sediment flux, habitat condition, or ecological processes.

## Metric Catalog

``` r

catalog <- metric_catalog()
catalog[, c("metric", "label", "process_group", "scale_sensitive")]
#> # A tibble: 16 × 4
#>    metric             label                      process_group   scale_sensitive
#>    <chr>              <chr>                      <chr>           <lgl>          
#>  1 bathy              Bathymetry                 base_bathymetry TRUE           
#>  2 slope_deg          Slope                      slope_gradient  TRUE           
#>  3 slope_rad          Slope                      slope_gradient  TRUE           
#>  4 aspect_deg         Aspect                     orientation     TRUE           
#>  5 aspect_rad         Aspect                     orientation     TRUE           
#>  6 northness          Northness                  orientation     TRUE           
#>  7 eastness           Eastness                   orientation     TRUE           
#>  8 hillshade          Hillshade                  surface_struct… TRUE           
#>  9 roughness          Roughness                  seafloor_rugos… TRUE           
#> 10 tri                Terrain Ruggedness Index   seafloor_rugos… TRUE           
#> 11 tpi                Topographic Position Index seafloor_posit… TRUE           
#> 12 bpi_3x3            Fine BPI                   seafloor_posit… TRUE           
#> 13 bpi_11x11          Broad BPI                  seafloor_posit… TRUE           
#> 14 curvature          Curvature                  curvature       TRUE           
#> 15 surface_area_ratio Surface Area Ratio         surface_struct… TRUE           
#> 16 rugosity_vrm_3x3   Vector Ruggedness          seafloor_rugos… TRUE
```

The catalog records the source function, units, and interpretation notes
for the exported terrain metrics.

## Assigning Groups

``` r

bathy <- read_bathy(blueterra_example("hitw"))
prepared <- prepare_bathy(bathy, depth_range = c(-220, -25), smooth = TRUE)
terrain <- derive_terrain(
  prepared,
  metrics = c("slope", "aspect", "northness", "eastness", "tri", "bpi",
              "curvature", "surface_area_ratio")
)

assign_process_groups(terrain)
#> # A tibble: 9 × 7
#>   metric metric_standard label process_group description source_function matched
#>   <chr>  <chr>           <chr> <chr>         <chr>       <chr>           <lgl>  
#> 1 slope… slope_deg       Slope slope_gradie… Local slop… derive_slope    TRUE   
#> 2 aspec… aspect_deg      Aspe… orientation   Local down… derive_aspect   TRUE   
#> 3 north… northness       Nort… orientation   Cosine tra… derive_northne… TRUE   
#> 4 eastn… eastness        East… orientation   Sine trans… derive_eastness TRUE   
#> 5 tri    tri             Terr… seafloor_rug… Local terr… derive_tri      TRUE   
#> 6 bpi_3… bpi_3x3         Fine… seafloor_pos… Fine-scale… derive_bpi      TRUE   
#> 7 bpi_1… bpi_11x11       Broa… seafloor_pos… Broad-scal… derive_bpi      TRUE   
#> 8 curva… curvature       Curv… curvature     Laplacian-… derive_curvatu… TRUE   
#> 9 surfa… surface_area_r… Surf… surface_stru… Approximat… derive_surface… TRUE
summarize_process_groups(terrain)
#> # A tibble: 6 × 3
#>   process_group     n_metrics metrics                        
#>   <chr>                 <int> <chr>                          
#> 1 curvature                 1 curvature                      
#> 2 orientation               3 aspect_deg, northness, eastness
#> 3 seafloor_position         2 bpi_3x3, bpi_11x11             
#> 4 seafloor_rugosity         1 tri                            
#> 5 slope_gradient            1 slope_deg                      
#> 6 surface_structure         1 surface_area_ratio
```

The assignment is based on layer names.
[`standardize_metric_names()`](https://el-cordero.github.io/blueterra/reference/standardize_metric_names.md)
is useful when metric names come from external rasters or older project
files.

``` r

standardize_metric_names(c("Slope degrees", "Broad BPI", "Curvature index"))
#> [1] "slope_degrees"   "broad_bpi"       "curvature_index"
rename_metric_layers(c("slope_old", "curv_old"), c(slope_old = "slope_deg"))
#> [1] "slope_deg" "curv_old"
```

## Representatives

Representative metrics are starting points for compact reporting. The
final choice should still follow raster resolution, sampling design,
collinearity, and the feature scale of the analysis.

``` r

select_process_representatives(metrics_available = names(terrain))
#> # A tibble: 6 × 9
#>   metric             label       process_group description units source_function
#>   <chr>              <chr>       <chr>         <chr>       <chr> <chr>          
#> 1 curvature          Curvature   curvature     Laplacian-… inpu… derive_curvatu…
#> 2 aspect_deg         Aspect      orientation   Local down… degr… derive_aspect  
#> 3 bpi_11x11          Broad BPI   seafloor_pos… Broad-scal… inpu… derive_bpi     
#> 4 tri                Terrain Ru… seafloor_rug… Local terr… inpu… derive_tri     
#> 5 slope_deg          Slope       slope_gradie… Local slop… degr… derive_slope   
#> 6 surface_area_ratio Surface Ar… surface_stru… Approximat… unit… derive_surface…
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
select_process_representatives(
  representatives = c(orientation = "northness", slope_gradient = "slope_deg")
)
#> # A tibble: 7 × 9
#>   metric    label      process_group     description       units source_function
#>   <chr>     <chr>      <chr>             <chr>             <chr> <chr>          
#> 1 bathy     Bathymetry base_bathymetry   Input bathymetri… inpu… as_bathy       
#> 2 curvature Curvature  curvature         Laplacian-style … inpu… derive_curvatu…
#> 3 bpi_11x11 Broad BPI  seafloor_position Broad-scale bath… inpu… derive_bpi     
#> 4 roughness Roughness  seafloor_rugosity Local range-base… inpu… derive_roughne…
#> 5 hillshade Hillshade  surface_structure Illumination mod… rela… derive_hillsha…
#> 6 northness Northness  orientation       Cosine transform… unit… derive_northne…
#> 7 slope_deg Slope      slope_gradient    Local slope grad… degr… derive_slope   
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
```

``` r

cells <- sample_terrain_cells(
  terrain[[c("slope_deg", "tri", "bpi_3x3", "curvature")]],
  size = 50,
  method = "regular"
)
pca <- terrain_pca(cells, vars = c("slope_deg", "tri", "bpi_3x3", "curvature"))
pca_axis_labels(pca)
#>                               PC1                               PC2 
#> "PC1 (77.9%; bpi_3x3, slope_deg)"     "PC2 (20.6%; tri, curvature)"
plot_process_pca(pca, title = "Terrain PCA with Dominant Loading Labels")
```

![PCA scores for sampled terrain
metrics.](process-groups_files/figure-html/pca-1.png)

## Custom Metrics

Custom metrics can be added to a stack when they share the same grid,
CRS, and extent. Catalog rows then place those layers into process
groups for summaries and model-ready tables.

``` r

slope_tri <- derive_custom_metric(
  terrain,
  name = "slope_tri_index",
  expression = quote(slope_deg * tri)
)

extended <- add_metric_layers(terrain, slope_tri)

custom_catalog <- extend_metric_catalog(
  metric_catalog(),
  create_metric_catalog(
    metric = "slope_tri_index",
    label = "Slope-TRI index",
    process_group = "custom_relief",
    description = "Product of local slope and terrain ruggedness index.",
    units = "index",
    source_function = "derive_custom_metric",
    interpretation_notes = "Example index; define custom metrics from an explicit process model."
  )
)

assign_process_groups(extended, catalog = custom_catalog)
#> # A tibble: 10 × 7
#>    metric        metric_standard label process_group description source_function
#>    <chr>         <chr>           <chr> <chr>         <chr>       <chr>          
#>  1 slope_deg     slope_deg       Slope slope_gradie… Local slop… derive_slope   
#>  2 aspect_deg    aspect_deg      Aspe… orientation   Local down… derive_aspect  
#>  3 northness     northness       Nort… orientation   Cosine tra… derive_northne…
#>  4 eastness      eastness        East… orientation   Sine trans… derive_eastness
#>  5 tri           tri             Terr… seafloor_rug… Local terr… derive_tri     
#>  6 bpi_3x3       bpi_3x3         Fine… seafloor_pos… Fine-scale… derive_bpi     
#>  7 bpi_11x11     bpi_11x11       Broa… seafloor_pos… Broad-scal… derive_bpi     
#>  8 curvature     curvature       Curv… curvature     Laplacian-… derive_curvatu…
#>  9 surface_area… surface_area_r… Surf… surface_stru… Approximat… derive_surface…
#> 10 slope_tri_in… slope_tri_index Slop… custom_relief Product of… derive_custom_…
#> # ℹ 1 more variable: matched <lgl>
summarize_process_groups(extended, catalog = custom_catalog)
#> # A tibble: 7 × 3
#>   process_group     n_metrics metrics                        
#>   <chr>                 <int> <chr>                          
#> 1 curvature                 1 curvature                      
#> 2 custom_relief             1 slope_tri_index                
#> 3 orientation               3 aspect_deg, northness, eastness
#> 4 seafloor_position         2 bpi_3x3, bpi_11x11             
#> 5 seafloor_rugosity         1 tri                            
#> 6 slope_gradient            1 slope_deg                      
#> 7 surface_structure         1 surface_area_ratio
```
