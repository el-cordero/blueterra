#!/usr/bin/env Rscript

# Wrapper-agreement checks for blueterra.
#
# Each comparison recreates the corresponding upstream terra operation or the
# package's documented transparent formula with identical grid, neighbourhood,
# and missing-value arguments.  This tests orchestration and parameter handling;
# it is not an independent scientific validation of terra algorithms.

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
plane <- make_plane(template, ax = 2, ay = 1)
relief_fixture <- make_bpi_fixture()$raster
quadratic_xy <- terra::xyFromCell(template, seq_len(terra::ncell(template)))
quadratic <- template
terra::values(quadratic) <- quadratic_xy[, "x"]^2 + quadratic_xy[, "y"]^2
names(quadratic) <- "quadratic"

results <- list()

for (neighbors in c(4, 8)) {
  slope_degrees <- derive_slope(plane, units = "degrees", neighbors = neighbors)
  slope_degrees_reference <- terra::terrain(plane, v = "slope", unit = "degrees", neighbors = neighbors)
  results <- append_result(results, comparison_record(
    paste0("derive_slope_degrees_neighbors", neighbors), "wrapper_agreement",
    raster_values(slope_degrees), raster_values(slope_degrees_reference),
    sprintf("terra::terrain(v = 'slope', unit = 'degrees', neighbors = %d)", neighbors),
    notes = "Direct upstream comparison with the package's supplied neighbour argument.",
    edge_behavior = "terra::terrain has an outer NA ring for this complete raster."
  ))

  aspect_degrees <- derive_aspect(plane, units = "degrees", neighbors = neighbors)
  aspect_degrees_reference <- terra::terrain(plane, v = "aspect", unit = "degrees", neighbors = neighbors)
  results <- append_result(results, comparison_record(
    paste0("derive_aspect_degrees_neighbors", neighbors), "wrapper_agreement",
    raster_values(aspect_degrees), raster_values(aspect_degrees_reference),
    sprintf("terra::terrain(v = 'aspect', unit = 'degrees', neighbors = %d)", neighbors),
    notes = "Direct upstream comparison with the package's supplied neighbour argument.",
    edge_behavior = "terra::terrain has an outer NA ring for this complete raster."
  ))
}

slope_radians_reference <- terra::terrain(plane, v = "slope", unit = "radians", neighbors = 8)
aspect_radians_reference <- terra::terrain(plane, v = "aspect", unit = "radians", neighbors = 8)
results <- append_result(results, comparison_record(
  "derive_slope_radians_neighbors8", "wrapper_agreement",
  raster_values(derive_slope(plane, units = "radians", neighbors = 8)),
  raster_values(slope_radians_reference),
  "terra::terrain(v = 'slope', unit = 'radians', neighbors = 8)",
  edge_behavior = "terra::terrain has an outer NA ring for this complete raster."
))
results <- append_result(results, comparison_record(
  "derive_aspect_radians_neighbors8", "wrapper_agreement",
  raster_values(derive_aspect(plane, units = "radians", neighbors = 8)),
  raster_values(aspect_radians_reference),
  "terra::terrain(v = 'aspect', unit = 'radians', neighbors = 8)",
  edge_behavior = "terra::terrain has an outer NA ring for this complete raster."
))
results <- append_result(results, comparison_record(
  "derive_northness", "wrapper_agreement",
  raster_values(derive_northness(plane, neighbors = 8)),
  raster_values(cos(aspect_radians_reference)),
  "cos(terra::terrain aspect in radians)",
  edge_behavior = "Matches aspect's outer NA ring."
))
results <- append_result(results, comparison_record(
  "derive_eastness", "wrapper_agreement",
  raster_values(derive_eastness(plane, neighbors = 8)),
  raster_values(sin(aspect_radians_reference)),
  "sin(terra::terrain aspect in radians)",
  edge_behavior = "Matches aspect's outer NA ring."
))

surface_ratio_reference <- 1 / terra::clamp(cos(slope_radians_reference), lower = 1e-6, values = TRUE)
results <- append_result(results, comparison_record(
  "derive_surface_area_ratio", "wrapper_agreement",
  raster_values(derive_surface_area_ratio(plane, neighbors = 8)),
  raster_values(surface_ratio_reference),
  "1 / clamp(cos(terra::terrain slope radians), lower = 1e-6)",
  notes = "This is the package's local planar secant formula, not triangulated area.",
  edge_behavior = "Matches slope's outer NA ring."
))

for (metric in c("roughness", "TRI", "TPI")) {
  actual <- switch(
    metric,
    roughness = derive_roughness(relief_fixture),
    TRI = derive_tri(relief_fixture),
    TPI = derive_tpi(relief_fixture)
  )
  reference <- terra::terrain(relief_fixture, v = metric)
  results <- append_result(results, comparison_record(
    paste0("derive_", tolower(metric)), "wrapper_agreement",
    raster_values(actual), raster_values(reference),
    sprintf("terra::terrain(v = '%s')", metric),
    notes = "Direct upstream comparison on a non-planar deterministic fixture.",
    edge_behavior = "terra::terrain has an outer NA ring for this complete raster."
  ))
}

