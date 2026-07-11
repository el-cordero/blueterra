#!/usr/bin/env Rscript

# Reproducible computational assessment for the blueterra Software Article.
#
# The benchmark uses the documented BlueTopo elevation crop prepared by
# article/data_provenance/acquire_bluetopo_example.R.  Larger workloads are
# nearest-neighbour disaggregations of that exact crop and exist only to scale
# computational work; they are not additional observations and are not used in
# scientific maps or scale-sensitivity interpretation.
#
# Each configuration has one unrecorded warm-up and 20 timed repetitions.  The
# elapsed time covers metric derivation and forced output materialisation.  It
# excludes package loading and one-time input-workload construction.  The
# runtime environment prevents process-level RSS measurement (both `ps` and
# `/usr/bin/time -l` are restricted), so peak memory is deliberately omitted;
# R Vcell estimates are not used as a substitute.

suppressPackageStartupMessages({
  library(terra)
  library(pkgload)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/benchmark/run_benchmark.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
out_dir <- file.path(root, "article", "benchmark", "results")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

source_path <- file.path(
  root, "article", "data_provenance", "results",
  "bluetopo_bh54s4zb_elevation_example.tif"
)
manifest_path <- file.path(
  root, "article", "data_provenance", "results",
  "bluetopo_example_manifest.csv"
)
if (!file.exists(source_path) || !file.exists(manifest_path)) {
  stop(
    "The documented BlueTopo article raster and its manifest are required. Run ",
    "article/data_provenance/acquire_bluetopo_example.R first.",
    call. = FALSE
  )
}

pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
set.seed(20260711)

write_csv <- function(x, name) {
  utils::write.csv(x, file.path(out_dir, name), row.names = FALSE, na = "")
}

manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
manifest_value <- function(field) {
  value <- manifest$value[manifest$field == field]
  if (length(value) != 1L) NA_character_ else as.character(value[[1]])
}

format_number <- function(x) {
  format(signif(as.numeric(x), 3L), trim = TRUE, scientific = FALSE)
}

hardware_profile <- function() {
  lines <- try(system2("system_profiler", "SPHardwareDataType", stdout = TRUE, stderr = TRUE), silent = TRUE)
  if (inherits(lines, "try-error")) {
    return(list(
      hardware = "hardware profile unavailable",
      installed_memory_gb = NA_real_,
      raw = "system_profiler unavailable"
    ))
  }
  value_for <- function(label) {
    line <- grep(paste0("^[[:space:]]*", label, ":"), lines, value = TRUE)
    if (length(line) == 0L) return(NA_character_)
    trimws(sub("^[^:]*:", "", line[[1]]))
  }
  model <- value_for("Model Name")
  identifier <- value_for("Model Identifier")
  chip <- value_for("Chip")
  cores <- value_for("Total Number of Cores")
  memory <- value_for("Memory")
  memory_gb <- suppressWarnings(as.numeric(sub("[[:space:]]*GB.*$", "", memory)))
  hardware <- paste(
    c(
      if (!is.na(model)) model,
      if (!is.na(identifier)) paste0("(", identifier, ")"),
      if (!is.na(chip)) chip,
      if (!is.na(cores)) paste0(cores, " cores"),
      if (!is.na(memory)) paste0(memory, " installed RAM")
    ),
    collapse = "; "
  )
  list(hardware = hardware, installed_memory_gb = memory_gb, raw = lines)
}

available_memory_snapshot <- function() {
  lines <- try(system2("vm_stat", stdout = TRUE, stderr = TRUE), silent = TRUE)
  if (inherits(lines, "try-error") || length(lines) == 0L) {
    return(list(gb = NA_real_, method = "not available"))
  }
  page_line <- grep("page size of", lines, value = TRUE)
  page_size <- if (length(page_line) == 1L) {
    suppressWarnings(as.numeric(sub(".*page size of ([0-9]+) bytes.*", "\\1", page_line[[1]])))
  } else {
    NA_real_
  }
  pages_for <- function(label) {
    line <- grep(paste0("^", label, ":"), trimws(lines), value = TRUE)
    if (length(line) != 1L) return(NA_real_)
    suppressWarnings(as.numeric(gsub("[^0-9]", "", line[[1]])))
  }
  pages <- c(
    free = pages_for("Pages free"),
    inactive = pages_for("Pages inactive"),
    speculative = pages_for("Pages speculative")
  )
  if (!is.finite(page_size) || any(!is.finite(pages))) {
    return(list(gb = NA_real_, method = "not available"))
  }
  list(
    gb = sum(pages) * page_size / 1024^3,
    method = "macOS vm_stat snapshot: free + inactive + speculative pages; not a memory requirement"
  )
}

system_profile <- hardware_profile()
available_memory <- available_memory_snapshot()
os_lines <- try(system2("sw_vers", stdout = TRUE, stderr = TRUE), silent = TRUE)
operating_system <- if (inherits(os_lines, "try-error")) {
  paste(Sys.info()[c("sysname", "release", "machine")], collapse = " | ")
} else {
  paste(trimws(os_lines), collapse = "; ")
}

package_version <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) return(NA_character_)
  as.character(utils::packageVersion(pkg))
}
blueterra_version <- as.character(read.dcf(file.path(root, "DESCRIPTION"))[1L, "Version"])
dependency_versions <- paste(
  vapply(
    c("terra", "dplyr", "cli", "rlang", "tibble"),
    function(pkg) paste(pkg, package_version(pkg)),
    FUN.VALUE = character(1)
  ),
  collapse = "; "
)

