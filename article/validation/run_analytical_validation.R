#!/usr/bin/env Rscript

# Controlled analytical checks for blueterra's implemented metric definitions.
#
# This script uses projected, one-metre synthetic rasters and keeps the outer
# cell ring explicit: terra::terrain() returns NA there for its 3 x 3
# neighbourhood operations, whereas derive_bpi() uses partial focal windows at
# raster edges.  Results are written before the script exits on any failed
# check.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(script_arg)) {
  dirname(normalizePath(sub("^--file=", "", script_arg[[1]]), mustWork = TRUE))
} else {
  normalizePath(file.path("article", "validation"), mustWork = TRUE)
}
source(file.path(script_dir, "helpers.R"))

load_blueterra_source()

append_result <- function(results, record) {
  results[[length(results) + 1L]] <- record
  results
}

template <- make_projected_raster(nrows = 21, ncols = 21, resolution = 1)
plane_ax <- 2
plane_ay <- 1
plane <- make_plane(template, ax = plane_ax, ay = plane_ay)
constant <- make_constant(template, value = 5)

slope_degrees <- atan(sqrt(plane_ax^2 + plane_ay^2)) * 180 / pi
slope_radians <- atan(sqrt(plane_ax^2 + plane_ay^2))
aspect_degrees <- (atan2(-plane_ax, -plane_ay) * 180 / pi + 360) %% 360
aspect_radians <- aspect_degrees * pi / 180
surface_area_ratio <- 1 / cos(slope_radians)
plane_roughness <- 2 * (abs(plane_ax) * terra::res(template)[1] + abs(plane_ay) * terra::res(template)[2])
plane_tri <- mean(abs(c(
  -plane_ax * terra::res(template)[1] + plane_ay * terra::res(template)[2],
  plane_ay * terra::res(template)[2],
  plane_ax * terra::res(template)[1] + plane_ay * terra::res(template)[2],
  -plane_ax * terra::res(template)[1],
  plane_ax * terra::res(template)[1],
  -plane_ax * terra::res(template)[1] - plane_ay * terra::res(template)[2],
  -plane_ay * terra::res(template)[2],
  plane_ax * terra::res(template)[1] - plane_ay * terra::res(template)[2]
)))

results <- list()

slope_deg <- derive_slope(plane, units = "degrees")
slope_rad <- derive_slope(plane, units = "radians")
aspect_deg <- derive_aspect(plane, units = "degrees")
aspect_rad <- derive_aspect(plane, units = "radians")
northness <- derive_northness(plane)
eastness <- derive_eastness(plane)
sar <- derive_surface_area_ratio(plane)

results <- append_result(results, comparison_record(
  "plane_slope_degrees", "analytical", raster_values(slope_deg),
  raster_values(interior_reference(template, slope_degrees)),
  "atan(sqrt(ax^2 + ay^2)) in degrees",
  notes = "Plane z = 2x + y on a 1 m projected grid.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "plane_slope_radians", "analytical", raster_values(slope_rad),
  raster_values(interior_reference(template, slope_radians)),
  "atan(sqrt(ax^2 + ay^2)) in radians",
  notes = "Same plane and edge convention as plane_slope_degrees.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "plane_aspect_degrees", "analytical", raster_values(aspect_deg),
  raster_values(interior_reference(template, aspect_degrees)),
  "downslope azimuth = (atan2(-ax, -ay) + 360) modulo 360",
  notes = "Aspect is interpreted as a compass bearing clockwise from north.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "plane_aspect_radians", "analytical", raster_values(aspect_rad),
  raster_values(interior_reference(template, aspect_radians)),
  "analytical aspect in radians",
  notes = "Radians are the degree reference multiplied by pi / 180.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "plane_northness", "analytical", raster_values(northness),
  raster_values(interior_reference(template, cos(aspect_radians))),
  "cos(analytical aspect in radians)",
  notes = "Northness is the cosine of aspect.",
  edge_behavior = "Matches aspect's outer NA ring."
))
results <- append_result(results, comparison_record(
  "plane_eastness", "analytical", raster_values(eastness),
  raster_values(interior_reference(template, sin(aspect_radians))),
  "sin(analytical aspect in radians)",
  notes = "Eastness is the sine of aspect.",
  edge_behavior = "Matches aspect's outer NA ring."
))
results <- append_result(results, comparison_record(
  "plane_surface_area_ratio", "analytical", raster_values(sar),
  raster_values(interior_reference(template, surface_area_ratio)),
  "1 / cos(atan(sqrt(ax^2 + ay^2)))",
  notes = "For a unit horizontal grid this is sqrt(1 + ax^2 + ay^2).",
  edge_behavior = "Matches slope's outer NA ring."
))

