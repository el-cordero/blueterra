#' Summarize terrain metrics by polygon zones
#'
#' @description
#' Computes summary statistics for raster metrics inside polygons, buffers, or
#' corridor features.
#'
#' @param metrics A metric raster stack.
#' @param zones Polygon zones as `sf`, `terra::SpatVector`, or a local vector
#'   path.
#' @param fun Summary functions. Supported values are `"mean"`, `"sd"`,
#'   `"min"`, `"max"`, `"median"`, `"sum"`, and `"count"`.
#' @param na.rm Logical. Remove missing values before summarizing.
#' @param exact Logical. If `TRUE`, use `exactextractr` for extraction. The
#'   optional package must be installed.
#' @param ... Additional arguments passed to extraction functions.
#'
#' @return A tibble with zone identifiers, zone attributes, and wide summary
#'   columns named `metric_function`.
#'
#' @details
#' `summarize_terrain()` does not assume specific zones, depth ranges, or
#' ecological labels. For distance-sensitive summaries, use zones and rasters in
#' a projected CRS.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
#' zones <- terra::vect(blueterra_example("zones"))
#' summarize_terrain(terrain, zones)
#'
#' @seealso [summarize_depth_bands()], [extract_terrain_points()]
#' @export
summarize_terrain <- function(
    metrics,
    zones,
    fun = c("mean", "sd", "min", "max", "median"),
    na.rm = TRUE,
    exact = FALSE,
    ...
) {
  r <- as_bathy(metrics, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  fun <- safe_summary_funs(fun)
  if (isTRUE(exact)) {
    return(summarize_terrain_exact(r, zones, fun = fun, na.rm = na.rm, ...))
  }
  z <- as_spatvector(zones)
  if (!terra::same.crs(r, z)) {
    z <- terra::project(z, terra::crs(r))
  }
  values <- terra::extract(r, z, ID = TRUE, ...)
  attrs <- as.data.frame(z)
  attrs$zone_id <- seq_len(nrow(attrs))
  pieces <- split(values, values$ID)
  rows <- lapply(seq_along(pieces), function(id) {
    vals <- pieces[[id]]
    summarize_zone_values(vals, id = as.integer(id), attrs = attrs, fun = fun, na.rm = na.rm)
  })
  tibble::as_tibble(do.call(rbind, rows))
}

summarize_terrain_exact <- function(r, zones, fun, na.rm, ...) {
  check_installed("exactextractr", "for `exact = TRUE` summaries")
  check_installed("sf", "for `exact = TRUE` summaries")
  zsf <- as_sf_object(zones)
  if (!terra::same.crs(r, terra::vect(zsf))) {
    zsf <- sf::st_transform(zsf, terra::crs(r))
  }
  extracted <- exactextractr::exact_extract(r, zsf, progress = FALSE, ...)
  attrs <- sf::st_drop_geometry(zsf)
  attrs$zone_id <- seq_len(nrow(attrs))
  rows <- lapply(seq_along(extracted), function(id) {
    vals <- extracted[[id]]
    summarize_zone_values(vals, id = id, attrs = attrs, fun = fun, na.rm = na.rm)
  })
  tibble::as_tibble(do.call(rbind, rows))
}

summarize_zone_values <- function(vals, id, attrs, fun, na.rm) {
  metric_cols <- intersect(names(vals), names(vals)[vapply(vals, is.numeric, logical(1))])
  metric_cols <- setdiff(metric_cols, c("ID", "coverage_fraction"))
  attr_row <- attrs[attrs$zone_id == id, , drop = FALSE]
  out <- as.list(attr_row[1, , drop = FALSE])
  for (metric in metric_cols) {
    for (f in fun) {
      out[[paste(metric, f, sep = "_")]] <- apply_summary_fun(vals[[metric]], f, na.rm = na.rm)
    }
  }
  as.data.frame(out, check.names = FALSE)
}

#' @rdname summarize_terrain
#' @export
summarize_terrain_by_zone <- function(
    metrics,
    zones,
    fun = c("mean", "sd", "min", "max", "median"),
    na.rm = TRUE,
    exact = FALSE,
    ...
) {
  summarize_terrain(
    metrics = metrics,
    zones = zones,
    fun = fun,
    na.rm = na.rm,
    exact = exact,
    ...
  )
}

#' Summarize terrain by depth bands
#'
#' @description
#' Groups raster cells into depth or elevation bands and summarizes metric
#' values within each band.
#'
#' @param bathy A bathymetric or elevation raster.
#' @param metrics Optional metric raster stack. If `NULL`, `bathy` is summarized.
#' @param breaks Numeric band breaks.
#' @param positive_depth Optional logical. If `TRUE`, bands are applied to
#'   absolute depth. If `FALSE` or `NULL`, bands are applied to stored values.
#' @param fun Summary functions.
#' @param na.rm Logical. Remove missing values.
#'
#' @return A tibble with one row per depth band and metric.
#'
#' @details
#' Depth bands are sensitive to vertical sign convention. For negative-elevation
#' bathymetry, use negative breaks or set `positive_depth = TRUE` with positive
#' depth breaks.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' summarize_depth_bands(bathy, breaks = c(-90, -60, -30, 0))
#'
#' @seealso [depth_filter()], [summarize_terrain()]
#' @export
summarize_depth_bands <- function(
    bathy,
    metrics = NULL,
    breaks,
    positive_depth = NULL,
    fun = c("mean", "sd", "min", "max", "median"),
    na.rm = TRUE
) {
  b <- first_layer(bathy)
  m <- if (is.null(metrics)) b else as_bathy(metrics, check = FALSE)
  validate_bathy(m, allow_multi = TRUE)
  if (!terra::compareGeom(b, m, stopOnError = FALSE)) {
    bt_abort("`bathy` and `metrics` must have matching geometry.")
  }
  breaks <- sort(as.numeric(breaks))
  if (length(breaks) < 2 || any(!is.finite(breaks))) {
    bt_abort("`breaks` must contain at least two finite numeric values.")
  }
  depth_values <- terra::values(if (isTRUE(positive_depth)) abs(b) else b, mat = FALSE)
  band <- cut(depth_values, breaks = breaks, include.lowest = TRUE, right = FALSE)
  vals <- terra::values(m, mat = TRUE)
  fun <- safe_summary_funs(fun)
  rows <- list()
  k <- 1
  for (band_level in levels(band)) {
    idx <- which(band == band_level)
    for (metric in colnames(vals)) {
      row <- list(depth_band = band_level, metric = metric, n_cells = length(idx))
      for (f in fun) {
        row[[f]] <- apply_summary_fun(vals[idx, metric], f, na.rm = na.rm)
      }
      rows[[k]] <- as.data.frame(row, check.names = FALSE)
      k <- k + 1
    }
  }
  tibble::as_tibble(do.call(rbind, rows))
}

#' Extract terrain values at points
#'
#' @description
#' Extracts raster values at point locations.
#'
#' @param metrics A metric raster stack.
#' @param points Points as `sf`, `terra::SpatVector`, or a local vector path.
#' @param method Extraction method passed to `terra::extract()`.
#' @param ... Additional arguments passed to `terra::extract()`.
#'
#' @return A tibble with point attributes and raster values.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' zones <- terra::vect(blueterra_example("zones"))
#' pts <- terra::centroids(zones)
#' extract_terrain_points(bathy, pts)
#'
#' @seealso [sample_terrain_cells()]
#' @export
extract_terrain_points <- function(metrics, points, method = "bilinear", ...) {
  r <- as_bathy(metrics, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  pts <- as_spatvector(points)
  if (!terra::same.crs(r, pts)) {
    pts <- terra::project(pts, terra::crs(r))
  }
  vals <- terra::extract(r, pts, ID = FALSE, method = method, ...)
  attrs <- as.data.frame(pts)
  tibble::as_tibble(cbind(attrs, vals))
}

#' Sample terrain raster cells
#'
#' @description
#' Draws random or regular samples from raster cells and returns a table.
#'
#' @param metrics A metric raster stack.
#' @param size Number of cells to sample.
#' @param method Sampling method, `"random"` or `"regular"`.
#' @param na.rm Logical. Omit rows with missing values.
#' @param xy Logical. Include cell coordinates.
#'
#' @return A tibble of sampled cell values.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' sample_terrain_cells(bathy, size = 10)
#'
#' @seealso [extract_terrain_points()], [prepare_model_matrix()]
#' @export
sample_terrain_cells <- function(
    metrics,
    size,
    method = c("random", "regular"),
    na.rm = TRUE,
    xy = TRUE
) {
  method <- match.arg(method)
  r <- as_bathy(metrics, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  if (!is.numeric(size) || length(size) != 1 || size <= 0) {
    bt_abort("`size` must be one positive numeric value.")
  }
  out <- terra::spatSample(
    r,
    size = as.integer(size),
    method = method,
    na.rm = na.rm,
    xy = xy,
    as.df = TRUE
  )
  tibble::as_tibble(out)
}
