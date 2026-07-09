#' Terrain metric catalog
#'
#' @description
#' Returns a catalog of terrain metrics, labels, process groups, assumptions,
#' and source functions used by `blueterra`.
#'
#' @return A tibble with columns `metric`, `label`, `process_group`,
#'   `description`, `units`, `source_function`,
#'   `requires_optional_dependency`, `scale_sensitive`, and
#'   `interpretation_notes`.
#'
#' @details
#' The catalog is an interpretation aid, not a claim that terrain metrics
#' directly measure ecological or oceanographic processes. Groups such as
#' orientation, slope gradient, seafloor position, rugosity, surface structure,
#' and curvature describe terrain form. Transport or convergence interpretations
#' require separate validation and are not direct current or sediment-flux
#' measurements.
#'
#' @examples
#' metric_catalog()
#' process_groups()
#'
#' @seealso [derive_terrain()], [assign_process_groups()]
#' @export
metric_catalog <- function() {
  if (exists("metric_catalog_data", inherits = TRUE)) {
    return(get("metric_catalog_data", inherits = TRUE))
  }
  utils::data("metric_catalog_data", package = "blueterra", envir = environment())
  get("metric_catalog_data", envir = environment(), inherits = FALSE)
}

#' @rdname metric_catalog
#' @export
process_groups <- function() {
  unique(metric_catalog()$process_group)
}

#' Assign metrics to process groups
#'
#' @description
#' Matches raster layer names or character metric names to the metric catalog.
#'
#' @param x A `terra::SpatRaster`, character vector, or data frame with metric
#'   columns.
#' @param catalog Optional catalog table. Defaults to [metric_catalog()].
#' @param groups Optional named character vector mapping metric names to process
#'   groups. Supplied mappings override catalog matches for those metrics.
#' @param unmatched Character value assigned to unmatched metrics.
#'
#' @return A tibble with one row per supplied metric.
#'
#' @details
#' Matching uses standardized lower-case metric names. Unmatched metrics are
#' returned with `process_group = unmatched` so users can inspect custom layers.
#'
#' @examples
#' terrain <- derive_terrain(read_bathy(blueterra_example("bathy")))
#' assign_process_groups(terrain)
#'
#' @seealso [metric_catalog()], [summarize_process_groups()]
#' @export
assign_process_groups <- function(
    x,
    catalog = metric_catalog(),
    groups = NULL,
    unmatched = "unassigned"
) {
  catalog <- validate_metric_catalog(catalog)
  metric_names <- metric_names_from_input(x)
  clean_metric <- clean_layer_name(metric_names)
  catalog$metric_clean <- clean_layer_name(catalog$metric)
  idx <- match(clean_metric, catalog$metric_clean)
  out <- tibble::tibble(
    metric = metric_names,
    metric_standard = clean_metric,
    label = catalog$label[idx],
    process_group = catalog$process_group[idx],
    description = catalog$description[idx],
    source_function = catalog$source_function[idx],
    matched = !is.na(idx)
  )
  if (!is.null(groups)) {
    if (!is.character(groups) || is.null(names(groups))) {
      bt_abort("`groups` must be a named character vector.")
    }
    group_idx <- match(clean_metric, clean_layer_name(names(groups)))
    has_group <- !is.na(group_idx)
    out$process_group[has_group] <- unname(groups[group_idx[has_group]])
    out$matched[has_group] <- TRUE
    out$label[has_group & is.na(out$label)] <- out$metric[has_group & is.na(out$label)]
  }
  out$process_group[is.na(out$process_group)] <- unmatched
  out
}

metric_names_from_input <- function(x) {
  if (is_spatraster(x)) {
    return(names(x))
  }
  if (is.character(x)) {
    return(x)
  }
  if (is.data.frame(x)) {
    numeric_cols <- vapply(x, is.numeric, logical(1))
    return(names(x)[numeric_cols])
  }
  bt_abort("`x` must be a SpatRaster, character vector, or data frame.")
}

