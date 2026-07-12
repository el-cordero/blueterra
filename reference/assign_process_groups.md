# Assign metrics to process groups

Matches raster layer names or character metric names to the metric
catalog.

## Usage

``` r
assign_process_groups(
  x,
  catalog = metric_catalog(),
  groups = NULL,
  unmatched = "unassigned"
)
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

  Optional named character vector mapping metric names to process
  groups. Supplied mappings override catalog matches for those metrics.

- unmatched:

  Character value assigned to unmatched metrics.

## Value

A tibble with one row per supplied metric.

## Details

Matching uses standardized lower-case metric names. Unmatched metrics
are returned with `process_group = unmatched` so users can inspect
custom layers.

## See also

[`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md),
[`summarize_process_groups()`](https://el-cordero.github.io/blueterra/reference/summarize_process_groups.md)

## Examples

``` r
terrain <- derive_terrain(read_bathy(blueterra_example("bathy")))
assign_process_groups(terrain)
#> # A tibble: 13 × 7
#>    metric        metric_standard label process_group description source_function
#>    <chr>         <chr>           <chr> <chr>         <chr>       <chr>          
#>  1 bathy         bathy           Bath… base_bathyme… Input bath… as_bathy       
#>  2 slope_deg     slope_deg       Slope slope_gradie… Local stee… derive_slope   
#>  3 aspect_deg    aspect_deg      Aspe… seafloor_asp… Local down… derive_aspect  
#>  4 northness     northness       Nort… seafloor_asp… Cosine tra… derive_northne…
#>  5 eastness      eastness        East… seafloor_asp… Sine trans… derive_eastness
#>  6 hillshade     hillshade       Hill… base_bathyme… Shaded-rel… derive_hillsha…
#>  7 roughness     roughness       Roug… seafloor_rug… Difference… derive_roughne…
#>  8 tri           tri             Terr… seafloor_rug… terra terr… derive_tri     
#>  9 tpi           tpi             Topo… seafloor_pos… Cell posit… derive_tpi     
#> 10 bpi_3x3       bpi_3x3         Fine… seafloor_pos… Fine-scale… derive_bpi     
#> 11 bpi_11x11     bpi_11x11       Broa… seafloor_pos… Broad-scal… derive_bpi     
#> 12 curvature     curvature       Four… curvature     Sum of the… derive_curvatu…
#> 13 surface_area… surface_area_r… Surf… seafloor_rug… Slope-seca… derive_surface…
#> # ℹ 1 more variable: matched <lgl>
```
