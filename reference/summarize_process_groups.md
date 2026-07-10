# Summarize process group representation

Counts available metrics by process group.

## Usage

``` r
summarize_process_groups(x, catalog = metric_catalog(), groups = NULL)
```

## Arguments

- x:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
  character vector, or data frame with metric columns.

- catalog:

  Optional catalog table. Defaults to
  [`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md).

- groups:

  Optional named character vector passed to
  [`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md).

## Value

A tibble with process group counts.

## Details

This function summarizes which process groups are represented by a
metric stack. It does not compute raster statistics; use
[`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)
for spatial summaries.

## See also

[`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md),
[`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)

## Examples

``` r
terrain <- derive_terrain(read_bathy(blueterra_example("bathy")))
summarize_process_groups(terrain)
#> # A tibble: 6 × 3
#>   process_group     n_metrics metrics                           
#>   <chr>                 <int> <chr>                             
#> 1 base_bathymetry           2 bathy, hillshade                  
#> 2 curvature                 1 curvature                         
#> 3 seafloor_aspect           3 aspect_deg, northness, eastness   
#> 4 seafloor_position         3 tpi, bpi_3x3, bpi_11x11           
#> 5 seafloor_rugosity         3 roughness, tri, surface_area_ratio
#> 6 slope_gradient            1 slope_deg                         
```
