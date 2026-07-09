test_that("transects can be created and sampled", {
  bathy <- example_bathy()
  zones <- example_zones()
  transects <- make_transects(zones[1, ], spacing = 100, angle = 0)
  expect_s4_class(transects, "SpatVector")
  expect_true(all(c("angle_deg", "angle_source", "transect_id") %in% names(transects)))
  samples <- sample_transects(transects, bathy, n = 5)
  expect_s3_class(samples, "tbl_df")
  expect_true(all(c("transect_id", "angle_deg", "angle_source", "distance", "bathy") %in% names(samples)))
  sections <- extract_cross_sections(transects, bathy, n = 5)
  expect_equal(nrow(sections), nrow(samples))
})

test_that("surface orientation is estimated from planar rasters", {
  r <- terra::rast(nrows = 20, ncols = 20, xmin = 0, xmax = 20, ymin = 0, ymax = 20, crs = "EPSG:32620")
  x <- terra::init(r, "x")
  y <- terra::init(r, "y")
  planes <- list(
    south = y,
    north = -y,
    east = -x,
    west = x
  )
  expected <- c(south = 90, north = 90, east = 0, west = 0)
  area <- terra::vect(rbind(c(0, 0), c(20, 0), c(20, 20), c(0, 20), c(0, 0)),
    type = "polygons", crs = terra::crs(r)
  )
  for (nm in names(planes)) {
    plane <- planes[[nm]]
    names(plane) <- "z"
    angle <- estimate_surface_orientation(plane, area, orientation_weight = "none")
    expect_equal(angle, expected[[nm]], tolerance = 1)
  }
})

test_that("make_transects uses automatic surface orientation and manual overrides", {
  r <- terra::rast(nrows = 20, ncols = 20, xmin = 0, xmax = 20, ymin = 0, ymax = 20, crs = "EPSG:32620")
  y <- terra::init(r, "y")
  names(y) <- "south_facing"
  area <- terra::vect(rbind(c(2, 2), c(18, 2), c(18, 18), c(2, 18), c(2, 2)),
    type = "polygons", crs = terra::crs(r)
  )
  auto <- make_transects(area, spacing = 5, bathy = y)
  expect_equal(unique(auto$angle_source), "surface")
  expect_equal(unique(auto$angle_deg), 90, tolerance = 1)
  expect_true(all(c("mean_aspect_deg", "n_orientation_cells") %in% names(auto)))

  manual <- make_transects(area, spacing = 5, angle = 0, bathy = y)
  expect_equal(unique(manual$angle_source), "manual")
  expect_equal(unique(manual$angle_deg), 0)
})

test_that("README-style terrain-oriented transects work on Hole-in-the-Wall", {
  hitw <- read_bathy(blueterra_example("hitw"))
  zones <- terra::vect(blueterra_example("sampling_rectangles"))
  hitw_rect <- zones[zones$site_id == "hitw", ]
  hitw_prepared <- prepare_bathy(hitw, depth_range = c(-220, -25), smooth = TRUE)
  transects <- make_transects(hitw_rect, spacing = 75, bathy = hitw_prepared)
  expect_equal(unique(transects$angle_source), "surface")
  expect_true(abs(unique(transects$angle_deg)[1] - 90) < 15)
  samples <- sample_transects(transects, hitw_prepared, n = 8)
  expect_true(all(c("angle_deg", "angle_source", "mean_aspect_deg") %in% names(samples)))
})

test_that("cross-section summaries work", {
  bathy <- example_bathy()
  zones <- example_zones()
  samples <- sample_transects(make_transects(zones[1, ], spacing = 100, angle = 0), bathy, n = 5)
  summary <- summarize_cross_sections(samples)
  expect_true("bathy_mean" %in% names(summary))
  normalized <- summarize_cross_sections(samples, normalize_distance = TRUE, n_bins = 3)
  expect_true("distance_bin" %in% names(normalized))
})
