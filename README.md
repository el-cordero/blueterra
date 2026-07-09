
<img src="man/figures/logo.png" align="right" height="140" alt="blueterra logo" />

# blueterra

`blueterra` provides tools for process-oriented geomorphometry of
submerged terrain from user-supplied bathymetric or elevation rasters.
It derives terrain metrics, organizes them into geomorphic process
groups, and summarizes terrain across polygons, transects, depth bands,
and isobath corridors.

`blueterra` does not download or mosaic BlueTopo data. BlueTopo
acquisition will be handled by a separate package. Users can provide any
suitable bathymetric or elevation raster supported by `terra`.

## Installation

Install from a local source checkout:

``` r
install.packages("path/to/blueterra", repos = NULL, type = "source")
```

After a public repository is available, install from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("owner/blueterra")
```

## Scope

`blueterra` focuses on local terrain analysis after a raster already
exists:

- read and validate user-supplied bathymetric or elevation rasters
- prepare raster surfaces for terrain analysis
- derive slope, aspect, orientation, ruggedness, BPI, TPI, curvature,
  and surface-structure metrics
- map metrics to process-oriented terrain groups
- summarize metrics across polygons, depth bands, transects, and isobath
  corridors
- create model-ready tables and summary plots

Out of scope:

- BlueTopo download
- BlueTopo tile discovery
- BlueTopo mosaicking or combining
- remote bathymetry acquisition
- persistent download caches

## Quick Start

``` r
library(blueterra)

bathy <- read_bathy(blueterra_example("bathy"))
bathy_info(bathy)
#> # A tibble: 1 × 13
#>   layer  nrow  ncol ncell  xmin  xmax  ymin  ymax  xres  yres   min   max crs   
#>   <chr> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <chr> 
#> 1 bathy    60    60  3600     0   600     0   600    10    10 -86.3 -20.5 "PROJ…

terrain <- derive_terrain(
  bathy,
  metrics = c("slope", "aspect", "northness", "eastness", "bpi", "roughness")
)

