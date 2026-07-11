#!/usr/bin/env Rscript

# Execute the documented Route-B BlueTopo workflow in one fresh R process.
# This worker never loads blueterra from the working tree: it uses only the
# package installed in --library. The BlueTopo raster and author-created
# analysis windows are deliberately external, provenance-checked inputs.

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_argument)) sub("^--file=", "", script_argument[[1]]) else "run_route_b_examples.R"
script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
script_dir <- dirname(normalizePath(script_path, mustWork = TRUE))
source(file.path(script_dir, "reproducibility_helpers.R"))

args <- bt_repro_parse_args(commandArgs(trailingOnly = TRUE))
if (isTRUE(args$help)) {
  cat(paste(
    "Usage:",
    "  Rscript --vanilla run_route_b_examples.R --library PATH --output PATH --run-id ID --seed INTEGER --data-root PATH --tag TAG --package-version VERSION",
    sep = "\n"
  ))
  quit(status = 0L)
}

required <- c("library", "output", "run-id", "seed", "data-root", "tag", "package-version")
missing <- required[!vapply(required, function(key) !is.null(args[[key]]) && length(args[[key]]) > 0L, logical(1))]
if (length(missing)) {
  stop("Missing required argument(s): ", paste(paste0("--", missing), collapse = ", "), call. = FALSE)
}

library_dir <- normalizePath(args[["library"]], mustWork = TRUE)
output_dir <- normalizePath(args[["output"]], mustWork = FALSE)
data_root <- normalizePath(args[["data-root"]], mustWork = TRUE)
run_id <- as.character(args[["run-id"]])
release_tag <- as.character(args$tag)
expected_package_version <- as.character(args[["package-version"]])
seed <- suppressWarnings(as.integer(args$seed))
if (is.na(seed)) stop("`--seed` must be an integer.", call. = FALSE)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
tables_dir <- file.path(output_dir, "tables")
binary_dir <- file.path(output_dir, "binary")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(binary_dir, recursive = TRUE, showWarnings = FALSE)

Sys.setenv(R_LIBS_USER = library_dir)
.libPaths(unique(c(library_dir, .libPaths())))

suppressPackageStartupMessages(library(package = "blueterra", lib.loc = library_dir, character.only = TRUE))
suppressPackageStartupMessages(library(terra))

package_path <- normalizePath(find.package("blueterra"), mustWork = TRUE)
if (!startsWith(package_path, paste0(library_dir, "/"))) {
  stop("`blueterra` was not loaded from the isolated package library.", call. = FALSE)
}
if (!requireNamespace("exactextractr", quietly = TRUE) || !requireNamespace("sf", quietly = TRUE)) {
  stop("Route-B exact polygon summaries require the installed `exactextractr` and `sf` packages.", call. = FALSE)
}
installed_package_version <- as.character(utils::packageVersion("blueterra"))
if (!identical(installed_package_version, expected_package_version)) {
  stop(
    "Installed blueterra version ", installed_package_version,
    " does not match the tagged archive version ", expected_package_version, ".",
    call. = FALSE
  )
}

set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
seed_initial_sha256 <- bt_repro_sha256_text(paste(.Random.seed, collapse = ","))
started_at <- bt_repro_utc()

input_paths <- c(
  elevation_raster = file.path(data_root, "bluetopo_bh54s4zb_elevation_example.tif"),
  analysis_windows = file.path(data_root, "bluetopo_author_analysis_windows.gpkg"),
  provenance_manifest = file.path(data_root, "bluetopo_example_manifest.csv")
)
missing_inputs <- names(input_paths)[!file.exists(input_paths)]
if (length(missing_inputs)) {
  stop("Missing documented Route-B input(s): ", paste(missing_inputs, collapse = ", "), call. = FALSE)
}

