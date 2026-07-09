#' Principal components analysis for terrain tables
#'
#' @description
#' Runs PCA on numeric terrain variables and returns tidy scores, loadings,
#' variance explained, and the fitted model.
#'
#' @param data A data frame.
#' @param vars Optional character vector of numeric variables.
#' @param center Logical passed to `stats::prcomp()`.
#' @param scale. Logical passed to `stats::prcomp()`.
#' @param metadata_cols Optional non-PCA columns appended to the score table.
#' @param keep_metadata Logical. Preserve non-PCA columns in `scores`.
#' @param ... Additional arguments passed to `stats::prcomp()`.
#'
#' @return A list with `scores`, `loadings`, `variance`, `model`, `vars`, and
#'   `complete_rows`.
#'
#' @details
#' Rows with incomplete values in selected variables are omitted before PCA.
#' PCA is descriptive and should be interpreted with scale, CRS, and sampling
#' design in mind.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' terrain <- derive_terrain(bathy, metrics = c("slope", "bpi", "roughness"))
#' cells <- sample_terrain_cells(terrain, size = 30)
#' terrain_pca(cells)
#'
#' @seealso [prepare_model_matrix()], [terrain_correlation()]
#' @export
terrain_pca <- function(
    data,
    vars = NULL,
    center = TRUE,
    scale. = TRUE,
    metadata_cols = NULL,
    keep_metadata = TRUE,
    ...
) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  vars <- resolve_numeric_vars(data, vars)
  mat <- as.matrix(data[, vars, drop = FALSE])
  storage.mode(mat) <- "double"
  complete_rows <- stats::complete.cases(mat)
  mat <- mat[complete_rows, , drop = FALSE]
  if (ncol(mat) < 2) {
    bt_abort("PCA requires at least two numeric variables.")
  }
  if (nrow(mat) == 0) {
    bt_abort("No complete rows are available for PCA.")
  }
  fit <- stats::prcomp(mat, center = center, scale. = scale., ...)
  variance <- fit$sdev^2
  variance <- variance / sum(variance)
  scores <- tibble::as_tibble(fit$x)
  scores$row_id <- which(complete_rows)
  scores <- scores[c("row_id", setdiff(names(scores), "row_id"))]
  if (isTRUE(keep_metadata)) {
    if (is.null(metadata_cols)) {
      metadata_cols <- setdiff(names(data), vars)
    } else {
      missing_cols <- setdiff(metadata_cols, names(data))
      if (length(missing_cols) > 0) {
        bt_abort(paste0("`metadata_cols` were not found: ", paste(missing_cols, collapse = ", ")))
      }
      metadata_cols <- setdiff(metadata_cols, vars)
    }
    metadata_cols <- setdiff(metadata_cols, names(scores))
    if (length(metadata_cols) > 0) {
      scores <- tibble::as_tibble(cbind(scores, data[complete_rows, metadata_cols, drop = FALSE]))
    }
  }
  list(
    scores = scores,
    loadings = tibble::as_tibble(fit$rotation, rownames = "variable"),
    variance = tibble::tibble(
      component = paste0("PC", seq_along(variance)),
      proportion = variance,
      cumulative = cumsum(variance)
    ),
    model = fit,
    vars = vars,
    complete_rows = complete_rows
  )
}

numeric_matrix_from_data <- function(data, vars = NULL, na.rm = TRUE) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  vars <- resolve_numeric_vars(data, vars)
  mat <- as.matrix(data[, vars, drop = FALSE])
  storage.mode(mat) <- "double"
  if (isTRUE(na.rm)) {
    mat <- mat[stats::complete.cases(mat), , drop = FALSE]
  }
  if (nrow(mat) == 0) {
    bt_abort("No complete rows are available.")
  }
  mat
}

