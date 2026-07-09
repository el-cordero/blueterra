#' Extract isobaths from a raster
#'
#' @description
#' Converts raster contour levels to line features.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param depths Numeric contour levels.
#' @param positive_depth Optional logical. If `TRUE`, `depths` are converted to
#'   positive values. If `FALSE`, they are converted to negative values. If
#'   `NULL`, `depths` are used exactly as supplied.
#' @param as Output type: `"sf"` or `"SpatVector"`.
#' @param ... Additional arguments reserved for future extensions.
#'
#' @return Isobath line features as `sf` or `terra::SpatVector`.
#'
#' @details
#' Depth convention is explicit. For rasters stored as negative elevation,
#' either pass negative `depths` or set `positive_depth = FALSE` when passing
#' positive depth labels.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' extract_isobaths(bathy, depths = c(-40, -60))
#'
#' @seealso [make_isobath_corridors()]
#' @export
extract_isobaths <- function(
    x,
    depths,
    positive_depth = NULL,
    as = c("sf", "SpatVector"),
    ...
) {
  as <- match.arg(as)
  r <- first_layer(x)
  depths <- as.numeric(depths)
  if (length(depths) < 1 || any(!is.finite(depths))) {
    bt_abort("`depths` must contain finite numeric contour levels.")
  }
  levels <- depths
  if (isTRUE(positive_depth)) {
    levels <- abs(depths)
  } else if (identical(positive_depth, FALSE)) {
    levels <- -abs(depths)
  }
  contours <- terra::as.contour(r, levels = levels)
  if (is.null(contours) || nrow(contours) == 0) {
    bt_abort("No isobaths were created for the supplied depths.")
  }
  out <- sf::st_as_sf(contours)
  value_col <- intersect(c("level", "value", "z"), names(out))[1]
  if (is.na(value_col)) {
    out$level <- rep(levels, length.out = nrow(out))
    value_col <- "level"
  }
  out$contour_value <- as.numeric(out[[value_col]])
  out$depth_label <- depths[match(out$contour_value, levels)]
  out$depth_label[is.na(out$depth_label)] <- out$contour_value[is.na(out$depth_label)]
  out <- out[sf::st_geometry_type(out) %in% c("LINESTRING", "MULTILINESTRING"), ]
  if (as == "SpatVector") {
    return(terra::vect(out))
  }
  out
}

#' Build isobath corridors
#'
#' @description
#' Buffers isobath contour lines to create depth-following corridor polygons.
#'
#' @inheritParams extract_isobaths
#' @param width Buffer width in map units.
#' @param smooth Logical. If `TRUE`, apply a zero-width buffer after buffering
#'   to clean polygon topology.
#'
#' @return Isobath corridor polygons as `sf` or `terra::SpatVector`.
#'
#' @details
#' `width` is interpreted in the CRS map units. Projected CRS are strongly
#' recommended. If the raster uses longitude/latitude, the function warns before
#' buffering because distance interpretation may be misleading.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' make_isobath_corridors(bathy, depths = c(-40, -60), width = 20)
#'
#' @seealso [extract_isobaths()], [summarize_isobath_terrain()]
#' @export
make_isobath_corridors <- function(
    x,
    depths,
    width,
    smooth = FALSE,
    as = c("sf", "SpatVector"),
    positive_depth = NULL,
    ...
) {
  as <- match.arg(as)
  r <- first_layer(x)
  if (!is.numeric(width) || length(width) != 1 || width <= 0) {
    bt_abort("`width` must be one positive numeric value in map units.")
  }
  if (!nzchar(terra::crs(r))) {
    bt_abort("Raster CRS is required before creating isobath corridors.")
  }
  if (is_lonlat(r)) {
    bt_warn("Raster CRS is longitude/latitude; corridor width may be misleading.")
  }
  lines <- extract_isobaths(
    r,
    depths = depths,
    positive_depth = positive_depth,
    as = "sf"
  )
  corridors <- suppressWarnings(sf::st_buffer(lines, dist = width))
  if (isTRUE(smooth)) {
    corridors <- sf::st_buffer(corridors, dist = 0)
  }
  corridors$corridor_id <- seq_len(nrow(corridors))
  if (as == "SpatVector") {
    return(terra::vect(corridors))
  }
  corridors
}

#' Extract terrain cells in isobath corridors
#'
#' @description
#' Extracts raster cell values under corridor polygons.
#'
#' @param metrics A metric raster stack.
#' @param corridors Corridor polygons from [make_isobath_corridors()] or another
#'   polygon source.
#' @param ... Additional arguments passed to `terra::extract()`.
#'
#' @return A tibble with corridor identifiers and extracted raster values.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
#' corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
#' extract_isobath_corridors(terrain, corridors)
#'
#' @seealso [summarize_isobath_terrain()], [summarize_terrain()]
#' @export
extract_isobath_corridors <- function(metrics, corridors, ...) {
  r <- as_bathy(metrics, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  zones <- as_spatvector(corridors)
  if (!terra::same.crs(r, zones)) {
    zones <- terra::project(zones, terra::crs(r))
  }
  vals <- terra::extract(r, zones, ID = TRUE, ...)
  attrs <- as.data.frame(zones)
  attrs$ID <- seq_len(nrow(attrs))
  out <- merge(attrs, vals, by = "ID", all.y = TRUE)
  tibble::as_tibble(out)
}

#' Summarize terrain by isobath corridor
#'
#' @description
#' Computes summary statistics for metric rasters inside corridor polygons.
#'
#' @param metrics A metric raster stack.
#' @param corridors Corridor polygons.
#' @param fun Summary functions.
#' @param na.rm Logical. Remove missing values.
#' @param exact Logical. Use `exactextractr` when available.
#' @param ... Additional arguments passed to [summarize_terrain()].
#'
#' @return A tibble with one row per corridor.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
#' corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
#' summarize_isobath_terrain(terrain, corridors)
#'
#' @seealso [make_isobath_corridors()], [summarize_terrain()]
#' @export
summarize_isobath_terrain <- function(
    metrics,
    corridors,
    fun = c("mean", "sd", "min", "max", "median"),
    na.rm = TRUE,
    exact = FALSE,
    ...
) {
  summarize_terrain(
    metrics = metrics,
    zones = corridors,
    fun = fun,
    na.rm = na.rm,
    exact = exact,
    ...
  )
}

#' Plot isobath corridors
#'
#' @description
#' Plots corridor polygons, optionally over a raster background.
#'
#' @param corridors Corridor polygons.
#' @param bathy Optional raster background.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
#' plot_isobath_corridors(corridors, bathy)
#'
#' @seealso [make_isobath_corridors()]
#' @export
plot_isobath_corridors <- function(corridors, bathy = NULL) {
  optional_ggplot2()
  corridor_sf <- as_sf_object(corridors)
  p <- ggplot2::ggplot()
  if (!is.null(bathy)) {
    df <- raster_plot_data(bathy)
    value_col <- setdiff(names(df), c("x", "y"))[1]
    p <- p +
      ggplot2::geom_raster(
        data = df,
        ggplot2::aes(x = .data[["x"]], y = .data[["y"]], fill = .data[[value_col]])
      ) +
      ggplot2::scale_fill_viridis_c(option = "C", na.value = NA)
  }
  p +
    ggplot2::geom_sf(data = corridor_sf, fill = NA, color = "white") +
    ggplot2::labs(x = NULL, y = NULL)
}
