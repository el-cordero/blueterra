#!/usr/bin/env Rscript

# Separate grid-resolution, preprocessing, focal-neighborhood, sign, and
# coordinate-unit sensitivity experiments for the documented BlueTopo article
# example. The analysis is descriptive: it reports consequences of stated
# operations and does not select a universally correct scale.

suppressPackageStartupMessages({
  library(terra)
  library(pkgload)
})
suppressMessages(terra::projNetwork(FALSE))

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/sensitivity/run_sensitivity.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
out_dir <- file.path(root, "article", "sensitivity", "results")
raster_dir <- file.path(out_dir, "rasters")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(raster_dir, recursive = TRUE, showWarnings = FALSE)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
set.seed(20260711)

write_csv <- function(x, name) {
  utils::write.csv(x, file.path(out_dir, name), row.names = FALSE, na = "")
}

numeric_values <- function(x) as.numeric(terra::values(x, mat = FALSE))

metric_units <- c(
  slope_deg = "degrees",
  bpi = "m (stored elevation)",
  vrm = "unitless",
  laplacian_index = "m (stored elevation)",
  surface_area_ratio = "unitless ratio"
)

derive_selected <- function(x, bpi_window = 3L, vrm_window = 3L) {
  out <- c(
    derive_slope(x, units = "degrees"),
    derive_bpi(x, window = bpi_window),
    derive_rugosity(x, window = vrm_window),
    derive_curvature(x),
    derive_surface_area_ratio(x)
  )
  names(out) <- c("slope_deg", "bpi", "vrm", "laplacian_index", "surface_area_ratio")
  out
}

compare_layer <- function(
    scenario_class, scenario, metric, reference, candidate,
    reference_processing, candidate_processing, resolution, smoothing,
    focal_cells, focal_metres, interpretation, resample_candidate = FALSE
) {
  candidate_for_comparison <- candidate
  interpolation <- "none"
  if (isTRUE(resample_candidate) || !terra::compareGeom(reference, candidate, stopOnError = FALSE)) {
    candidate_for_comparison <- terra::resample(candidate, reference, method = "bilinear")
    interpolation <- "candidate derivative resampled bilinearly to the reference grid after derivation"
  }
  ref <- numeric_values(reference)
  cand <- numeric_values(candidate_for_comparison)
  keep <- is.finite(ref) & is.finite(cand)
  delta <- cand[keep] - ref[keep]
  rho <- if (sum(keep) > 2L && length(unique(ref[keep])) > 1L && length(unique(cand[keep])) > 1L) {
    suppressWarnings(stats::cor(ref[keep], cand[keep], method = "spearman"))
  } else {
    NA_real_
  }
  data.frame(
    scenario_class = scenario_class,
    scenario = scenario,
    metric = metric,
    units = unname(metric_units[[metric]]),
    reference_processing = reference_processing,
    candidate_processing = candidate_processing,
    resolution = resolution,
    smoothing = smoothing,
    focal_scale_cells = focal_cells,
    focal_scale_metres = focal_metres,
    comparison_grid = if (interpolation == "none") "native comparison grid" else "native grid after candidate-derivative interpolation",
    interpolation = interpolation,
    n_compared = sum(keep),
    median_absolute_cellwise_difference = if (length(delta)) stats::median(abs(delta)) else NA_real_,
    median_signed_cellwise_difference = if (length(delta)) stats::median(delta) else NA_real_,
    spearman_rho = rho,
    interpretation = interpretation,
    stringsAsFactors = FALSE
  )
}

write_artifact <- function(x, name) {
  path <- file.path(raster_dir, paste0(name, ".tif"))
  terra::writeRaster(x, path, overwrite = TRUE, wopt = list(gdal = "COMPRESS=DEFLATE"))
  path
}

example_path <- file.path(
  root, "article", "data_provenance", "results", "bluetopo_bh54s4zb_elevation_example.tif"
)
if (!file.exists(example_path)) {
  stop("Run article/data_provenance/acquire_bluetopo_example.R before this sensitivity analysis.", call. = FALSE)
}
bathy <- terra::rast(example_path)
names(bathy) <- "elevation_m"
native_resolution <- terra::res(bathy)

# Baseline and processing scenarios use the documented 4 m elevation crop.
native_3 <- derive_selected(bathy, bpi_window = 3L, vrm_window = 3L)
smoothed_bathy <- smooth_bathy(bathy, window = 3L)
smoothed_3 <- derive_selected(smoothed_bathy, bpi_window = 3L, vrm_window = 3L)
positive_bathy <- set_depth_positive(bathy)
positive_3 <- derive_selected(positive_bathy, bpi_window = 3L, vrm_window = 3L)

