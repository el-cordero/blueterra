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
#' @param ... Additional arguments passed to `stats::prcomp()`.
#'
#' @return A list with `scores`, `loadings`, `variance`, and `model`.
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
    ...
) {
  mat <- numeric_matrix_from_data(data, vars = vars, na.rm = TRUE)
  if (ncol(mat) < 2) {
    bt_abort("PCA requires at least two numeric variables.")
  }
  fit <- stats::prcomp(mat, center = center, scale. = scale., ...)
  variance <- fit$sdev^2
  variance <- variance / sum(variance)
  list(
    scores = tibble::as_tibble(fit$x, rownames = "row_id"),
    loadings = tibble::as_tibble(fit$rotation, rownames = "variable"),
    variance = tibble::tibble(
      component = paste0("PC", seq_along(variance)),
      proportion = variance,
      cumulative = cumsum(variance)
    ),
    model = fit
  )
}

numeric_matrix_from_data <- function(data, vars = NULL, na.rm = TRUE) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  if (is.null(vars)) {
    vars <- names(data)[vapply(data, is.numeric, logical(1))]
  }
  vars <- setdiff(vars, c("x", "y", "ID", "zone_id"))
  if (length(vars) == 0 || !all(vars %in% names(data))) {
    bt_abort("No selected numeric variables were found.")
  }
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
