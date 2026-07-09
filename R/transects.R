#' Create transects across polygon zones
#'
#' @description
#' Builds regularly spaced straight transects through polygon features.
#'
#' @param area An `sf` polygon object, `terra::SpatVector`, or local vector path.
#' @param spacing Distance between transects in map units.
#' @param angle Transect direction in degrees counterclockwise from the x axis.
#' @param length Optional transect length in map units. If `NULL`, a length based
#'   on the polygon bounding box is used.
#' @param id_field Optional field in `area` used as the zone identifier.
#' @param as Output type: `"sf"` or `"SpatVector"`.
#'
#' @return An `sf` object or `terra::SpatVector` of line transects.
#'
#' @details
#' Transect spacing and length are interpreted in map units. Use a projected CRS
#' for metric distances. The function creates candidate lines through each
#' polygon bounding box and clips them to the polygon.
#'
#' @examples
#' sites <- sf::st_read(blueterra_example("sites"), quiet = TRUE)
#' transects <- make_transects(sites[1, ], spacing = 50)
#' transects
#'
#' @seealso [sample_transects()], [extract_cross_sections()]
#' @export
make_transects <- function(
    area,
    spacing,
    angle = 0,
    length = NULL,
    id_field = NULL,
    as = c("sf", "SpatVector")
) {
  as <- match.arg(as)
  area_sf <- as_sf_object(area)
  if (is.na(sf::st_crs(area_sf))) {
    bt_abort("`area` must have a CRS for distance-based transect spacing.")
  }
  if (sf::st_is_longlat(area_sf)) {
    bt_abort("`area` must use a projected CRS for distance-based transect spacing.")
  }
  if (!is.numeric(spacing) || length(spacing) != 1 || spacing <= 0) {
    bt_abort("`spacing` must be one positive numeric value.")
  }
  if (!is.null(id_field) && !id_field %in% names(area_sf)) {
    bt_abort("`id_field` was not found in `area`.")
  }
  out <- vector("list", nrow(area_sf))
  for (i in seq_len(nrow(area_sf))) {
    out[[i]] <- transects_for_polygon(
      area_sf[i, ],
      spacing = spacing,
      angle = angle,
      length = length,
      zone_id = if (is.null(id_field)) i else as.character(area_sf[[id_field]][i])
    )
  }
  out <- do.call(rbind, out)
  row.names(out) <- NULL
  if (as == "SpatVector") {
    return(terra::vect(out))
  }
  out
}

transects_for_polygon <- function(poly, spacing, angle, length, zone_id) {
  bbox <- sf::st_bbox(poly)
  cx <- mean(c(bbox[["xmin"]], bbox[["xmax"]]))
  cy <- mean(c(bbox[["ymin"]], bbox[["ymax"]]))
  diag_len <- sqrt((bbox[["xmax"]] - bbox[["xmin"]])^2 + (bbox[["ymax"]] - bbox[["ymin"]])^2)
  line_len <- if (is.null(length)) diag_len * 1.5 else as.numeric(length)
  if (!is.finite(line_len) || line_len <= 0) {
    bt_abort("`length` must be one positive numeric value.")
  }
  theta <- angle * pi / 180
  along <- c(cos(theta), sin(theta))
  normal <- c(-sin(theta), cos(theta))
  offsets <- seq(-diag_len, diag_len, by = spacing)
  lines <- vector("list", length(offsets))
  for (j in seq_along(offsets)) {
    mid <- c(cx, cy) + offsets[j] * normal
    p1 <- mid - along * line_len / 2
    p2 <- mid + along * line_len / 2
    lines[[j]] <- sf::st_linestring(rbind(p1, p2))
  }
  line_sf <- sf::st_sf(
    zone_id = zone_id,
    transect_id = seq_along(lines),
    offset = offsets,
    geometry = sf::st_sfc(lines, crs = sf::st_crs(poly))
  )
  clipped <- suppressWarnings(sf::st_intersection(line_sf, sf::st_geometry(poly)))
  clipped <- clipped[!sf::st_is_empty(clipped), , drop = FALSE]
  clipped <- sf::st_collection_extract(clipped, "LINESTRING", warn = FALSE)
  if (nrow(clipped) == 0) {
    bt_abort("No transects intersected the supplied polygon.")
  }
  clipped$transect_id <- paste0(clipped$zone_id, "_", seq_len(nrow(clipped)))
  clipped
}

#' Sample rasters along transects
#'
#' @description
#' Extracts raster values along transect lines at regular distances.
#'
#' @param transects Line geometry from [make_transects()] or another source.
#' @param x A raster-like object accepted by [as_bathy()].
#' @param spacing Optional sample spacing in map units.
#' @param n Optional number of sample points per transect.
#' @param method Extraction method passed to `terra::extract()`.
#'
#' @return A tibble with transect identifiers, distances, coordinates, and
#'   raster values.
#'
#' @details
#' If `spacing` and `n` are both `NULL`, twenty points are sampled per transect.
#' Distances are measured from the first line vertex and are in map units.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' sites <- sf::st_read(blueterra_example("sites"), quiet = TRUE)
#' transects <- make_transects(sites[1, ], spacing = 100)
#' sample_transects(transects, bathy, n = 5)
#'
#' @seealso [make_transects()], [summarize_cross_sections()]
#' @export
sample_transects <- function(
    transects,
    x,
    spacing = NULL,
    n = NULL,
    method = "bilinear"
) {
  lines <- as_sf_object(transects)
  r <- as_bathy(x, check = TRUE)
  if (!terra::same.crs(r, terra::vect(lines))) {
    lines <- sf::st_transform(lines, terra::crs(r))
  }
  if (is.null(lines$transect_id)) {
    lines$transect_id <- seq_len(nrow(lines))
  }
  samples <- vector("list", nrow(lines))
  for (i in seq_len(nrow(lines))) {
    samples[[i]] <- sample_one_transect(lines[i, ], r, spacing, n, method)
  }
  dplyr::bind_rows(samples)
}