source_raster <- terra::rast(source_path)
if (!terra::hasValues(source_raster)) {
  stop("The documented BlueTopo article raster contains no values.", call. = FALSE)
}
source_rows <- suppressWarnings(as.integer(manifest_value("study_rows")))
source_columns <- suppressWarnings(as.integer(manifest_value("study_columns")))
if (is.finite(source_rows) && is.finite(source_columns) &&
    (terra::nrow(source_raster) != source_rows || terra::ncol(source_raster) != source_columns)) {
  stop("BlueTopo article raster dimensions disagree with its provenance manifest.", call. = FALSE)
}

# Workload construction happens once before timing. The resulting temporary
# GeoTIFFs ensure every timed repetition reads a file-backed source raster.
work_dir <- file.path(tempdir(), paste0("blueterra_benchmark_", Sys.getpid()))
dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)

prepare_workload <- function(size_id, disaggregation_factor) {
  if (disaggregation_factor == 1L) {
    path <- source_path
    preparation <- "Documented BlueTopo elevation crop; no smoothing, vertical transformation, aggregation, or resampling."
  } else {
    path <- file.path(work_dir, paste0(size_id, "_input.tif"))
    scaled <- terra::disagg(
      terra::rast(source_path),
      fact = c(disaggregation_factor, disaggregation_factor),
      method = "near"
    )
    names(scaled) <- "elevation_m"
    terra::writeRaster(scaled, path, overwrite = TRUE, wopt = list(gdal = "COMPRESS=LZW"))
    preparation <- paste0(
      "Nearest-neighbour disaggregation of the documented BlueTopo crop by factor ",
      disaggregation_factor,
      " in each dimension for computational scaling only; not a new observation or scientific-resolution analysis."
    )
  }
  x <- terra::rast(path)
  data.frame(
    size_id = size_id,
    disaggregation_factor = as.integer(disaggregation_factor),
    input_path = normalizePath(path, mustWork = TRUE),
    rows = terra::nrow(x),
    columns = terra::ncol(x),
    cells = terra::ncell(x),
    grid_spacing_x_m = terra::res(x)[[1]],
    grid_spacing_y_m = terra::res(x)[[2]],
    input_storage_mode = "file-backed GeoTIFF",
    input_preparation = preparation,
    stringsAsFactors = FALSE
  )
}

