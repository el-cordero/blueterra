test_that("real analysis example rasters and rectangles are usable", {
  example_names <- c("hitw", "hoyo", "slope")
  rectangles <- terra::vect(blueterra_example("sampling_rectangles"))

  expect_s4_class(rectangles, "SpatVector")
  expect_true(nrow(rectangles) >= 3)
  expect_true(nzchar(terra::crs(rectangles)))
  expect_true(all(c("site_id", "site_name", "feature_type") %in% names(rectangles)))

  for (nm in example_names) {
    bathy <- read_bathy(blueterra_example(nm))
    expect_s4_class(bathy, "SpatRaster")
    expect_true(nzchar(terra::crs(bathy)))
    expect_lte(max(terra::nrow(bathy), terra::ncol(bathy)), 250)
    expect_gt(terra::ncell(bathy), 1000)
    expect_false(all(is.na(terra::values(bathy))))

    prepared <- prepare_bathy(bathy, depth_range = c(-300, -15), smooth = TRUE)
    expect_s4_class(prepared, "SpatRaster")

    terrain <- derive_terrain(
      prepared,
      metrics = c("slope", "northness", "eastness", "tri", "bpi", "curvature")
    )
    expect_true(all(c("slope_deg", "bpi_3x3", "curvature") %in% names(terrain)))

    site_zone <- rectangles[rectangles$site_id == nm, ]
    if (nrow(site_zone) > 0) {
      zone_summary <- summarize_terrain(terrain, site_zone, fun = c("mean", "sd"))
      expect_s3_class(zone_summary, "tbl_df")
      expect_true("slope_deg_mean" %in% names(zone_summary))

      transects <- make_transects(site_zone, spacing = 100, bathy = prepared)
      expect_s4_class(transects, "SpatVector")
      expect_true("angle_source" %in% names(transects))
      samples <- sample_transects(transects, prepared, n = 6)
      expect_s3_class(samples, "tbl_df")
    }

    bands <- summarize_depth_bands(
      prepared,
      metrics = terrain,
      breaks = c(-300, -150, -100, -60, -30, -15)
    )
    expect_s3_class(bands, "tbl_df")
    expect_true("depth_band" %in% names(bands))
  }
})

test_that("real examples support isobath-corridor workflows and plots", {
  testthat::skip_if_not_installed("ggplot2")

  bathy <- read_bathy(blueterra_example("hitw"))
  terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
  corridors <- make_isobath_corridors(bathy, depths = c(-50, -80), width = 5)
  expect_s4_class(corridors, "SpatVector")
  expect_equal(terra::geomtype(corridors), "polygons")

  iso <- extract_isobaths(bathy, depths = c(-50, -80))
  expect_s4_class(iso, "SpatVector")

  summary <- summarize_isobath_terrain(terrain, corridors)
  expect_s3_class(summary, "tbl_df")
  expect_true("slope_deg_mean" %in% names(summary))

  expect_s3_class(plot_bathy(bathy), "ggplot")
  expect_s3_class(plot_metric(terrain, "slope_deg"), "ggplot")
  expect_s3_class(plot_isobath_corridors(corridors, bathy, isobaths = iso), "ggplot")
})
