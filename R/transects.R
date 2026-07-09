#' Create transects across polygon zones
#'
#' @description
#' Builds regularly spaced straight transects through polygon features.
#'
#' @param area A `terra::SpatVector`, local vector path, or optional `sf`
#'   polygon object.
#' @param spacing Distance between transects in map units.
#' @param angle Transect direction in degrees counterclockwise from the x axis.
#' @param length Optional transect length in map units. If `NULL`, a length based
#'   on the polygon bounding box is used.
#' @param id_field Optional field in `area` used as the zone identifier.
#' @param as Output type: `"SpatVector"` or `"sf"`.
#'
#' @return A `terra::SpatVector` by default. If `as = "sf"`, an `sf` object is
#'   returned and the optional `sf` package must be installed.
#'
#' @details
#' Transect spacing and length are interpreted in map units. Use a projected CRS
#' for metric distances. Candidate lines are generated through each polygon
#' bounding box and clipped to the polygon with `terra::intersect()`.
#'
#' @examples
#' zones <- terra::vect(blueterra_example("zones"))
#' transects <- make_transects(zones[1, ], spacing = 50)
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
    as = c("SpatVector", "sf")
) {
  as <- match.arg(as)
  zones <- as_spatvector(area)
  require_projected(zones, operation = "transect spacing")
  if (!is.numeric(spacing) || length(spacing) != 1 || spacing <= 0) {
    bt_abort("`spacing` must be one positive numeric value.")
  }
  if (!is.null(id_field) && !id_field %in% names(zones)) {
    bt_abort("`id_field` was not found in `area`.")
  }
  out <- vector("list", nrow(zones))
  for (i in seq_len(nrow(zones))) {
    zone_id <- if (is.null(id_field)) i else as.character(zones[[id_field]][i, 1])
    out[[i]] <- transects_for_zone(
      zones[i, ],
      spacing = spacing,
      angle = angle,
      length = length,
      zone_id = zone_id
    )
  }
  out <- do.call(rbind, out)
  out$transect_id <- paste0(out$zone_id, "_", seq_len(nrow(out)))
  if (as == "sf") {
    check_installed("sf", "to return sf objects")
    return(sf::st_as_sf(out))
  }
  out
}

transects_for_zone <- function(zone, spacing, angle, length, zone_id) {
  bbox <- terra::ext(zone)
  cx <- mean(c(bbox[1], bbox[2]))
  cy <- mean(c(bbox[3], bbox[4]))
  diag_len <- sqrt((bbox[2] - bbox[1])^2 + (bbox[4] - bbox[3])^2)
  line_len <- if (is.null(length)) diag_len * 1.5 else as.numeric(length)
  if (!is.finite(line_len) || line_len <= 0) {
    bt_abort("`length` must be one positive numeric value.")
  }
  theta <- angle * pi / 180
  along <- c(cos(theta), sin(theta))
  normal <- c(-sin(theta), cos(theta))
  offsets <- seq(-diag_len, diag_len, by = spacing)
  pieces <- vector("list", length(offsets))
  for (j in seq_along(offsets)) {
    mid <- c(cx, cy) + offsets[j] * normal
    p1 <- mid - along * line_len / 2
    p2 <- mid + along * line_len / 2
    candidate <- terra::vect(rbind(p1, p2), type = "lines", crs = terra::crs(zone))
    clipped <- suppressWarnings(terra::intersect(candidate, zone))
    if (!is.null(clipped) && nrow(clipped) > 0) {
      clipped$zone_id <- as.character(zone_id)
      clipped$offset <- offsets[j]
      pieces[[j]] <- clipped
    }
  }
  pieces <- Filter(Negate(is.null), pieces)
  if (length(pieces) == 0) {
    bt_abort("No transects intersected the supplied polygon.")
  }
  do.call(rbind, pieces)
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
#' zones <- terra::vect(blueterra_example("zones"))
#' transects <- make_transects(zones[1, ], spacing = 100)
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
  lines <- as_spatvector(transects)
  r <- as_bathy(x, check = TRUE)
  if (!terra::same.crs(r, lines)) {
    lines <- terra::project(lines, terra::crs(r))
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
  coords <- as.data.frame(terra::geom(line))
  coords <- coords[is.finite(coords$x) & is.finite(coords$y), c("x", "y")]
  coords <- unique(coords)
  if (nrow(coords) < 2) {
    return(tibble::tibble())
  }
  p1 <- as.numeric(coords[1, ])
  p2 <- as.numeric(coords[nrow(coords), ])
  line_len <- sqrt(sum((p2 - p1)^2))
  if (!is.finite(line_len) || line_len <= 0) {
    return(tibble::tibble())
  }
  if (is.null(n)) {
    n <- if (is.null(spacing)) 20 else floor(line_len / spacing) + 1
  }
  n <- max(2, as.integer(n))
  distance <- seq(0, line_len, length.out = n)
  frac <- distance / line_len
  xy <- cbind(
    x = p1[1] + frac * (p2[1] - p1[1]),
    y = p1[2] + frac * (p2[2] - p1[2])
  )
  pts <- terra::vect(xy, type = "points", crs = terra::crs(r))
  vals <- terra::extract(r, pts, method = method, ID = FALSE)
  tibble::as_tibble(cbind(
    transect_id = as.character(line$transect_id[[1]]),
    distance = distance,
    x = xy[, "x"],
    y = xy[, "y"],
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
#' zones <- terra::vect(blueterra_example("zones"))
#' transects <- make_transects(zones[1, ], spacing = 100)
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
    values <- as.numeric(pieces[[id]])
    out <- lapply(fun, function(f) apply_summary_fun(values, f, na.rm = na.rm))
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
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   bathy <- read_bathy(blueterra_example("bathy"))
#'   zones <- terra::vect(blueterra_example("zones"))
#'   transects <- make_transects(zones[1, ], spacing = 100)
#'   samples <- sample_transects(transects, bathy, n = 5)
#'   plot_cross_sections(samples)
#' }
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
