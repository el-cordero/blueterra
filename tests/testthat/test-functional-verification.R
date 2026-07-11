make_projected_test_raster <- function(
    nrows = 20,
    ncols = 20,
    xres = 1,
    yres = 1,
    values = NULL
) {
  r <- terra::rast(
    nrows = nrows,
    ncols = ncols,
    xmin = 0,
    xmax = ncols * xres,
    ymin = 0,
    ymax = nrows * yres,
    crs = "EPSG:32620"
  )
  if (is.null(values)) {
    values <- seq_len(terra::ncell(r))
  }
  terra::values(r) <- values
  names(r) <- "z"
  r
}

rectangle_zone <- function(xmin, ymin, xmax, ymax, crs = "EPSG:32620") {
  terra::vect(
    rbind(
      c(xmin, ymin), c(xmax, ymin), c(xmax, ymax),
      c(xmin, ymax), c(xmin, ymin)
    ),
    type = "polygons",
    crs = crs
  )
}

test_that("annular BPI uses both raster cell dimensions and rejects longitude latitude", {
  r <- make_projected_test_raster(nrows = 5, ncols = 7, xres = 2, yres = 4)
  annulus <- blueterra:::bpi_window(
    r, inner_radius = 0, outer_radius = 4, window = NULL, scale = "custom"
  )
  expect_equal(dim(annulus), c(3, 5))
  expect_equal(sum(!is.na(annulus)), 7)
  expect_equal(annulus[1, 3], 1)
  expect_true(is.na(annulus[1, 2]))

  lonlat <- terra::rast(r)
  terra::crs(lonlat) <- "EPSG:4326"
  terra::values(lonlat) <- terra::values(r, mat = FALSE)
  expect_error(
    derive_bpi(lonlat, outer_radius = 4),
    "projected"
  )
})

test_that("BPI normalization and focal metrics handle zero variance and partial support deliberately", {
  constant <- make_projected_test_raster(nrows = 7, ncols = 7, values = rep(5, 49))
  normalized <- derive_bpi(constant, window = 3, normalize = TRUE)
  expect_true(all(is.na(terra::values(normalized, mat = FALSE))))

  r <- make_projected_test_raster(nrows = 7, ncols = 7)
  partial_bpi <- derive_bpi(r, window = 3)
  expect_true(is.finite(terra::values(partial_bpi, mat = FALSE)[1]))
  partial_vrm <- derive_rugosity(r, window = 3)
  # The first raster row lacks a slope/aspect derivative, whereas the second
  # row has a valid VRM value computed with partial focal support.
  expect_true(is.finite(terra::values(partial_vrm, mat = FALSE)[9]))

  values <- terra::values(r, mat = FALSE)
  values[25] <- NA_real_
  terra::values(r) <- values
  missing_boundary_bpi <- derive_bpi(r, window = 3)
  expect_true(is.na(terra::values(missing_boundary_bpi, mat = FALSE)[25]))
  expect_true(any(is.finite(terra::values(missing_boundary_bpi, mat = FALSE))))
})

test_that("transects retain known orientation, spacing, clipping, and reliability metadata", {
  r <- make_projected_test_raster(nrows = 100, ncols = 100)
  y <- terra::init(r, "y")
  names(y) <- "south_facing"
  area <- rectangle_zone(0, 0, 100, 100)

  orientation <- estimate_surface_orientation(y, area, orientation_weight = "none", return = "both")
  expect_equal(orientation$transect_angle_deg, 90, tolerance = 1e-6)
  expect_equal(orientation$orientation_resultant_length, 1, tolerance = 1e-6)

  lines <- make_transects(area, spacing = 25, angle = 0)
  expect_equal(nrow(lines), 4)
  expect_equal(sort(unique(diff(sort(unique(lines$offset))))), 25)
  coords <- terra::crds(lines)
  expect_true(all(coords[, 1] >= 0 & coords[, 1] <= 100))
  expect_true(all(coords[, 2] >= 0 & coords[, 2] <= 100))

  automatic <- make_transects(area, spacing = 25, bathy = y)
  expect_equal(unique(automatic$angle_source), "surface")
  expect_equal(unique(automatic$angle_deg), 90, tolerance = 1e-6)
  expect_equal(unique(automatic$orientation_resultant_length), 1, tolerance = 1e-6)
})

