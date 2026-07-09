#' Derive bathymetric terrain metrics
#'
#' @description
#' Computes one or more terrain metrics from a user-supplied bathymetric or
#' elevation raster.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param metrics Character vector of metrics, or `"default"`.
#' @param scales Optional BPI/TPI window sizes used when multiscale BPI is
#'   requested.
#' @param units Slope and aspect units, `"degrees"` or `"radians"`.
#' @param neighbors Neighborhood passed to `terra::terrain()`.
#' @param positive_depth Optional logical documenting the input sign convention.
#'   Metric values are not sign-flipped unless a specific function says so.
#' @param filename Optional output raster path.
#' @param overwrite Logical. Allow overwriting `filename`.
#' @param progress Logical. Reserved for long-running workflows.
#'
#' @return A `terra::SpatRaster` containing named metric layers.
#'
#' @details
#' Terrain metrics are scale-sensitive. Slope, curvature, rugosity, TPI, BPI,
#' roughness, and surface-area style metrics depend on grid resolution,
#' smoothing, and focal-window size. Use projected coordinate systems when
#' distances or slopes are interpreted in real linear units.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' terrain <- derive_terrain(bathy, metrics = c("slope", "aspect", "bpi"))
#' names(terrain)
#'
#' @seealso [derive_metric_stack()], [derive_bpi()], [metric_catalog()]
#' @export
derive_terrain <- function(
    x,
    metrics = "default",
    scales = NULL,
    units = c("degrees", "radians"),
    neighbors = 8,
    positive_depth = NULL,
    filename = "",
    overwrite = FALSE,
    progress = TRUE
) {
  derive_metric_stack(
    x = x,
    metrics = metrics,
    scales = scales,
    units = units,
    neighbors = neighbors,
    positive_depth = positive_depth,
    filename = filename,
    overwrite = overwrite,
    progress = progress
  )
}

