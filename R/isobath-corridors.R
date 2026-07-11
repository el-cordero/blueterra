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
#' @param as Output type: `"SpatVector"` or `"sf"`.
#' @param ... Additional arguments reserved for future extensions.
#'
#' @return Isobath line features as `terra::SpatVector` by default.
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
    as = c("SpatVector", "sf"),
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
  out <- contours
  value_col <- intersect(c("level", "value", "z"), names(out))[1]
  if (is.na(value_col)) {
    out$level <- rep(levels, length.out = nrow(out))
    value_col <- "level"
  }
  attrs <- as.data.frame(out)
  out$contour_value <- as.numeric(attrs[[value_col]])
  out$depth_label <- depths[match(out$contour_value, levels)]
  out$depth_label[is.na(out$depth_label)] <- out$contour_value[is.na(out$depth_label)]
  if (as == "sf") {
    check_installed("sf", "to return sf objects")
    return(sf::st_as_sf(out))
  }
  out
}

#' Build isobath corridors
#'
#' @description
#' Buffers isobath contour lines to create depth-following corridor polygons.
#'
#' @inheritParams extract_isobaths
#' @param width One-sided buffer distance in map units. The nominal full
#'   corridor width is twice this value.
#' @param smooth Logical. If `TRUE`, apply a zero-width buffer after buffering
#'   to clean polygon topology.
#'
#' @return Isobath corridor polygons as `terra::SpatVector` by default.
#'
#' @details
#' `width` is interpreted as a one-sided buffer distance in the CRS map units.
#' Projected CRS are strongly recommended. If the raster uses
#' longitude/latitude, the function warns before buffering because distance
#' interpretation may be misleading. Corridors are returned as independent
#' buffers and can overlap; their summaries are therefore not mutually
#' exclusive or additive.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' make_isobath_corridors(bathy, depths = c(-40, -60), width = 5)
#'
#' @seealso [extract_isobaths()], [summarize_isobath_terrain()]
#' @export
make_isobath_corridors <- function(
    x,
    depths,
    width,
    smooth = FALSE,
    as = c("SpatVector", "sf"),
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
    as = "SpatVector"
  )
  corridors <- terra::buffer(lines, width = width)
  if (isTRUE(smooth)) {
    corridors <- terra::buffer(corridors, width = 0)
  }
  corridors$corridor_id <- seq_len(nrow(corridors))
  corridors$buffer_distance <- width
  corridors$nominal_corridor_width <- 2 * width
  corridors$overlap_policy <- "independent_may_overlap"
  if (as == "sf") {
    check_installed("sf", "to return sf objects")
    return(sf::st_as_sf(corridors))
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
#' corridors <- make_isobath_corridors(bathy, depths = -50, width = 5)
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
  attrs <- zone_attributes(zones)
  attrs$ID <- seq_len(nrow(zones))
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
#' @param exact Logical. Use coverage-fraction-weighted exact intersections
#'   through [summarize_terrain()] when available.
#' @param ... Additional arguments passed to [summarize_terrain()].
#'
#' @return A tibble with one row per corridor.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
#' corridors <- make_isobath_corridors(bathy, depths = -50, width = 5)
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
#' Plots isobath corridor polygons, optionally over hillshaded bathymetry with
#' contour lines. The hillshade layer is visual context only.
#'
#' @param corridors Corridor polygons.
#' @param bathy Optional raster background.
#' @param isobaths Optional source isobath lines to draw over the corridors.
#' @param hillshade Logical. Draw hillshade from `bathy` when available.
#' @param background_contours Logical. Draw general bathymetric background
#'   contours. Defaults to `FALSE` to keep corridor figures readable.
#' @param source_isobaths Logical. Draw the source isobaths used to create the
#'   corridors.
#' @param isobath_color,isobath_linewidth Source-isobath line styling.
#' @param corridor_color,corridor_linewidth,corridor_fill,corridor_alpha
#'   Corridor polygon styling.
#' @param labels Logical. Label corridors with `label_field`.
#' @param label_field Attribute used for labels. Defaults to `depth_label` when
#'   present, otherwise `contour_value`.
#' @param title,subtitle,caption Plot text.
#' @param contours Deprecated alias for `background_contours`.
#' @param ... Additional arguments passed to [plot_bathy()].
#'
#' @return A `ggplot` object.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   bathy <- read_bathy(blueterra_example("bathy"))
#'   corridors <- make_isobath_corridors(bathy, depths = -50, width = 5)
#'   isobaths <- extract_isobaths(bathy, depths = -50)
#'   plot_isobath_corridors(corridors, bathy, isobaths = isobaths)
#' }
#'
#' @seealso [make_isobath_corridors()], [plot_bathy()]
#' @export
plot_isobath_corridors <- function(
    corridors,
    bathy = NULL,
    isobaths = NULL,
    hillshade = TRUE,
    background_contours = FALSE,
    source_isobaths = TRUE,
    isobath_color = "black",
    isobath_linewidth = 0.6,
    corridor_color = "white",
    corridor_linewidth = 0.45,
    corridor_fill = NA,
    corridor_alpha = 0.20,
    labels = TRUE,
    label_field = NULL,
    title = "Isobath Corridors",
    subtitle = NULL,
    caption = NULL,
    contours = NULL,
    ...
) {
  optional_ggplot2()
  if (!is.null(contours)) {
    bt_warn("`contours` is deprecated for `plot_isobath_corridors()`; use `background_contours`.")
    background_contours <- contours
  }
  corridor_v <- as_spatvector(corridors)
  if (is.null(label_field)) {
    label_field <- intersect(c("depth_label", "contour_value", "corridor_id"), names(corridor_v))[1]
  }
  source_v <- NULL
  if (isTRUE(source_isobaths)) {
    if (!is.null(isobaths)) {
      source_v <- as_spatvector(isobaths)
    } else if (!is.null(bathy)) {
      depth_field <- intersect(c("contour_value", "depth_label"), names(corridor_v))[1]
      if (!is.na(depth_field)) {
        depths <- unique(stats::na.omit(as.numeric(as.data.frame(corridor_v)[[depth_field]])))
        if (length(depths) > 0) {
          source_v <- try(extract_isobaths(bathy, depths = depths), silent = TRUE)
          if (inherits(source_v, "try-error")) {
            source_v <- NULL
          }
        }
      }
    }
  }
  if (is.null(bathy)) {
    corridor_df <- vector_plot_data(corridor_v)
    p <- ggplot2::ggplot() +
      ggplot2::geom_polygon(
        data = corridor_df,
        ggplot2::aes(x = .data[["x"]], y = .data[["y"]], group = .data[["group"]]),
        color = corridor_color,
        fill = corridor_fill,
        alpha = corridor_alpha,
        linewidth = corridor_linewidth
      ) +
      ggplot2::coord_equal() +
      ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle, caption = caption)
    if (!is.null(source_v)) {
      source_df <- vector_plot_data(source_v)
      p <- p +
        ggplot2::geom_path(
          data = source_df,
          ggplot2::aes(x = .data[["x"]], y = .data[["y"]], group = .data[["group"]]),
          inherit.aes = FALSE,
          color = isobath_color,
          linewidth = isobath_linewidth
        )
    }
    if (isTRUE(labels) && !is.na(label_field)) {
      label_df <- vector_label_data(corridor_v, label_field = label_field)
      p <- p +
        ggplot2::geom_text(
          data = label_df,
          ggplot2::aes(x = .data[["x"]], y = .data[["y"]], label = .data[["label"]]),
          inherit.aes = FALSE,
          size = 3
        )
    }
    return(p)
  }
  p <- plot_bathy(
    bathy,
    hillshade = hillshade,
    contours = background_contours,
    vectors = NULL,
    labels = NULL,
    title = title,
    subtitle = subtitle,
    caption = caption,
    legend_title = "Bathymetry",
    ...
  )
  corridor_df <- vector_plot_data(corridor_v)
  p <- p +
    ggplot2::geom_polygon(
      data = corridor_df,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]], group = .data[["group"]]),
      inherit.aes = FALSE,
      color = corridor_color,
      fill = corridor_fill,
      alpha = corridor_alpha,
      linewidth = corridor_linewidth
    )
  if (!is.null(source_v)) {
    source_df <- vector_plot_data(source_v)
    p <- p +
      ggplot2::geom_path(
        data = source_df,
        ggplot2::aes(x = .data[["x"]], y = .data[["y"]], group = .data[["group"]]),
        inherit.aes = FALSE,
        color = isobath_color,
        linewidth = isobath_linewidth
      )
  }
  if (isTRUE(labels) && !is.na(label_field)) {
    label_df <- vector_label_data(corridor_v, label_field = label_field)
    p <- p +
      ggplot2::geom_text(
        data = label_df,
        ggplot2::aes(x = .data[["x"]], y = .data[["y"]], label = .data[["label"]]),
        inherit.aes = FALSE,
        color = "white",
        fontface = "bold",
        size = 3
      )
  }
  p
}
