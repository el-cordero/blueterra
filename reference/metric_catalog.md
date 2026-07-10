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
seafloor aspect, slope gradient, accumulation potential, seafloor
position, seafloor rugosity, downslope pathway proximity, transport
potential, and curvature describe terrain form and terrain-routing
proxies. Accumulation, pathway, and transport interpretations require
separate validation and are not direct current or sediment-flux
measurements.

## See also

[`derive_terrain()`](https://el-cordero.github.io/blueterra/reference/derive_terrain.md),
[`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md)

## Examples

``` r
metric_catalog()
#> # A tibble: 50 × 9
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
#> # ℹ 40 more rows
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
process_groups()
#> [1] "base_bathymetry"             "seafloor_aspect"            
#> [3] "slope_gradient"              "seafloor_position"          
#> [5] "seafloor_rugosity"           "curvature"                  
#> [7] "accumulation_potential"      "transport_potential"        
#> [9] "downslope_pathway_proximity"
```
