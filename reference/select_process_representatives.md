# Select representative metrics for each process group

Chooses a small set of catalog metrics for process-oriented summaries.

## Usage

``` r
select_process_representatives(
  catalog = metric_catalog(),
  groups = NULL,
  metrics_available = NULL,
  representatives = NULL
)
```

## Arguments

- catalog:

  Optional catalog table. Defaults to
  [`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md).

- groups:

  Optional process groups to retain.

- metrics_available:

  Optional vector of available metric names.

- representatives:

  Optional named character vector mapping process-group names to
  representative metric names.

## Value

A tibble with one representative metric per process group.

## Details

The default representative is the first implemented metric in the
catalog for each process group. Users should review and override
representatives based on their raster resolution, focal scales, and
scientific question.

## See also

[`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md),
[`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md)

## Examples

``` r
select_process_representatives()
#> # A tibble: 9 × 9
#>   metric                   label process_group description units source_function
#>   <chr>                    <chr> <chr>         <chr>       <chr> <chr>          
#> 1 flowacc                  Conv… accumulation… Terrain-de… index external       
#> 2 bathy                    Bath… base_bathyme… Input bath… inpu… as_bathy       
#> 3 curvature                Curv… curvature     Laplacian-… inpu… derive_curvatu…
#> 4 downslope_distance_to_s… Down… downslope_pa… Modeled do… map … external       
#> 5 aspect_deg               Aspe… seafloor_asp… Local down… degr… derive_aspect  
#> 6 tpi                      Topo… seafloor_pos… Cell posit… inpu… derive_tpi     
#> 7 roughness                Roug… seafloor_rug… Local rang… inpu… derive_roughne…
#> 8 slope_deg                Slope slope_gradie… Local stee… degr… derive_slope   
#> 9 stream_power_index_wbt   Terr… transport_po… Compound t… index external       
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
```
