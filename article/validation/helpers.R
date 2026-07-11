# Shared utilities for the article validation scripts.
#
# These scripts deliberately load the package from the source tree so results
# correspond to the checked-out implementation rather than an installed copy.

validation_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)))
  }
  normalizePath(file.path("article", "validation"), mustWork = TRUE)
}

validation_repo_root <- function() {
  normalizePath(file.path(validation_dir(), "..", ".."), mustWork = TRUE)
}

validation_results_dir <- function() {
  out <- file.path(validation_dir(), "results")
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  out
}

load_blueterra_source <- function() {
  if (!requireNamespace("pkgload", quietly = TRUE)) {
    stop("The validation scripts require pkgload to load the checked-out package source.", call. = FALSE)
  }
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("The validation scripts require terra.", call. = FALSE)
  }
  pkgload::load_all(validation_repo_root(), quiet = TRUE)
  invisible(TRUE)
}

numeric_tolerance <- function(reference, relative = 1e-8, absolute = 1e-10) {
  finite <- abs(as.numeric(reference)[is.finite(as.numeric(reference))])
  magnitude <- if (length(finite)) max(1, finite) else 1
  max(absolute, relative * magnitude, 128 * .Machine$double.eps * magnitude)
}

comparison_record <- function(
    test_id,
    category,
    actual,
    reference,
    reference_method,
    notes = "",
    edge_behavior = "",
    missing_value_behavior = "",
    relative_tolerance = 1e-8,
    absolute_tolerance = 1e-10
) {
  actual <- as.numeric(actual)
  reference <- as.numeric(reference)
  if (length(actual) != length(reference)) {
    stop("Actual and reference values must have equal length.", call. = FALSE)
  }
  same_missing_pattern <- identical(is.na(actual), is.na(reference))
  paired <- is.finite(actual) & is.finite(reference)
  n_compared <- sum(paired)
  max_abs_error <- if (n_compared) max(abs(actual[paired] - reference[paired])) else NA_real_
  tolerance <- numeric_tolerance(reference[paired], relative_tolerance, absolute_tolerance)
  pass <- same_missing_pattern && n_compared > 0 && is.finite(max_abs_error) && max_abs_error <= tolerance
  data.frame(
    test_id = test_id,
    category = category,
    reference_method = reference_method,
    n_values = length(actual),
    n_compared = n_compared,
    n_missing_actual = sum(is.na(actual)),
    n_missing_reference = sum(is.na(reference)),
    missing_pattern_matches = same_missing_pattern,
    reference_min = if (n_compared) min(reference[paired]) else NA_real_,
    reference_max = if (n_compared) max(reference[paired]) else NA_real_,
    observed_min = if (n_compared) min(actual[paired]) else NA_real_,
    observed_max = if (n_compared) max(actual[paired]) else NA_real_,
    max_abs_error = max_abs_error,
    tolerance = tolerance,
    pass = pass,
    edge_behavior = edge_behavior,
    missing_value_behavior = missing_value_behavior,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

scalar_record <- function(
    test_id,
    category,
    observed,
    reference,
    reference_method,
    notes = "",
    edge_behavior = "",
    missing_value_behavior = "",
    relative_tolerance = 1e-8,
    absolute_tolerance = 1e-10
) {
  observed <- as.numeric(observed)[[1]]
  reference <- as.numeric(reference)[[1]]
  tolerance <- numeric_tolerance(reference, relative_tolerance, absolute_tolerance)
  same_missing <- identical(is.na(observed), is.na(reference))
  max_abs_error <- if (is.finite(observed) && is.finite(reference)) abs(observed - reference) else NA_real_
  pass <- if (same_missing && is.na(observed)) {
    TRUE
  } else {
    same_missing && is.finite(max_abs_error) && max_abs_error <= tolerance
  }
  data.frame(
    test_id = test_id,
    category = category,
    reference_method = reference_method,
    n_values = 1L,
    n_compared = as.integer(is.finite(observed) && is.finite(reference)),
    n_missing_actual = as.integer(is.na(observed)),
    n_missing_reference = as.integer(is.na(reference)),
    missing_pattern_matches = same_missing,
    reference_min = reference,
    reference_max = reference,
    observed_min = observed,
    observed_max = observed,
    max_abs_error = max_abs_error,
    tolerance = tolerance,
    pass = pass,
    edge_behavior = edge_behavior,
    missing_value_behavior = missing_value_behavior,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

raster_values <- function(x) {
  terra::values(x, mat = FALSE)
}

interior_reference <- function(template, value) {
  nr <- terra::nrow(template)
  nc <- terra::ncol(template)
  if (nr < 3 || nc < 3) {
    stop("The analytical fixtures need at least a 3 by 3 raster.", call. = FALSE)
  }
  values <- matrix(NA_real_, nrow = nr, ncol = nc)
  values[2:(nr - 1), 2:(nc - 1)] <- value
  out <- template
  terra::values(out) <- as.vector(t(values))
  out
}

make_projected_raster <- function(nrows = 21, ncols = 21, resolution = 1) {
  terra::rast(
    nrows = nrows,
    ncols = ncols,
    xmin = 0,
    xmax = ncols * resolution,
    ymin = 0,
    ymax = nrows * resolution,
    crs = "EPSG:32620"
  )
}

make_plane <- function(template, ax = 2, ay = 1, intercept = 0) {
  xy <- terra::xyFromCell(template, seq_len(terra::ncell(template)))
  out <- template
  terra::values(out) <- intercept + ax * xy[, "x"] + ay * xy[, "y"]
  names(out) <- "plane"
  out
}

make_constant <- function(template, value = 5) {
  out <- template
  terra::values(out) <- rep(value, terra::ncell(out))
  names(out) <- "constant"
  out
}

make_bpi_fixture <- function() {
  template <- make_projected_raster(nrows = 7, ncols = 7, resolution = 1)
  values <- outer(seq_len(7), seq_len(7), function(i, j) 3 * i + 2 * j + i * j)
  values[4, 4] <- 75
  terra::values(template) <- as.vector(t(values))
  names(template) <- "bpi_fixture"
  list(raster = template, values = values, row = 4L, col = 4L)
}

annulus_weights <- function(raster, inner_radius, outer_radius) {
  resolution <- terra::res(raster)
  nx <- max(1L, ceiling(outer_radius / resolution[[1]]))
  ny <- max(1L, ceiling(outer_radius / resolution[[2]]))
  x_offsets <- seq(-nx, nx) * resolution[[1]]
  y_offsets <- seq(-ny, ny) * resolution[[2]]
  distances <- sqrt(outer(y_offsets^2, x_offsets^2, "+"))
  ifelse(distances <= outer_radius & distances >= inner_radius, 1, NA_real_)
}

manual_bpi_at <- function(values, row, col, weights, normalize = FALSE) {
  half_r <- (nrow(weights) - 1L) / 2L
  half_c <- (ncol(weights) - 1L) / 2L
  rows <- (row - half_r):(row + half_r)
  cols <- (col - half_c):(col + half_c)
  neighborhood <- values[rows, cols, drop = FALSE]
  used <- as.numeric(neighborhood[!is.na(weights)])
  center <- values[row, col]
  raw <- center - mean(used)
  if (!normalize) {
    return(list(value = raw, mean = mean(used), sd = stats::sd(used), n = length(used)))
  }
  list(value = raw / stats::sd(used), mean = mean(used), sd = stats::sd(used), n = length(used))
}

direct_bpi <- function(raster, weights, normalize = FALSE) {
  focal_mean <- terra::focal(raster, w = weights, fun = mean, na.rm = TRUE, na.policy = "omit")
  out <- raster - focal_mean
  if (isTRUE(normalize)) {
    focal_sd <- terra::focal(raster, w = weights, fun = stats::sd, na.rm = TRUE, na.policy = "omit")
    out <- terra::ifel(focal_sd > 0, out / focal_sd, NA)
  }
  out
}

direct_vrm <- function(raster, window = 3, neighbors = 8) {
  slope <- terra::terrain(raster, v = "slope", unit = "radians", neighbors = neighbors)
  aspect <- terra::terrain(raster, v = "aspect", unit = "radians", neighbors = neighbors)
  dx <- sin(slope) * cos(aspect)
  dy <- sin(slope) * sin(aspect)
  dz <- cos(slope)
  weights <- matrix(1, nrow = window, ncol = window)
  mdx <- terra::focal(dx, w = weights, fun = mean, na.rm = TRUE, na.policy = "omit")
  mdy <- terra::focal(dy, w = weights, fun = mean, na.rm = TRUE, na.policy = "omit")
  mdz <- terra::focal(dz, w = weights, fun = mean, na.rm = TRUE, na.policy = "omit")
  terra::clamp(1 - sqrt(mdx^2 + mdy^2 + mdz^2), lower = 0, upper = 1, values = TRUE)
}

write_session_info <- function(path = file.path(validation_results_dir(), "session-info.txt")) {
  packages <- c("blueterra", "terra", "pkgload", "exactextractr", "sf", "ggplot2", "rmarkdown", "pkgdown")
  versions <- vapply(
    packages,
    function(package) {
      if (requireNamespace(package, quietly = TRUE)) {
        as.character(utils::packageVersion(package))
      } else {
        NA_character_
      }
    },
    character(1)
  )
  commit <- tryCatch(
    system2("git", c("-C", shQuote(validation_repo_root()), "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
    error = function(error) NA_character_
  )
  if (!length(commit)) {
    commit <- NA_character_
  }
  lines <- c(
    paste("Repository:", validation_repo_root()),
    paste("Commit:", commit[[1]]),
    paste("Timestamp UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    paste("R:", R.version.string),
    paste("terra GDAL:", terra::gdal()),
    "",
    "Package versions:",
    paste(names(versions), versions, sep = " = "),
    "",
    capture.output(sessionInfo())
  )
  writeLines(lines, path)
  invisible(path)
}

write_validation_outputs <- function(prefix, results, details = list()) {
  out_dir <- validation_results_dir()
  csv_path <- file.path(out_dir, paste0(prefix, ".csv"))
  rds_path <- file.path(out_dir, paste0(prefix, ".rds"))
  utils::write.csv(results, csv_path, row.names = FALSE, na = "")
  saveRDS(list(results = results, details = details), rds_path)
  write_session_info()
  list(csv = csv_path, rds = rds_path)
}

write_results_readme <- function() {
  out_dir <- validation_results_dir()
  result_files <- c(
    analytical_validation = file.path(out_dir, "analytical_validation.csv"),
    wrapper_agreement = file.path(out_dir, "wrapper_agreement.csv"),
    functional_verification = file.path(out_dir, "functional_verification.csv")
  )
  present <- result_files[file.exists(result_files)]
  lines <- c(
    "# Executed validation results",
    "",
    "This file is regenerated by the validation scripts. It reports the current source checkout and should be retained with the CSV, RDS, and session artifacts.",
    ""
  )
  if (!length(present)) {
    lines <- c(lines, "No validation CSVs have been generated yet.")
  } else {
    lines <- c(lines, "## Summary", "")
    for (label in names(present)) {
      results <- utils::read.csv(present[[label]], check.names = FALSE)
      lines <- c(
        lines,
        sprintf("- `%s`: %d/%d passing checks; %d failures.", label, sum(results$pass), nrow(results), sum(!results$pass))
      )
    }
  }
  bpi_path <- file.path(out_dir, "bpi_center_inclusion.csv")
  if (file.exists(bpi_path)) {
    bpi <- utils::read.csv(bpi_path, check.names = FALSE)
    lines <- c(
      lines,
      "",
      "## BPI center-cell behavior",
      "",
      "| Scenario | Normalized | Center included | Cells | Expected center value | Observed center value | Pass |",
      "|---|---:|---:|---:|---:|---:|---:|"
    )
    lines <- c(lines, vapply(seq_len(nrow(bpi)), function(i) {
      row <- bpi[i, , drop = FALSE]
      sprintf(
        "| %s | %s | %s | %d | %.10g | %.10g | %s |",
        row$scenario,
        row$normalize,
        row$centre_included_by_weights,
        row$neighbourhood_cells,
        row$expected_centre_value,
        row$observed_centre_value,
        row$pass
      )
    }, character(1)))
  }
  lines <- c(
    lines,
    "",
    "## Interpretation boundary",
    "",
    "These checks establish numerical behavior and direct wrapper agreement for the tested implementation. They do not establish ecological, hydrodynamic, sedimentological, or habitat-prediction validity."
  )
  writeLines(lines, file.path(out_dir, "README.md"))
  invisible(file.path(out_dir, "README.md"))
}

stop_on_failed_results <- function(results, label) {
  if (any(!results$pass)) {
    failed <- results$test_id[!results$pass]
    stop(
      sprintf("%s completed with failed checks: %s", label, paste(failed, collapse = ", ")),
      call. = FALSE
    )
  }
  invisible(results)
}
