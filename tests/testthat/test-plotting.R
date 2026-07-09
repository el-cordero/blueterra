test_that("plotting functions return ggplot objects when ggplot2 is installed", {
  testthat::skip_if_not_installed("ggplot2")
  bathy <- example_bathy()
  terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
  zones <- example_zones()
  expect_s3_class(plot_bathy(bathy), "ggplot")
  expect_s3_class(
    plot_bathy(bathy, vectors = zones, labels = TRUE, label_field = "zone_id"),
    "ggplot"
  )
  expect_s3_class(plot_hillshade(bathy), "ggplot")
  expect_s3_class(plot_metric(terrain, "slope_deg"), "ggplot")
  expect_s3_class(
    plot_metric(terrain, "slope_deg", bathy = bathy, contours = TRUE, contour_interval = 20),
    "ggplot"
  )
  expect_s3_class(plot_terrain_map(bathy, terrain[["bpi_3x3"]]), "ggplot")
  expect_s3_class(plot_sampling_rectangles(bathy, zones), "ggplot")
  expect_s3_class(plot_metric_stack(terrain), "ggplot")
  expect_s3_class(plot_process_density(data.frame(value = rnorm(20)), "value"), "ggplot")
  cells <- sample_terrain_cells(terrain, size = 30)
  expect_s3_class(plot_process_pca(terrain_pca(cells)), "ggplot")
  profile <- data.frame(distance = 1:5, depth = -seq(10, 50, by = 10))
  expect_s3_class(plot_depth_profile(profile, depth_col = "depth"), "ggplot")
  summary <- data.frame(zone_id = 1:2, slope_mean = c(2, 5))
  expect_s3_class(plot_terrain_summary(summary, value = "slope_mean"), "ggplot")
  corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
  expect_s3_class(plot_isobath_corridors(corridors, bathy), "ggplot")
  transects <- make_transects(zones[1, ], spacing = 100)
  expect_s3_class(plot_transects(bathy, transects), "ggplot")
  samples <- sample_transects(transects, bathy, n = 5)
  expect_s3_class(plot_cross_sections(samples), "ggplot")
})

test_that("optional plotting dependency failure is clear", {
  expect_true(is.function(plot_bathy))
})