workloads <- do.call(rbind, list(
  prepare_workload("native", 1L),
  prepare_workload("medium", 2L),
  prepare_workload("large", 4L)
))

metric_request <- paste(
  "slope; BPI at 3x3 and 11x11 cells; VRM-style rugosity;",
  "four-neighbor Laplacian-style index; slope-based surface-area ratio"
)
focal_windows <- "BPI 3x3 and 11x11 cells; VRM 3x3 cells; slope neighbors = 8"
output_layers_expected <- 6L
repetitions <- 20L
warmup_runs <- 1L
peak_memory_summary <- "Not reported"
peak_memory_method <- paste(
  "OS-level peak RSS was unavailable in this restricted execution environment;",
  "R Vcell estimates were intentionally not substituted."
)

derive_benchmark_stack <- function(x, filename = "") {
  derive_metric_stack(
    x,
    metrics = c("slope", "bpi", "rugosity", "curvature", "surface_area_ratio"),
    scales = c(3L, 11L),
    neighbors = 8L,
    filename = filename,
    overwrite = TRUE
  )
}

run_once <- function(workload, output_storage_mode, output_path = "") {
  x <- terra::rast(workload$input_path[[1]])
  gc(FALSE)
  started <- proc.time()[["elapsed"]]
  result <- if (identical(output_storage_mode, "file-backed GeoTIFF")) {
    derive_benchmark_stack(x, filename = output_path)
  } else {
    derive_benchmark_stack(x)
  }
  # Evaluate every requested output layer before stopping the clock.
  invisible(terra::global(result, "mean", na.rm = TRUE))
  elapsed <- proc.time()[["elapsed"]] - started
  output_in_memory <- all(terra::inMemory(result))
  output_file_bytes <- if (nzchar(output_path) && file.exists(output_path)) {
    as.numeric(file.info(output_path)$size)
  } else {
    NA_real_
  }
  output_layers <- terra::nlyr(result)
  if (output_layers != output_layers_expected) {
    stop(
      "The benchmark metric request produced ", output_layers,
      " layers; expected ", output_layers_expected, ".",
      call. = FALSE
    )
  }
  rm(x, result)
  gc(FALSE)
  data.frame(
    elapsed_seconds = as.numeric(elapsed),
    output_layers = as.integer(output_layers),
    output_in_memory = output_in_memory,
    output_file_bytes = output_file_bytes,
    stringsAsFactors = FALSE
  )
}

configs <- data.frame(
  size_id = c("native", "medium", "large", "large"),
  output_storage_mode = c(
    "in-memory SpatRaster", "in-memory SpatRaster",
    "in-memory SpatRaster", "file-backed GeoTIFF"
  ),
  stringsAsFactors = FALSE
)

