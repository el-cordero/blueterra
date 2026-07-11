#' Create transects across polygon zones
#'
#' @description
#' Builds regularly spaced straight transects through polygon features.
#'
#' @param area A `terra::SpatVector`, local vector path, or optional `sf`
#'   polygon object.
#' @param spacing Distance between transects in map units.
#' @param angle Optional transect direction in degrees counterclockwise from the
#'   projected x axis. When supplied, this manual value overrides orientation
#'   estimation.
#' @param bathy Optional bathymetry raster used to estimate a terrain-based
#'   transect orientation when `angle = NULL`.
#' @param orientation Orientation strategy. `"auto"` uses surface orientation
#'   when `bathy` is supplied and otherwise falls back to the historical
#'   horizontal line angle with a warning. `"surface"` requires `bathy`,
#'   `"bbox"` uses the polygon bounding-box axis, and `"manual"` requires
#'   `angle`.
#' @param orientation_weight Weighting for surface orientation. `"slope"` gives
#'   steeper cells more influence; `"none"` averages aspect components equally.
#' @param min_slope Minimum slope, in degrees, used when
#'   `orientation_weight = "slope"`.
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
#' for metric distances. Candidate lines are created through each polygon
#' bounding box and clipped to the polygon with `terra::intersect()`.
#'
#' With `angle = NULL` and a supplied `bathy` raster, the default transect
#' direction is estimated from the mean surface aspect within each polygon.
#' Aspect is converted to northness and eastness, averaged as circular
#' components, and converted to the mathematical line angle used for transect
#' generation. For example, a south-facing mean aspect near 180 degrees yields a
#' transect angle near 90 degrees, producing north-south transects in projected
#' coordinates. The estimated angle, source metadata, and circular resultant
#' length are stored on the output lines. Resultant lengths near zero indicate
#' weakly concentrated aspects and an unstable mean direction.
#'
#' @examples
#' zones <- terra::vect(blueterra_example("zones"))
#' bathy <- read_bathy(blueterra_example("bathy"))
#' transects <- make_transects(zones[1, ], spacing = 50, bathy = bathy)
#' transects
#'
#' manual <- make_transects(zones[1, ], spacing = 50, angle = 90)
#' manual[, c("angle_deg", "angle_source")]
#'
#' @seealso [estimate_surface_orientation()], [sample_transects()],
#'   [extract_cross_sections()]
#' @export
make_transects <- function(
    area,
    spacing,
    angle = NULL,
    bathy = NULL,
    orientation = c("auto", "surface", "bbox", "manual"),
    orientation_weight = c("slope", "none"),
    min_slope = 0,
    length = NULL,
    id_field = NULL,
    as = c("SpatVector", "sf")
) {
  as <- match.arg(as)
  orientation <- match.arg(orientation)
  orientation_weight <- match.arg(orientation_weight)
  zones <- as_spatvector(area)
  require_projected(zones, operation = "transect spacing")
  if (!is.numeric(spacing) || length(spacing) != 1 || spacing <= 0) {
    bt_abort("`spacing` must be one positive numeric value.")
  }
  if (!is.null(angle) && (!is.numeric(angle) || length(angle) != 1 || !is.finite(angle))) {
    bt_abort("`angle` must be one finite numeric value when supplied.")
  }
  if (!is.numeric(min_slope) || length(min_slope) != 1 || !is.finite(min_slope) || min_slope < 0) {
    bt_abort("`min_slope` must be one non-negative numeric value.")
  }
  if (orientation == "manual" && is.null(angle)) {
    bt_abort("`orientation = \"manual\"` requires a supplied `angle`.")
  }
  if (orientation == "surface" && is.null(bathy) && is.null(angle)) {
    bt_abort("`orientation = \"surface\"` requires `bathy` when `angle` is not supplied.")
  }
  if (!is.null(id_field) && !id_field %in% names(zones)) {
    bt_abort("`id_field` was not found in `area`.")
  }
  bathy_r <- NULL
  if (!is.null(bathy)) {
    bathy_r <- first_layer(bathy)
  }
  if (is.null(angle) && orientation == "auto" && is.null(bathy_r)) {
    bt_warn("No `bathy` raster was supplied; using the historical horizontal transect angle of 0 degrees.")
  }
  out <- vector("list", nrow(zones))
  for (i in seq_len(nrow(zones))) {
    zone_id <- if (is.null(id_field)) i else as.character(zones[[id_field]][i, 1])
    orientation_info <- resolve_transect_orientation(
      zone = zones[i, ],
      angle = angle,
      bathy = bathy_r,
      orientation = orientation,
      orientation_weight = orientation_weight,
      min_slope = min_slope
    )
    out[[i]] <- transects_for_zone(
      zones[i, ],
      spacing = spacing,
      angle = orientation_info$angle_deg,
      length = length,
      zone_id = zone_id,
      orientation_info = orientation_info
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

resolve_transect_orientation <- function(
    zone,
    angle = NULL,
    bathy = NULL,
    orientation = "auto",
    orientation_weight = "slope",
    min_slope = 0
) {
  if (!is.null(angle)) {
    return(list(
      angle_deg = normalize_line_angle(angle),
      angle_source = "manual",
      mean_aspect_deg = NA_real_,
      orientation_weight = NA_character_,
      n_orientation_cells = NA_integer_,
      orientation_resultant_length = NA_real_
    ))
  }

  if (orientation %in% c("auto", "surface") && !is.null(bathy)) {
    estimated <- estimate_surface_orientation(
      bathy = bathy,
      area = zone,
      orientation_weight = orientation_weight,
      min_slope = min_slope,
      return = "both"
    )
    return(list(
      angle_deg = estimated$transect_angle_deg[[1]],
      angle_source = "surface",
      mean_aspect_deg = estimated$bearing_deg[[1]],
      orientation_weight = orientation_weight,
      n_orientation_cells = estimated$n_orientation_cells[[1]],
      orientation_resultant_length = estimated$orientation_resultant_length[[1]]
    ))
  }

  if (orientation == "bbox") {
    return(list(
      angle_deg = bbox_transect_angle(zone),
      angle_source = "bbox",
      mean_aspect_deg = NA_real_,
      orientation_weight = NA_character_,
      n_orientation_cells = NA_integer_,
      orientation_resultant_length = NA_real_
    ))
  }

  if (orientation == "surface") {
    bt_abort("Surface-based transect orientation requires `bathy`.")
  }

  list(
    angle_deg = 0,
    angle_source = "fallback",
    mean_aspect_deg = NA_real_,
    orientation_weight = NA_character_,
    n_orientation_cells = NA_integer_,
    orientation_resultant_length = NA_real_
  )
}

normalize_line_angle <- function(angle) {
  angle <- angle %% 180
  if (angle < 0) {
    angle <- angle + 180
  }
  angle
}

bbox_transect_angle <- function(zone) {
  bbox <- terra::ext(zone)
  width <- bbox[2] - bbox[1]
  height <- bbox[4] - bbox[3]
  if (is.finite(width) && is.finite(height) && height > width) {
    return(90)
  }
  0
}

transects_for_zone <- function(zone, spacing, angle, length, zone_id, orientation_info) {
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
      clipped$angle_deg <- orientation_info$angle_deg
      clipped$angle_source <- orientation_info$angle_source
      clipped$mean_aspect_deg <- orientation_info$mean_aspect_deg
      clipped$orientation_weight <- orientation_info$orientation_weight
      clipped$n_orientation_cells <- orientation_info$n_orientation_cells
      clipped$orientation_resultant_length <- orientation_info$orientation_resultant_length
      pieces[[j]] <- clipped
    }
  }
  pieces <- Filter(Negate(is.null), pieces)
  if (length(pieces) == 0) {
    bt_abort("No transects intersected the supplied polygon.")
  }
  do.call(rbind, pieces)
}

#' Estimate mean surface orientation from a bathymetric raster
#'
#' @description
#' Estimates the mean aspect direction of a raster surface and converts that
#' compass bearing to the line-angle convention used by [make_transects()].
#'
#' @param bathy A single-layer bathymetric or elevation raster, or a raster input
#'   accepted by [as_bathy()].
#' @param area Optional polygon area used to crop and mask `bathy` before
#'   estimating orientation.
#' @param orientation_weight Weighting method. `"slope"` weights aspect
#'   components by slope magnitude; `"none"` averages finite aspect cells
#'   equally.
#' @param min_slope Minimum slope in degrees retained when
#'   `orientation_weight = "slope"`.
#' @param return Return type: `"transect_angle"` for the mathematical line angle
#'   used by [make_transects()], `"bearing"` for the mean compass aspect, or
#'   `"both"` for a tibble containing both values and the number of cells used.
#'
#' @return A numeric angle for `"transect_angle"` or `"bearing"`, or a tibble
#'   with `bearing_deg`, `transect_angle_deg`, `orientation_weight`,
#'   `min_slope`, and `n_orientation_cells` when `return = "both"`.
#'
#' @details
#' Aspect is treated as a compass bearing where northness is `cos(aspect)` and
#' eastness is `sin(aspect)`. Mean circular components are converted to a
#' compass bearing with `atan2(eastness, northness)`. Transect lines are
#' undirected, so the line angle is normalized to `[0, 180)`. A south-facing
#' mean aspect near 180 degrees therefore produces a transect angle near 90
#' degrees.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("hitw"))
#' zones <- terra::vect(blueterra_example("zones"))
#' hitw <- zones[zones$site_id == "hitw", ]
#' estimate_surface_orientation(bathy, hitw)
#'
#' @seealso [make_transects()], [derive_aspect()], [derive_slope()]
#' @export
estimate_surface_orientation <- function(
    bathy,
    area = NULL,
    orientation_weight = c("slope", "none"),
    min_slope = 0,
    return = c("transect_angle", "bearing", "both")
) {
  orientation_weight <- match.arg(orientation_weight)
  return <- match.arg(return)
  if (!is.numeric(min_slope) || length(min_slope) != 1 || !is.finite(min_slope) || min_slope < 0) {
    bt_abort("`min_slope` must be one non-negative numeric value.")
  }

  r <- first_layer(bathy)
  if (!is.null(area)) {
    zone <- as_spatvector(area)
    if (!terra::same.crs(r, zone)) {
      zone <- terra::project(zone, terra::crs(r))
    }
    r <- terra::crop(r, zone)
    r <- terra::mask(r, zone)
  }

  aspect <- derive_aspect(r, units = "radians")
  aspect_values <- terra::values(aspect, mat = FALSE)
  northness <- cos(aspect_values)
  eastness <- sin(aspect_values)
  keep <- is.finite(northness) & is.finite(eastness)

  weights <- rep(1, length(aspect_values))
  if (orientation_weight == "slope") {
    slope <- derive_slope(r, units = "degrees")
    weights <- terra::values(slope, mat = FALSE)
    keep <- keep & is.finite(weights) & weights >= min_slope & weights > 0
  }

  if (!any(keep)) {
    bt_abort("No finite aspect cells were available for surface-orientation estimation.")
  }

  if (orientation_weight == "slope") {
    w <- as.numeric(weights[keep])
    if (!is.finite(sum(w)) || sum(w) <= 0) {
      bt_abort("Slope weights were all zero; surface orientation could not be estimated.")
    }
    mean_north <- stats::weighted.mean(northness[keep], w = w)
    mean_east <- stats::weighted.mean(eastness[keep], w = w)
  } else {
    mean_north <- mean(northness[keep])
    mean_east <- mean(eastness[keep])
  }

  orientation_resultant_length <- sqrt(mean_north^2 + mean_east^2)
  if (!is.finite(mean_north) || !is.finite(mean_east) ||
      orientation_resultant_length < .Machine$double.eps) {
    bt_abort("Mean aspect components cancel out; surface orientation is ambiguous.")
  }

  bearing_deg <- atan2(mean_east, mean_north) * 180 / pi
  if (bearing_deg < 0) {
    bearing_deg <- bearing_deg + 360
  }
  transect_angle_deg <- (90 - bearing_deg) %% 180

  if (return == "transect_angle") {
    return(transect_angle_deg)
  }
  if (return == "bearing") {
    return(bearing_deg)
  }
  tibble::tibble(
    bearing_deg = bearing_deg,
    transect_angle_deg = transect_angle_deg,
    orientation_weight = orientation_weight,
    min_slope = min_slope,
    n_orientation_cells = sum(keep),
    orientation_resultant_length = orientation_resultant_length
  )
}

#' Sample rasters along transects
#'
#' @description
#' Extracts raster values along transect lines at regular distances.
#'
#' @param transects Line geometry from [make_transects()] or another source.
#' @param x A `terra::SpatRaster` or local raster path. Multi-layer rasters are
#'   accepted when sampling bathymetry together with derived terrain metrics.
#' @param spacing Optional sample spacing in map units.
#' @param n Optional number of sample points per transect.
#' @param method Extraction method passed to `terra::extract()`.
#' @param drop_na Logical. If `TRUE`, remove sample rows where all raster value
#'   columns are missing.
#'
#' @return A tibble with transect identifiers, distances, coordinates, and
#'   raster values.
#'
#' @details
#' If `spacing` and `n` are both `NULL`, twenty points are sampled per transect.
#' Distances are measured from the first line vertex and are in map units.
#' Transect attribute columns, including orientation metadata created by
#' [make_transects()], are preserved in the sampled table.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' zones <- terra::vect(blueterra_example("zones"))
#' transects <- make_transects(zones[1, ], spacing = 100, bathy = bathy)
#' sample_transects(transects, bathy, n = 5)
#'
#' @seealso [make_transects()], [summarize_cross_sections()]
#' @export
sample_transects <- function(
    transects,
    x,
    spacing = NULL,
    n = NULL,
    method = "bilinear",
    drop_na = FALSE
) {
  lines <- as_spatvector(transects)
  r <- as_bathy(x, check = FALSE)
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
  out <- dplyr::bind_rows(samples)
  if (isTRUE(drop_na) && nrow(out) > 0) {
    value_cols <- setdiff(names(r), character())
    value_cols <- intersect(value_cols, names(out))
    keep <- rowSums(!is.na(out[, value_cols, drop = FALSE])) > 0
    out <- out[keep, , drop = FALSE]
  }
  out
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
  attrs <- as.data.frame(line)
  if (!"transect_id" %in% names(attrs)) {
    attrs$transect_id <- seq_len(nrow(attrs))
  }
  attrs <- attrs[rep(1, n), , drop = FALSE]
  row.names(attrs) <- NULL
  tibble::as_tibble(cbind(
    attrs,
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
#' @param normalize_distance Logical. If `TRUE`, summarize values by normalized
#'   position along each transect.
#' @param n_bins Number of normalized-distance bins when
#'   `normalize_distance = TRUE`.
#'
#' @return A tibble with one row per group.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' zones <- terra::vect(blueterra_example("zones"))
#' transects <- make_transects(zones[1, ], spacing = 100, bathy = bathy)
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
    na.rm = TRUE,
    normalize_distance = FALSE,
    n_bins = 50
) {
  if (!is.data.frame(samples)) {
    bt_abort("`samples` must be a data frame.")
  }
  if (!group_col %in% names(samples)) {
    bt_abort("`group_col` was not found in `samples`.")
  }
  value_col <- terrain_value_column(samples, value_col, context = "value")
  fun <- safe_summary_funs(fun)
  if (isTRUE(normalize_distance)) {
    if (!"distance" %in% names(samples)) {
      bt_abort("`samples` must contain `distance` for normalized-distance summaries.")
    }
    if (!is.numeric(n_bins) || length(n_bins) != 1 || n_bins < 2) {
      bt_abort("`n_bins` must be an integer greater than one.")
    }
    samples <- add_normalized_distance(samples, group_col = group_col)
    samples$distance_bin <- cut(
      samples$normalized_distance,
      breaks = seq(0, 1, length.out = as.integer(n_bins) + 1),
      include.lowest = TRUE
    )
    pieces <- split(samples[[value_col]], list(samples[[group_col]], samples$distance_bin), drop = TRUE)
    rows <- lapply(names(pieces), function(id) {
      values <- as.numeric(pieces[[id]])
      ids <- strsplit(id, ".", fixed = TRUE)[[1]]
      out <- lapply(fun, function(f) apply_summary_fun(values, f, na.rm = na.rm))
      names(out) <- paste(value_col, fun, sep = "_")
      data.frame(
        transect_id = ids[[1]],
        distance_bin = ids[[2]],
        out,
        check.names = FALSE
      )
    })
    return(tibble::as_tibble(do.call(rbind, rows)))
  }
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
#' @param color_col Optional column used to color profiles. Defaults to
#'   `group_col`.
#' @param show_legend Logical. Show the line-color legend.
#' @param points Logical. Draw sample points over profile lines.
#' @param mean_profile Logical. Overlay an interpolated mean profile across
#'   transects.
#' @param mean_profile_na_rm Logical. Remove missing interpolated profile values
#'   when averaging the mean profile. The default, `TRUE`, lets the mean profile
#'   use the full available distance range rather than stopping where the
#'   shortest transect ends. Set to `FALSE` to require every profile to
#'   contribute at each distance.
#' @param normalize_distance Logical. Plot distance as 0-1 normalized position
#'   along each transect.
#' @param profile_direction Direction used to orient distance before plotting.
#'   `"top_to_bottom"` (the default) orients bathymetric or elevation profiles
#'   from the shallow or top endpoint toward the deeper or bottom endpoint.
#'   With negative-elevation bathymetry this means higher numeric values to
#'   lower numeric values. With positive-depth bathymetry, set
#'   `positive_depth = TRUE` so the profile runs from lower depth values to
#'   higher depth values. `"bottom_to_top"` reverses that convention.
#'   `"max_to_min"` and `"min_to_max"` provide explicit numeric endpoint
#'   controls for metrics, and `"as_sampled"` preserves the sampled line order.
#'   Legacy values `"high_to_low"` and `"low_to_high"` are accepted as aliases
#'   for `"top_to_bottom"` and `"bottom_to_top"`.
#' @param positive_depth Logical depth convention for `value_col`. This affects
#'   top-to-bottom profile orientation for depth-like variables and y-axis
#'   display for positive-depth values.
#' @param depth_increases_down Logical. If `TRUE`, positive-depth profiles are
#'   plotted with a reversed y-axis so larger depths appear lower in the panel.
#' @param title,subtitle,caption Plot text.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   bathy <- read_bathy(blueterra_example("bathy"))
#'   zones <- terra::vect(blueterra_example("zones"))
#'   transects <- make_transects(zones[1, ], spacing = 100, bathy = bathy)
#'   samples <- sample_transects(transects, bathy, n = 5)
#'   plot_cross_sections(samples)
#' }
#'
#' @seealso [sample_transects()], [plot_depth_profile()]
#' @export
plot_cross_sections <- function(
    samples,
    value_col = NULL,
    group_col = "transect_id",
    color_col = NULL,
    show_legend = TRUE,
    points = FALSE,
    mean_profile = FALSE,
    mean_profile_na_rm = TRUE,
    normalize_distance = FALSE,
    profile_direction = c(
      "top_to_bottom", "bottom_to_top", "as_sampled",
      "max_to_min", "min_to_max", "high_to_low", "low_to_high"
    ),
    positive_depth = NULL,
    depth_increases_down = TRUE,
    title = NULL,
    subtitle = NULL,
    caption = NULL
) {
  optional_ggplot2()
  if (!is.data.frame(samples)) {
    bt_abort("`samples` must be a data frame.")
  }
  if (!"distance" %in% names(samples)) {
    bt_abort("`samples` must contain a `distance` column.")
  }
  if (!group_col %in% names(samples)) {
    bt_abort("`group_col` was not found in `samples`.")
  }
  value_col <- infer_profile_value_col(samples, value_col = value_col)
  color_col <- color_col %||% group_col
  if (!is.null(color_col) && !color_col %in% names(samples)) {
    bt_abort("`color_col` was not found in `samples`.")
  }
  plot_data <- orient_profile_distance(
    samples,
    value_col = value_col,
    distance_col = "distance",
    group_col = group_col,
    profile_direction = profile_direction,
    positive_depth = positive_depth
  )
  x_col <- "distance_profile"
  x_lab <- "Distance along profile (m)"
  if (isTRUE(normalize_distance)) {
    plot_data <- add_normalized_distance(plot_data, group_col = group_col, distance_col = x_col)
    x_col <- "normalized_distance"
    x_lab <- "Normalized distance along transect"
  }
  plot_data <- plot_data[order(plot_data[[group_col]], plot_data[[x_col]]), , drop = FALSE]

  if (is.null(color_col)) {
    mapping <- ggplot2::aes(
      x = .data[[x_col]],
      y = .data[[value_col]],
      group = .data[[group_col]]
    )
  } else {
    mapping <- ggplot2::aes(
      x = .data[[x_col]],
      y = .data[[value_col]],
      group = .data[[group_col]],
      color = .data[[color_col]]
    )
  }
  p <- ggplot2::ggplot(plot_data, mapping) +
    ggplot2::geom_line(alpha = 0.75, na.rm = TRUE) +
    ggplot2::labs(
      x = x_lab,
      y = profile_axis_label(value_col),
      color = if (identical(color_col, group_col)) "Transect" else color_col,
      title = title,
      subtitle = subtitle,
      caption = caption
    )
  if (isTRUE(points)) {
    p <- p + ggplot2::geom_point(na.rm = TRUE, size = 1.3, alpha = 0.75)
  }

  if (isTRUE(mean_profile)) {
    mean_data <- mean_profile_data(
      plot_data,
      x_col = x_col,
      value_col = value_col,
      group_col = group_col,
      na.rm = mean_profile_na_rm
    )
    p <- p +
      ggplot2::geom_line(
        data = mean_data,
        ggplot2::aes(x = .data[[x_col]], y = .data[["mean_value"]]),
        inherit.aes = FALSE,
        linewidth = 1.1,
        color = "black",
        alpha = 0.9,
        na.rm = TRUE
      )
  }
  if (!isTRUE(show_legend)) {
    p <- p + ggplot2::guides(color = "none")
  }
  orient_depth_axis(p, plot_data[[value_col]], depth_increases_down)
}

add_normalized_distance <- function(samples, group_col = "transect_id", distance_col = "distance") {
  pieces <- split(samples, samples[[group_col]])
  pieces <- lapply(pieces, function(piece) {
    rng <- range(piece[[distance_col]], na.rm = TRUE)
    if (!all(is.finite(rng)) || diff(rng) == 0) {
      piece$normalized_distance <- 0
    } else {
      piece$normalized_distance <- (piece[[distance_col]] - rng[1]) / diff(rng)
    }
    piece
  })
  dplyr::bind_rows(pieces)
}

mean_profile_data <- function(samples, x_col, value_col, group_col, n_bins = 50, na.rm = TRUE) {
  data <- samples
  if (!is.logical(na.rm) || length(na.rm) != 1 || is.na(na.rm)) {
    bt_abort("`na.rm` must be `TRUE` or `FALSE`.")
  }
  if (!"normalized_distance" %in% names(data)) {
    data <- add_normalized_distance(data, group_col = group_col, distance_col = x_col)
  }

  pieces <- split(data, data[[group_col]], drop = TRUE)
  profile_pieces <- lapply(pieces, function(piece) {
    ok <- is.finite(piece[[x_col]]) & is.finite(piece[[value_col]])
    piece <- piece[ok, , drop = FALSE]
    if (nrow(piece) < 2) {
      return(NULL)
    }
    piece <- piece[order(piece[[x_col]]), , drop = FALSE]
    profile <- stats::aggregate(
      piece[[value_col]],
      by = list(profile_x = piece[[x_col]]),
      FUN = mean,
      na.rm = TRUE
    )
    names(profile)[[2]] <- "profile_value"
    if (nrow(profile) < 2) {
      return(NULL)
    }
    profile
  })
  profile_pieces <- Filter(Negate(is.null), profile_pieces)

  if (!length(profile_pieces)) {
    out <- tibble::tibble(
      normalized_distance = numeric(),
      mean_value = numeric()
    )
    if (!identical(x_col, "normalized_distance")) {
      out[[x_col]] <- numeric()
    }
    return(out[, unique(c("normalized_distance", x_col, "mean_value")), drop = FALSE])
  }

  profile_mins <- vapply(profile_pieces, function(piece) min(piece$profile_x, na.rm = TRUE), numeric(1))
  profile_maxs <- vapply(profile_pieces, function(piece) max(piece$profile_x, na.rm = TRUE), numeric(1))
  x_range <- c(min(profile_mins, na.rm = TRUE), max(profile_maxs, na.rm = TRUE))
  if (!all(is.finite(x_range)) || diff(x_range) == 0) {
    out <- tibble::tibble(
      normalized_distance = 0,
      mean_value = mean(data[[value_col]], na.rm = TRUE)
    )
    if (!identical(x_col, "normalized_distance")) {
      out[[x_col]] <- 0
    }
    return(out[, unique(c("normalized_distance", x_col, "mean_value")), drop = FALSE])
  }
  common_x <- seq(x_range[[1]], x_range[[2]], length.out = n_bins)

  profile_values <- lapply(profile_pieces, function(profile) {
    stats::approx(
      x = profile$profile_x,
      y = profile$profile_value,
      xout = common_x,
      method = "linear",
      ties = "ordered",
      rule = 1
    )$y
  })
  value_matrix <- do.call(cbind, profile_values)
  mean_values <- rowMeans(value_matrix, na.rm = na.rm)
  mean_values[is.nan(mean_values)] <- NA_real_
  if (!any(is.finite(mean_values))) {
    out <- tibble::tibble(normalized_distance = numeric(), mean_value = numeric())
    if (!identical(x_col, "normalized_distance")) out[[x_col]] <- numeric()
    return(out[, unique(c("normalized_distance", x_col, "mean_value")), drop = FALSE])
  }
  out <- tibble::tibble(
    mean_profile_x = common_x,
    mean_value = mean_values
  )
  out$normalized_distance <- if (identical(x_col, "normalized_distance")) {
    out$mean_profile_x
  } else {
    (out$mean_profile_x - x_range[[1]]) / diff(x_range)
  }
  out[[x_col]] <- out$mean_profile_x
  out$mean_profile_x <- NULL
  out[, unique(c("normalized_distance", x_col, "mean_value")), drop = FALSE]
}
