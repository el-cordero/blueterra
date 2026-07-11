#!/usr/bin/env Rscript

# Functional verification of blueterra-specific spatial workflow components.
# The checks use synthetic projected surfaces with known geometry. They verify
# software behaviour only; they do not validate physical-process inference.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_dir <- if (length(script_arg)) {
  dirname(normalizePath(sub("^--file=", "", script_arg[[1]]), mustWork = TRUE))
} else {
  normalizePath(file.path("article", "validation"), mustWork = TRUE)
}
source(file.path(script_dir, "helpers.R"))
load_blueterra_source()

record <- function(
    test_id, metric_family, reference_behavior, evaluated_domain, edge_policy,
    observed, expected, tolerance = 0, pass = NULL, note = ""
) {
  numeric_pair <- is.numeric(observed) && is.numeric(expected) &&
    length(observed) == 1L && length(expected) == 1L
  error <- if (numeric_pair && is.finite(observed) && is.finite(expected)) {
    abs(observed - expected)
  } else {
    NA_real_
  }
  if (is.null(pass)) {
    pass <- if (numeric_pair) is.finite(error) && error <= tolerance else identical(observed, expected)
  }
  data.frame(
    test_id = test_id,
    metric_family = metric_family,
    reference_behavior = reference_behavior,
    evaluated_domain = evaluated_domain,
    edge_policy = edge_policy,
    observed = as.character(observed),
    expected = as.character(expected),
    max_abs_error = error,
    tolerance = tolerance,
    pass = isTRUE(pass),
    note = note,
    stringsAsFactors = FALSE
  )
}

projected_raster <- function(nrows, ncols, xres = 1, yres = 1, values = NULL) {
  r <- terra::rast(
    nrows = nrows, ncols = ncols,
    xmin = 0, xmax = ncols * xres, ymin = 0, ymax = nrows * yres,
    crs = "EPSG:32620"
  )
  terra::values(r) <- if (is.null(values)) seq_len(terra::ncell(r)) else values
  names(r) <- "z"
  r
}

rectangle <- function(xmin, ymin, xmax, ymax) {
  terra::vect(
    rbind(c(xmin, ymin), c(xmax, ymin), c(xmax, ymax), c(xmin, ymax), c(xmin, ymin)),
    type = "polygons", crs = "EPSG:32620"
  )
}

results <- list()
add <- function(x) {
  results[[length(results) + 1L]] <<- x
}

# BPI geometry, CRS, zero variance, and partial support.
non_square <- projected_raster(5, 7, xres = 2, yres = 4)
kernel <- blueterra:::bpi_window(
  non_square, inner_radius = 0, outer_radius = 4, window = NULL, scale = "custom"
)
add(record(
  "annular_bpi_non_square_kernel", "BPI", "independent x/y map-unit offsets",
  "5 by 7 cells at 2 by 4 m", "annulus includes cells on both radius boundaries",
  sum(!is.na(kernel)), 7, note = "Kernel has 3 rows by 5 columns; the focal cell is included."
))
lonlat <- terra::rast(non_square)
terra::values(lonlat) <- terra::values(non_square, mat = FALSE)
terra::crs(lonlat) <- "EPSG:4326"
crs_error <- tryCatch({
  derive_bpi(lonlat, outer_radius = 4)
  FALSE
}, error = function(error) grepl("projected", conditionMessage(error), ignore.case = TRUE))
add(record(
  "annular_bpi_requires_projected_crs", "BPI", "map-unit radii require projected CRS",
  "longitude-latitude synthetic grid", "not applicable", crs_error, TRUE,
  note = "The error prevents interpreting angular degrees as map-unit radii."
))
constant <- projected_raster(7, 7, values = rep(5, 49))
normalized <- derive_bpi(constant, window = 3, normalize = TRUE)
add(record(
  "normalized_bpi_zero_variance", "BPI", "undefined normalization recorded as missing",
  "constant 7 by 7 raster", "partial windows allowed; all local SD values are zero",
  all(is.na(terra::values(normalized, mat = FALSE))), TRUE,
  note = "No NaN values are emitted."
))
partial <- projected_raster(7, 7)
partial_bpi <- derive_bpi(partial, window = 3)
partial_vrm <- derive_rugosity(partial, window = 3)
add(record(
  "bpi_partial_focal_support", "BPI", "available in-bounds neighbourhood cells are used",
  "upper-left raster corner", "BPI focal mean uses partial support", 
  is.finite(terra::values(partial_bpi, mat = FALSE)[1]), TRUE
))
add(record(
  "vrm_partial_focal_support", "VRM-style rugosity", "available normal-vector cells are used",
  "second row, second column adjacent to derivative boundary", "outer slope/aspect row is missing",
  is.finite(terra::values(partial_vrm, mat = FALSE)[9]), TRUE,
  note = "The outermost raster cells remain missing because terrain derivatives need neighbours."
))

