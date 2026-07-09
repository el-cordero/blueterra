#' Plot bathymetry and terrain rasters
#'
#' @description
#' Creates quick `ggplot2` raster maps for bathymetry and derived terrain
#' metrics.
#'
#' @param x A raster-like object accepted by [as_bathy()].
#' @param metric Optional layer name or index.
#' @param max_cells Maximum raster cells used for plotting.
#'
#' @return A `ggplot` object.
#'
#' @details
#' Plotting functions require `ggplot2`, which is suggested rather than
#' imported. Large rasters are regularly sampled before plotting to keep
#' examples and interactive work responsive.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   bathy <- read_bathy(blueterra_example("bathy"))
#'   plot_bathy(bathy)
#' }
#'
#' @seealso [derive_terrain()], [plot_metric_stack()]
#' @export
plot_bathy <- function(x, max_cells = getOption("blueterra.max_plot_cells", 10000)) {
  plot_metric(x, metric = 1, max_cells = max_cells) +
    ggplot2::labs(fill = "Bathymetry")
}

#' @rdname plot_bathy
#' @export
plot_metric <- function(
    x,
    metric = NULL,
    max_cells = getOption("blueterra.max_plot_cells", 10000)
) {
  optional_ggplot2()
  r <- as_bathy(x, check = TRUE)
  if (!is.null(metric)) {
    r <- r[[metric]]
  } else if (terra::nlyr(r) > 1) {
    r <- r[[1]]
  }
  df <- raster_plot_data(r, max_cells = max_cells)
  value_col <- setdiff(names(df), c("x", "y"))[1]
  ggplot2::ggplot(df, ggplot2::aes(x = .data[["x"]], y = .data[["y"]])) +
    ggplot2::geom_raster(ggplot2::aes(fill = .data[[value_col]])) +
    ggplot2::coord_equal() +
    ggplot2::scale_fill_viridis_c(option = "C", na.value = NA) +
    ggplot2::labs(x = NULL, y = NULL, fill = value_col)
}

#' @rdname plot_bathy
#' @export
plot_hillshade <- function(x, max_cells = getOption("blueterra.max_plot_cells", 10000)) {
  r <- as_bathy(x, check = TRUE)
  if (!"hillshade" %in% names(r)) {
    r <- derive_hillshade(r)
  } else {
    r <- r[["hillshade"]]
  }
  plot_metric(r, max_cells = max_cells) +
    ggplot2::scale_fill_gradient(low = "black", high = "white", na.value = NA)
}

#' @rdname plot_bathy
#' @export
plot_metric_stack <- function(
    x,
    max_cells = getOption("blueterra.max_plot_cells", 10000)
) {
  optional_ggplot2()
  r <- as_bathy(x, check = TRUE)
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
    ggplot2::facet_wrap(ggplot2::vars(.data[["metric"]]), scales = "free") +
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
    group_col = NULL
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
  p + ggplot2::geom_line(na.rm = TRUE) + ggplot2::labs(x = distance_col, y = depth_col)
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
