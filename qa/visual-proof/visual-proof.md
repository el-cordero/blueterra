# blueterra Visual Proof

- Date/time: 2026-07-09 23:53:48 AST
- Git commit: a56cdd2851b93ea4b69632ac742dfecfad1bf028
- Working tree dirty at proof start: TRUE
- Dirty paths at proof start:  M R/transects.R;  M man/figures/README-profile-and-corridors-1.png;  M qa/visual-proof/figures/18-cross-sections-with-legend.png;  M qa/visual-proof/visual-proof.md;  M tests/testthat/test-plotting.R
- R version: R version 4.5.3 (2026-03-11)
- Package version: 0.1.0
- System: Darwin 25.2.0 arm64
- Package tarball: blueterra_0.1.0.tar.gz
- Package tarball size: 4484410 bytes
- Package tarball size: 4.484 MB
- Local pkgdown site: /Users/ec/Documents/Data/MCE Geomorphometry HW v HY/Geomorphic_Analysis_Project/blueterra/docs/index.html
- Expected GitHub Pages URL: https://el-cordero.github.io/blueterra/
- Deployment workflow: .github/workflows/pkgdown.yaml

## Example Files

                 name                                file bytes    mb
1                hitw           laparguera_hitw_bathy.tif 17528 0.018
2                hoyo           laparguera_hoyo_bathy.tif 24563 0.025
3               slope          laparguera_slope_bathy.tif 20990 0.021
4 sampling_rectangles laparguera_sampling_rectangles.gpkg 98304 0.098
5     synthetic_bathy            synthetic_test_bathy.tif 16484 0.016
6     synthetic_zones           synthetic_test_zones.gpkg 98304 0.098

## Commands Run

- Rscript qa/visual-proof/visual-proof.R
- rmarkdown::render('README.Rmd', output_format = github_document)
- pkgdown::build_site(examples = FALSE, new_process = FALSE)
- devtools::test()
- devtools::check(args = "--as-cran")
- R CMD build .

## Figures

- [00-study-area-pr-southwest-shelf-margin.png](figures/00-study-area-pr-southwest-shelf-margin.png)
- [01-hitw-bathymetry.png](figures/01-hitw-bathymetry.png)
- [02-hoyo-bathymetry.png](figures/02-hoyo-bathymetry.png)
- [03-slope-clip-bathymetry.png](figures/03-slope-clip-bathymetry.png)
- [04-sampling-rectangles-over-bathymetry.png](figures/04-sampling-rectangles-over-bathymetry.png)
- [05-prepared-depth-filtered-bathymetry.png](figures/05-prepared-depth-filtered-bathymetry.png)
- [06-hillshade.png](figures/06-hillshade.png)
- [07-slope.png](figures/07-slope.png)
- [08-northness.png](figures/08-northness.png)
- [09-rugosity.png](figures/09-rugosity.png)
- [10-bpi.png](figures/10-bpi.png)
- [11-curvature.png](figures/11-curvature.png)
- [12-surface-area-ratio.png](figures/12-surface-area-ratio.png)
- [13-metric-stack-preview.png](figures/13-metric-stack-preview.png)
- [14-process-group-summary.png](figures/14-process-group-summary.png)
- [15-sampling-rectangle-summary.png](figures/15-sampling-rectangle-summary.png)
- [16-depth-band-summary.png](figures/16-depth-band-summary.png)
- [17-transects-over-bathymetry-auto-orientation.png](figures/17-transects-over-bathymetry-auto-orientation.png)
- [18-cross-sections-with-legend.png](figures/18-cross-sections-with-legend.png)
- [19-depth-profile-single-transect.png](figures/19-depth-profile-single-transect.png)
- [20-isobaths-over-bathymetry.png](figures/20-isobaths-over-bathymetry.png)
- [21-isobath-corridors-source-isobaths.png](figures/21-isobath-corridors-source-isobaths.png)
- [22-isobath-terrain-summary.png](figures/22-isobath-terrain-summary.png)
- [23-pca-overall.png](figures/23-pca-overall.png)
- [24-pca-hole-in-the-wall.png](figures/24-pca-hole-in-the-wall.png)
- [25-pca-el-hoyo.png](figures/25-pca-el-hoyo.png)
- [26-correlation-plot.png](figures/26-correlation-plot.png)

## Screenshots

-  Screenshot tooling was not available in this environment.

## Representative Outputs

