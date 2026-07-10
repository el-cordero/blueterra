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
  corridors <- make_isobath_corridors(bathy, depths = -50, width = 5)
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

test_that("profile distance orientation uses numeric minimum-to-maximum direction", {
  elevation <- data.frame(distance = 0:2, bathy_m = c(-50, -70, -90))
  oriented <- blueterra:::orient_profile_distance(elevation, "bathy_m")
  expect_equal(oriented$bathy_m, c(-90, -70, -50))
  expect_equal(oriented$distance_original, c(2, 1, 0))
  expect_true(all(oriented$profile_reversed))

  correct_elevation <- data.frame(distance = 0:2, bathy_m = c(-90, -70, -50))
  already_oriented <- blueterra:::orient_profile_distance(correct_elevation, "bathy_m")
  expect_equal(already_oriented$bathy_m, c(-90, -70, -50))
  expect_equal(already_oriented$distance_original, 0:2)
  expect_false(any(already_oriented$profile_reversed))

  positive_metric <- data.frame(distance = 0:2, slope_deg = c(10, 20, 30))
  metric_oriented <- blueterra:::orient_profile_distance(positive_metric, "slope_deg")
  expect_equal(metric_oriented$slope_deg, c(10, 20, 30))
  expect_false(any(metric_oriented$profile_reversed))

  reversed_metric <- data.frame(distance = 0:2, slope_deg = c(30, 20, 10))
  metric_reversed <- blueterra:::orient_profile_distance(reversed_metric, "slope_deg")
  expect_equal(metric_reversed$slope_deg, c(10, 20, 30))
  expect_true(all(metric_reversed$profile_reversed))

  as_sampled <- blueterra:::orient_profile_distance(
    elevation,
    "bathy_m",
    profile_direction = "as_sampled"
  )
  expect_equal(as_sampled$bathy_m, elevation$bathy_m)
  expect_false(any(as_sampled$profile_reversed))

  max_to_min <- blueterra:::orient_profile_distance(
    data.frame(distance = 0:2, bathy_m = c(-90, -70, -50)),
    "bathy_m",
    profile_direction = "max_to_min"
  )
  expect_equal(max_to_min$bathy_m, c(-50, -70, -90))
  expect_true(all(max_to_min$profile_reversed))

  legacy <- blueterra:::orient_profile_distance(
    data.frame(distance = 0:2, bathy_m = c(-90, -70, -50)),
    "bathy_m",
    profile_direction = "high_to_low"
  )
  expect_equal(legacy$bathy_m, c(-50, -70, -90))
})

test_that("profile distance orientation is applied per transect group", {
  grouped <- data.frame(
    transect_id = rep(c("a", "b"), each = 4),
    distance = rep(0:3, 2),
    bathy_m = c(-50, -70, -90, -110, -120, -100, -80, -60)
  )
  oriented <- blueterra:::orient_profile_distance(
    grouped,
    value_col = "bathy_m",
    group_col = "transect_id"
  )
  a <- oriented[oriented$transect_id == "a", ]
  b <- oriented[oriented$transect_id == "b", ]
  expect_equal(a$bathy_m, c(-110, -90, -70, -50))
  expect_equal(b$bathy_m, c(-120, -100, -80, -60))
  expect_true(all(a$profile_reversed))
  expect_false(any(b$profile_reversed))
})

test_that("profile plots use minimum-to-maximum direction and preserve overrides", {
  testthat::skip_if_not_installed("ggplot2")
  samples <- data.frame(
    transect_id = rep(c("a", "b"), each = 4),
    distance = rep(0:3, 2),
    width_m = 300,
    height_m = 400,
    angle_deg = 94.6,
    offset = rep(c(-50, 50), each = 4),
    bathy_m = c(-60, -50, -40, -30, -20, -30, -40, -50),
    slope_deg = c(12, 15, 18, 21, 13, 16, 19, 22)
  )
  cross_plot <- plot_cross_sections(samples, value_col = "bathy_m", profile_direction = "min_to_max")
  expect_s3_class(cross_plot, "ggplot")
  cross_data <- ggplot2::ggplot_build(cross_plot)$data[[1]]
  expect_true(nrow(cross_data) > 0)
  expect_true(min(cross_data$x[cross_data$group == 1]) == 0)
  expect_equal(cross_plot$labels$y, "Bathymetry / elevation (m)")

  depth_plot <- plot_depth_profile(
    samples[samples$transect_id == "a", ],
    value_col = "bathy_m",
    profile_direction = "min_to_max"
  )
  expect_s3_class(depth_plot, "ggplot")
  depth_data <- ggplot2::ggplot_build(depth_plot)$data[[1]]
  expect_equal(depth_data$y[order(depth_data$x)], c(-60, -50, -40, -30))

  sampled_plot <- plot_depth_profile(
    samples[samples$transect_id == "a", ],
    value_col = "bathy_m",
    profile_direction = "as_sampled"
  )
  sampled_data <- ggplot2::ggplot_build(sampled_plot)$data[[1]]
  expect_equal(sampled_data$y[order(sampled_data$x)], c(-60, -50, -40, -30))

  metric_plot <- plot_depth_profile(
    samples[samples$transect_id == "a", ],
    value_col = "slope_deg",
    profile_direction = "as_sampled"
  )
  expect_equal(metric_plot$labels$y, "Slope (degrees)")
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