#' Select representative metrics for each process group
#'
#' @description
#' Chooses a small set of catalog metrics for process-oriented summaries.
#'
#' @param catalog Optional catalog table. Defaults to [metric_catalog()].
#' @param groups Optional process groups to retain.
#' @param metrics_available Optional vector of available metric names.
#' @param representatives Optional named character vector mapping process-group
#'   names to representative metric names.
#'
#' @return A tibble with one representative metric per process group.
#'
#' @details
#' The default representative is the first implemented metric in the catalog for
#' each process group. Users should review and override representatives based on
#' their raster resolution, focal scales, and scientific question.
#'
#' @examples
#' select_process_representatives()
#'
#' @seealso [metric_catalog()], [assign_process_groups()]
#' @export
select_process_representatives <- function(
    catalog = metric_catalog(),
    groups = NULL,
    metrics_available = NULL,
    representatives = NULL
) {
  catalog <- validate_metric_catalog(catalog)
  out <- catalog
  if (!is.null(groups)) {
    out <- out[out$process_group %in% groups, , drop = FALSE]
  }
  if (!is.null(metrics_available)) {
    out <- out[clean_layer_name(out$metric) %in% clean_layer_name(metrics_available), , drop = FALSE]
  }
  out <- out[order(out$process_group, out$metric), , drop = FALSE]
  keep <- !duplicated(out$process_group)
  out <- tibble::as_tibble(out[keep, , drop = FALSE])
  if (!is.null(representatives)) {
    if (!is.character(representatives) || is.null(names(representatives))) {
      bt_abort("`representatives` must be a named character vector.")
    }
    rows <- lapply(names(representatives), function(group_name) {
      metric_name <- representatives[[group_name]]
      row <- catalog[clean_layer_name(catalog$metric) == clean_layer_name(metric_name), , drop = FALSE]
      if (nrow(row) > 0) {
        row <- row[1, , drop = FALSE]
        row$process_group <- group_name
        return(row)
      }
      create_metric_catalog(
        metric = metric_name,
        label = metric_name,
        process_group = group_name,
        description = "User-defined representative metric.",
        source_function = NA_character_,
        scale_sensitive = NA
      )
    })
    out <- dplyr::bind_rows(out[!out$process_group %in% names(representatives), , drop = FALSE], rows)
  }
  tibble::as_tibble(out)
}

#' Summarize process group representation
#'
#' @description
#' Counts available metrics by process group.
#'
#' @param x A `terra::SpatRaster`, character vector, or data frame with metric
#'   columns.
#' @param catalog Optional catalog table. Defaults to [metric_catalog()].
#' @param groups Optional named character vector passed to
#'   [assign_process_groups()].
#'
#' @return A tibble with process group counts.
#'
#' @details
#' This function summarizes which process groups are represented by a metric
#' stack. It does not compute raster statistics; use [summarize_terrain()] for
#' spatial summaries.
#'
#' @examples
#' terrain <- derive_terrain(read_bathy(blueterra_example("bathy")))
#' summarize_process_groups(terrain)
#'
#' @seealso [assign_process_groups()], [summarize_terrain()]
#' @export
summarize_process_groups <- function(x, catalog = metric_catalog(), groups = NULL) {
  assigned <- assign_process_groups(x, catalog = catalog, groups = groups)
  pieces <- split(assigned$metric, assigned$process_group)
  tibble::tibble(
    process_group = names(pieces),
    n_metrics = lengths(pieces),
    metrics = vapply(pieces, paste, collapse = ", ", FUN.VALUE = character(1))
  )
}

#' Standardize or rename metric layers
#'
#' @description
#' Converts metric names to stable snake-case names or applies a user-supplied
#' dictionary.
#'
#' @param x A `terra::SpatRaster`, character vector, or data frame.
#' @param dictionary Optional named character vector. Names are old metric names;
#'   values are new metric names.
#'
#' @return An object of the same broad type as `x`.
#'
#' @details
#' Standardization is conservative and does not change raster values. Use this
#' helper to make layer names predictable before joining to the metric catalog or
#' exporting model-ready tables.
#'
#' @examples
#' standardize_metric_names(c("Slope (deg)", "Broad BPI"))
#'
#' @seealso [metric_catalog()]
#' @export
standardize_metric_names <- function(x) {
  if (is_spatraster(x)) {
    names(x) <- clean_layer_name(names(x))
    return(x)
  }
  if (is.character(x)) {
    return(clean_layer_name(x))
  }
  if (is.data.frame(x)) {
    names(x) <- clean_layer_name(names(x))
    return(x)
  }
  bt_abort("`x` must be a SpatRaster, character vector, or data frame.")
}

#' @rdname standardize_metric_names
#' @export
rename_metric_layers <- function(x, dictionary = NULL) {
  if (is.null(dictionary)) {
    return(standardize_metric_names(x))
  }
  if (is.null(names(dictionary))) {
    bt_abort("`dictionary` must be a named character vector.")
  }
  rename_values <- function(values) {
    idx <- match(values, names(dictionary))
    values[!is.na(idx)] <- dictionary[idx[!is.na(idx)]]
    values
  }
  if (is_spatraster(x)) {
    names(x) <- rename_values(names(x))
    return(x)
  }
  if (is.character(x)) {
    return(rename_values(x))
  }
  if (is.data.frame(x)) {
    names(x) <- rename_values(names(x))
    return(x)
  }
  bt_abort("`x` must be a SpatRaster, character vector, or data frame.")
}