#' Derive individual terrain metrics
#'
#' @description
#' Convenience wrappers around `terra` terrain functions and lightweight
#' geomorphometry formulas.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param units Units for slope or aspect: `"degrees"` or `"radians"`.
#' @param neighbors Neighborhood size passed to `terra::terrain()`.
#' @param angle Illumination angle for hillshade.
#' @param direction Illumination direction for hillshade.
#' @param window Odd integer focal-window size for local metrics.
#' @param filename Optional output raster path.
#' @param overwrite Logical. Allow overwriting `filename`.
#'
#' @return A single-layer `terra::SpatRaster`, except where documented
#' otherwise.
#'
#' @details
#' Functions preserve the input raster sign. For example, slope depends on the
#' magnitude of local gradients, while BPI/TPI interpretation depends on whether
#' the raster stores elevation-like values or positive depth.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' derive_slope(bathy)
#' derive_northness(bathy)
#'
#' @seealso [derive_terrain()], [derive_bpi()]
#' @export
derive_slope <- function(
    x,
    units = c("degrees", "radians"),
    neighbors = 8,
    filename = "",
    overwrite = FALSE
) {
  units <- match.arg(units)
  out <- terra::terrain(first_layer(x), v = "slope", unit = units, neighbors = neighbors)
  names(out) <- if (units == "degrees") "slope_deg" else "slope_rad"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_aspect <- function(
    x,
    units = c("degrees", "radians"),
    neighbors = 8,
    filename = "",
    overwrite = FALSE
) {
  units <- match.arg(units)
  out <- terra::terrain(first_layer(x), v = "aspect", unit = units, neighbors = neighbors)
  names(out) <- if (units == "degrees") "aspect_deg" else "aspect_rad"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_northness <- function(
    x,
    neighbors = 8,
    filename = "",
    overwrite = FALSE
) {
  aspect_rad <- derive_aspect(x, units = "radians", neighbors = neighbors)
  out <- cos(aspect_rad)
  names(out) <- "northness"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_eastness <- function(
    x,
    neighbors = 8,
    filename = "",
    overwrite = FALSE
) {
  aspect_rad <- derive_aspect(x, units = "radians", neighbors = neighbors)
  out <- sin(aspect_rad)
  names(out) <- "eastness"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_hillshade <- function(
    x,
    angle = 45,
    direction = 315,
    neighbors = 8,
    filename = "",
    overwrite = FALSE
) {
  slope <- derive_slope(x, units = "radians", neighbors = neighbors)
  aspect <- derive_aspect(x, units = "radians", neighbors = neighbors)
  out <- terra::shade(slope, aspect, angle = angle, direction = direction)
  if (terra::nlyr(out) > 1) {
    out <- mean(out)
  }
  names(out) <- "hillshade"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_roughness <- function(x, filename = "", overwrite = FALSE) {
  out <- terra::terrain(first_layer(x), v = "roughness")
  names(out) <- "roughness"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_tri <- function(x, filename = "", overwrite = FALSE) {
  out <- terra::terrain(first_layer(x), v = "TRI")
  names(out) <- "tri"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_tpi <- function(x, filename = "", overwrite = FALSE) {
  out <- terra::terrain(first_layer(x), v = "TPI")
  names(out) <- "tpi"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_rugosity <- function(
    x,
    window = 3,
    neighbors = 8,
    filename = "",
    overwrite = FALSE
) {
  window <- as.integer(window)
  if (length(window) != 1 || window < 3 || window %% 2 == 0) {
    bt_abort("`window` must be one odd integer greater than or equal to 3.")
  }
  slope <- derive_slope(x, units = "radians", neighbors = neighbors)
  aspect <- derive_aspect(x, units = "radians", neighbors = neighbors)
  dx <- sin(slope) * cos(aspect)
  dy <- sin(slope) * sin(aspect)
  dz <- cos(slope)
  w <- matrix(1, nrow = window, ncol = window)
  mdx <- terra::focal(dx, w = w, fun = mean, na.rm = TRUE, na.policy = "omit")
  mdy <- terra::focal(dy, w = w, fun = mean, na.rm = TRUE, na.policy = "omit")
  mdz <- terra::focal(dz, w = w, fun = mean, na.rm = TRUE, na.policy = "omit")
  out <- 1 - sqrt(mdx^2 + mdy^2 + mdz^2)
  out <- terra::clamp(out, lower = 0, upper = 1, values = TRUE)
  names(out) <- paste0("rugosity_vrm_", window, "x", window)
  write_raster_if_requested(out, filename, overwrite)
}

#' Derive bathymetric position index
#'
#' @description
#' Computes a local bathymetric position index from the difference between each
#' cell and its focal-neighborhood mean.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param inner_radius Optional inner radius for an annulus window in map units.
#' @param outer_radius Optional outer radius for an annulus window in map units.
#' @param window Optional odd integer square window size in cells.
#' @param scale Preset scale when `window` and `outer_radius` are not supplied.
#' @param normalize Logical. If `TRUE`, divide BPI by local focal standard
#'   deviation.
#' @param filename Optional output raster path.
#' @param overwrite Logical. Allow overwriting `filename`.
#' @param ... Reserved for future extensions.
#'
#' @return A single-layer `terra::SpatRaster`.
#'
#' @details
#' The calculation is `cell value - focal mean`. Positive values therefore mean
#' higher-than-neighborhood values when the raster is elevation-like. For
#' positive-depth rasters, interpretation is reversed unless users convert the
#' sign convention first.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' derive_bpi(bathy, window = 5)
#'
#' @seealso [derive_multiscale_bpi()], [derive_tpi()]
#' @export
derive_bpi <- function(
    x,
    inner_radius = NULL,
    outer_radius = NULL,
    window = NULL,
    scale = c("fine", "broad", "custom"),
    normalize = FALSE,
    filename = "",
    overwrite = FALSE,
    ...
) {
  r <- first_layer(x)
  scale <- match.arg(scale)
  w <- bpi_window(r, inner_radius, outer_radius, window, scale)
  focal_mean <- terra::focal(r, w = w, fun = mean, na.rm = TRUE, na.policy = "omit")
  out <- r - focal_mean
  if (isTRUE(normalize)) {
    focal_sd <- terra::focal(r, w = w, fun = stats::sd, na.rm = TRUE, na.policy = "omit")
    out <- out / focal_sd
  }
  suffix <- if (!is.null(window)) {
    paste0(window, "x", window)
  } else if (!is.null(outer_radius)) {
    paste0("r", outer_radius)
  } else {
    scale
  }
  names(out) <- paste0("bpi_", clean_layer_name(suffix))
  write_raster_if_requested(out, filename, overwrite)
}

bpi_window <- function(r, inner_radius, outer_radius, window, scale) {
  if (!is.null(window)) {
    window <- as.integer(window)
    if (length(window) != 1 || window < 3 || window %% 2 == 0) {
      bt_abort("`window` must be one odd integer greater than or equal to 3.")
    }
    return(matrix(1, nrow = window, ncol = window))
  }
  if (!is.null(outer_radius)) {
    outer_radius <- as.numeric(outer_radius)
    inner_radius <- if (is.null(inner_radius)) 0 else as.numeric(inner_radius)
    if (length(outer_radius) != 1 || outer_radius <= 0 || !is.finite(outer_radius)) {
      bt_abort("`outer_radius` must be one positive finite value.")
    }
    if (length(inner_radius) != 1 || inner_radius < 0 || !is.finite(inner_radius)) {
      bt_abort("`inner_radius` must be one non-negative finite value.")
    }
    cell <- min(terra::res(r))
    n <- ceiling(outer_radius / cell)
    n <- max(1, n)
    axis <- seq(-n, n)
    d <- sqrt(outer(axis * cell, axis * cell, function(a, b) a^2 + b^2))
    w <- ifelse(d <= outer_radius & d >= inner_radius, 1, NA)
    if (all(is.na(w))) {
      bt_abort("BPI annulus does not include any cells.")
    }
    return(w)
  }
  if (scale == "fine") {
    return(matrix(1, nrow = 3, ncol = 3))
  }
  if (scale == "broad") {
    return(matrix(1, nrow = 11, ncol = 11))
  }
  bt_abort("For `scale = 'custom'`, supply `window` or `outer_radius`.")
}

#' @rdname derive_bpi
#' @param windows Integer vector of odd square window sizes.
#' @export
derive_multiscale_bpi <- function(
    x,
    windows = c(3, 11),
    normalize = FALSE,
    filename = "",
    overwrite = FALSE,
    ...
) {
  layers <- lapply(windows, function(w) derive_bpi(x, window = w, normalize = normalize))
  out <- do.call(c, layers)
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_curvature <- function(x, filename = "", overwrite = FALSE) {
  kernel <- matrix(c(0, 1, 0, 1, -4, 1, 0, 1, 0), nrow = 3, byrow = TRUE)
  out <- terra::focal(first_layer(x), w = kernel, fun = sum, na.policy = "omit")
  names(out) <- "curvature"
  write_raster_if_requested(out, filename, overwrite)
}

#' @rdname derive_slope
#' @export
derive_surface_area_ratio <- function(
    x,
    neighbors = 8,
    filename = "",
    overwrite = FALSE
) {
  slope <- derive_slope(x, units = "radians", neighbors = neighbors)
  out <- 1 / cos(slope)
  names(out) <- "surface_area_ratio"
  write_raster_if_requested(out, filename, overwrite)
}

#' Build a stack of terrain metrics
#'
#' @description
#' Computes selected metrics and returns them as a named raster stack.
#'
#' @inheritParams derive_terrain
#'
#' @return A `terra::SpatRaster`.
#'
#' @details
#' `"default"` currently expands to bathymetry, slope, aspect, northness,
#' eastness, hillshade, roughness, TRI, TPI, fine BPI, broad BPI, curvature, and
#' surface-area ratio. All metrics are derived locally from the supplied raster.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' derive_metric_stack(bathy, metrics = "default")
#'
#' @seealso [derive_terrain()]
#' @export
derive_metric_stack <- function(
    x,
    metrics = "default",
    scales = NULL,
    units = c("degrees", "radians"),
    neighbors = 8,
    positive_depth = NULL,
    filename = "",
    overwrite = FALSE,
    progress = TRUE
) {
  r <- first_layer(x)
  units <- match.arg(units)
  if (identical(metrics, "default")) {
    metrics <- c(
      "bathy", "slope", "aspect", "northness", "eastness", "hillshade",
      "roughness", "tri", "tpi", "bpi", "curvature", "surface_area_ratio"
    )
  }
  allowed <- c(
    "bathy", "slope", "aspect", "northness", "eastness", "hillshade",
    "rugosity", "roughness", "tri", "tpi", "bpi", "multiscale_bpi",
    "curvature", "surface_area_ratio"
  )
  bad <- setdiff(metrics, allowed)
  if (length(bad) > 0) {
    bt_abort(paste0("Unknown terrain metric: ", paste(bad, collapse = ", ")))
  }
  layers <- list()
  for (metric in metrics) {
    layer <- switch(
      metric,
      bathy = set_clean_names(r, "bathy"),
      slope = derive_slope(r, units = units, neighbors = neighbors),
      aspect = derive_aspect(r, units = units, neighbors = neighbors),
      northness = derive_northness(r, neighbors = neighbors),
      eastness = derive_eastness(r, neighbors = neighbors),
      hillshade = derive_hillshade(r, neighbors = neighbors),
      rugosity = derive_rugosity(r, neighbors = neighbors),
      roughness = derive_roughness(r),
      tri = derive_tri(r),
      tpi = derive_tpi(r),
      bpi = {
        wins <- if (is.null(scales)) c(3, 11) else scales
        derive_multiscale_bpi(r, windows = wins)
      },
      multiscale_bpi = {
        wins <- if (is.null(scales)) c(3, 11) else scales
        derive_multiscale_bpi(r, windows = wins)
      },
      curvature = derive_curvature(r),
      surface_area_ratio = derive_surface_area_ratio(r, neighbors = neighbors)
    )
    layers[[metric]] <- layer
  }
  out <- do.call(c, layers)
  names(out) <- clean_layer_name(names(out))
  write_raster_if_requested(out, filename, overwrite)
}
