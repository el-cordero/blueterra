# blueterra Visual Proof

- Date/time: 2026-07-08 23:56:08 AST
- Git commit: c00bb45d97104c7f09ad754e16a83c245b762cf5
- Working tree dirty at proof time: TRUE
- R version: R version 4.5.3 (2026-03-11)
- Package version: 0.1.0
- System: Darwin 25.2.0 arm64

## Commands Run

- Rscript qa/visual-proof/visual-proof.R
- devtools::build_readme()
- pkgdown::build_site()
- devtools::test()
- devtools::check(args = "--as-cran")

## Figures

- [01-input-raster.png](figures/01-input-raster.png)
- [02-prepared-raster.png](figures/02-prepared-raster.png)
- [03-hillshade.png](figures/03-hillshade.png)
- [04-slope.png](figures/04-slope.png)
- [05-northness.png](figures/05-northness.png)
- [06-rugosity.png](figures/06-rugosity.png)
- [07-bpi.png](figures/07-bpi.png)
- [08-curvature.png](figures/08-curvature.png)
- [09-metric-stack-preview.png](figures/09-metric-stack-preview.png)
- [10-process-summary-plot.png](figures/10-process-summary-plot.png)
- [11-depth-band-summary.png](figures/11-depth-band-summary.png)
- [12-transects-over-bathymetry.png](figures/12-transects-over-bathymetry.png)
- [13-cross-sections.png](figures/13-cross-sections.png)
- [14-isobaths-over-bathymetry.png](figures/14-isobaths-over-bathymetry.png)
- [15-isobath-corridors.png](figures/15-isobath-corridors.png)
- [16-terrain-summary-table.png](figures/16-terrain-summary-table.png)
- [17-pca-plot.png](figures/17-pca-plot.png)

## Screenshots

- Screenshot tooling was not available in this environment.

## Representative Outputs

```
# A tibble: 1 × 13
  layer  nrow  ncol ncell  xmin  xmax  ymin  ymax  xres  yres   min   max crs   
  <chr> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <chr> 
1 bathy    60    60  3600     0   600     0   600    10    10 -94.3 -20.3 "PROJ…
 [1] "slope_deg"          "aspect_deg"         "northness"         
 [4] "eastness"           "tri"                "bpi_3x3"           
 [7] "bpi_11x11"          "rugosity_vrm_3x3"   "curvature"         
[10] "surface_area_ratio"
# A tibble: 2 × 52
  zone_id setting     slope_deg_mean slope_deg_sd slope_deg_min slope_deg_max
    <int> <chr>                <dbl>        <dbl>         <dbl>         <dbl>
1       1 ridge_basin           8.32         4.53         0.431          19.9
2       2 slope_break           9.28         2.40         5.67           14.7
# ℹ 46 more variables: slope_deg_median <dbl>, aspect_deg_mean <dbl>,
#   aspect_deg_sd <dbl>, aspect_deg_min <dbl>, aspect_deg_max <dbl>,
#   aspect_deg_median <dbl>, northness_mean <dbl>, northness_sd <dbl>,
#   northness_min <dbl>, northness_max <dbl>, northness_median <dbl>,
#   eastness_mean <dbl>, eastness_sd <dbl>, eastness_min <dbl>,
#   eastness_max <dbl>, eastness_median <dbl>, tri_mean <dbl>, tri_sd <dbl>,
#   tri_min <dbl>, tri_max <dbl>, tri_median <dbl>, bpi_3x3_mean <dbl>, …
# A tibble: 6 × 8
  depth_band metric     n_cells     mean      sd    min     max   median
  <chr>      <chr>        <int>    <dbl>   <dbl>  <dbl>   <dbl>    <dbl>
1 [-90,-70)  slope_deg      794   8.51     2.96   3.66   18.2     7.11  
2 [-90,-70)  aspect_deg     794 189.     150.     0.303 360.    295.    
3 [-90,-70)  northness      794   0.809    0.201  0.292   1.000   0.886 
4 [-90,-70)  eastness       794   0.0213   0.552 -0.940   0.956  -0.0922
5 [-90,-70)  tri            794   1.16     0.404  0.514   2.39    0.973 
6 [-90,-70)  bpi_3x3        794  -0.0747   0.160 -0.680   0.186  -0.0249
# A tibble: 10 × 3
   component proportion cumulative
   <chr>          <dbl>      <dbl>
 1 PC1         0.445         0.445
 2 PC2         0.250         0.695
 3 PC3         0.122         0.817
 4 PC4         0.0901        0.907
 5 PC5         0.0563        0.963
 6 PC6         0.0214        0.985
 7 PC7         0.0111        0.996
 8 PC8         0.00374       1.000
 9 PC9         0.000171      1.000
10 PC10        0.000115      1    
```

## Test Results

- devtools::test ok: TRUE
- Log: qa/visual-proof/logs/devtools-test.log

## Check Results

- devtools::check ok: TRUE
- Log: qa/visual-proof/logs/devtools-check.log

## HTML Results

- pkgdown build ok: TRUE
- xml2 HTML parse ok: TRUE
- HTML Tidy log: qa/visual-proof/logs/html-tidy.log

## Known Limitations

- Browser screenshot capture was skipped because webshot2 was not available.