provenance_manifest <- utils::read.csv(input_paths[["provenance_manifest"]], stringsAsFactors = FALSE)
manifest_value <- function(field) {
  value <- provenance_manifest$value[provenance_manifest$field == field]
  if (length(value) != 1L) NA_character_ else as.character(value[[1]])
}
if (!identical(manifest_value("tile_id"), "BH54S4ZB")) {
  stop("The Route-B manifest does not identify BlueTopo tile BH54S4ZB.", call. = FALSE)
}
if (!identical(basename(input_paths[["elevation_raster"]]), manifest_value("study_raster"))) {
  stop("The Route-B raster filename does not match its provenance manifest.", call. = FALSE)
}

input_hashes <- data.frame(
  scope = "documented_route_b_input",
  artifact = paste0("data_provenance/results/", basename(unname(input_paths))),
  input_name = names(input_paths),
  bytes = as.numeric(file.info(unname(input_paths))$size),
  sha256 = vapply(unname(input_paths), bt_repro_sha256_file, character(1)),
  stringsAsFactors = FALSE
)
raster_hash <- input_hashes$sha256[input_hashes$input_name == "elevation_raster"]
if (!identical(raster_hash, manifest_value("study_raster_sha256"))) {
  stop("The documented Route-B elevation raster SHA-256 does not match its manifest.", call. = FALSE)
}
vector_hash <- input_hashes$sha256[input_hashes$input_name == "analysis_windows"]
vector_manifest_text <- manifest_value("sampling_polygons")
vector_manifest_hash <- regmatches(vector_manifest_text, regexpr("[[:xdigit:]]{64}", vector_manifest_text))
if (length(vector_manifest_hash) != 1L || !identical(tolower(vector_hash), tolower(vector_manifest_hash))) {
  stop("The documented Route-B analysis-window SHA-256 does not match its manifest.", call. = FALSE)
}

# Route-B real-data workflow. The source raster is an elevation grid in metres;
# negative values represent deeper water. Values are preserved as elevation
# rather than reinterpreted as positive depth.
elevation <- read_bathy(input_paths[["elevation_raster"]])
windows <- terra::vect(input_paths[["analysis_windows"]])
window_attributes <- terra::as.data.frame(windows)
if (!"zone_id" %in% names(window_attributes) || !all(c("shelf_window", "slope_window") %in% window_attributes$zone_id)) {
  stop("The documented Route-B analysis windows do not contain shelf_window and slope_window identifiers.", call. = FALSE)
}
slope_window <- windows[window_attributes$zone_id == "slope_window", ]

bathy_metadata <- as.data.frame(bathy_info(elevation), stringsAsFactors = FALSE)
prepared <- prepare_bathy(
  elevation,
  depth_range = c(-800, -10),
  smooth = FALSE
)
metrics <- derive_terrain(
  prepared,
  metrics = c("slope", "bpi", "rugosity", "curvature", "surface_area_ratio"),
  scales = c(3L, 11L),
  neighbors = 8L
)

terrain_summary_exact <- as.data.frame(
  summarize_terrain(
    metrics,
    windows,
    fun = c("mean", "sd", "median", "count"),
    exact = TRUE
  ),
  stringsAsFactors = FALSE
)
depth_band_summary <- as.data.frame(
  summarize_depth_bands(
    prepared,
    metrics = metrics,
    breaks = c(-800, -600, -400, -200, 0),
    fun = c("mean", "median", "count")
  ),
  stringsAsFactors = FALSE
)
transects <- make_transects(slope_window, spacing = 100, bathy = prepared)
cross_sections <- as.data.frame(
  sample_transects(transects, c(prepared, metrics[["slope_deg"]]), n = 20L),
  stringsAsFactors = FALSE
)
isobaths <- extract_isobaths(prepared, depths = c(-50, -200, -400))
corridors <- make_isobath_corridors(prepared, depths = c(-50, -200, -400), width = 20)
corridor_summary_exact <- as.data.frame(
  summarize_isobath_terrain(metrics, corridors, fun = c("mean", "count"), exact = TRUE),
  stringsAsFactors = FALSE
)
metric_global <- terra::global(metrics, fun = c("mean", "sd", "min", "max"), na.rm = TRUE)
metric_global <- data.frame(metric = rownames(metric_global), metric_global, row.names = NULL, check.names = FALSE)