test_that("weakly concentrated surface aspects report a low resultant length", {
  r <- make_projected_test_raster(nrows = 40, ncols = 40)
  x <- terra::init(r, "x")
  y <- terra::init(r, "y")
  mixed <- terra::ifel(x < 24, y, -y)
  names(mixed) <- "mixed_aspect"
  area <- rectangle_zone(0, 0, 40, 40)
  orientation <- estimate_surface_orientation(mixed, area, orientation_weight = "none", return = "both")
  expect_lt(orientation$orientation_resultant_length, 0.45)
  expect_gt(orientation$orientation_resultant_length, 0)
})

test_that("isobath corridors recover a synthetic ramp location, width, and overlap semantics", {
  r <- make_projected_test_raster(nrows = 40, ncols = 100)
  x <- terra::init(r, "x")
  ramp <- -x
  names(ramp) <- "elevation"
  isobath <- extract_isobaths(ramp, depths = -50)
  expect_equal(mean(terra::crds(isobath)[, 1]), 50, tolerance = 1e-6)

  corridor <- make_isobath_corridors(ramp, depths = -50, width = 10)
  expect_equal(unique(corridor$buffer_distance), 10)
  expect_equal(unique(corridor$nominal_corridor_width), 20)
  expect_equal(unique(corridor$overlap_policy), "independent_may_overlap")
  corridor_extent <- terra::ext(corridor)
  expect_equal(unname(c(corridor_extent[1], corridor_extent[2])), c(40, 60), tolerance = 1e-6)

  overlapping <- make_isobath_corridors(ramp, depths = c(-45, -50), width = 10)
  intersection <- terra::intersect(overlapping[1, ], overlapping[2, ])
  expect_gt(nrow(intersection), 0)
})

test_that("polygon, depth-band, and exact-intersection summaries have documented semantics", {
  r <- make_projected_test_raster(nrows = 2, ncols = 2, values = c(1, 2, 3, 4))
  whole <- rectangle_zone(0, 0, 2, 2)
  summary <- summarize_terrain(r, whole, fun = c("mean", "count"))
  expect_equal(summary$zone_id, 1L)
  expect_equal(summary$z_mean, 2.5)
  expect_equal(summary$z_count, 4)

  depth <- terra::rast(r)
  terra::values(depth) <- c(-4, -3, -2, -1)
  names(depth) <- "depth"
  bands <- summarize_depth_bands(
    depth, metrics = depth, breaks = c(-4, -2, 0), fun = "mean"
  )
  expect_equal(bands$depth_band, c("[-4,-2)", "[-2,0]"))
  expect_equal(bands$n_cells, c(2, 2))
  expect_equal(bands$mean, c(-3.5, -1.5))

  skip_if_not_installed("exactextractr")
  skip_if_not_installed("sf")
  exact_r <- make_projected_test_raster(nrows = 1, ncols = 2, values = c(0, 10))
  partial <- rectangle_zone(0, 0, 1.5, 1)
  exact <- summarize_terrain(exact_r, partial, fun = c("mean", "sum", "count"), exact = TRUE)
  expect_equal(exact$z_mean, 10 / 3, tolerance = 1e-8)
  expect_equal(exact$z_sum, 5, tolerance = 1e-8)
  expect_equal(exact$z_count, 1.5, tolerance = 1e-8)
})

test_that("custom layers and metric catalogs reject geometry mismatch and identify unmatched names", {
  base <- derive_terrain(make_projected_test_raster(), metrics = c("slope", "bpi"))
  shifted <- terra::aggregate(base[["slope_deg"]], fact = 2)
  expect_error(add_metric_layers(base, shifted), "match the geometry")

  assignment <- assign_process_groups(c("slope_deg", "unmatched_metric"))
  expect_true(assignment$matched[assignment$metric == "slope_deg"])
  expect_false(assignment$matched[assignment$metric == "unmatched_metric"])
  expect_equal(
    assignment$process_group[assignment$metric == "unmatched_metric"],
    "unassigned"
  )
})