# Transect orientation, spacing, clipping, and resultant reliability.
r100 <- projected_raster(100, 100)
y <- terra::init(r100, "y")
names(y) <- "south_facing"
zone <- rectangle(0, 0, 100, 100)
orientation <- estimate_surface_orientation(y, zone, orientation_weight = "none", return = "both")
add(record(
  "planar_transect_orientation", "transects", "south-facing plane yields north-south transects",
  "100 by 100 m square", "interior terrain cells", orientation$transect_angle_deg, 90, 1e-6
))
add(record(
  "planar_orientation_resultant", "transects", "aligned aspects have unit circular resultant",
  "100 by 100 m square", "interior terrain cells", orientation$orientation_resultant_length, 1, 1e-6
))
manual_lines <- make_transects(zone, spacing = 25, angle = 0)
coordinates <- terra::crds(manual_lines)
add(record(
  "transect_line_count", "transects", "regular offsets intersect a 100 m square four times",
  "100 by 100 m square; 25 m spacing", "candidate lines clipped to polygon", nrow(manual_lines), 4
))
add(record(
  "transect_offset_spacing", "transects", "adjacent generated offsets differ by 25 m",
  "manual horizontal lines", "candidate lines clipped to polygon",
  min(diff(sort(unique(manual_lines$offset)))), 25, 1e-9
))
add(record(
  "transect_clipping", "transects", "all output vertices lie within source rectangle",
  "manual horizontal lines", "intersected with source polygon",
  all(coordinates[, 1] >= 0 & coordinates[, 1] <= 100 & coordinates[, 2] >= 0 & coordinates[, 2] <= 100), TRUE
))
x40 <- terra::init(projected_raster(40, 40), "x")
y40 <- terra::init(projected_raster(40, 40), "y")
mixed <- terra::ifel(x40 < 24, y40, -y40)
names(mixed) <- "mixed_aspect"
mixed_orientation <- estimate_surface_orientation(mixed, rectangle(0, 0, 40, 40), orientation_weight = "none", return = "both")
add(record(
  "weak_aspect_resultant", "transects", "opposing aspect modes produce low concentration",
  "40 by 40 m two-mode synthetic surface", "interior finite aspect cells",
  mixed_orientation$orientation_resultant_length, 0.45, tolerance = 0,
  pass = mixed_orientation$orientation_resultant_length > 0 && mixed_orientation$orientation_resultant_length < 0.45,
  note = "The numeric expected value is an upper reliability threshold, not an equality target."
))