roughness_constant <- derive_roughness(constant)
roughness_plane <- derive_roughness(plane)
tri_constant <- derive_tri(constant)
tri_plane <- derive_tri(plane)
tpi_constant <- derive_tpi(constant)
tpi_plane <- derive_tpi(plane)

results <- append_result(results, comparison_record(
  "constant_roughness", "analytical", raster_values(roughness_constant),
  raster_values(interior_reference(template, 0)),
  "max(neighbourhood) - min(neighbourhood) on a constant surface",
  notes = "Constant local relief must be zero.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "plane_roughness", "analytical", raster_values(roughness_plane),
  raster_values(interior_reference(template, plane_roughness)),
  "2 * (abs(ax) * xres + abs(ay) * yres) for a 3 x 3 planar neighbourhood",
  notes = "The expected 3 x 3 range is 6 on the one-metre z = 2x + y plane.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "constant_tri", "analytical", raster_values(tri_constant),
  raster_values(interior_reference(template, 0)),
  "TRI on a constant surface",
  notes = "Tests the zero-relief limiting case; direct terra agreement is in the companion script.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "plane_tri", "analytical", raster_values(tri_plane),
  raster_values(interior_reference(template, plane_tri)),
  "mean absolute difference between the centre and its eight planar neighbours",
  notes = "terra::terrain(v = 'TRI') uses mean absolute neighbour difference; the expected value is 1.75.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "constant_tpi", "analytical", raster_values(tpi_constant),
  raster_values(interior_reference(template, 0)),
  "TPI on a constant surface",
  notes = "Tests the zero-relative-position limiting case.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))
results <- append_result(results, comparison_record(
  "plane_tpi", "analytical", raster_values(tpi_plane),
  raster_values(interior_reference(template, 0)),
  "cell minus symmetric local neighbourhood mean on a plane",
  notes = "A linear plane has zero local relative position away from edges.",
  edge_behavior = "Outer one-cell ring is expected NA for terra::terrain()."
))

vrm_constant <- derive_rugosity(constant, window = 3)
vrm_plane <- derive_rugosity(plane, window = 3)
results <- append_result(results, comparison_record(
  "constant_vrm_rugosity", "analytical", raster_values(vrm_constant),
  raster_values(interior_reference(template, 0)),
  "1 - length(mean unit normal) on a constant surface",
  notes = "Identical vertical normals yield VRM = 0.",
  edge_behavior = "Outer one-cell ring is NA; values one cell in can use a partial focal window of finite normals."
))
results <- append_result(results, comparison_record(
  "plane_vrm_rugosity", "analytical", raster_values(vrm_plane),
  raster_values(interior_reference(template, 0)),
  "1 - length(mean unit normal) on a planar surface",
  notes = "Identical tilted normals yield VRM = 0.",
  edge_behavior = "Outer one-cell ring is NA; values one cell in can use a partial focal window of finite normals."
))

quad_template <- make_projected_raster(nrows = 21, ncols = 21, resolution = 1)
quad_xy <- terra::xyFromCell(quad_template, seq_len(terra::ncell(quad_template)))
convex <- quad_template
terra::values(convex) <- quad_xy[, "x"]^2 + quad_xy[, "y"]^2
concave <- -convex
names(convex) <- "convex_quadratic"
names(concave) <- "concave_quadratic"
curvature_plane <- derive_curvature(plane)
curvature_convex <- derive_curvature(convex)
curvature_concave <- derive_curvature(concave)
results <- append_result(results, comparison_record(
  "plane_laplacian_curvature", "analytical", raster_values(curvature_plane),
  raster_values(interior_reference(template, 0)),
  "four-neighbour Laplacian of a plane",
  notes = "The package implements a Laplacian-style index, not plan/profile curvature.",
  edge_behavior = "Outer one-cell ring is expected NA for the 3 x 3 focal kernel."
))
results <- append_result(results, comparison_record(
  "convex_laplacian_curvature", "analytical", raster_values(curvature_convex),
  raster_values(interior_reference(quad_template, 4)),
  "four-neighbour discrete Laplacian of x^2 + y^2",
  notes = "With unit cells, f(x+1)+f(x-1)+f(y+1)+f(y-1)-4f(x,y) = 4.",
  edge_behavior = "Outer one-cell ring is expected NA for the 3 x 3 focal kernel."
))
results <- append_result(results, comparison_record(
  "concave_laplacian_curvature", "analytical", raster_values(curvature_concave),
  raster_values(interior_reference(quad_template, -4)),
  "four-neighbour discrete Laplacian of -(x^2 + y^2)",
  notes = "The concave quadratic is the sign-reversed convex reference.",
  edge_behavior = "Outer one-cell ring is expected NA for the 3 x 3 focal kernel."
))

bpi_fixture <- make_bpi_fixture()
bpi_raster <- bpi_fixture$raster
bpi_values <- bpi_fixture$values
center_row <- bpi_fixture$row
center_col <- bpi_fixture$col
square_weights <- matrix(1, nrow = 3, ncol = 3)
annulus_including_center <- annulus_weights(bpi_raster, inner_radius = 0, outer_radius = 1)
annulus_excluding_center <- annulus_weights(bpi_raster, inner_radius = 1, outer_radius = sqrt(2))

bpi_cases <- list(
  list(
    id = "bpi_square_3x3", label = "square 3 x 3", weights = square_weights,
    call = function(normalize) derive_bpi(bpi_raster, window = 3, normalize = normalize),
    normalize = c(FALSE, TRUE)
  ),
  list(
    id = "bpi_annulus_inner0_outer1", label = "annulus inner 0, outer 1", weights = annulus_including_center,
    call = function(normalize) derive_bpi(bpi_raster, inner_radius = 0, outer_radius = 1, normalize = normalize),
    normalize = c(FALSE, TRUE)
  ),
  list(
    id = "bpi_annulus_inner1_outer_sqrt2", label = "annulus inner 1, outer sqrt(2)", weights = annulus_excluding_center,
    call = function(normalize) derive_bpi(bpi_raster, inner_radius = 1, outer_radius = sqrt(2), normalize = normalize),
    normalize = c(FALSE, TRUE)
  )
)

bpi_behavior <- list()
for (case in bpi_cases) {
  for (normalize in case$normalize) {
    manual <- manual_bpi_at(bpi_values, center_row, center_col, case$weights, normalize = normalize)
    observed_raster <- case$call(normalize)
    observed <- terra::as.matrix(observed_raster, wide = TRUE)[center_row, center_col]
    suffix <- if (normalize) "normalized" else "unnormalized"
    results <- append_result(results, scalar_record(
      paste(case$id, suffix, sep = "_"), "analytical_bpi", observed, manual$value,
      "manual focal mean and sample SD over the source-defined weights",
      notes = sprintf(
        "%s uses %d cells; centre included = %s.",
        case$label, manual$n, !is.na(case$weights[(nrow(case$weights) + 1) / 2, (ncol(case$weights) + 1) / 2])
      ),
      edge_behavior = "Interior centre cell only; edge behaviour is recorded separately."
    ))
    counter_weights <- case$weights
    counter_weights[(nrow(counter_weights) + 1) / 2, (ncol(counter_weights) + 1) / 2] <- NA_real_
    counterfactual <- manual_bpi_at(bpi_values, center_row, center_col, counter_weights, normalize = normalize)
    bpi_behavior[[length(bpi_behavior) + 1L]] <- data.frame(
      scenario = case$id,
      geometry = case$label,
      normalize = normalize,
      centre_included_by_weights = !is.na(case$weights[(nrow(case$weights) + 1) / 2, (ncol(case$weights) + 1) / 2]),
      neighbourhood_cells = manual$n,
      focal_mean = manual$mean,
      focal_sd = manual$sd,
      expected_centre_value = manual$value,
      observed_centre_value = observed,
      counterfactual_excluding_centre = counterfactual$value,
      tolerance = numeric_tolerance(manual$value),
      pass = abs(observed - manual$value) <= numeric_tolerance(manual$value),
      stringsAsFactors = FALSE
    )
  }
}

bpi_square <- derive_bpi(bpi_raster, window = 3)
edge_expected <- bpi_values[1, 1] - mean(bpi_values[1:2, 1:2])
edge_observed <- terra::as.matrix(bpi_square, wide = TRUE)[1, 1]
results <- append_result(results, scalar_record(
  "bpi_edge_partial_window", "edge_missing_behavior", edge_observed, edge_expected,
  "manual partial 2 x 2 window at the upper-left corner",
  notes = "derive_bpi() uses terra::focal(..., na.rm = TRUE, na.policy = 'omit'); edge cells use available in-bounds values.",
  edge_behavior = "Corner BPI is finite and uses a partial focal window."
))

missing_bpi <- bpi_raster
center_cell <- terra::cellFromRowCol(missing_bpi, center_row, center_col)
missing_values <- terra::values(missing_bpi, mat = FALSE)
missing_values[center_cell] <- NA_real_
terra::values(missing_bpi) <- missing_values
missing_output <- derive_bpi(missing_bpi, window = 3)
missing_matrix <- terra::as.matrix(missing_output, wide = TRUE)
results <- append_result(results, scalar_record(
  "bpi_missing_centre_is_na", "edge_missing_behavior", as.numeric(is.na(missing_matrix[center_row, center_col])), 1,
  "na.policy = 'omit' leaves an NA focal centre uncomputed",
  missing_value_behavior = "An input NA at the focal centre remains NA in BPI output."
))
results <- append_result(results, scalar_record(
  "bpi_missing_neighbour_is_ignored", "edge_missing_behavior", as.numeric(is.finite(missing_matrix[center_row, center_col + 1])), 1,
  "na.rm = TRUE uses remaining finite neighbourhood values",
  missing_value_behavior = "A neighbouring NA does not force an otherwise valid focal centre to NA."
))

normalized_constant_bpi <- derive_bpi(constant, window = 3, normalize = TRUE)
constant_center <- terra::as.matrix(normalized_constant_bpi, wide = TRUE)[11, 11]
results <- append_result(results, scalar_record(
  "bpi_normalized_zero_variance_is_na", "edge_missing_behavior", constant_center, NA_real_,
  "documented undefined normalized BPI when local sample SD is zero",
  missing_value_behavior = "A zero-variance focal neighbourhood yields NA for normalized BPI."
))

results <- do.call(rbind, results)
bpi_behavior <- do.call(rbind, bpi_behavior)
paths <- write_validation_outputs(
  "analytical_validation",
  results,
  details = list(
    plane = list(ax = plane_ax, ay = plane_ay, slope_degrees = slope_degrees, aspect_degrees = aspect_degrees),
    bpi_center_behavior = bpi_behavior
  )
)
utils::write.csv(
  bpi_behavior,
  file.path(validation_results_dir(), "bpi_center_inclusion.csv"),
  row.names = FALSE,
  na = ""
)
write_results_readme()

message("Wrote analytical validation results to ", paths$csv)
stop_on_failed_results(results, "Analytical validation")