resolve_numeric_vars <- function(data, vars = NULL) {
  if (is.null(vars)) {
    vars <- names(data)[vapply(data, is.numeric, logical(1))]
  }
  vars <- setdiff(vars, c("x", "y", "ID", "id", "zone_id", "cell"))
  missing <- setdiff(vars, names(data))
  if (length(missing) > 0) {
    bt_abort(paste0("Selected variables were not found: ", paste(missing, collapse = ", ")))
  }
  non_numeric <- vars[!vapply(data[, vars, drop = FALSE], is.numeric, logical(1))]
  if (length(non_numeric) > 0) {
    bt_abort(paste0("Selected variables must be numeric: ", paste(non_numeric, collapse = ", ")))
  }
  if (length(vars) == 0) {
    bt_abort("No selected numeric variables were found.")
  }
  vars
}

#' Label PCA axes with variance and dominant loadings
#'
#' @description
#' Builds axis labels for [plot_process_pca()] from a `terrain_pca()` object.
#'
#' @param pca Output from [terrain_pca()].
#' @param components Components to label.
#' @param top_n Number of high-loading variables included per component.
#' @param unique Logical. Avoid repeating the same dominant variable across
#'   component labels when possible.
#' @param include_variance Logical. Include percent variance explained.
#'
#' @return A named character vector of axis labels.
#'
#' @details
#' Variables are ranked by absolute loading for each component. These labels are
#' descriptive aids for ordination plots; they do not replace inspection of the
#' full loading table.
#'
#' @examples
#' df <- data.frame(a = rnorm(10), b = rnorm(10), c = rnorm(10))
#' pca_axis_labels(terrain_pca(df))
#'
#' @seealso [terrain_pca()], [plot_process_pca()]
#' @export
pca_axis_labels <- function(
    pca,
    components = c("PC1", "PC2"),
    top_n = 2,
    unique = TRUE,
    include_variance = TRUE
) {
  if (!is.list(pca) || is.null(pca$loadings)) {
    bt_abort("`pca` must be output from `terrain_pca()`.")
  }
  if (!is.numeric(top_n) || length(top_n) != 1 || top_n < 1) {
    bt_abort("`top_n` must be one positive numeric value.")
  }
  loadings <- pca$loadings
  if (!all(c("variable", components) %in% names(loadings))) {
    bt_abort("Requested PCA components were not found in `pca$loadings`.")
  }
  used <- character()
  labels <- stats::setNames(character(length(components)), components)
  for (component in components) {
    ranked <- loadings$variable[order(abs(loadings[[component]]), decreasing = TRUE)]
    if (isTRUE(unique)) {
      preferred <- setdiff(ranked, used)
      if (length(preferred) >= top_n) {
        ranked <- preferred
      }
    }
    chosen <- utils::head(ranked, as.integer(top_n))
    used <- unique(c(used, chosen))
    prefix <- component
    if (isTRUE(include_variance) && !is.null(pca$variance)) {
      prop <- pca$variance$proportion[pca$variance$component == component][1]
      if (is.finite(prop)) {
        prefix <- sprintf("%s (%.1f%%", component, 100 * prop)
      }
    }
    if (startsWith(prefix, paste0(component, " ("))) {
      labels[[component]] <- paste0(prefix, "; ", paste(chosen, collapse = ", "), ")")
    } else {
      labels[[component]] <- paste0(prefix, " (", paste(chosen, collapse = ", "), ")")
    }
  }
  labels
}