write_table <- function(object, filename) {
  bt_repro_write_csv(as.data.frame(object, stringsAsFactors = FALSE), file.path(tables_dir, filename))
}

write_table(bathy_metadata, "bathy_metadata.csv")
write_table(terrain_summary_exact, "terrain_summary_exact.csv")
write_table(depth_band_summary, "depth_band_summary.csv")
write_table(metric_global, "metric_global_summary.csv")
write_table(terra::as.data.frame(transects), "transect_attributes.csv")
write_table(cross_sections, "cross_sections.csv")
write_table(terra::as.data.frame(isobaths), "isobath_attributes.csv")
write_table(terra::as.data.frame(corridors), "corridor_attributes.csv")
write_table(corridor_summary_exact, "corridor_summary_exact.csv")

prepared_path <- file.path(binary_dir, "prepared_elevation.tif")
metrics_path <- file.path(binary_dir, "metric_stack.tif")
transects_path <- file.path(binary_dir, "transects.gpkg")
corridors_path <- file.path(binary_dir, "isobath_corridors.gpkg")
terra::writeRaster(prepared, prepared_path, overwrite = TRUE, wopt = list(gdal = "COMPRESS=DEFLATE"))
terra::writeRaster(metrics, metrics_path, overwrite = TRUE, wopt = list(gdal = "COMPRESS=DEFLATE"))
terra::writeVector(transects, transects_path, overwrite = TRUE)
terra::writeVector(corridors, corridors_path, overwrite = TRUE)

input_schema <- do.call(rbind, list(
  bt_repro_object_schema("documented_elevation", elevation),
  bt_repro_object_schema("author_analysis_windows", windows),
  bt_repro_object_schema("provenance_manifest", provenance_manifest)
))
output_schema <- do.call(rbind, list(
  bt_repro_object_schema("prepared_elevation", prepared),
  bt_repro_object_schema("metric_stack", metrics),
  bt_repro_object_schema("terrain_summary_exact", terrain_summary_exact),
  bt_repro_object_schema("depth_band_summary", depth_band_summary),
  bt_repro_object_schema("transects", transects),
  bt_repro_object_schema("cross_sections", cross_sections),
  bt_repro_object_schema("isobaths", isobaths),
  bt_repro_object_schema("isobath_corridors", corridors),
  bt_repro_object_schema("corridor_summary_exact", corridor_summary_exact)
))
bt_repro_write_csv(input_hashes, file.path(output_dir, "input_hashes.csv"))
bt_repro_write_csv(input_schema, file.path(output_dir, "input_schema.csv"))
bt_repro_write_csv(output_schema, file.path(output_dir, "output_schema.csv"))

binary_inventory <- data.frame(
  artifact = c(
    "binary/prepared_elevation.tif", "binary/metric_stack.tif",
    "binary/transects.gpkg", "binary/isobath_corridors.gpkg"
  ),
  object = c("prepared_elevation", "metric_stack", "transects", "isobath_corridors"),
  format = c("GeoTIFF", "GeoTIFF", "GeoPackage", "GeoPackage"),
  bytes = as.numeric(file.info(c(prepared_path, metrics_path, transects_path, corridors_path))$size),
  comparison_policy = "schema comparison; binary hash not treated as platform-independent",
  stringsAsFactors = FALSE
)
bt_repro_write_csv(binary_inventory, file.path(output_dir, "output_binary_inventory.csv"))

