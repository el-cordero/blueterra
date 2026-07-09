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
#> # A tibble: 7 × 9
#>   metric     label      process_group     description      units source_function
#>   <chr>      <chr>      <chr>             <chr>            <chr> <chr>          
#> 1 bathy      Bathymetry base_bathymetry   Input bathymetr… inpu… as_bathy       
#> 2 curvature  Curvature  curvature         Laplacian-style… inpu… derive_curvatu…
#> 3 aspect_deg Aspect     orientation       Local downslope… degr… derive_aspect  
#> 4 bpi_11x11  Broad BPI  seafloor_position Broad-scale bat… inpu… derive_bpi     
#> 5 roughness  Roughness  seafloor_rugosity Local range-bas… inpu… derive_roughne…
#> 6 slope_deg  Slope      slope_gradient    Local slope gra… degr… derive_slope   
#> 7 hillshade  Hillshade  surface_structure Illumination mo… rela… derive_hillsha…
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
```