#' Run PCA overall and within groups
#'
#' @description
#' Fits one terrain PCA across all rows and one PCA within each group level.
#'
#' @param data A data frame.
#' @param group Character name of the grouping column.
#' @param vars Optional numeric variables used in PCA.
#' @param center,scale. Logical values passed to [terrain_pca()].
#' @param min_rows Minimum rows required for a group-specific PCA.
#' @param ... Additional arguments passed to [terrain_pca()].
#'
#' @return A named list with `overall` and `groups`. `groups` is a named list of
#'   PCA objects.
#'
#' @details
#' Group-specific PCA is useful for checking whether ordination structure is
#' dominated by one site or sampling frame. Groups with fewer than `min_rows`
#' rows are omitted with a warning.
#'
#' @examples
#' df <- data.frame(site = rep(c("a", "b"), each = 8), slope = rnorm(16),
#'                  tri = rnorm(16), bpi = rnorm(16))
#' terrain_pca_by_group(df, group = "site")
#'
#' @seealso [terrain_pca()], [plot_process_pca()]
#' @export
terrain_pca_by_group <- function(
    data,
    group,
    vars = NULL,
    center = TRUE,
    scale. = TRUE,
    min_rows = 5,
    ...
) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  if (!is.character(group) || length(group) != 1 || !group %in% names(data)) {
    bt_abort("`group` must be the name of a grouping column.")
  }
  if (!is.numeric(min_rows) || length(min_rows) != 1 || min_rows < 1) {
    bt_abort("`min_rows` must be one positive numeric value.")
  }
  overall <- terrain_pca(
    data,
    vars = vars,
    center = center,
    scale. = scale.,
    keep_metadata = TRUE,
    metadata_cols = group,
    ...
  )
  pieces <- split(data, data[[group]])
  groups <- list()
  skipped <- character()
  for (nm in names(pieces)) {
    piece <- pieces[[nm]]
    if (nrow(piece) < min_rows) {
      skipped <- c(skipped, nm)
      next
    }
    groups[[nm]] <- terrain_pca(
      piece,
      vars = vars,
      center = center,
      scale. = scale.,
      keep_metadata = TRUE,
      metadata_cols = group,
      ...
    )
  }
  if (length(skipped) > 0) {
    bt_warn(paste0("Skipped PCA groups with fewer than `min_rows` rows: ", paste(skipped, collapse = ", ")))
  }
  list(overall = overall, groups = groups)
}

#' Terrain effect sizes
#'
#' @description
#' Computes standardized differences between two groups for numeric terrain
#' variables.
#'
#' @param data A data frame.
#' @param group Character name of the grouping column.
#' @param vars Optional character vector of numeric variables.
#' @param method Effect-size method. Currently `"cohens_d"`.
#' @param ... Reserved for future methods.
#'
#' @return A tibble with one row per variable.
#'
#' @details
#' Cohen's d is computed as the difference in group means divided by pooled
#' standard deviation. Exactly two non-missing groups are required.
#'
#' @examples
#' df <- data.frame(group = rep(c("a", "b"), each = 5), slope = 1:10)
#' terrain_effect_size(df, group = "group", vars = "slope")
#'
#' @seealso [terrain_pca()]
#' @export
terrain_effect_size <- function(
    data,
    group,
    vars = NULL,
    method = "cohens_d",
    ...
) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  if (!is.character(group) || length(group) != 1 || !group %in% names(data)) {
    bt_abort("`group` must be the name of a grouping column.")
  }
  method <- match.arg(method, "cohens_d")
  if (is.null(vars)) {
    vars <- names(data)[vapply(data, is.numeric, logical(1))]
  }
  vars <- setdiff(vars, group)
  groups <- unique(stats::na.omit(data[[group]]))
  if (length(groups) != 2) {
    bt_abort("`terrain_effect_size()` requires exactly two groups.")
  }
  rows <- lapply(vars, function(v) {
    x1 <- data[data[[group]] == groups[1], v, drop = TRUE]
    x2 <- data[data[[group]] == groups[2], v, drop = TRUE]
    x1 <- x1[is.finite(x1)]
    x2 <- x2[is.finite(x2)]
    pooled <- sqrt(((length(x1) - 1) * stats::var(x1) + (length(x2) - 1) * stats::var(x2)) /
      (length(x1) + length(x2) - 2))
    d <- (mean(x1) - mean(x2)) / pooled
    tibble::tibble(
      variable = v,
      group_1 = as.character(groups[1]),
      group_2 = as.character(groups[2]),
      mean_1 = mean(x1),
      mean_2 = mean(x2),
      effect_size = d,
      method = method
    )
  })
  dplyr::bind_rows(rows)
}