names(terrain)
#> [1] "slope_deg"  "aspect_deg" "northness"  "eastness"   "bpi_3x3"   
#> [6] "bpi_11x11"  "roughness"
assign_process_groups(terrain)
#> # A tibble: 7 × 7
#>   metric metric_standard label process_group description source_function matched
#>   <chr>  <chr>           <chr> <chr>         <chr>       <chr>           <lgl>  
#> 1 slope… slope_deg       Slope slope_gradie… Local slop… derive_slope    TRUE   
#> 2 aspec… aspect_deg      Aspe… orientation   Local down… derive_aspect   TRUE   
#> 3 north… northness       Nort… orientation   Cosine tra… derive_northne… TRUE   
#> 4 eastn… eastness        East… orientation   Sine trans… derive_eastness TRUE   
#> 5 bpi_3… bpi_3x3         Fine… seafloor_pos… Fine-scale… derive_bpi      TRUE   
#> 6 bpi_1… bpi_11x11       Broa… seafloor_pos… Broad-scal… derive_bpi      TRUE   
#> 7 rough… roughness       Roug… seafloor_rug… Local rang… derive_roughne… TRUE
```

Summarize terrain by polygons:

``` r
sites <- sf::st_read(blueterra_example("sites"), quiet = TRUE)
summarize_terrain(terrain, sites)
#> # A tibble: 2 × 38
#>   site_id setting zone_id slope_deg_mean slope_deg_sd slope_deg_min
#>   <chr>   <chr>     <int>          <dbl>        <dbl>         <dbl>
#> 1 site_a  mound         1           7.68         4.34         0.431
#> 2 site_b  channel       2           7.46         2.21         1.91 
#> # ℹ 32 more variables: slope_deg_max <dbl>, slope_deg_median <dbl>,
#> #   aspect_deg_mean <dbl>, aspect_deg_sd <dbl>, aspect_deg_min <dbl>,
#> #   aspect_deg_max <dbl>, aspect_deg_median <dbl>, northness_mean <dbl>,
#> #   northness_sd <dbl>, northness_min <dbl>, northness_max <dbl>,
#> #   northness_median <dbl>, eastness_mean <dbl>, eastness_sd <dbl>,
#> #   eastness_min <dbl>, eastness_max <dbl>, eastness_median <dbl>,
#> #   bpi_3x3_mean <dbl>, bpi_3x3_sd <dbl>, bpi_3x3_min <dbl>, …
```

Summarize by depth bands:

``` r
summarize_depth_bands(
  bathy,
  metrics = terrain,
  breaks = c(-90, -60, -30, 0)
)
#> # A tibble: 21 × 8
#>    depth_band metric     n_cells     mean      sd     min     max   median
#>    <chr>      <chr>        <int>    <dbl>   <dbl>   <dbl>   <dbl>    <dbl>
#>  1 [-90,-60)  slope_deg     1419   7.27     2.33   1.89    16.5     6.94  
#>  2 [-90,-60)  aspect_deg    1419 154.     141.     0.0569 360.     56.0   
#>  3 [-90,-60)  northness     1419   0.741    0.199  0.325    1.000   0.780 
#>  4 [-90,-60)  eastness      1419   0.0717   0.637 -0.946    0.893   0.283 
#>  5 [-90,-60)  bpi_3x3       1419  -0.0395   0.114 -0.700    0.104  -0.0108
#>  6 [-90,-60)  bpi_11x11     1419  -0.576    1.00  -3.59     1.43   -0.635 
#>  7 [-90,-60)  roughness     1419   3.41     1.19   0.836    8.38    3.22  
#>  8 [-60,-30)  slope_deg     1679   7.41     2.90   0.431   18.2     6.61  
#>  9 [-60,-30)  aspect_deg    1679 196.     154.     0.141  360.    307.    
#> 10 [-60,-30)  northness     1679   0.840    0.213 -0.999    1.000   0.915 
#> # ℹ 11 more rows
```

Build and summarize an isobath corridor:

``` r
corridor <- make_isobath_corridors(bathy, depths = -50, width = 20)
summarize_isobath_terrain(terrain, corridor)
#> # A tibble: 1 × 40
#>   level contour_value depth_label corridor_id zone_id slope_deg_mean
#>   <dbl>         <dbl>       <dbl>       <int>   <int>          <dbl>
#> 1   -50           -50         -50           1       1           9.53
#> # ℹ 34 more variables: slope_deg_sd <dbl>, slope_deg_min <dbl>,
#> #   slope_deg_max <dbl>, slope_deg_median <dbl>, aspect_deg_mean <dbl>,
#> #   aspect_deg_sd <dbl>, aspect_deg_min <dbl>, aspect_deg_max <dbl>,
#> #   aspect_deg_median <dbl>, northness_mean <dbl>, northness_sd <dbl>,
#> #   northness_min <dbl>, northness_max <dbl>, northness_median <dbl>,
#> #   eastness_mean <dbl>, eastness_sd <dbl>, eastness_min <dbl>,
#> #   eastness_max <dbl>, eastness_median <dbl>, bpi_3x3_mean <dbl>, …
```

## User-Supplied Rasters

Use any local raster readable by `terra`:

``` r
path <- "my_bathymetry_or_dem.tif"
bathy <- read_bathy(path)
terrain <- derive_terrain(bathy)
```

`blueterra` preserves depth sign conventions unless a function
explicitly asks for a conversion:

``` r
positive_depth <- set_depth_positive(bathy)
negative_depth <- set_depth_negative(positive_depth)
```

Metric derivation is scale-sensitive. Use projected coordinate systems
when distances, slopes, buffers, or focal windows need interpretable
linear units.

## Function Overview

Input and validation: `read_bathy()`, `as_bathy()`, `validate_bathy()`,
`check_bathy_crs()`, `check_bathy_units()`, `bathy_info()`.

Raster preparation: `prepare_bathy()`, `crop_bathy()`, `mask_bathy()`,
`resample_bathy()`, `project_bathy()`, `smooth_bathy()`,
`depth_filter()`, `invert_depth()`, `set_depth_positive()`,
`set_depth_negative()`.

Terrain metrics: `derive_terrain()`, `derive_slope()`,
`derive_aspect()`, `derive_northness()`, `derive_eastness()`,
`derive_hillshade()`, `derive_rugosity()`, `derive_roughness()`,
`derive_tri()`, `derive_tpi()`, `derive_bpi()`,
`derive_multiscale_bpi()`, `derive_curvature()`,
`derive_surface_area_ratio()`, `derive_metric_stack()`.

Summaries and geometry: `summarize_terrain()`,
`summarize_depth_bands()`, `make_transects()`, `sample_transects()`,
`extract_cross_sections()`, `extract_isobaths()`,
`make_isobath_corridors()`, `summarize_isobath_terrain()`.

Modeling and plotting: `terrain_pca()`, `terrain_effect_size()`,
`terrain_correlation()`, `prepare_model_matrix()`, `balance_samples()`,
`plot_bathy()`, `plot_metric()`, `plot_metric_stack()`,
`plot_depth_profile()`.

## Citation

Citation details will be added before release. Until then, cite the
package source and version used in your analysis.

## License

MIT. See `LICENSE.md`.

## Development Status

Development version. Confirm author, maintainer, repository, copyright,
and release metadata before CRAN submission.
