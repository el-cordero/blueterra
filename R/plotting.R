#' Plot bathymetry and terrain rasters
#'
#' @description
#' Creates `ggplot2` maps for bathymetry and derived terrain metrics using
#' `terra` rasters and vectors. Hillshade can be drawn as a semitransparent
#' visual relief layer, and bathymetric contours, sampling rectangles, transects,
#' or other `terra::SpatVector` geometries can be overlaid.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param metric Optional layer name or index. For `plot_terrain_map()`, this
#'   may also be a raster-like metric layer.
#' @param bathy Optional bathymetry raster used to derive hillshade and contours
#'   when `x` is a metric raster.
#' @param hillshade Logical. Draw hillshade as a visual relief layer.
#' @param hillshade_alpha Maximum alpha for the hillshade shadow overlay.
#' @param contours Logical. Draw contour lines from `bathy` or `x`.
#' @param contour_interval Optional contour interval in raster units.
#' @param contour_color Contour line color.
#' @param contour_linewidth Contour line width.
#' @param vectors Optional `terra::SpatVector`, `sf` object, or local vector path
#'   drawn over the raster.
#' @param vector_color Vector outline color.
#' @param vector_linewidth Vector outline width.
#' @param labels Optional label source. Use `TRUE` to label `vectors`, or supply
#'   a vector object/path.
#' @param label_field Optional field used for vector labels.
#' @param title,subtitle,caption Plot text passed to `ggplot2::labs()`.
#' @param legend_title Optional raster legend title.
#' @param max_cells Maximum raster cells used for plotting.
#' @param ... Additional plotting options passed from convenience wrappers to
#'   `plot_bathy()` or `plot_metric()`.
#'
#' @return A `ggplot` object.
#'
#' @details
#' Plotting functions require `ggplot2`, which is suggested rather than
#' imported. Large rasters are regularly sampled before plotting to keep
#' examples and interactive work responsive. Hillshade is used only as a visual
#' relief layer; it is not a terrain predictor unless a user explicitly derives
#' and analyzes it as one.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   bathy <- read_bathy(blueterra_example("bathy"))
#'   zones <- terra::vect(blueterra_example("zones"))
#'   plot_bathy(bathy, vectors = zones, labels = TRUE, label_field = "site_id")
#' }
#'
#' @seealso [derive_terrain()], [plot_metric_stack()]
#' @export
plot_bathy <- function(
    x,
    hillshade = TRUE,
    hillshade_alpha = 0.30,
    contours = TRUE,
    contour_interval = NULL,
    contour_color = "white",
    contour_linewidth = 0.25,
    vectors = NULL,
    vector_color = "white",
    vector_linewidth = 0.5,
    labels = NULL,
    label_field = NULL,
    title = NULL,
    subtitle = NULL,
    caption = NULL,
    legend_title = "Bathymetry",
    max_cells = getOption("blueterra.max_plot_cells", 10000)
) {
  plot_metric(
    x = x,
    metric = 1,
    bathy = x,
    hillshade = hillshade,
    hillshade_alpha = hillshade_alpha,
    contours = contours,
    contour_interval = contour_interval,
    contour_color = contour_color,
    contour_linewidth = contour_linewidth,
    vectors = vectors,
    vector_color = vector_color,
    vector_linewidth = vector_linewidth,
    labels = labels,
    label_field = label_field,
    title = title,
    subtitle = subtitle,
    caption = caption,
    legend_title = legend_title,
    max_cells = max_cells
  )
}

