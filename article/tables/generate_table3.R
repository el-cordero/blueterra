#!/usr/bin/env Rscript

# Main-text Table 3 combines only the most informative sensitivity and timing
# results. Full sensitivity, benchmark, hash, and clean-environment records
# remain supplementary.

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/tables/generate_table3.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
out_dir <- file.path(root, "article", "tables", "results")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
sensitivity <- utils::read.csv(file.path(root, "article", "sensitivity", "results", "sensitivity_results.csv"), stringsAsFactors = FALSE, check.names = FALSE)
benchmark <- utils::read.csv(file.path(root, "article", "benchmark", "results", "table5_computational_evaluation.csv"), stringsAsFactors = FALSE, check.names = FALSE)

pick_sensitivity <- function(index, label, note) {
  row <- sensitivity[index, , drop = FALSE]
  data.frame(
    assessment = "Sensitivity",
    scenario = label,
    setting = paste(row$resolution, ";", row$smoothing, ";", row$focal_scale_metres),
    observed_result = sprintf("median absolute cellwise difference = %.3g %s; Spearman's rho = %.3f", row$median_absolute_cellwise_difference, row$units, row$spearman_rho),
    interpretation = note,
    stringsAsFactors = FALSE
  )
}

find_row <- function(class, metric, scenario_pattern = ".*") {
  which(sensitivity$scenario_class == class & sensitivity$metric == metric & grepl(scenario_pattern, sensitivity$scenario))[1]
}

sens_rows <- rbind(
  pick_sensitivity(find_row("grid resolution", "slope_deg"), "4 m versus 8 m derivative grid: slope", "The 8 m candidate was mean-aggregated, differentiated, then bilinearly resampled only for paired comparison; this is not a pure resolution effect."),
  pick_sensitivity(find_row("grid resolution", "bpi", "approximately constant"), "4 m 7-cell versus 8 m 3-cell BPI", "Focal side lengths were approximately matched at 28 versus 24 m before paired comparison."),
  pick_sensitivity(find_row("preprocessing", "bpi"), "No smoothing versus 3 by 3 mean smoothing: BPI", "A stated preprocessing choice changed local-position values; it was not treated as artefact correction."),
  pick_sensitivity(find_row("focal neighborhood", "bpi", "11-cell"), "3 by 3 versus 11 by 11 BPI at 4 m", "Focal side length increased from 12 to 44 m; neither scale is universally preferred."),
  pick_sensitivity(find_row("vertical sign", "bpi"), "Negative elevation versus positive depth: BPI", "The observed rho near -1 reflects sign inversion of stored-elevation differences, not a vertical-datum conversion.")
)

native_benchmark <- benchmark[benchmark$size_id == "native" & benchmark$output_storage_mode == "in-memory SpatRaster", , drop = FALSE][1, , drop = FALSE]
large_memory <- benchmark[benchmark$output_storage_mode == "in-memory SpatRaster", , drop = FALSE]
large_memory <- large_memory[which.max(large_memory$cell_count), , drop = FALSE]
large_file <- benchmark[benchmark$output_storage_mode == "file-backed GeoTIFF", , drop = FALSE]
large_file <- large_file[which.max(large_file$cell_count), , drop = FALSE]
bench_rows <- rbind(native_benchmark, large_memory, large_file)
bench_table <- data.frame(
  assessment = "Computation",
  scenario = paste0(format(bench_rows$cell_count, big.mark = ","), " cells; ", bench_rows$output_storage_mode),
  setting = paste(bench_rows$raster_dimensions, ";", bench_rows$metric_request, ";", bench_rows$repetitions, "timed repetitions after warm-up"),
  observed_result = sprintf(
    "median %.3g s (IQR %.3g s; range %.3g–%.3g s)",
    bench_rows$runtime_median_seconds, bench_rows$runtime_iqr_seconds,
    bench_rows$runtime_min_seconds, bench_rows$runtime_max_seconds
  ),
  interpretation = "Peak resident memory was not reported because an operating-system-level measurement method was unavailable; no R Vcell proxy was substituted.",
  stringsAsFactors = FALSE
)

table3 <- rbind(sens_rows, bench_table)
utils::write.csv(table3, file.path(out_dir, "table3_sensitivity_computational_summary.csv"), row.names = FALSE, na = "")
utils::write.csv(sensitivity, file.path(out_dir, "table3_full_sensitivity_records.csv"), row.names = FALSE, na = "")
utils::write.csv(benchmark, file.path(out_dir, "table3_full_benchmark_records.csv"), row.names = FALSE, na = "")
writeLines(capture.output(utils::sessionInfo()), file.path(out_dir, "table3_sessionInfo.txt"))
message("Wrote main-text Table 3 and detailed supplementary records to ", out_dir)
