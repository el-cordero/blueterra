#' Terrain metric catalog data
#'
#' @description
#' A compact table describing the metrics returned by core `blueterra`
#' functions and their process-oriented interpretation groups.
#'
#' @format A tibble with columns:
#' \describe{
#'   \item{metric}{Stable metric name.}
#'   \item{label}{Human-readable label.}
#'   \item{process_group}{Process-oriented terrain group.}
#'   \item{description}{Metric description.}
#'   \item{units}{Expected units.}
#'   \item{source_function}{Function that derives the metric.}
#'   \item{requires_optional_dependency}{Whether an optional dependency is
#'   needed.}
#'   \item{scale_sensitive}{Whether interpretation depends on raster scale.}
#'   \item{interpretation_notes}{Important interpretation notes.}
#' }
#'
#' @details
#' Use [metric_catalog()] to retrieve this table in normal workflows.
#'
#' @keywords datasets
"metric_catalog_data"