#' @rdname plot_bathy
#' @export
plot_metric <- function(
    x,
    metric = NULL,
    bathy = NULL,
    hillshade = TRUE,
    hillshade_alpha = 0.30,
    contours = FALSE,
    contour_interval = NULL,
    contour_color = "white",
    contour_linewidth = 0.25,
    vectors = NULL,
    vector_color = "white",
    vector_linewidth = 0.5,
    labels = NULL,
    label_field = NULL,
    title = NULL,
    subtitle = NULL,
    caption = NULL,
    legend_title = NULL,
    max_cells = getOption("blueterra.max_plot_cells", 10000)
) {
  optional_ggplot2()
  r <- as_bathy(x, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  if (!is.null(metric)) {
    r <- r[[metric]]
  } else if (terra::nlyr(r) > 1) {
    r <- r[[1]]
  }

  relief <- if (is.null(bathy)) r else first_layer(bathy)
  df <- raster_plot_data(r, max_cells = max_cells)
  value_col <- setdiff(names(df), c("x", "y"))[1]
  legend_title <- legend_title %||% value_col

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["x"]], y = .data[["y"]])) +
    ggplot2::geom_raster(ggplot2::aes(fill = .data[[value_col]])) +
    ggplot2::coord_equal() +
    ggplot2::scale_fill_viridis_c(option = "C", na.value = NA, name = legend_title) +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle, caption = caption)

  if (isTRUE(hillshade)) {
    hillshade_df <- hillshade_plot_data(relief, max_cells = max_cells)
    p <- p +
      ggplot2::geom_raster(
        data = hillshade_df,
        ggplot2::aes(x = .data[["x"]], y = .data[["y"]], alpha = .data[["shadow_alpha"]]),
        fill = "black",
        inherit.aes = FALSE
      ) +
      ggplot2::scale_alpha(range = c(0, hillshade_alpha), guide = "none")
  }

  if (isTRUE(contours)) {
    contour_df <- contour_plot_data(relief, contour_interval)
    if (!is.null(contour_df) && nrow(contour_df) > 0) {
      p <- p +
        ggplot2::geom_path(
          data = contour_df,
          ggplot2::aes(x = .data[["x"]], y = .data[["y"]], group = .data[["group"]]),
          color = contour_color,
          linewidth = contour_linewidth,
          alpha = 0.75,
          inherit.aes = FALSE
        )
    }
  }

  if (!is.null(vectors)) {
    vector_df <- vector_plot_data(vectors)
    p <- p +
      ggplot2::geom_path(
        data = vector_df,
        ggplot2::aes(x = .data[["x"]], y = .data[["y"]], group = .data[["group"]]),
        color = vector_color,
        linewidth = vector_linewidth,
        inherit.aes = FALSE
      )
  }

  label_source <- label_source(labels, vectors)
  if (!is.null(label_source)) {
    label_df <- vector_label_data(label_source, label_field = label_field)
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

#' @rdname plot_bathy
#' @param metric Optional metric raster or a layer name/index in `bathy`.
#' @export
plot_terrain_map <- function(
    bathy,
    metric = NULL,
    vectors = NULL,
    contours = TRUE,
    contour_interval = 20,
    hillshade = TRUE,
    title = NULL,
    subtitle = NULL,
    caption = NULL,
    ...
) {
  if (is.null(metric)) {
    return(plot_bathy(
      bathy,
      vectors = vectors,
      contours = contours,
      contour_interval = contour_interval,
      hillshade = hillshade,
      title = title,
      subtitle = subtitle,
      caption = caption,
      ...
    ))
  }
  if (is.character(metric) || is.numeric(metric)) {
    r <- as_bathy(bathy, check = FALSE)
    if (is.numeric(metric) || all(metric %in% names(r))) {
      return(plot_metric(
        r,
        metric = metric,
        bathy = bathy,
        vectors = vectors,
        contours = contours,
        contour_interval = contour_interval,
        hillshade = hillshade,
        title = title,
        subtitle = subtitle,
        caption = caption,
        ...
      ))
    }
  }
  plot_metric(
    metric,
    bathy = bathy,
    vectors = vectors,
    contours = contours,
    contour_interval = contour_interval,
    hillshade = hillshade,
    title = title,
    subtitle = subtitle,
    caption = caption,
    ...
  )
}

#' @rdname plot_bathy
#' @export
plot_hillshade <- function(
    x,
    max_cells = getOption("blueterra.max_plot_cells", 10000)
) {
  optional_ggplot2()
  r <- as_bathy(x, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  if (!"hillshade" %in% names(r)) {
    r <- derive_hillshade(r)
  } else {
    r <- r[["hillshade"]]
  }
  df <- raster_plot_data(r, max_cells = max_cells)
  value_col <- setdiff(names(df), c("x", "y"))[1]
  ggplot2::ggplot(df, ggplot2::aes(x = .data[["x"]], y = .data[["y"]])) +
    ggplot2::geom_raster(ggplot2::aes(fill = .data[[value_col]])) +
    ggplot2::coord_equal() +
    ggplot2::scale_fill_gradient(low = "black", high = "white", na.value = NA, name = "Hillshade") +
    ggplot2::labs(x = NULL, y = NULL)
}

#' @rdname plot_bathy
#' @param rectangles Sampling rectangles or polygon zones.
#' @export
plot_sampling_rectangles <- function(
    bathy,
    rectangles,
    label_field = "site_id",
    ...
) {
  plot_bathy(
    bathy,
    vectors = rectangles,
    labels = TRUE,
    label_field = label_field,
    ...
  )
}

#' @rdname plot_bathy
#' @param transects Transect line geometry.
#' @export
plot_transects <- function(
    bathy,
    transects,
    ...
) {
  plot_bathy(
    bathy,
    vectors = transects,
    labels = FALSE,
    ...
  )
}

#' @rdname plot_bathy
#' @export
plot_metric_stack <- function(
    x,
    max_cells = getOption("blueterra.max_plot_cells", 10000)
) {
  optional_ggplot2()
  r <- as_bathy(x, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  df <- raster_plot_data(r, max_cells = max_cells)
  long <- stats::reshape(
    as.data.frame(df),
    varying = setdiff(names(df), c("x", "y")),
    v.names = "value",
    timevar = "metric",
    times = setdiff(names(df), c("x", "y")),
    direction = "long"
  )
  ggplot2::ggplot(long, ggplot2::aes(x = .data[["x"]], y = .data[["y"]])) +
    ggplot2::geom_raster(ggplot2::aes(fill = .data[["value"]])) +
    ggplot2::facet_wrap(ggplot2::vars(.data[["metric"]])) +
    ggplot2::coord_equal() +
    ggplot2::scale_fill_viridis_c(option = "C", na.value = NA) +
    ggplot2::labs(x = NULL, y = NULL, fill = "Value")
}

#' Plot process density
#'
#' @description
#' Plots density curves for one or more process-group metrics.
#'
#' @param data A data frame of terrain values.
#' @param value Character name of the numeric value column.
#' @param group Optional grouping column.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   df <- data.frame(value = rnorm(20), process = rep(c("a", "b"), each = 10))
#'   plot_process_density(df, value = "value", group = "process")
#' }
#'
#' @seealso [assign_process_groups()]
#' @export
plot_process_density <- function(data, value, group = NULL) {
  optional_ggplot2()
  if (!is.data.frame(data) || !value %in% names(data)) {
    bt_abort("`data` must contain the requested `value` column.")
  }
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[value]]))
  if (!is.null(group)) {
    if (!group %in% names(data)) {
      bt_abort("`group` was not found in `data`.")
    }
    p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[value]], color = .data[[group]]))
  }
  p + ggplot2::geom_density(na.rm = TRUE) + ggplot2::labs(x = value, y = "Density")
}