square_weights <- matrix(1, nrow = 3, ncol = 3)
annular_include_weights <- annulus_weights(relief_fixture, inner_radius = 0, outer_radius = 1)
annular_exclude_weights <- annulus_weights(relief_fixture, inner_radius = 1, outer_radius = sqrt(2))
bpi_cases <- list(
  list(
    id = "square_3x3", weights = square_weights,
    call = function(normalize) derive_bpi(relief_fixture, window = 3, normalize = normalize)
  ),
  list(
    id = "annulus_inner0_outer1", weights = annular_include_weights,
    call = function(normalize) derive_bpi(relief_fixture, inner_radius = 0, outer_radius = 1, normalize = normalize)
  ),
  list(
    id = "annulus_inner1_outer_sqrt2", weights = annular_exclude_weights,
    call = function(normalize) derive_bpi(relief_fixture, inner_radius = 1, outer_radius = sqrt(2), normalize = normalize)
  )
)
for (case in bpi_cases) {
  for (normalize in c(FALSE, TRUE)) {
    actual <- case$call(normalize)
    reference <- direct_bpi(relief_fixture, case$weights, normalize = normalize)
    results <- append_result(results, comparison_record(
      paste0("derive_bpi_", case$id, if (normalize) "_normalized" else "_unnormalized"),
      "wrapper_agreement", raster_values(actual), raster_values(reference),
      "terra::focal mean (and stats::sd for normalized output) with the same source-defined weights",
      notes = sprintf(
        "Centre included by weights = %s.",
        !is.na(case$weights[(nrow(case$weights) + 1) / 2, (ncol(case$weights) + 1) / 2])
      ),
      edge_behavior = "Focal BPI uses available in-bounds values because na.rm = TRUE."
    ))
  }
}

multi_actual <- derive_multiscale_bpi(relief_fixture, windows = c(3, 5), normalize = TRUE)
multi_reference <- c(
  direct_bpi(relief_fixture, matrix(1, 3, 3), normalize = TRUE),
  direct_bpi(relief_fixture, matrix(1, 5, 5), normalize = TRUE)
)
results <- append_result(results, comparison_record(
  "derive_multiscale_bpi_normalized", "wrapper_agreement",
  raster_values(multi_actual), raster_values(multi_reference),
  "concatenated direct BPI references for 3 x 3 and 5 x 5 windows",
  notes = "Checks layer stacking in addition to single-window BPI wrappers.",
  edge_behavior = "Focal BPI uses available in-bounds values because na.rm = TRUE."
))

results <- append_result(results, comparison_record(
  "derive_rugosity_vrm", "wrapper_agreement",
  raster_values(derive_rugosity(relief_fixture, window = 3, neighbors = 8)),
  raster_values(direct_vrm(relief_fixture, window = 3, neighbors = 8)),
  "slope/aspect unit normals, componentwise terra::focal means, and clamp(1 - norm(mean normal), 0, 1)",
  notes = "Direct reconstruction of the in-package VRM formula on non-planar relief.",
  edge_behavior = "Outer slope/aspect ring is NA; focal means may use partial valid normal windows."
))

curvature_kernel <- matrix(c(0, 1, 0, 1, -4, 1, 0, 1, 0), nrow = 3, byrow = TRUE)
curvature_reference <- terra::focal(quadratic, w = curvature_kernel, fun = sum, na.policy = "omit")
results <- append_result(results, comparison_record(
  "derive_curvature_laplacian", "wrapper_agreement",
  raster_values(derive_curvature(quadratic)), raster_values(curvature_reference),
  "terra::focal sum with the four-neighbour Laplacian kernel",
  notes = "The reference deliberately has no dx/dy normalization.",
  edge_behavior = "Outer one-cell ring is NA for the 3 x 3 focal kernel."
))

hillshade_reference <- terra::shade(slope_radians_reference, aspect_radians_reference, angle = 45, direction = 315)
if (terra::nlyr(hillshade_reference) > 1) {
  hillshade_reference <- mean(hillshade_reference)
}
results <- append_result(results, comparison_record(
  "derive_hillshade", "wrapper_agreement",
  raster_values(derive_hillshade(plane, angle = 45, direction = 315, neighbors = 8)),
  raster_values(hillshade_reference),
  "terra::shade(direct slope radians, direct aspect radians, angle = 45, direction = 315)",
  notes = "The package preserves the unnormalised terra::shade output.",
  edge_behavior = "Matches slope/aspect's outer NA ring."
))

results <- do.call(rbind, results)
paths <- write_validation_outputs(
  "wrapper_agreement",
  results,
  details = list(
    terra_version = as.character(utils::packageVersion("terra")),
    algorithms = c(
      "terra::terrain wrappers",
      "terra::focal BPI reconstruction",
      "transparent VRM reconstruction",
      "four-neighbour focal Laplacian",
      "terra::shade"
    )
  )
)
write_results_readme()
message("Wrote wrapper-agreement results to ", paths$csv)
stop_on_failed_results(results, "Wrapper agreement")
