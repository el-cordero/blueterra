#' Read a bathymetric or elevation raster
#'
#' @description
#' Reads a local raster file with `terra::rast()` and optionally validates that
#' the result is usable as a bathymetric or elevation surface.
#'
#' @param path Local raster file path.
#' @param ... Additional arguments passed to `terra::rast()`.
#' @param check Logical. If `TRUE`, validate the raster before returning it.
#'
#' @return A `terra::SpatRaster`.
#'
#' @details
#' `read_bathy()` is data-source agnostic. The input can be any local raster
#' format supported by `terra`, including GeoTIFF and many GDAL-readable files.
#' The function does not assume BlueTopo provenance and never downloads data.
#'
#' @examples
#' path <- blueterra_example("bathy")
#' bathy <- read_bathy(path)
#' bathy
#'
#' @seealso [as_bathy()], [validate_bathy()], [prepare_bathy()]
#' @export
read_bathy <- function(path, ..., check = TRUE) {
  if (!is.character(path) || length(path) != 1 || !nzchar(path)) {
    bt_abort("`path` must be a single local raster file path.")
  }
  if (!file.exists(path)) {
    bt_abort("Raster file does not exist.")
  }
  out <- try(terra::rast(path, ...), silent = TRUE)
  if (inherits(out, "try-error")) {
    bt_abort("Raster could not be read by terra.")
  }
  if (isTRUE(check)) {
    validate_bathy(out)
  }
  out
}

#' Coerce common raster inputs to a bathymetry raster
#'
#' @description
#' Accepts a `terra::SpatRaster` or a local raster file path and returns a
#' `terra::SpatRaster`.
#'
#' @param x A `terra::SpatRaster` or local raster path.
#' @param ... Additional arguments passed to [read_bathy()] when `x` is a path.
#' @param check Logical. If `TRUE`, validate the raster before returning it.
#'
#' @return A `terra::SpatRaster`.
#'
#' @details
#' `as_bathy()` preserves raster values and metadata when possible. It does not
#' flip signs, project CRS, or filter depths unless another function explicitly
#' requests that behavior.
#'
#' @examples
#' as_bathy(blueterra_example("bathy"))
#'
#' @seealso [read_bathy()], [validate_bathy()]
#' @export
as_bathy <- function(x, ..., check = TRUE) {
  if (is_spatraster(x)) {
    if (isTRUE(check)) {
      validate_bathy(x)
    }
    return(x)
  }
  if (is.character(x) && length(x) == 1) {
    return(read_bathy(x, ..., check = check))
  }
  bt_abort("`x` must be a terra::SpatRaster or a local raster file path.")
}

#' Validate a bathymetric or elevation raster
#'
#' @description
#' Checks that an object is a readable `terra::SpatRaster` with dimensions,
#' layers, and values suitable for terrain analysis.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param require_crs Logical. If `TRUE`, require a declared CRS.
#' @param require_values Logical. If `TRUE`, require raster values.
#' @param allow_multi Logical. If `FALSE`, warn when more than one layer is
#'   supplied.
#'
#' @return Invisibly returns the input raster.
#'
#' @details
#' Validation does not decide whether values represent positive depth or
#' negative elevation. Use [check_bathy_units()], [set_depth_positive()], or
#' [set_depth_negative()] when sign convention matters.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' validate_bathy(bathy)
#'
#' @seealso [check_bathy_crs()], [check_bathy_units()]
#' @export
validate_bathy <- function(
    x,
    require_crs = FALSE,
    require_values = TRUE,
    allow_multi = FALSE
) {
  if (!is_spatraster(x)) {
    bt_abort("`x` must be a terra::SpatRaster.")
  }
  if (terra::nlyr(x) < 1) {
    bt_abort("Raster must have at least one layer.")
  }
  if (terra::ncell(x) < 1 || terra::nrow(x) < 1 || terra::ncol(x) < 1) {
    bt_abort("Raster must have at least one cell, row, and column.")
  }
  if (!allow_multi && terra::nlyr(x) > 1) {
    bt_warn("Raster has multiple layers; many bathymetry functions use the first layer.")
  }
  if (require_crs && !nzchar(terra::crs(x))) {
    bt_abort("Raster has no CRS. Supply or assign a CRS before this operation.")
  }
  if (require_values && !terra::hasValues(x)) {
    bt_abort("Raster has no values.")
  }
  invisible(x)
}