# Grid resolution experiment: aggregate the elevation to 8 m, differentiate on
# that coarser grid, and only then resample derivative products to the 4 m grid
# for cellwise comparison. This is reported as a compound comparison, not a
# pure resolution effect.
coarse_bathy <- terra::aggregate(bathy, fact = 2L, fun = mean, na.rm = TRUE)
coarse_5 <- derive_selected(coarse_bathy, bpi_window = 5L, vrm_window = 5L)
coarse_3 <- derive_selected(coarse_bathy, bpi_window = 3L, vrm_window = 3L)
native_5 <- derive_selected(bathy, bpi_window = 5L, vrm_window = 5L)
native_7 <- derive_selected(bathy, bpi_window = 7L, vrm_window = 7L)
native_11 <- derive_selected(bathy, bpi_window = 11L, vrm_window = 11L)

native_res_text <- sprintf("native %.0f by %.0f m", native_resolution[[1]], native_resolution[[2]])
coarse_res_text <- sprintf("coarse %.0f by %.0f m", terra::res(coarse_bathy)[[1]], terra::res(coarse_bathy)[[2]])
resolution_text <- paste(native_res_text, "versus", coarse_res_text)
results <- list()
add <- function(x) results[[length(results) + 1L]] <<- x

# Resolution effects with constant cell-count windows. Non-focal metrics are
# calculated once per grid using their cell-neighbor definitions.
for (metric in c("slope_deg", "laplacian_index", "surface_area_ratio")) {
  add(compare_layer(
    "grid resolution", "aggregate elevation to 8 m; derive at 8 m; resample derivatives for 4 m comparison",
    metric, native_3[[metric]], coarse_5[[metric]],
    "derive on 4 m elevation grid", "mean aggregate elevation to 8 m, then derive",
    resolution_text, "none", "metric-defined cell neighborhood", "metric-defined map support changes with grid",
    "The candidate was differentiated on the coarser grid and then interpolated to pair cells; the reported difference combines aggregation, changed derivative support, and interpolation.",
    resample_candidate = TRUE
  ))
}
for (metric in c("bpi", "vrm")) {
  add(compare_layer(
    "grid resolution", "constant 5-cell focal windows: aggregate elevation to 8 m; derive; resample derivatives",
    metric, native_5[[metric]], coarse_5[[metric]],
    "derive with 5 by 5 cells at 4 m", "mean aggregate elevation to 8 m, then derive with 5 by 5 cells",
    resolution_text, "none", "5 by 5 cells", "20 m native; 40 m coarse",
    "Cell count was held constant, so physical focal support doubled on the coarser grid; the candidate derivative was interpolated only for comparison.",
    resample_candidate = TRUE
  ))
}
for (metric in c("bpi", "vrm")) {
  add(compare_layer(
    "grid resolution", "approximately constant map-unit focal support: native 7-cell versus coarse 3-cell windows",
    metric, native_7[[metric]], coarse_3[[metric]],
    "derive with 7 by 7 cells at 4 m", "mean aggregate elevation to 8 m, then derive with 3 by 3 cells",
    resolution_text, "none", "7 by 7 versus 3 by 3 cells", "28 m native; 24 m coarse",
    "Focal side lengths were approximately matched in map units, while the coarser derivative was still resampled to the native grid for pairwise statistics.",
    resample_candidate = TRUE
  ))
}

# Preprocessing is tested separately at the same native grid resolution.
for (metric in names(native_3)) {
  add(compare_layer(
    "preprocessing", "no smoothing versus 3 by 3 mean smoothing before derivation",
    metric, native_3[[metric]], smoothed_3[[metric]],
    "derive from unsmoothed 4 m elevation", "3 by 3 mean smooth at 4 m, then derive",
    native_res_text, "none versus 3 by 3 mean (12 m side length)", "BPI/VRM 3 by 3 cells", "12 m for BPI/VRM",
    "This preprocessing sensitivity isolates the documented mean filter; it is not presented as an artefact correction."
  ))
}

# Focal-neighborhood sensitivity is tested separately at fixed native grid
# spacing and without smoothing.
for (metric in c("bpi", "vrm")) {
  for (window in c(7L, 11L)) {
    candidate <- if (window == 7L) native_7[[metric]] else native_11[[metric]]
    add(compare_layer(
      "focal neighborhood", paste0(metric, " 3-cell versus ", window, "-cell square windows at native resolution"),
      metric, native_3[[metric]], candidate,
      "derive with 3 by 3 cells", paste0("derive with ", window, " by ", window, " cells"),
      native_res_text, "none", paste0("3 by 3 versus ", window, " by ", window, " cells"),
      paste0("12 m versus ", window * native_resolution[[1]], " m square side length"),
      "Changing focal support changes the local reference for BPI and the normal-vector aggregation area for VRM; neither window is universally preferred."
    ))
  }
}

