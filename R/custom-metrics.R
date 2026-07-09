#' Add metric layers to an existing raster stack
#'
#' @description
#' Combines precomputed metric rasters with an existing metric stack after
#' checking grid geometry.
#'
#' @param metrics A `terra::SpatRaster` metric stack or raster input accepted by
#'   [as_bathy()].
#' @param ... One or more `terra::SpatRaster` objects or local raster paths to
#'   add.
#' @param names Optional names for the added layers.
#' @param overwrite Logical. Allow added layers to replace layers with matching
#'   names in `metrics`.
#' @param check_geometry Logical. Require matching CRS, extent, resolution,
#'   dimensions, and origin.
#'
#' @return A combined `terra::SpatRaster`.
#'
#' @details
#' Custom metrics must be on the same raster grid as the stack they extend.
#' Geometry checks are enabled by default because summaries, PCA tables, and
#' process-group assignments assume cell-aligned layers.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' metrics <- derive_terrain(bathy, metrics = c("slope", "tri"))
#' index <- derive_custom_metric(metrics, "slope_tri_index", expression = quote(slope_deg * tri))
#' add_metric_layers(metrics, index)
#'
#' @seealso [derive_custom_metric()], [create_metric_catalog()]
#' @export
add_metric_layers <- function(
    metrics,
    ...,
    names = NULL,
    overwrite = FALSE,
    check_geometry = TRUE
) {
  base <- as_bathy(metrics, check = FALSE)
  validate_bathy(base, allow_multi = TRUE)
  additions <- list(...)
  if (length(additions) == 0) {
    bt_abort("Supply at least one raster layer to add.")
  }
  additions <- lapply(additions, function(layer) {
    out <- as_bathy(layer, check = FALSE)
    validate_bathy(out, allow_multi = TRUE)
    if (isTRUE(check_geometry) && !terra::compareGeom(base, out, stopOnError = FALSE)) {
      bt_abort("Added metric layers must match the geometry of `metrics`.")
    }
    out
  })
  added <- combine_rasters(additions)
  if (!is.null(names)) {
    if (!is.character(names) || length(names) != terra::nlyr(added)) {
      bt_abort("`names` must match the number of added raster layers.")
    }
    names(added) <- names
  }
  duplicate_added <- names(added)[duplicated(names(added))]
  if (length(duplicate_added) > 0) {
    bt_abort(paste0("Added metric names are duplicated: ", paste(unique(duplicate_added), collapse = ", ")))
  }
  duplicates <- intersect(names(base), names(added))
  if (length(duplicates) > 0) {
    if (!isTRUE(overwrite)) {
      bt_abort(paste0(
        "Metric layers already exist: ", paste(duplicates, collapse = ", "),
        ". Use `overwrite = TRUE` to replace them."
      ))
    }
    keep <- setdiff(names(base), duplicates)
    if (length(keep) == 0) {
      return(added)
    }
    base <- base[[keep]]
  }
  c(base, added)
}

#' Derive a custom metric from raster layers
#'
#' @description
#' Creates a single custom metric layer from an expression or a user-supplied R
#' function.
#'
#' @param metrics A `terra::SpatRaster` metric stack.
#' @param name Output layer name.
#' @param expression Optional quoted R expression evaluated with raster layers
#'   available by name.
#' @param fun Optional function called as `fun(metrics, ...)`. The function must
#'   return a single-layer `terra::SpatRaster`.
#' @param ... Additional arguments passed to `fun`.
#' @param overwrite Logical. Allow `name` to match an existing layer in
#'   `metrics`.
#'
#' @return A single-layer `terra::SpatRaster` named `name`.
#'
#' @details
#' Expressions must be quoted, for example
#' `quote(slope_deg * rugosity_vrm_3x3)`. Character strings are not evaluated.
#' This keeps the workflow explicit and avoids treating text as code.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' metrics <- derive_terrain(bathy, metrics = c("slope", "tri", "bpi"))
#' derive_custom_metric(metrics, "slope_tri_index", expression = quote(slope_deg * tri))
#'
#' relief <- derive_custom_metric(metrics, "relief_index", fun = function(r) {
#'   out <- r[["tri"]] + abs(r[["bpi_3x3"]])
#'   names(out) <- "relief_index"
#'   out
#' })
#' relief
#'
#' @seealso [add_metric_layers()]
#' @export
derive_custom_metric <- function(
    metrics,
    name,
    expression = NULL,
    fun = NULL,
    ...,
    overwrite = FALSE
) {
  r <- as_bathy(metrics, check = FALSE)
  validate_bathy(r, allow_multi = TRUE)
  if (!is.character(name) || length(name) != 1 || !nzchar(name)) {
    bt_abort("`name` must be one non-empty character value.")
  }
  if (name %in% names(r) && !isTRUE(overwrite)) {
    bt_abort("`name` already exists in `metrics`; use `overwrite = TRUE` to replace it.")
  }
  if (!is.null(expression) && !is.null(fun)) {
    bt_abort("Supply either `expression` or `fun`, not both.")
  }
  if (is.null(expression) && is.null(fun)) {
    bt_abort("Supply either `expression` or `fun`.")
  }

  if (!is.null(expression)) {
    if (is.character(expression)) {
      bt_abort("`expression` must be a quoted expression, not a character string.")
    }
    env <- new.env(parent = parent.frame())
    for (nm in names(r)) {
      env[[nm]] <- r[[nm]]
      env[[make.names(nm)]] <- r[[nm]]
    }
    out <- eval(expression, envir = env)
  } else {
    if (!is.function(fun)) {
      bt_abort("`fun` must be a function.")
    }
    out <- fun(r, ...)
  }

  if (!is_spatraster(out)) {
    bt_abort("Custom metric output must be a terra::SpatRaster.")
  }
  validate_bathy(out, allow_multi = TRUE)
  if (terra::nlyr(out) != 1) {
    bt_abort("Custom metric output must contain exactly one raster layer.")
  }
  if (!terra::compareGeom(r, out, stopOnError = FALSE)) {
    bt_abort("Custom metric output must match the geometry of `metrics`.")
  }
  names(out) <- name
  out
}