dependency_roles <- c(
  blueterra = "tagged package under test",
  terra = "direct import and Route-B spatial workflow",
  cli = "direct import",
  dplyr = "direct import",
  rlang = "direct import",
  tibble = "direct import",
  exactextractr = "exact coverage-fraction-weighted polygon summaries",
  sf = "exact summary geometry conversion"
)
dependency_versions <- do.call(rbind, lapply(names(dependency_roles), function(package) {
  available <- requireNamespace(package, quietly = TRUE)
  data.frame(
    package = package,
    role = unname(dependency_roles[[package]]),
    available = available,
    version = if (available) as.character(utils::packageVersion(package)) else NA_character_,
    library = if (available) normalizePath(find.package(package), mustWork = TRUE) else NA_character_,
    loaded = package %in% loadedNamespaces(),
    stringsAsFactors = FALSE
  )
}))
bt_repro_write_csv(dependency_versions, file.path(output_dir, "dependency_versions.csv"))

platform_details <- data.frame(
  key = c(
    "run_id", "release_tag", "r_version", "r_platform", "os_name", "sysname",
    "release", "machine", "timezone", "r_libs_user", "package_library",
    "package_path", "package_version", "terra_version", "exactextractr_version",
    "input_data_root"
  ),
  value = c(
    run_id, release_tag, R.version.string, R.version$platform, .Platform$OS.type,
    unname(Sys.info()[["sysname"]]), unname(Sys.info()[["release"]]),
    unname(Sys.info()[["machine"]]), Sys.timezone(), Sys.getenv("R_LIBS_USER"),
    library_dir, package_path, installed_package_version,
    as.character(utils::packageVersion("terra")),
    as.character(utils::packageVersion("exactextractr")), data_root
  ),
  stringsAsFactors = FALSE
)
bt_repro_write_csv(platform_details, file.path(output_dir, "platform_details.csv"))
capture.output(sessionInfo(), file = file.path(output_dir, "sessionInfo.txt"))

# Table CSVs are deterministic within a fixed software environment. Binary
# raster and vector files are represented by schemas and the inventory above.
output_hashes <- bt_repro_file_hashes(tables_dir, scope = "deterministic_table")
bt_repro_write_csv(output_hashes, file.path(output_dir, "output_hashes.csv"))

warning_lines <- capture.output(warnings())
if (!length(warning_lines)) warning_lines <- "No warnings recorded."
writeLines(warning_lines, file.path(output_dir, "warnings.txt"), useBytes = TRUE)

seed_final_sha256 <- bt_repro_sha256_text(paste(.Random.seed, collapse = ","))
finished_at <- bt_repro_utc()
bt_repro_write_json(
  list(
    run_id = run_id,
    release_tag = release_tag,
    started_at_utc = started_at,
    finished_at_utc = finished_at,
    random_seed = seed,
    random_seed_kind = "Mersenne-Twister / Inversion / Rejection",
    random_seed_initial_sha256 = seed_initial_sha256,
    random_seed_final_sha256 = seed_final_sha256,
    package_version = installed_package_version,
    package_path = package_path,
    isolated_library = library_dir,
    route_b_data_root = data_root,
    route_b_tile_id = manifest_value("tile_id"),
    route_b_raster_sha256 = raster_hash,
    worker_sha256 = bt_repro_sha256_file(script_path),
    helpers_sha256 = bt_repro_sha256_file(file.path(script_dir, "reproducibility_helpers.R")),
    output_table_artifacts = nrow(output_hashes),
    output_binary_artifacts = nrow(binary_inventory),
    loaded_namespaces = sort(loadedNamespaces())
  ),
  file.path(output_dir, "run_metadata.json")
)

bt_repro_write_csv(
  data.frame(
    run_id = run_id,
    release_tag = release_tag,
    status = "PASS",
    started_at_utc = started_at,
    finished_at_utc = finished_at,
    input_artifacts = nrow(input_hashes),
    output_table_artifacts = nrow(output_hashes),
    output_binary_artifacts = nrow(binary_inventory),
    stringsAsFactors = FALSE
  ),
  file.path(output_dir, "workflow_status.csv")
)

cat("Documented Route-B BlueTopo workflow completed successfully for ", run_id, ".\n", sep = "")
