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
#> # A tibble: 51 × 9
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
#> # ℹ 41 more rows
#> # ℹ 3 more variables: requires_optional_dependency <lgl>,
#> #   scale_sensitive <lgl>, interpretation_notes <chr>
```
