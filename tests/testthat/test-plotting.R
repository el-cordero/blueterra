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
  pca <- terrain_pca(cells)
  expect_s3_class(plot_process_pca(pca), "ggplot")
  expect_s3_class(plot_process_pca(pca, axis_labels = "variance"), "ggplot")
  profile <- data.frame(distance = 1:5, depth = -seq(10, 50, by = 10))
  expect_s3_class(plot_depth_profile(profile, depth_col = "depth"), "ggplot")
  summary <- data.frame(zone_id = 1:2, slope_mean = c(2, 5))
  expect_s3_class(plot_terrain_summary(summary, value = "slope_mean"), "ggplot")
  corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
  isobaths <- extract_isobaths(bathy, depths = -50)
  corridor_plot <- plot_isobath_corridors(corridors, bathy, isobaths = isobaths)
  expect_s3_class(corridor_plot, "ggplot")
  expect_gte(length(corridor_plot$layers), 4)
  transects <- make_transects(zones[1, ], spacing = 100, angle = 0)
  expect_s3_class(plot_transects(bathy, transects), "ggplot")
  expect_s3_class(plot_transects(bathy, transects, color_by = "transect_id", show_legend = TRUE), "ggplot")
  samples <- sample_transects(transects, bathy, n = 5)
  cross_plot <- plot_cross_sections(samples)
  expect_s3_class(cross_plot, "ggplot")
  expect_equal(cross_plot$labels$colour, "Transect")
  expect_s3_class(plot_cross_sections(samples, show_legend = FALSE), "ggplot")
})

test_that("optional plotting dependency failure is clear", {
  expect_true(is.function(plot_bathy))
})

test_that("profile value inference ignores transect metadata", {
  samples <- data.frame(
    transect_id = rep(c("a", "b"), each = 4),
    distance = rep(1:4, 2),
    width_m = 300,
    height_m = 400,
    angle_deg = 94.6,
    offset = rep(c(-50, 50), each = 4),
    bathy_m = c(-40, -45, -50, -55, -42, -47, -52, -57),
    slope_deg = c(12, 15, 18, 21, 13, 16, 19, 22)
  )
  expect_equal(blueterra:::infer_profile_value_col(samples), "bathy_m")
  expect_equal(blueterra:::infer_profile_value_col(samples, value_col = "slope_deg"), "slope_deg")

  testthat::skip_if_not_installed("ggplot2")
  cross_plot <- plot_cross_sections(samples)
  expect_equal(cross_plot$labels$y, "Bathymetry / elevation (m)")
  expect_equal(cross_plot$labels$colour, "Transect")

  profile_plot <- plot_depth_profile(samples[samples$transect_id == "a", ])
  expect_equal(profile_plot$labels$y, "Bathymetry / elevation (m)")

  slope_plot <- plot_depth_profile(samples[samples$transect_id == "a", ], value_col = "slope_deg")
  expect_equal(slope_plot$labels$y, "Slope (degrees)")
})

test_that("depth profile plots README-style transect subsets", {
  testthat::skip_if_not_installed("ggplot2")
  bathy <- read_bathy(blueterra_example("hitw"))
  zones <- terra::vect(blueterra_example("sampling_rectangles"))
  hitw_rect <- zones[zones$site_id == "hitw", ]
  hitw_prepared <- prepare_bathy(bathy, depth_range = c(-220, -25), smooth = TRUE)
  transects <- make_transects(hitw_rect, spacing = 75, bathy = hitw_prepared)
  transect_samples <- sample_transects(transects, hitw_prepared, n = 8)
  one <- transect_samples[transect_samples$transect_id == transect_samples$transect_id[1], ]
  p <- plot_depth_profile(one, value_col = "bathy_m")
  expect_s3_class(p, "ggplot")
  built <- ggplot2::ggplot_build(p)
  expect_true(any(vapply(built$data, nrow, integer(1)) > 0))

  metric_samples <- sample_transects(transects, derive_slope(hitw_prepared), n = 8)
  metric_one <- metric_samples[metric_samples$transect_id == metric_samples$transect_id[1], ]
  metric_plot <- plot_depth_profile(metric_one, value_col = "slope_deg")
  expect_s3_class(metric_plot, "ggplot")

  bad <- data.frame(distance = 1:3, transect_id = letters[1:3])
  expect_error(plot_depth_profile(bad), "Could not identify")

  one_point <- data.frame(distance = 1, depth = -10)
  expect_warning(point_plot <- plot_depth_profile(one_point), "Only one finite sample")
  expect_s3_class(point_plot, "ggplot")
})