#' Create and validate metric catalog rows
#'
#' @description
#' Builds catalog rows for custom metrics and checks that metric catalogs follow
#' the schema used by [metric_catalog()].
#'
#' @param metric Metric layer name.
#' @param label Human-readable metric label.
#' @param process_group Process-group label.
#' @param description Metric description.
#' @param units Metric units.
#' @param source_function Function or workflow that produced the metric.
#' @param requires_optional_dependency Logical. Whether the metric requires an
#'   optional package.
#' @param scale_sensitive Logical. Whether the metric is sensitive to grid
#'   resolution or focal scale.
#' @param interpretation_notes Notes on interpretation.
#' @param catalog Existing metric catalog.
#' @param ... One or more catalog rows or tibbles to append.
#'
#' @return A tibble with the same columns as [metric_catalog()].
#'
#' @details
#' Custom process groups are user-defined terrain-form categories. The catalog
#' records how custom layers should be grouped and interpreted without changing
#' raster values.
#'
#' @examples
#' row <- create_metric_catalog(
#'   metric = "slope_tri_index",
#'   process_group = "custom_relief",
#'   description = "Product of local slope and terrain ruggedness index."
#' )
#' validate_metric_catalog(row)
#' extend_metric_catalog(metric_catalog(), row)
#'
#' @seealso [assign_process_groups()], [summarize_process_groups()]
#' @export
create_metric_catalog <- function(
    metric,
    label = metric,
    process_group,
    description = NA_character_,
    units = NA_character_,
    source_function = NA_character_,
    requires_optional_dependency = FALSE,
    scale_sensitive = TRUE,
    interpretation_notes = NA_character_
) {
  out <- tibble::tibble(
    metric = as.character(metric),
    label = as.character(label),
    process_group = as.character(process_group),
    description = as.character(description),
    units = as.character(units),
    source_function = as.character(source_function),
    requires_optional_dependency = as.logical(requires_optional_dependency),
    scale_sensitive = as.logical(scale_sensitive),
    interpretation_notes = as.character(interpretation_notes)
  )
  validate_metric_catalog(out)
}

#' @rdname create_metric_catalog
#' @export
extend_metric_catalog <- function(catalog = metric_catalog(), ...) {
  rows <- list(...)
  if (length(rows) == 0) {
    return(validate_metric_catalog(catalog))
  }
  rows <- lapply(rows, validate_metric_catalog)
  out <- dplyr::bind_rows(validate_metric_catalog(catalog), rows)
  validate_metric_catalog(out)
}

#' @rdname create_metric_catalog
#' @export
validate_metric_catalog <- function(catalog) {
  required <- c(
    "metric", "label", "process_group", "description", "units",
    "source_function", "requires_optional_dependency", "scale_sensitive",
    "interpretation_notes"
  )
  if (!is.data.frame(catalog)) {
    bt_abort("`catalog` must be a data frame.")
  }
  missing <- setdiff(required, names(catalog))
  if (length(missing) > 0) {
    bt_abort(paste0("Metric catalog is missing required columns: ", paste(missing, collapse = ", ")))
  }
  out <- catalog[required]
  char_cols <- setdiff(required, c("requires_optional_dependency", "scale_sensitive"))
  for (nm in char_cols) {
    out[[nm]] <- as.character(out[[nm]])
  }
  out$requires_optional_dependency <- as.logical(out$requires_optional_dependency)
  out$scale_sensitive <- as.logical(out$scale_sensitive)
  if (any(!nzchar(out$metric)) || any(!nzchar(out$process_group))) {
    bt_abort("`metric` and `process_group` must be non-empty.")
  }
  tibble::as_tibble(out)
}