#' Plot terrain PCA
#'
#' @description
#' Plots the first two principal component score axes from [terrain_pca()].
#'
#' @param pca Output from [terrain_pca()].
#'
#' @return A `ggplot` object.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   df <- data.frame(a = rnorm(20), b = rnorm(20), c = rnorm(20))
#'   plot_process_pca(terrain_pca(df))
#' }
#'
#' @seealso [terrain_pca()]
#' @export
plot_process_pca <- function(pca) {
  optional_ggplot2()
  if (!is.list(pca) || is.null(pca$scores)) {
    bt_abort("`pca` must be output from `terrain_pca()`.")
  }
  ggplot2::ggplot(pca$scores, ggplot2::aes(x = .data[["PC1"]], y = .data[["PC2"]])) +
    ggplot2::geom_point() +
    ggplot2::labs(x = "PC1", y = "PC2")
}

#' Plot a depth profile
#'
#' @description
#' Plots depth or elevation values along a sampled profile.
#'
#' @param data A data frame.
#' @param distance_col Distance column name.
#' @param depth_col Depth or elevation column name. If `NULL`, the first numeric
#'   non-coordinate value column is used.
#' @param group_col Optional grouping column.
#' @param depth_increases_down Logical. If `TRUE`, positive-depth profiles are
#'   plotted with a reversed y-axis so larger depths appear lower in the panel.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   df <- data.frame(distance = 1:5, depth = -c(10, 12, 20, 25, 30))
#'   plot_depth_profile(df, depth_col = "depth")
#' }
#'
#' @seealso [sample_transects()]
#' @export
plot_depth_profile <- function(
    data,
    distance_col = "distance",
    depth_col = NULL,
    group_col = NULL,
    depth_increases_down = TRUE
) {
  optional_ggplot2()
  if (!is.data.frame(data) || !distance_col %in% names(data)) {
    bt_abort("`data` must contain `distance_col`.")
  }
  if (is.null(depth_col)) {
    numeric_cols <- names(data)[vapply(data, is.numeric, logical(1))]
    depth_col <- setdiff(numeric_cols, c(distance_col, "x", "y"))[1]
  }
  if (is.na(depth_col) || !depth_col %in% names(data)) {
    bt_abort("Could not identify a depth/value column.")
  }
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[distance_col]], y = .data[[depth_col]]))
  if (!is.null(group_col)) {
    if (!group_col %in% names(data)) {
      bt_abort("`group_col` was not found in `data`.")
    }
    p <- ggplot2::ggplot(
      data,
      ggplot2::aes(
        x = .data[[distance_col]],
        y = .data[[depth_col]],
        group = .data[[group_col]]
      )
    )
  }
  p <- p +
    ggplot2::geom_line(na.rm = TRUE) +
    ggplot2::labs(x = distance_col, y = depth_col)
  orient_depth_axis(p, data[[depth_col]], depth_increases_down)
}