#' Check raster CRS for geomorphometry
#'
#' @description
#' Reports whether a bathymetric or elevation raster has a CRS and whether that
#' CRS appears to be geographic longitude/latitude.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param require_projected Logical. If `TRUE`, error when the CRS is missing or
#'   longitude/latitude.
#' @param warn_lonlat Logical. If `TRUE`, warn when the raster is lon/lat.
#'
#' @return A tibble with CRS status fields.
#'
#' @details
#' Many terrain metrics can be calculated on any numeric grid, but metric
#' interpretation is usually strongest in projected coordinate systems with
#' linear units. Buffers, distances, slope, surface-area ratios, and focal
#' windows are all scale-sensitive.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' check_bathy_crs(bathy)
#'
#' @seealso [prepare_bathy()], [project_bathy()]
#' @export
check_bathy_crs <- function(
    x,
    require_projected = FALSE,
    warn_lonlat = TRUE
) {
  x <- as_bathy(x, check = TRUE)
  crs_text <- terra::crs(x)
  has_crs <- nzchar(crs_text)
  lonlat <- if (has_crs) is_lonlat(x) else NA
  projected <- if (has_crs) !isTRUE(lonlat) else FALSE
  if (isTRUE(warn_lonlat) && isTRUE(lonlat)) {
    bt_warn("Raster CRS is longitude/latitude; distance-based metrics may be misleading.")
  }
  if (isTRUE(require_projected) && (!has_crs || isTRUE(lonlat))) {
    bt_abort("A projected CRS with linear map units is required.")
  }
  tibble::tibble(
    has_crs = has_crs,
    is_lonlat = lonlat,
    is_projected = projected,
    crs = crs_text
  )
}

#' Check bathymetry value conventions
#'
#' @description
#' Summarizes raster value ranges and records the intended depth convention when
#' supplied by the user.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param units Optional character label for vertical units, such as `"m"`.
#' @param positive_depth Optional logical. Use `TRUE` when larger positive
#'   values mean deeper water, `FALSE` when bathymetry is stored as negative
#'   elevation, or `NULL` when unknown.
#'
#' @return A tibble with value range and convention fields.
#'
#' @details
#' This function does not infer or alter scientific meaning. It reports the
#' observed range and the user-supplied convention so downstream workflows can
#' be explicit.
#'
#' @examples
#' check_bathy_units(blueterra_example("bathy"), units = "m", positive_depth = FALSE)
#'
#' @seealso [set_depth_positive()], [set_depth_negative()]
#' @export
check_bathy_units <- function(x, units = NULL, positive_depth = NULL) {
  x <- first_layer(x)
  rng <- safe_global_range(x)
  if (!is.null(positive_depth) && !is.logical(positive_depth)) {
    bt_abort("`positive_depth` must be TRUE, FALSE, or NULL.")
  }
  tibble::tibble(
    layer = names(x)[1],
    min = rng[["min"]],
    max = rng[["max"]],
    units = if (is.null(units)) NA_character_ else as.character(units),
    positive_depth = if (is.null(positive_depth)) NA else positive_depth
  )
}

#' Summarize a bathymetric or elevation raster
#'
#' @description
#' Returns a compact table describing raster dimensions, extent, CRS, resolution,
#' layer names, and value range.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#'
#' @return A tibble with one row per raster layer.
#'
#' @examples
#' bathy_info(blueterra_example("bathy"))
#'
#' @seealso [validate_bathy()], [check_bathy_crs()]
#' @export
bathy_info <- function(x) {
  x <- as_bathy(x, check = TRUE)
  ext <- terra::ext(x)
  res <- terra::res(x)
  rows <- vector("list", terra::nlyr(x))
  for (i in seq_len(terra::nlyr(x))) {
    rng <- safe_global_range(x[[i]])
    rows[[i]] <- tibble::tibble(
      layer = names(x)[i],
      nrow = terra::nrow(x),
      ncol = terra::ncol(x),
      ncell = terra::ncell(x),
      xmin = ext[1],
      xmax = ext[2],
      ymin = ext[3],
      ymax = ext[4],
      xres = res[1],
      yres = res[2],
      min = rng[["min"]],
      max = rng[["max"]],
      crs = terra::crs(x)
    )
  }
  dplyr::bind_rows(rows)
}
