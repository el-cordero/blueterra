#' Prepare a bathymetric or elevation raster
#'
#' @description
#' Applies common preprocessing steps for terrain analysis: optional projection,
#' resampling, cropping, masking, depth filtering, sign conversion, smoothing,
#' and optional file-backed output.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param crs Optional target CRS passed to [project_bathy()].
#' @param resolution Optional target cell size. A single value is used for both
#'   axes; two values are used as x and y resolution.
#' @param extent Optional crop extent: `SpatExtent`, numeric
#'   `xmin, xmax, ymin, ymax`, raster, or vector object.
#' @param mask Optional polygon/vector mask.
#' @param depth_range Optional numeric length-two range of retained depths or
#'   elevations.
#' @param positive_depth Optional logical. If `TRUE`, convert output to positive
#'   depth. If `FALSE`, convert output to negative depth/elevation. If `NULL`,
#'   preserve sign convention.
#' @param method Resampling and projection method passed to `terra`.
#' @param smooth Logical. If `TRUE`, apply [smooth_bathy()].
#' @param smooth_window Odd integer focal-window size for smoothing.
#' @param filename Optional output raster path.
#' @param overwrite Logical. Allow overwriting `filename`.
#'
#' @return A `terra::SpatRaster`.
#'
#' @details
#' `prepare_bathy()` never automatically reprojects or flips depth signs. Those
#' operations occur only when `crs` or `positive_depth` are supplied. Distance-
#' based geomorphometry should generally be performed in a projected CRS with
#' linear units.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' prepared <- prepare_bathy(bathy, depth_range = c(-90, -20), smooth = TRUE)
#' prepared
#'
#' @seealso [crop_bathy()], [mask_bathy()], [depth_filter()]
#' @export
prepare_bathy <- function(
    x,
    crs = NULL,
    resolution = NULL,
    extent = NULL,
    mask = NULL,
    depth_range = NULL,
    positive_depth = NULL,
    method = "bilinear",
    smooth = FALSE,
    smooth_window = 3,
    filename = "",
    overwrite = FALSE
) {
  out <- as_bathy(x, check = TRUE)
  if (!is.null(crs)) {
    out <- project_bathy(out, crs = crs, method = method)
  }
  if (!is.null(resolution)) {
    resolution <- as.numeric(resolution)
    if (!length(resolution) %in% c(1, 2) || any(!is.finite(resolution))) {
      bt_abort("`resolution` must be one or two finite numeric values.")
    }
    template <- terra::rast(
      terra::ext(out),
      resolution = resolution,
      crs = terra::crs(out)
    )
    out <- terra::resample(out, template, method = method)
  }
  if (!is.null(extent)) {
    out <- crop_bathy(out, extent)
  }
  if (!is.null(mask)) {
    out <- mask_bathy(out, mask)
  }
  if (!is.null(depth_range)) {
    out <- depth_filter(out, depth_range = depth_range)
  }
  if (!is.null(positive_depth)) {
    if (!is.logical(positive_depth) || length(positive_depth) != 1) {
      bt_abort("`positive_depth` must be TRUE, FALSE, or NULL.")
    }
    out <- if (positive_depth) set_depth_positive(out) else set_depth_negative(out)
  }
  if (isTRUE(smooth)) {
    out <- smooth_bathy(out, window = smooth_window)
  }
  write_raster_if_requested(out, filename, overwrite)
}