#' Correlation table for terrain variables
#'
#' @description
#' Computes pairwise correlations among numeric terrain variables.
#'
#' @param data A data frame.
#' @param vars Optional character vector of numeric variables.
#' @param method Correlation method passed to `stats::cor()`.
#' @param use Missing-value handling passed to `stats::cor()`.
#'
#' @return A tibble with variable pairs and correlation coefficients.
#'
#' @examples
#' bathy <- read_bathy(blueterra_example("bathy"))
#' terrain <- derive_terrain(bathy, metrics = c("slope", "bpi", "roughness"))
#' cells <- sample_terrain_cells(terrain, size = 30)
#' terrain_correlation(cells)
#'
#' @seealso [terrain_pca()]
#' @export
terrain_correlation <- function(
    data,
    vars = NULL,
    method = "pearson",
    use = "pairwise.complete.obs"
) {
  mat <- numeric_matrix_from_data(data, vars = vars, na.rm = FALSE)
  corr <- stats::cor(mat, method = method, use = use)
  idx <- which(upper.tri(corr), arr.ind = TRUE)
  tibble::tibble(
    var1 = rownames(corr)[idx[, 1]],
    var2 = colnames(corr)[idx[, 2]],
    correlation = corr[idx]
  )
}

#' Prepare a model matrix from terrain data
#'
#' @description
#' Converts a terrain table to a numeric predictor matrix and optional response
#' vector.
#'
#' @param data A data frame.
#' @param vars Optional predictor variable names.
#' @param response Optional response column name.
#' @param scale Logical. If `TRUE`, center and scale predictors.
#' @param na.rm Logical. Remove incomplete rows.
#'
#' @return A list with `x`, `y`, and `data`.
#'
#' @examples
#' df <- data.frame(y = c(0, 1, 0), slope = c(1, 2, 3), bpi = c(0.2, 0.1, 0.4))
#' prepare_model_matrix(df, response = "y")
#'
#' @seealso [sample_terrain_cells()], [terrain_pca()]
#' @export
prepare_model_matrix <- function(
    data,
    vars = NULL,
    response = NULL,
    scale = FALSE,
    na.rm = TRUE
) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  mat <- numeric_matrix_from_data(data, vars = vars, na.rm = FALSE)
  keep <- rep(TRUE, nrow(data))
  if (isTRUE(na.rm)) {
    keep <- stats::complete.cases(mat)
    if (!is.null(response)) {
      keep <- keep & !is.na(data[[response]])
    }
  }
  x <- mat[keep, , drop = FALSE]
  if (isTRUE(scale)) {
    x <- scale(x)
  }
  y <- NULL
  if (!is.null(response)) {
    if (!response %in% names(data)) {
      bt_abort("`response` was not found in `data`.")
    }
    y <- data[[response]][keep]
  }
  list(x = x, y = y, data = data[keep, , drop = FALSE])
}

#' Balance samples across groups
#'
#' @description
#' Down-samples or samples with replacement so each group has the same number of
#' rows.
#'
#' @param data A data frame.
#' @param group Character name of the grouping column.
#' @param n Optional number of rows per group. Defaults to the smallest group
#'   size when `replace = FALSE`.
#' @param replace Logical. Sample with replacement.
#' @param seed Optional random seed.
#'
#' @return A tibble.
#'
#' @examples
#' df <- data.frame(group = rep(c("a", "b"), c(2, 5)), value = seq_len(7))
#' balance_samples(df, group = "group")
#'
#' @seealso [prepare_model_matrix()]
#' @export
balance_samples <- function(
    data,
    group,
    n = NULL,
    replace = FALSE,
    seed = NULL
) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  if (!is.character(group) || length(group) != 1 || !group %in% names(data)) {
    bt_abort("`group` must be the name of a grouping column.")
  }
  if (!is.null(seed)) {
    set.seed(seed)
  }
  groups <- split(seq_len(nrow(data)), data[[group]])
  if (is.null(n)) {
    n <- if (isTRUE(replace)) max(lengths(groups)) else min(lengths(groups))
  }
  rows <- unlist(lapply(groups, sample, size = n, replace = replace), use.names = FALSE)
  tibble::as_tibble(data[rows, , drop = FALSE])
}