# Sign convention is a representation comparison at fixed grid, focal support,
# and preprocessing; it is not a vertical-datum conversion.
for (metric in names(native_3)) {
  add(compare_layer(
    "vertical sign", "negative elevation versus positive-depth representation",
    metric, native_3[[metric]], positive_3[[metric]],
    "negative elevation values", "values multiplied by -1 before derivation",
    native_res_text, "none", "BPI/VRM 3 by 3 cells", "12 m for BPI/VRM",
    "Gradient magnitude and the surface-area approximation are sign-invariant, whereas aspect-dependent or elevation-difference quantities can reverse interpretation or sign."
  ))
}

# Geographic coordinates are a unit-control experiment, not a numerical
# comparison: map-unit annular BPI must reject longitude-latitude input.
geographic <- terra::project(bathy, "EPSG:4326", method = "bilinear")
annular_crs_message <- tryCatch({
  derive_bpi(geographic, outer_radius = 20)
  "unexpectedly accepted"
}, error = function(error) conditionMessage(error))
results[[length(results) + 1L]] <- data.frame(
  scenario_class = "coordinate-unit control",
  scenario = "annular BPI on longitude-latitude raster",
  metric = "annular BPI",
  units = "map-unit radius",
  reference_processing = "EPSG:6348 projected elevation",
  candidate_processing = "bilinear projection to EPSG:4326 for diagnostic only",
  resolution = sprintf("%.0f m projected source; %.8f by %.8f degrees diagnostic grid", native_resolution[[1]], terra::res(geographic)[[1]], terra::res(geographic)[[2]]),
  smoothing = "none",
  focal_scale_cells = "annulus",
  focal_scale_metres = "20 m request",
  comparison_grid = "not applicable",
  interpolation = "not applicable",
  n_compared = NA_integer_,
  median_absolute_cellwise_difference = NA_real_,
  median_signed_cellwise_difference = NA_real_,
  spearman_rho = NA_real_,
  interpretation = paste("The documented CRS guard returned:", annular_crs_message),
  stringsAsFactors = FALSE
)

table4 <- do.call(rbind, results)
write_csv(table4, "sensitivity_results.csv")
write_csv(table4, "table4_scale_preprocessing_sensitivity.csv")

scenario_metadata <- data.frame(
  scenario = c("native_unsmoothed", "native_3x3_smoothed", "coarse_8m_aggregate", "positive_depth", "geographic_diagnostic"),
  source = c("BlueTopo elevation crop", "BlueTopo elevation crop", "mean aggregation of native crop", "sign-converted native crop", "bilinear projection of native crop for CRS control"),
  rows = c(terra::nrow(bathy), terra::nrow(smoothed_bathy), terra::nrow(coarse_bathy), terra::nrow(positive_bathy), terra::nrow(geographic)),
  columns = c(terra::ncol(bathy), terra::ncol(smoothed_bathy), terra::ncol(coarse_bathy), terra::ncol(positive_bathy), terra::ncol(geographic)),
  cells = c(terra::ncell(bathy), terra::ncell(smoothed_bathy), terra::ncell(coarse_bathy), terra::ncell(positive_bathy), terra::ncell(geographic)),
  resolution_x = c(terra::res(bathy)[[1]], terra::res(smoothed_bathy)[[1]], terra::res(coarse_bathy)[[1]], terra::res(positive_bathy)[[1]], terra::res(geographic)[[1]]),
  resolution_y = c(terra::res(bathy)[[2]], terra::res(smoothed_bathy)[[2]], terra::res(coarse_bathy)[[2]], terra::res(positive_bathy)[[2]], terra::res(geographic)[[2]]),
  crs = c("EPSG:6348", "EPSG:6348", "EPSG:6348", "EPSG:6348", "EPSG:4326"),
  stringsAsFactors = FALSE
)
write_csv(scenario_metadata, "scenario_metadata.csv")

artifact_paths <- c(
  native_3 = write_artifact(native_3, "native_4m_metrics_3cell"),
  smoothed_3 = write_artifact(smoothed_3, "smoothed_4m_metrics_3cell"),
  native_5 = write_artifact(native_5, "native_4m_metrics_5cell"),
  coarse_5 = write_artifact(coarse_5, "coarse_8m_metrics_5cell"),
  native_7 = write_artifact(native_7, "native_4m_metrics_7cell"),
  coarse_3 = write_artifact(coarse_3, "coarse_8m_metrics_3cell"),
  native_11 = write_artifact(native_11, "native_4m_metrics_11cell"),
  positive_3 = write_artifact(positive_3, "positive_depth_4m_metrics_3cell"),
  native_bathy = write_artifact(bathy, "native_4m_elevation"),
  smoothed_bathy = write_artifact(smoothed_bathy, "smoothed_4m_elevation"),
  coarse_bathy = write_artifact(coarse_bathy, "coarse_8m_elevation")
)
saveRDS(
  list(paths = artifact_paths, sensitivity = table4, scenario_metadata = scenario_metadata),
  file.path(out_dir, "sensitivity_artifacts.rds")
)

writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
writeLines(capture.output(terra::gdal()), file.path(out_dir, "gdal.txt"))
message("Wrote separated sensitivity results to ", out_dir)