#' Crop, mask, resample, and project bathymetry
#'
#' @description
#' Small wrappers around `terra` raster-preparation operations with bathymetry
#' input validation.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param extent Crop extent.
#' @param mask Polygon/vector mask.
#' @param y Template raster used for resampling.
#' @param crs Target CRS.
#' @param method Interpolation method passed to `terra`.
#' @param filename Optional output raster path.
#' @param overwrite Logical. Allow overwriting `filename`.
#'
#' @return A `terra::SpatRaster`.
#'
#' @details
#' These helpers preserve depth sign and raster values except for interpolation
#' effects introduced by resampling or projection.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' crop_bathy(bathy, terra::ext(50, 350, 50, 350))
#'
#' @seealso [prepare_bathy()]
#' @export
crop_bathy <- function(x, extent, filename = "", overwrite = FALSE) {
  out <- terra::crop(as_bathy(x, check = TRUE), as_spat_extent(extent))
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname crop_bathy
#' @export
mask_bathy <- function(x, mask, filename = "", overwrite = FALSE) {
  r <- as_bathy(x, check = TRUE)
  v <- as_spatvector(mask)
  if (!terra::same.crs(r, v)) {
    v <- terra::project(v, terra::crs(r))
  }
  out <- terra::mask(r, v)
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname crop_bathy
#' @export
resample_bathy <- function(
    x,
    y,
    method = "bilinear",
    filename = "",
    overwrite = FALSE
) {
  out <- terra::resample(as_bathy(x, check = TRUE), as_bathy(y, check = TRUE), method = method)
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname crop_bathy
#' @export
project_bathy <- function(
    x,
    crs,
    method = "bilinear",
    filename = "",
    overwrite = FALSE
) {
  out <- terra::project(as_bathy(x, check = TRUE), y = crs, method = method)
  write_raster_if_requested(out, filename, overwrite)
}

#' Smooth a bathymetric or elevation raster
#'
#' @description
#' Applies a square moving-window mean filter.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param window Odd integer focal-window size.
#' @param na.rm Logical. Remove missing values inside the focal window.
#' @param filename Optional output raster path.
#' @param overwrite Logical. Allow overwriting `filename`.
#'
#' @return A `terra::SpatRaster`.
#'
#' @details
#' Smoothing changes local gradients and can strongly affect slope, curvature,
#' rugosity, TPI, and BPI. Use it deliberately and report the window size.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' smooth_bathy(bathy, window = 3)
#'
#' @seealso [prepare_bathy()]
#' @export
smooth_bathy <- function(
    x,
    window = 3,
    na.rm = TRUE,
    filename = "",
    overwrite = FALSE
) {
  window <- as.integer(window)
  if (length(window) != 1 || window < 3 || window %% 2 == 0) {
    bt_abort("`window` must be one odd integer greater than or equal to 3.")
  }
  w <- matrix(1, nrow = window, ncol = window)
  out <- terra::focal(
    as_bathy(x, check = TRUE),
    w = w,
    fun = mean,
    na.rm = na.rm,
    na.policy = "omit"
  )
  write_raster_if_requested(out, filename, overwrite)
}

#' Filter or convert bathymetric depth values
#'
#' @description
#' Keeps raster values within a depth or elevation range, or explicitly changes
#' sign convention.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param depth_range Numeric length-two retained range.
#' @param positive_depth Optional logical. If `TRUE`, filtering is applied to
#'   absolute depth values. If `FALSE` or `NULL`, filtering is applied to the
#'   stored raster values.
#' @param filename Optional output raster path.
#' @param overwrite Logical. Allow overwriting `filename`.
#'
#' @return A `terra::SpatRaster`.
#'
#' @details
#' `depth_filter()` does not flip signs. Use [set_depth_positive()],
#' [set_depth_negative()], or [invert_depth()] for explicit sign changes.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' depth_filter(bathy, c(-80, -30))
#' set_depth_positive(bathy)
#'
#' @seealso [check_bathy_units()]
#' @export
depth_filter <- function(
    x,
    depth_range,
    positive_depth = NULL,
    filename = "",
    overwrite = FALSE
) {
  r <- as_bathy(x, check = TRUE)
  depth_range <- sort(as.numeric(depth_range))
  if (length(depth_range) != 2 || any(!is.finite(depth_range))) {
    bt_abort("`depth_range` must contain two finite numeric values.")
  }
  comp <- if (isTRUE(positive_depth)) abs(r) else r
  out <- terra::ifel(comp >= depth_range[1] & comp <= depth_range[2], r, NA)
  out <- terra::trim(out)
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname depth_filter
#' @export
invert_depth <- function(x, filename = "", overwrite = FALSE) {
  out <- -as_bathy(x, check = TRUE)
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname depth_filter
#' @export
set_depth_positive <- function(x, filename = "", overwrite = FALSE) {
  out <- abs(as_bathy(x, check = TRUE))
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname depth_filter
#' @export
set_depth_negative <- function(x, filename = "", overwrite = FALSE) {
  out <- -abs(as_bathy(x, check = TRUE))
  write_raster_if_requested(out, filename, overwrite)
}