run_rows <- list()
warmup_rows <- list()
row_index <- 1L
warmup_index <- 1L
for (config_index in seq_len(nrow(configs))) {
  config <- configs[config_index, , drop = FALSE]
  workload <- workloads[workloads$size_id == config$size_id, , drop = FALSE]
  if (nrow(workload) != 1L) {
    stop("Benchmark workload lookup failed.", call. = FALSE)
  }
  output_path <- if (identical(config$output_storage_mode[[1]], "file-backed GeoTIFF")) {
    file.path(work_dir, paste0(config$size_id[[1]], "_metric_stack.tif"))
  } else {
    ""
  }

  warmup <- run_once(workload, config$output_storage_mode[[1]], output_path)
  warmup_rows[[warmup_index]] <- cbind(
    config,
    workload[, setdiff(names(workload), c("size_id", "input_path")), drop = FALSE],
    warmup_elapsed_seconds = warmup$elapsed_seconds,
    output_layers = warmup$output_layers,
    output_in_memory = warmup$output_in_memory,
    output_file_bytes = warmup$output_file_bytes
  )
  warmup_index <- warmup_index + 1L

  for (repetition in seq_len(repetitions)) {
    run <- run_once(workload, config$output_storage_mode[[1]], output_path)
    run_rows[[row_index]] <- data.frame(
      benchmark_task = "metric-stack derivation and materialisation",
      size_id = config$size_id[[1]],
      repetition = repetition,
      warmup_excluded = TRUE,
      disaggregation_factor = workload$disaggregation_factor[[1]],
      rows = workload$rows[[1]],
      columns = workload$columns[[1]],
      cells = workload$cells[[1]],
      grid_spacing_x_m = workload$grid_spacing_x_m[[1]],
      grid_spacing_y_m = workload$grid_spacing_y_m[[1]],
      input_storage_mode = workload$input_storage_mode[[1]],
      input_preparation = workload$input_preparation[[1]],
      output_storage_mode_requested = config$output_storage_mode[[1]],
      output_layers = run$output_layers,
      output_in_memory = run$output_in_memory,
      output_file_bytes = run$output_file_bytes,
      metric_request = metric_request,
      focal_windows = focal_windows,
      elapsed_seconds = run$elapsed_seconds,
      peak_memory_summary = peak_memory_summary,
      peak_memory_method = peak_memory_method,
      stringsAsFactors = FALSE
    )
    row_index <- row_index + 1L
  }
}

runs_df <- do.call(rbind, run_rows)
warmups_df <- do.call(rbind, warmup_rows)

summarise_runs <- function(one_config) {
  elapsed <- one_config$elapsed_seconds
  runtime_median <- stats::median(elapsed)
  runtime_iqr <- stats::IQR(elapsed)
  runtime_min <- min(elapsed)
  runtime_max <- max(elapsed)
  first <- one_config[1L, , drop = FALSE]
  data.frame(
    task = first$benchmark_task,
    size_id = first$size_id,
    raster_dimensions = sprintf("%d x %d", first$rows, first$columns),
    cell_count = first$cells,
    grid_spacing_m = sprintf("%s x %s", format_number(first$grid_spacing_x_m), format_number(first$grid_spacing_y_m)),
    source_data = paste0(
      "NOAA BlueTopo BH54S4ZB_20251117 documented elevation crop; SHA-256 ",
      manifest_value("study_raster_sha256")
    ),
    input_preparation = first$input_preparation,
    input_storage_mode = first$input_storage_mode,
    output_layers = first$output_layers,
    metric_request = first$metric_request,
    focal_windows = first$focal_windows,
    output_storage_mode = first$output_storage_mode_requested,
    warmup_runs = warmup_runs,
    repetitions = nrow(one_config),
    runtime_median_seconds = runtime_median,
    runtime_iqr_seconds = runtime_iqr,
    runtime_min_seconds = runtime_min,
    runtime_max_seconds = runtime_max,
    runtime_summary = paste0(
      "median ", format_number(runtime_median), " s; IQR ", format_number(runtime_iqr),
      " s; range ", format_number(runtime_min), "–", format_number(runtime_max), " s"
    ),
    peak_memory_summary = peak_memory_summary,
    peak_memory_method = peak_memory_method,
    hardware = system_profile$hardware,
    installed_memory_gb = system_profile$installed_memory_gb,
    available_ram_gb_at_start = available_memory$gb,
    available_ram_method = available_memory$method,
    operating_system = operating_system,
    r_version = R.version.string,
    blueterra_version = blueterra_version,
    terra_version = package_version("terra"),
    dependency_versions = dependency_versions,
    stringsAsFactors = FALSE
  )
}

summary_groups <- split(
  runs_df,
  interaction(runs_df$size_id, runs_df$output_storage_mode_requested, drop = TRUE)
)
summary_df <- do.call(rbind, lapply(summary_groups, summarise_runs))
row.names(summary_df) <- NULL
summary_df <- summary_df[
  order(
    summary_df$cell_count,
    match(summary_df$output_storage_mode, c("in-memory SpatRaster", "file-backed GeoTIFF"))
  ),
  , drop = FALSE
]

