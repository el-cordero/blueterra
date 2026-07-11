#!/usr/bin/env Rscript

# Reacquire and prepare the documented BlueTopo application example used by
# the revised Earth Science Informatics article. The script is intentionally
# specific to the selected public tile so that the article's real-data figures
# can be regenerated from named, checksummed source artifacts.

suppressPackageStartupMessages({
  library(terra)
  library(digest)
  library(jsonlite)
})
suppressMessages(terra::projNetwork(FALSE))

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/data_provenance/acquire_bluetopo_example.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
base <- file.path(root, "article", "data_provenance")
raw_dir <- file.path(base, "raw")
result_dir <- file.path(base, "results")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

tile_id <- "BH54S4ZB"
tile_date <- "20251117"
tile_url <- paste0(
  "https://noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/",
  tile_id, "/BlueTopo_", tile_id, "_", tile_date, ".tiff"
)
rat_url <- paste0(tile_url, ".aux.xml")
tile_scheme_url <- paste0(
  "https://noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/",
  "_BlueTopo_Tile_Scheme/BlueTopo_Tile_Scheme_20260626_132625.gpkg"
)
tile_path <- file.path(raw_dir, basename(tile_url))
rat_path <- file.path(raw_dir, basename(rat_url))
tile_scheme_path <- file.path(raw_dir, basename(tile_scheme_url))
expected_tile_sha256 <- "3625a8ef3df3e81a31467ab35e7ec589285d91a41daee12627448b10dd108d23"
expected_rat_sha256 <- "2d73d705e843387313668b66c3b92a18764bafabe25839c7fa52b49afa8cc8c2"
expected_scheme_sha256 <- "dc854cc98608eaae19e5cc8e4ccf92f9f61af998cc135c61c649d2052c3fc319"

download_checked <- function(url, path, expected_sha256) {
  if (!file.exists(path)) {
    utils::download.file(url, path, mode = "wb", method = "libcurl", quiet = TRUE)
  }
  observed <- digest::digest(file = path, algo = "sha256")
  if (!identical(observed, expected_sha256)) {
    stop("SHA-256 mismatch for ", basename(path), call. = FALSE)
  }
  observed
}

tile_scheme_sha256 <- download_checked(tile_scheme_url, tile_scheme_path, expected_scheme_sha256)
tile_sha256 <- download_checked(tile_url, tile_path, expected_tile_sha256)
rat_sha256 <- download_checked(rat_url, rat_path, expected_rat_sha256)

tile_scheme <- terra::vect(tile_scheme_path)
selected <- as.data.frame(tile_scheme[tile_scheme$tile == tile_id, ])
if (nrow(selected) != 1L) {
  stop("The selected tile was not found exactly once in the downloaded tile scheme.", call. = FALSE)
}
if (!identical(selected$GeoTIFF_SHA256_Checksum[[1]], tile_sha256) ||
    !identical(selected$RAT_SHA256_Checksum[[1]], rat_sha256)) {
  stop("Downloaded checksums disagree with the selected tile-scheme record.", call. = FALSE)
}

# The study extent is a deterministic rectangular analytical window within the
# named BlueTopo tile. It crosses the shelf break but is not presented as a
# habitat, management, or ecological sampling design.
source <- terra::rast(tile_path)[[1]]
study_extent_requested <- terra::ext(708000, 712000, 1976500, 1979500)
study <- terra::crop(source, study_extent_requested, snap = "out")
names(study) <- "elevation_m"
study_path <- file.path(result_dir, "bluetopo_bh54s4zb_elevation_example.tif")
terra::writeRaster(study, study_path, overwrite = TRUE, wopt = list(gdal = "COMPRESS=DEFLATE"))

