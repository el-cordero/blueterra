# Terrain metric catalog

Returns a catalog of terrain metrics, labels, process groups,
assumptions, and source functions used by `blueterra`.

## Usage

``` r
metric_catalog()

process_groups()
```

## Value

A tibble with columns `metric`, `label`, `process_group`, `description`,
`units`, `source_function`, `requires_optional_dependency`,
`scale_sensitive`, and `interpretation_notes`.

## Details

The catalog is an interpretation aid, not a claim that terrain metrics
directly measure ecological or oceanographic processes. Groups such as
orientation, slope gradient, seafloor position, rugosity, surface
structure, and curvature describe terrain form. Transport or convergence
interpretations require separate validation and are not direct current
or sediment-flux measurements.

## See also

[`derive_terrain()`](https://el-cordero.github.io/blueterra/reference/derive_terrain.md),
[`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md)

## Examples

``` r
metric_catalog()
#> # A tibble: 16 × 9
#>    metric             label      process_group description units source_function
#>    <chr>              <chr>      <chr>         <chr>       <chr> <chr>          
#>  1 bathy              Bathymetry base_bathyme… Input bath… inpu… as_bathy       
#>  2 slope_deg          Slope      slope_gradie… Local slop… degr… derive_slope   
#>  3 slope_rad          Slope      slope_gradie… Local slop… radi… derive_slope   
#>  4 aspect_deg         Aspect     orientation   Local down… degr… derive_aspect  
#>  5 aspect_rad         Aspect     orientation   Local down… radi… derive_aspect  
#>  6 northness          Northness  orientation   Cosine tra… unit… derive_northne…
#>  7 eastness           Eastness   orientation   Sine trans… unit… derive_eastness
#>  8 hillshade          Hillshade  surface_stru… Illuminati… rela… derive_hillsha…
#>  9 roughness          Roughness  seafloor_rug… Local rang… inpu… derive_roughne…
#> 10 tri                Terrain R… seafloor_rug… Local terr… inpu… derive_tri     
#> 11 tpi                Topograph… seafloor_pos… Cell posit… inpu… derive_tpi     
#> 12 bpi_3x3            Fine BPI   seafloor_pos… Fine-scale… inpu… derive_bpi     
#> 13 bpi_11x11          Broad BPI  seafloor_pos… Broad-scal… inpu… derive_bpi     
#> 14 curvature          Curvature  curvature     Laplacian-… inpu… derive_curvatu…
#> 15 surface_area_ratio Surface A… surface_stru… Approximat… unit… derive_surface…
#> 16 rugosity_vrm_3x3   Vector Ru… seafloor_rug… Vector rug… unit… derive_rugosity
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
process_groups()
#> [1] "base_bathymetry"   "slope_gradient"    "orientation"      
#> [4] "surface_structure" "seafloor_rugosity" "seafloor_position"
#> [7] "curvature"        
```