# Isobaths and corridors on a ramp with analytically known contour location.
ramp_template <- projected_raster(40, 100)
ramp <- -terra::init(ramp_template, "x")
names(ramp) <- "elevation"
contour <- extract_isobaths(ramp, depths = -50)
add(record(
  "ramp_isobath_location", "isobath corridors", "z = -x crosses -50 at x = 50 m",
  "100 m-wide projected ramp", "contour interior", mean(terra::crds(contour)[, 1]), 50, 1e-6
))
corridor <- make_isobath_corridors(ramp, depths = -50, width = 10)
corridor_extent <- terra::ext(corridor)
add(record(
  "corridor_nominal_width", "isobath corridors", "one-sided 10 m buffer has nominal 20 m full width",
  "single ramp contour", "buffer includes both sides", unique(corridor$nominal_corridor_width), 20
))
add(record(
  "corridor_geometry_width", "isobath corridors", "buffer spans x = 40 to 60 m",
  "single ramp contour", "round endcaps do not change x extent",
  unname(corridor_extent[2] - corridor_extent[1]), 20, 1e-6
))
overlapping <- make_isobath_corridors(ramp, depths = c(-45, -50), width = 10)
add(record(
  "corridor_overlap_policy", "isobath corridors", "nearby independent buffers can overlap",
  "two contours 5 m apart with 10 m one-sided buffers", "independent polygons retained",
  nrow(terra::intersect(overlapping[1, ], overlapping[2, ])) > 0, TRUE,
  note = "Corridor summaries are not mutually exclusive or additive when overlap occurs."
))

# Polygon, depth-band, exact-intersection, custom-layer, and catalog behavior.
known <- projected_raster(2, 2, values = c(1, 2, 3, 4))
whole <- rectangle(0, 0, 2, 2)
summary <- summarize_terrain(known, whole, fun = c("mean", "count"))
add(record(
  "polygon_summary_known_values", "spatial summaries", "whole-raster mean of 1, 2, 3, 4",
  "attribute-less polygon covering all cells", "cell-centre extraction", summary$z_mean, 2.5, 1e-12
))
add(record(
  "polygon_summary_zone_id", "spatial summaries", "attribute-less geometry receives stable zone id",
  "one polygon", "not applicable", summary$zone_id, 1L
))
depth <- terra::rast(known)
terra::values(depth) <- c(-4, -3, -2, -1)
names(depth) <- "depth"
bands <- summarize_depth_bands(depth, metrics = depth, breaks = c(-4, -2, 0), fun = "mean")
add(record(
  "depth_band_order_and_counts", "spatial summaries", "left-closed ordered bands each contain two cells",
  "values -4 through -1", "uppermost interval includes final break",
  paste(bands$n_cells, collapse = ","), "2,2",
  note = paste("Bands:", paste(bands$depth_band, collapse = "; "))
))
if (requireNamespace("exactextractr", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)) {
  two_cells <- projected_raster(1, 2, values = c(0, 10))
  fractional <- rectangle(0, 0, 1.5, 1)
  exact <- summarize_terrain(two_cells, fractional, fun = c("mean", "sum", "count"), exact = TRUE)
  add(record(
    "exact_intersection_weighted_mean", "spatial summaries", "coverage fractions 1 and 0.5 weight values 0 and 10",
    "two cells intersected by one 1.5-cell-wide polygon", "positive-coverage cell fractions",
    exact$z_mean, 10 / 3, 1e-8,
    note = "Exact sum is 5 and effective cell count is 1.5."
  ))
}
base <- derive_terrain(projected_raster(20, 20), metrics = c("slope", "bpi"))
misaligned <- terra::aggregate(base[["slope_deg"]], fact = 2)
geometry_error <- tryCatch({
  add_metric_layers(base, misaligned)
  FALSE
}, error = function(error) grepl("match the geometry", conditionMessage(error), fixed = TRUE))
add(record(
  "custom_layer_geometry_rejection", "custom layers", "misaligned raster cannot join metric stack",
  "20 by 20 m source and factor-two aggregate", "geometry check before merge", geometry_error, TRUE
))
assignment <- assign_process_groups(c("slope_deg", "unmatched_metric"))
add(record(
  "metric_catalog_unmatched_layer", "metric catalog", "unmatched name is labeled unassigned and not matched",
  "one known and one unknown metric name", "not applicable",
  assignment$process_group[assignment$metric == "unmatched_metric"], "unassigned"
))

results <- do.call(rbind, results)
out_path <- file.path(validation_results_dir(), "functional_verification.csv")
utils::write.csv(results, out_path, row.names = FALSE, na = "")
write_session_info()
write_results_readme()
if (any(!results$pass)) {
  stop("Functional verification failed: ", paste(results$test_id[!results$pass], collapse = ", "), call. = FALSE)
}
message("Wrote functional verification results to ", out_path)