#' Plot terrain summaries
#'
#' @description
#' Plots a summary column from [summarize_terrain()] or related functions.
#'
#' @param summary A summary data frame.
#' @param value Summary value column.
#' @param group Optional x-axis grouping column. Defaults to `zone_id` when
#'   present.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   df <- data.frame(zone_id = 1:3, slope_mean = c(5, 7, 2))
#'   plot_terrain_summary(df, value = "slope_mean")
#' }
#'
#' @seealso [summarize_terrain()]
#' @export
plot_terrain_summary <- function(summary, value, group = NULL) {
  optional_ggplot2()
  if (!is.data.frame(summary) || !value %in% names(summary)) {
    bt_abort("`summary` must contain `value`.")
  }
  if (is.null(group)) {
    group <- if ("zone_id" %in% names(summary)) "zone_id" else names(summary)[1]
  }
  ggplot2::ggplot(summary, ggplot2::aes(x = factor(.data[[group]]), y = .data[[value]])) +
    ggplot2::geom_col() +
    ggplot2::labs(x = group, y = value)
}

hillshade_plot_data <- function(x, max_cells = 10000) {
  shade <- derive_hillshade(first_layer(x))
  df <- raster_plot_data(shade, max_cells = max_cells)
  value_col <- setdiff(names(df), c("x", "y"))[1]
  values <- df[[value_col]]
  rng <- range(values, na.rm = TRUE)
  if (!all(is.finite(rng)) || diff(rng) == 0) {
    df$shadow_alpha <- 0
  } else {
    df$shadow_alpha <- 1 - ((values - rng[1]) / diff(rng))
    df$shadow_alpha <- pmin(pmax(df$shadow_alpha, 0), 1)
  }
  df[c("x", "y", "shadow_alpha")]
}

contour_plot_data <- function(x, contour_interval = NULL) {
  r <- first_layer(x)
  rng <- safe_global_range(r)
  if (!all(is.finite(rng)) || rng[1] == rng[2]) {
    return(NULL)
  }
  if (is.null(contour_interval)) {
    levels <- pretty(rng, n = 6)
    levels <- levels[levels >= rng[1] & levels <= rng[2]]
  } else {
    if (!is.numeric(contour_interval) || length(contour_interval) != 1 ||
        !is.finite(contour_interval) || contour_interval <= 0) {
      bt_abort("`contour_interval` must be one positive numeric value.")
    }
    start <- ceiling(rng[1] / contour_interval) * contour_interval
    end <- floor(rng[2] / contour_interval) * contour_interval
    if (!is.finite(start) || !is.finite(end) || start > end) {
      return(NULL)
    }
    levels <- seq(start, end, by = contour_interval)
  }
  levels <- unique(levels[is.finite(levels)])
  if (length(levels) == 0) {
    return(NULL)
  }
  contours <- try(terra::as.contour(r, levels = levels), silent = TRUE)
  if (inherits(contours, "try-error") || is.null(contours) || nrow(contours) == 0) {
    return(NULL)
  }
  vector_plot_data(contours)
}

label_source <- function(labels, vectors) {
  if (is.null(labels)) {
    if (!is.null(vectors)) {
      return(NULL)
    }
    return(NULL)
  }
  if (isTRUE(labels)) {
    return(vectors)
  }
  if (identical(labels, FALSE)) {
    return(NULL)
  }
  labels
}

vector_label_data <- function(x, label_field = NULL) {
  if (is.null(x)) {
    return(NULL)
  }
  v <- as_spatvector(x)
  centers <- suppressWarnings(terra::centroids(v))
  xy <- as.data.frame(terra::crds(centers))
  names(xy) <- c("x", "y")
  attrs <- as.data.frame(v)
  if (!is.null(label_field) && label_field %in% names(attrs)) {
    label <- attrs[[label_field]]
  } else {
    label <- seq_len(nrow(attrs))
  }
  tibble::tibble(
    x = xy$x,
    y = xy$y,
    label = as.character(label)
  )
}

orient_depth_axis <- function(plot, values, depth_increases_down = TRUE) {
  if (!isTRUE(depth_increases_down)) {
    return(plot)
  }
  values <- as.numeric(values)
  values <- values[is.finite(values)]
  if (length(values) == 0) {
    return(plot)
  }
  if (all(values >= 0)) {
    return(plot + ggplot2::scale_y_reverse())
  }
  plot
}