sample_one_transect <- function(line, r, spacing, n, method) {
  line_len <- as.numeric(sf::st_length(line))
  if (!is.finite(line_len) || line_len <= 0) {
    return(tibble::tibble())
  }
  if (is.null(n)) {
    n <- if (is.null(spacing)) 20 else floor(line_len / spacing) + 1
  }
  n <- max(2, as.integer(n))
  mp <- sf::st_line_sample(sf::st_geometry(line), n = n, type = "regular")
  pts <- sf::st_cast(mp, "POINT", warn = FALSE)
  pts_sf <- sf::st_sf(
    transect_id = as.character(line$transect_id[[1]]),
    distance = seq(0, line_len, length.out = length(pts)),
    geometry = pts,
    crs = sf::st_crs(line)
  )
  vals <- terra::extract(r, terra::vect(pts_sf), method = method, ID = FALSE)
  coords <- sf::st_coordinates(pts_sf)
  tibble::as_tibble(cbind(
    sf::st_drop_geometry(pts_sf),
    x = coords[, "X"],
    y = coords[, "Y"],
    vals
  ))
}

#' @rdname sample_transects
#' @export
extract_cross_sections <- function(
    transects,
    x,
    spacing = NULL,
    n = NULL,
    method = "bilinear"
) {
  sample_transects(
    transects = transects,
    x = x,
    spacing = spacing,
    n = n,
    method = method
  )
}

#' Summarize sampled cross-sections
#'
#' @description
#' Summarizes raster values sampled along transects.
#'
#' @param samples Output from [sample_transects()] or [extract_cross_sections()].
#' @param value_col Optional value column. Defaults to the first numeric column
#'   that is not an identifier or coordinate.
#' @param group_col Column used to group cross-section samples.
#' @param fun Summary functions.
#' @param na.rm Logical. Remove missing values.
#'
#' @return A tibble with one row per group.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' sites <- sf::st_read(blueterra_example("sites"), quiet = TRUE)
#' transects <- make_transects(sites[1, ], spacing = 100)
#' samples <- sample_transects(transects, bathy, n = 5)
#' summarize_cross_sections(samples)
#'
#' @seealso [sample_transects()]
#' @export
summarize_cross_sections <- function(
    samples,
    value_col = NULL,
    group_col = "transect_id",
    fun = c("mean", "sd", "min", "max", "median"),
    na.rm = TRUE
) {
  if (!is.data.frame(samples)) {
    bt_abort("`samples` must be a data frame.")
  }
  if (!group_col %in% names(samples)) {
    bt_abort("`group_col` was not found in `samples`.")
  }
  if (is.null(value_col)) {
    numeric_cols <- names(samples)[vapply(samples, is.numeric, logical(1))]
    value_col <- setdiff(numeric_cols, c("distance", "x", "y"))[1]
  }
  if (is.na(value_col) || !value_col %in% names(samples)) {
    bt_abort("Could not identify a numeric value column.")
  }
  fun <- safe_summary_funs(fun)
  pieces <- split(samples[[value_col]], samples[[group_col]])
  rows <- lapply(names(pieces), function(id) {
    stats <- vapply(pieces[[id]], function(z) z, numeric(1))
    out <- lapply(fun, function(f) apply_summary_fun(stats, f, na.rm = na.rm))
    names(out) <- paste(value_col, fun, sep = "_")
    data.frame(transect_id = id, out, check.names = FALSE)
  })
  tibble::as_tibble(do.call(rbind, rows))
}

#' Plot sampled cross-sections
#'
#' @description
#' Plots raster values against transect distance.
#'
#' @param samples Output from [sample_transects()].
#' @param value_col Optional value column.
#' @param group_col Grouping column for transect lines.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' sites <- sf::st_read(blueterra_example("sites"), quiet = TRUE)
#' transects <- make_transects(sites[1, ], spacing = 100)
#' samples <- sample_transects(transects, bathy, n = 5)
#' plot_cross_sections(samples)
#'
#' @seealso [sample_transects()], [plot_depth_profile()]
#' @export
plot_cross_sections <- function(
    samples,
    value_col = NULL,
    group_col = "transect_id"
) {
  optional_ggplot2()
  if (is.null(value_col)) {
    numeric_cols <- names(samples)[vapply(samples, is.numeric, logical(1))]
    value_col <- setdiff(numeric_cols, c("distance", "x", "y"))[1]
  }
  ggplot2::ggplot(
    samples,
    ggplot2::aes(x = .data[["distance"]], y = .data[[value_col]], group = .data[[group_col]])
  ) +
    ggplot2::geom_line(alpha = 0.6) +
    ggplot2::labs(x = "Distance", y = value_col)
}