metadata_df <- data.frame(
  field = c(
    "benchmark_task", "source_raster", "source_tile_id", "source_raster_sha256",
    "source_vertical_convention", "source_preprocessing", "random_seed",
    "warmup_runs_per_configuration", "timed_repetitions_per_configuration",
    "timing_scope", "peak_memory_summary", "peak_memory_method",
    "hardware", "installed_memory_gb", "available_ram_gb_at_start",
    "available_ram_method", "operating_system", "r_version", "blueterra_version",
    "terra_version", "dependency_versions"
  ),
  value = c(
    "metric-stack derivation and materialisation",
    normalizePath(source_path, mustWork = TRUE),
    manifest_value("tile_id"), manifest_value("study_raster_sha256"),
    manifest_value("vertical_convention"), manifest_value("preprocessing"),
    "20260711", as.character(warmup_runs), as.character(repetitions),
    "Metric derivation plus forced output materialisation; excludes package loading and one-time workload construction.",
    peak_memory_summary, peak_memory_method, system_profile$hardware,
    as.character(system_profile$installed_memory_gb), as.character(available_memory$gb),
    available_memory$method, operating_system, R.version.string, blueterra_version,
    package_version("terra"), dependency_versions
  ),
  stringsAsFactors = FALSE
)

write_csv(runs_df, "benchmark_runs.csv")
write_csv(warmups_df, "benchmark_warmup_runs.csv")
write_csv(summary_df, "table5_computational_evaluation.csv")
write_csv(metadata_df, "benchmark_metadata.csv")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
writeLines(capture.output(terra::gdal()), file.path(out_dir, "gdal.txt"))
writeLines(capture.output(terra::libVersion()), file.path(out_dir, "spatial_libraries.txt"))
writeLines(
  c(
    paste0("hardware=", system_profile$hardware),
    paste0("installed_memory_gb=", system_profile$installed_memory_gb),
    paste0("available_ram_gb_at_start=", available_memory$gb),
    paste0("available_ram_method=", available_memory$method),
    paste0("operating_system=", operating_system)
  ),
  file.path(out_dir, "system.txt")
)
writeLines(
  c(
    "Peak-memory result: not reported.",
    "Reason: the sandboxed execution environment did not permit OS-level RSS tools.",
    "The benchmark deliberately does not report R GC Vcell values as peak memory."
  ),
  file.path(out_dir, "memory_measurement_status.txt")
)
writeLines(
  c(
    "# Computational benchmark methods",
    "",
    "The task derived a six-layer metric stack from the documented BlueTopo elevation crop:",
    metric_request,
    "",
    "Three source-derived workloads were measured: the 751 x 1,001-cell documented crop,",
    "a factor-two nearest-neighbour disaggregation (1,502 x 2,002 cells), and a factor-four",
    "nearest-neighbour disaggregation (3,004 x 4,004 cells). Disaggregation was performed",
    "once before timing solely to create larger computational workloads; it was not used for",
    "scientific interpretation, map production, or scale-sensitivity results.",
    "",
    "Every configuration received one warm-up run followed by 20 timed repetitions. Timing",
    "started immediately before metric derivation and ended after all output layers were forced",
    "to materialise. Package loading and one-time workload preparation were excluded. The large",
    "workload was measured with both an in-memory output request and a file-backed GeoTIFF",
    "output request. Peak RSS was not reported because OS-level memory tools were unavailable",
    "in this execution environment; no R Vcell estimate was substituted."
  ),
  file.path(out_dir, "benchmark_methods.md")
)
unlink(work_dir, recursive = TRUE, force = TRUE)

message("Wrote benchmark results to ", out_dir)
