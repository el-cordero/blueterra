# Package index

## Input and validation

Read, validate, and inspect bathymetric or elevation rasters.

- [`read_bathy()`](https://el-cordero.github.io/blueterra/reference/read_bathy.md)
  : Read a bathymetric or elevation raster
- [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md)
  : Coerce common raster inputs to a bathymetry raster
- [`validate_bathy()`](https://el-cordero.github.io/blueterra/reference/validate_bathy.md)
  : Validate a bathymetric or elevation raster
- [`check_bathy_crs()`](https://el-cordero.github.io/blueterra/reference/check_bathy_crs.md)
  : Check raster CRS for geomorphometry
- [`check_bathy_units()`](https://el-cordero.github.io/blueterra/reference/check_bathy_units.md)
  : Check bathymetry value conventions
- [`bathy_info()`](https://el-cordero.github.io/blueterra/reference/bathy_info.md)
  : Summarize a bathymetric or elevation raster
- [`blueterra_example()`](https://el-cordero.github.io/blueterra/reference/blueterra_example.md)
  [`blueterra_examples()`](https://el-cordero.github.io/blueterra/reference/blueterra_example.md)
  [`blueterra_extdata()`](https://el-cordero.github.io/blueterra/reference/blueterra_example.md)
  : Locate package example files
- [`blueterra_options()`](https://el-cordero.github.io/blueterra/reference/blueterra_options.md)
  : Configure blueterra runtime options

## Raster preparation

Prepare surfaces before terrain derivatives are calculated.

- [`prepare_bathy()`](https://el-cordero.github.io/blueterra/reference/prepare_bathy.md)
  : Prepare a bathymetric or elevation raster
- [`crop_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md)
  [`mask_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md)
  [`resample_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md)
  [`project_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md)
  : Crop, mask, resample, and project bathymetry
- [`smooth_bathy()`](https://el-cordero.github.io/blueterra/reference/smooth_bathy.md)
  : Smooth a bathymetric or elevation raster
- [`depth_filter()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md)
  [`invert_depth()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md)
  [`set_depth_positive()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md)
  [`set_depth_negative()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md)
  : Filter or convert bathymetric depth values

## Terrain metrics

Derive terrain attributes from submerged surfaces.

- [`derive_terrain()`](https://el-cordero.github.io/blueterra/reference/derive_terrain.md)
  : Derive bathymetric terrain metrics
- [`derive_metric_stack()`](https://el-cordero.github.io/blueterra/reference/derive_metric_stack.md)
  : Build a stack of terrain metrics
- [`derive_slope()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_aspect()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_northness()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_eastness()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_hillshade()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_roughness()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_tri()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_tpi()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_rugosity()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_curvature()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  [`derive_surface_area_ratio()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)
  : Derive individual terrain metrics
- [`derive_bpi()`](https://el-cordero.github.io/blueterra/reference/derive_bpi.md)
  [`derive_multiscale_bpi()`](https://el-cordero.github.io/blueterra/reference/derive_bpi.md)
  : Derive bathymetric position index

## Custom metrics and process groups

Add user-defined raster layers, formulas, and process group catalogs.

- [`add_metric_layers()`](https://el-cordero.github.io/blueterra/reference/add_metric_layers.md)
  : Add metric layers to an existing raster stack
- [`derive_custom_metric()`](https://el-cordero.github.io/blueterra/reference/derive_custom_metric.md)
  : Derive a custom metric from raster layers
- [`create_metric_catalog()`](https://el-cordero.github.io/blueterra/reference/create_metric_catalog.md)
  [`extend_metric_catalog()`](https://el-cordero.github.io/blueterra/reference/create_metric_catalog.md)
  [`validate_metric_catalog()`](https://el-cordero.github.io/blueterra/reference/create_metric_catalog.md)
  : Create and validate metric catalog rows
- [`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md)
  [`process_groups()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md)
  : Terrain metric catalog
- [`metric_catalog_data`](https://el-cordero.github.io/blueterra/reference/metric_catalog_data.md)
  : Terrain metric catalog data
- [`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md)
  : Assign metrics to process groups
- [`select_process_representatives()`](https://el-cordero.github.io/blueterra/reference/select_process_representatives.md)
  : Select representative metrics for each process group
- [`summarize_process_groups()`](https://el-cordero.github.io/blueterra/reference/summarize_process_groups.md)
  : Summarize process group representation
- [`standardize_metric_names()`](https://el-cordero.github.io/blueterra/reference/standardize_metric_names.md)
  [`rename_metric_layers()`](https://el-cordero.github.io/blueterra/reference/standardize_metric_names.md)
  : Standardize or rename metric layers

## Transects and isobaths

Extract cross-sections and depth-following terrain summaries.

- [`estimate_surface_orientation()`](https://el-cordero.github.io/blueterra/reference/estimate_surface_orientation.md)
  : Estimate mean surface orientation from a bathymetric raster
- [`make_transects()`](https://el-cordero.github.io/blueterra/reference/make_transects.md)
  : Create transects across polygon zones
- [`sample_transects()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md)
  [`extract_cross_sections()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md)
  : Sample rasters along transects
- [`summarize_cross_sections()`](https://el-cordero.github.io/blueterra/reference/summarize_cross_sections.md)
  : Summarize sampled cross-sections
- [`extract_isobaths()`](https://el-cordero.github.io/blueterra/reference/extract_isobaths.md)
  : Extract isobaths from a raster
- [`make_isobath_corridors()`](https://el-cordero.github.io/blueterra/reference/make_isobath_corridors.md)
  : Build isobath corridors
- [`extract_isobath_corridors()`](https://el-cordero.github.io/blueterra/reference/extract_isobath_corridors.md)
  : Extract terrain cells in isobath corridors
- [`summarize_isobath_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_isobath_terrain.md)
  : Summarize terrain by isobath corridor

## Spatial summaries

Summarize raster values by zones, depth bands, and points.

- [`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)
  [`summarize_terrain_by_zone()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)
  : Summarize terrain metrics by polygon zones
- [`summarize_depth_bands()`](https://el-cordero.github.io/blueterra/reference/summarize_depth_bands.md)
  : Summarize terrain by depth bands
- [`extract_terrain_points()`](https://el-cordero.github.io/blueterra/reference/extract_terrain_points.md)
  : Extract terrain values at points
- [`sample_terrain_cells()`](https://el-cordero.github.io/blueterra/reference/sample_terrain_cells.md)
  : Sample terrain raster cells

## Modeling helpers

Prepare terrain tables for exploratory modeling.

- [`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md)
  : Principal components analysis for terrain tables
- [`terrain_pca_by_group()`](https://el-cordero.github.io/blueterra/reference/terrain_pca_by_group.md)
  : Run PCA overall and within groups
- [`pca_axis_labels()`](https://el-cordero.github.io/blueterra/reference/pca_axis_labels.md)
  : Label PCA axes with variance and dominant loadings
- [`terrain_effect_size()`](https://el-cordero.github.io/blueterra/reference/terrain_effect_size.md)
  : Terrain effect sizes
- [`terrain_correlation()`](https://el-cordero.github.io/blueterra/reference/terrain_correlation.md)
  : Correlation table for terrain variables
- [`prepare_model_matrix()`](https://el-cordero.github.io/blueterra/reference/prepare_model_matrix.md)
  : Prepare a model matrix from terrain data
- [`balance_samples()`](https://el-cordero.github.io/blueterra/reference/balance_samples.md)
  : Balance samples across groups

## Plotting

Create hillshade-supported maps, profiles, and summary plots.

- [`plot_bathy()`](https://el-cordero.github.io/blueterra/reference/plot_bathy.md)
  [`plot_metric()`](https://el-cordero.github.io/blueterra/reference/plot_bathy.md)
  [`plot_terrain_map()`](https://el-cordero.github.io/blueterra/reference/plot_bathy.md)
  [`plot_hillshade()`](https://el-cordero.github.io/blueterra/reference/plot_bathy.md)
  [`plot_sampling_rectangles()`](https://el-cordero.github.io/blueterra/reference/plot_bathy.md)
  [`plot_transects()`](https://el-cordero.github.io/blueterra/reference/plot_bathy.md)
  [`plot_metric_stack()`](https://el-cordero.github.io/blueterra/reference/plot_bathy.md)
  : Plot bathymetry and terrain rasters
- [`plot_cross_sections()`](https://el-cordero.github.io/blueterra/reference/plot_cross_sections.md)
  : Plot sampled cross-sections
- [`plot_depth_profile()`](https://el-cordero.github.io/blueterra/reference/plot_depth_profile.md)
  : Plot a depth profile
- [`plot_isobath_corridors()`](https://el-cordero.github.io/blueterra/reference/plot_isobath_corridors.md)
  : Plot isobath corridors
- [`plot_process_density()`](https://el-cordero.github.io/blueterra/reference/plot_process_density.md)
  : Plot process density
- [`plot_process_pca()`](https://el-cordero.github.io/blueterra/reference/plot_process_pca.md)
  : Plot terrain PCA
- [`plot_terrain_summary()`](https://el-cordero.github.io/blueterra/reference/plot_terrain_summary.md)
  : Plot terrain summaries
