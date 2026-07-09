# Create and validate metric catalog rows

Builds catalog rows for custom metrics and checks that metric catalogs
follow the schema used by
[`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md).

## Usage

``` r
create_metric_catalog(
  metric,
  label = metric,
  process_group,
  description = NA_character_,
  units = NA_character_,
  source_function = NA_character_,
  requires_optional_dependency = FALSE,
  scale_sensitive = TRUE,
  interpretation_notes = NA_character_
)

extend_metric_catalog(catalog = metric_catalog(), ...)

validate_metric_catalog(catalog)
```

## Arguments

- metric:

  Metric layer name.

- label:

  Human-readable metric label.

- process_group:

  Process-group label.

- description:

  Metric description.

- units:

  Metric units.

- source_function:

  Function or workflow that produced the metric.

- requires_optional_dependency:

  Logical. Whether the metric requires an optional package.

- scale_sensitive:

  Logical. Whether the metric is sensitive to grid resolution or focal
  scale.

- interpretation_notes:

  Notes on interpretation.

- catalog:

  Existing metric catalog.

- ...:

  One or more catalog rows or tibbles to append.

## Value

A tibble with the same columns as
[`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md).

## Details

Custom process groups are user-defined terrain-form categories. The
catalog records how custom layers should be grouped and interpreted
without changing raster values.

## See also

[`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md),
[`summarize_process_groups()`](https://el-cordero.github.io/blueterra/reference/summarize_process_groups.md)

## Examples

``` r
row <- create_metric_catalog(
  metric = "slope_tri_index",
  process_group = "custom_relief",
  description = "Product of local slope and terrain ruggedness index."
)
validate_metric_catalog(row)
#> # A tibble: 1 × 9
#>   metric          label          process_group description units source_function
#>   <chr>           <chr>          <chr>         <chr>       <chr> <chr>          
#> 1 slope_tri_index slope_tri_ind… custom_relief Product of… NA    NA             
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
extend_metric_catalog(metric_catalog(), row)
#> # A tibble: 17 × 9
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
#> 17 slope_tri_index    slope_tri… custom_relief Product of… NA    NA             
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
```