```
# A tibble: 1 × 13
  layer    nrow  ncol ncell    xmin   xmax   ymin   ymax  xres  yres   min   max
  <chr>   <dbl> <dbl> <dbl>   <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
1 bathy_m    75    75  5625 137474. 1.38e5 2.06e5 2.06e5  4.00  4.00 -269. -16.6
# ℹ 1 more variable: crs <chr>
# A tibble: 1 × 13
  layer    nrow  ncol ncell    xmin   xmax   ymin   ymax  xres  yres   min   max
  <chr>   <dbl> <dbl> <dbl>   <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
1 bathy_m   123   124 15252 135452. 1.36e5 2.05e5 2.05e5  4.00  4.00 -269. -19.4
# ℹ 1 more variable: crs <chr>
# A tibble: 1 × 13
  layer    nrow  ncol ncell    xmin   xmax   ymin   ymax  xres  yres   min   max
  <chr>   <dbl> <dbl> <dbl>   <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
1 bathy_m    90   190 17100 134960. 1.39e5 2.04e5 2.06e5  20.0  20.0 -427. -15.9
# ℹ 1 more variable: crs <chr>
class       : SpatVector
geometry    : polygons
dimensions  : 3, 7  (geometries, attributes)
extent      : 134960.3, 138741.2, 204155.7, 205950.2  (xmin, xmax, ymin, ymax)
source      : laparguera_sampling_rectangles.gpkg
coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
names       : site_id        site_name    feature_type      source_name width_m height_m angle_deg
type        :   <chr>            <chr>           <chr>            <chr>   <num>    <num>     <num>
values      :    hitw Hole-in-the-Wall sampling_recta~ Hole In the Wall     300      300         0
                 hoyo          El Hoyo sampling_recta~     Hoyo Terrace     300      400       135
                slope       Slope Clip analysis_extent  Slope_clip_bat~      NA       NA        NA
 [1] "slope_deg"          "aspect_deg"         "northness"         
 [4] "eastness"           "tri"                "rugosity_vrm_3x3"  
 [7] "bpi_3x3"            "bpi_11x11"          "curvature"         
[10] "surface_area_ratio"
# A tibble: 3 × 4
  site_id site_name        slope_deg_mean bpi_3x3_mean
  <chr>   <chr>                     <dbl>        <dbl>
1 hitw    Hole-in-the-Wall           31.6       0.223 
2 hoyo    El Hoyo                    26.9       0.230 
3 slope   Slope Clip                 27.7      -0.0384
# A tibble: 5 × 8
  depth_band  metric    n_cells  mean    sd   min   max median
  <chr>       <chr>       <int> <dbl> <dbl> <dbl> <dbl>  <dbl>
1 [-220,-150) slope_deg     819  55.3 10.7   34.8  80.5   51.8
2 [-150,-100) slope_deg     180  77.8  2.29  68.5  81.7   77.8
3 [-100,-60)  slope_deg     791  43.5  9.79  18.8  76.5   40.9
4 [-60,-30)   slope_deg     521  45.7  4.87  10.6  55.5   45.5
5 [-30,-20]   slope_deg       4  NA   NA     NA    NA     NA  
# A tibble: 1 × 5
  bearing_deg transect_angle_deg orientation_weight min_slope
        <dbl>              <dbl> <chr>                  <dbl>
1        175.               94.6 slope                      0
# ℹ 1 more variable: n_orientation_cells <int>
  angle_deg angle_source mean_aspect_deg
1  94.61515      surface        175.3849
# A tibble: 3 × 3
  contour_value slope_deg_mean bpi_3x3_mean
          <dbl>          <dbl>        <dbl>
1           -50           46.2     -0.01000
2           -80           40.0     -0.0209 
3          -120           77.7      1.25   
# A tibble: 4 × 3
  component proportion cumulative
  <chr>          <dbl>      <dbl>
1 PC1         0.711         0.711
2 PC2         0.257         0.968
3 PC3         0.0317        1.000
4 PC4         0.000138      1    
                              PC1                               PC2 
"PC1 (71.1%; bpi_3x3, curvature)"     "PC2 (25.7%; slope_deg, tri)" 
# A tibble: 4 × 3
  component proportion cumulative
  <chr>          <dbl>      <dbl>
1 PC1         0.779         0.779
2 PC2         0.206         0.984
3 PC3         0.0153        1.000
4 PC4         0.000168      1    
# A tibble: 4 × 3
  component proportion cumulative
  <chr>          <dbl>      <dbl>
1 PC1       0.611           0.611
2 PC2       0.369           0.980
3 PC3       0.0201          1.000
4 PC4       0.00000622      1    
# A tibble: 4 × 7
  variable  group_1          group_2 mean_1  mean_2 effect_size method  
  <chr>     <chr>            <chr>    <dbl>   <dbl>       <dbl> <chr>   
1 slope_deg Hole-in-the-Wall El Hoyo 53.0   29.3          1.37  cohens_d
2 tri       Hole-in-the-Wall El Hoyo  5.65   2.45         0.781 cohens_d
3 bpi_3x3   Hole-in-the-Wall El Hoyo  0.464  0.0714       0.356 cohens_d
4 curvature Hole-in-the-Wall El Hoyo -1.41  -0.222       -0.352 cohens_d
# A tibble: 6 × 3
  var1      var2      correlation
  <chr>     <chr>           <dbl>
1 slope_deg tri             0.872
2 slope_deg bpi_3x3         0.434
3 tri       bpi_3x3         0.486
4 slope_deg curvature      -0.425
5 tri       curvature      -0.470
6 bpi_3x3   curvature      -0.999
```

## Test Results

- devtools::test ok: TRUE
- Log: qa/visual-proof/logs/devtools-test.log

## Check Results

- devtools::check ok: TRUE
- Log: qa/visual-proof/logs/devtools-check.log
- R CMD build ok: TRUE
- Log: qa/visual-proof/logs/r-cmd-build.log

## HTML Results

- pkgdown build ok: TRUE
- Local docs path: docs/index.html
- Expected GitHub Pages URL: https://el-cordero.github.io/blueterra/
- Deployment workflow file: .github/workflows/pkgdown.yaml
- xml2 HTML parse ok: TRUE
- HTML Tidy path: /opt/homebrew/opt/tidy-html5/bin/tidy
- HTML Tidy status: 1
- HTML Tidy log: qa/visual-proof/logs/html-tidy.log

## Known Limitations

-  Screenshot tooling was not available in this environment.