# Author-created geometric windows support repeatable summaries and transects.
# They are derived only from the declared study window and have no external
# provenance or site-interpretation claim.
study_ext <- terra::ext(study)
window_bounds <- rbind(
  c(study_ext[1] +  400, study_ext[1] + 1600, study_ext[3] + 1200, study_ext[3] + 2200),
  c(study_ext[1] + 2100, study_ext[1] + 3500, study_ext[3] +  400, study_ext[3] + 1600)
)
make_window <- function(bounds) {
  coords <- matrix(c(
    bounds[1], bounds[3], bounds[2], bounds[3], bounds[2], bounds[4],
    bounds[1], bounds[4], bounds[1], bounds[3]
  ), ncol = 2, byrow = TRUE)
  terra::vect(coords, type = "polygons", crs = terra::crs(study))
}
zones <- do.call(rbind, lapply(seq_len(nrow(window_bounds)), function(i) make_window(window_bounds[i, ])))
zones$zone_id <- c("shelf_window", "slope_window")
zones$polygon_provenance <- "author-created deterministic analytical window"
zones_path <- file.path(result_dir, "bluetopo_author_analysis_windows.gpkg")
terra::writeVector(zones, zones_path, overwrite = TRUE)

study_bbox_wgs84 <- terra::project(terra::as.polygons(terra::ext(study), crs = terra::crs(study)), "EPSG:4326")
study_extent_wgs84 <- terra::ext(study_bbox_wgs84)
metadata_lines <- terra::describe(source)
vertical_datum <- grep("VERTICALDATUMWKT", metadata_lines, value = TRUE)
if (length(vertical_datum) == 0L) {
  vertical_datum <- "No VERTICALDATUMWKT metadata item was found."
}

study_sha256 <- digest::digest(file = study_path, algo = "sha256")
zones_sha256 <- digest::digest(file = zones_path, algo = "sha256")
manifest <- data.frame(
  field = c(
    "product", "tile_id", "tile_filename", "tile_url", "tile_delivered_date_utc",
    "tile_resolution", "tile_horizontal_crs", "tile_vertical_reference_summary", "tile_vertical_reference_wkt",
    "tile_sha256", "rat_url", "rat_sha256", "tile_scheme_url", "tile_scheme_sha256",
    "accessed_utc", "study_raster", "study_raster_sha256", "study_rows", "study_columns",
    "study_xmin_m", "study_xmax_m", "study_ymin_m", "study_ymax_m", "study_grid_spacing_m",
    "study_wgs84_xmin", "study_wgs84_xmax", "study_wgs84_ymin", "study_wgs84_ymax",
    "vertical_convention", "preprocessing", "sampling_polygons", "reuse_status"
  ),
  value = c(
    "NOAA Office of Coast Survey BlueTopo", tile_id, basename(tile_path), tile_url,
    selected$Delivered_Date[[1]], selected$Resolution[[1]],
    "EPSG:6348, NAD83(2011) / UTM zone 19N",
    "MSL(GEOID12B) height: Mean Sea Level, NOAA hybrid geoid 2012, B model; no vertical transformation was applied.",
    vertical_datum[[1]],
    tile_sha256, rat_url, rat_sha256, tile_scheme_url, tile_scheme_sha256,
    format(Sys.time(), tz = "UTC", usetz = TRUE), basename(study_path), study_sha256,
    terra::nrow(study), terra::ncol(study), study_ext[1], study_ext[2], study_ext[3], study_ext[4],
    terra::res(study)[1], study_extent_wgs84[1], study_extent_wgs84[2],
    study_extent_wgs84[3], study_extent_wgs84[4],
    "Elevation in metres; increasingly negative values represent deeper water.",
    "Elevation band only; crop to the declared analytical extent; no smoothing or vertical-datum transformation.",
    paste0(basename(zones_path), "; author-created deterministic rectangular analytical windows; SHA-256 ", zones_sha256),
    "BlueTopo is described by NOAA as free and in the U.S. public domain; the selected tile RAT records source licenses."
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(manifest, file.path(result_dir, "bluetopo_example_manifest.csv"), row.names = FALSE)
jsonlite::write_json(
  as.list(stats::setNames(manifest$value, manifest$field)),
  file.path(result_dir, "bluetopo_example_manifest.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)
writeLines(metadata_lines, file.path(result_dir, "bluetopo_tile_gdal_description.txt"))
writeLines(capture.output(sessionInfo()), file.path(result_dir, "sessionInfo.txt"))
message("Reacquired and prepared BlueTopo example data in ", result_dir)
