#!/usr/bin/env Rscript

# Summarise numerical, wrapper, and functional verification in approximately
# ten main-text rows. The complete record is retained as a supplementary CSV.

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/tables/generate_table2.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
validation_dir <- file.path(root, "article", "validation", "results")
out_dir <- file.path(root, "article", "tables", "results")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

analytical <- utils::read.csv(file.path(validation_dir, "analytical_validation.csv"), stringsAsFactors = FALSE, check.names = FALSE)
wrapper <- utils::read.csv(file.path(validation_dir, "wrapper_agreement.csv"), stringsAsFactors = FALSE, check.names = FALSE)
functional <- utils::read.csv(file.path(validation_dir, "functional_verification.csv"), stringsAsFactors = FALSE, check.names = FALSE)
raw <- rbind(analytical, wrapper)

summarise_numeric <- function(pattern, label, reference, domain, edge) {
  rows <- raw[grepl(pattern, raw$test_id, ignore.case = TRUE), , drop = FALSE]
  max_error <- max(rows$max_abs_error, na.rm = TRUE)
  tolerance <- max(rows$tolerance, na.rm = TRUE)
  data.frame(
    metric_family = label,
    reference_behavior_or_comparator = reference,
    evaluated_domain = domain,
    edge_policy = edge,
    maximum_error = format(max_error, scientific = TRUE, digits = 3),
    tolerance = format(tolerance, scientific = TRUE, digits = 3),
    result = if (all(rows$pass)) "pass" else "fail",
    stringsAsFactors = FALSE
  )
}

functional_row <- function(pattern, label, reference, domain, edge) {
  rows <- functional[grepl(pattern, functional$test_id, ignore.case = TRUE), , drop = FALSE]
  data.frame(
    metric_family = label,
    reference_behavior_or_comparator = reference,
    evaluated_domain = domain,
    edge_policy = edge,
    maximum_error = "behavioral check",
    tolerance = "stated condition",
    result = if (all(rows$pass)) "pass" else "fail",
    stringsAsFactors = FALSE
  )
}

table2 <- rbind(
  summarise_numeric("slope|aspect|northness|eastness", "Slope, aspect, and directional transforms", "Analytical plane and direct terra calls", "21 by 21 m projected plane", "terra derivative outer ring missing"),
  summarise_numeric("roughness|tri|tpi", "Roughness, TRI, and TPI", "Analytical constant/planar surfaces and direct terra calls", "21 by 21 m synthetic rasters", "terra terrain outer ring missing"),
  summarise_numeric("bpi", "Square and annular BPI", "Manual focal calculation and direct focal reconstruction", "7 by 7 center-relief fixture", "partial BPI windows at edges; missing center remains missing"),
  summarise_numeric("rugosity", "VRM-style rugosity", "Constant/planar normals and transparent formula reconstruction", "21 by 21 m synthetic surfaces", "outer derivative ring missing; interior focal support can be partial"),
  summarise_numeric("curvature", "Four-neighbor Laplacian-style index", "Planar, convex, concave surfaces and focal-kernel reconstruction", "21 by 21 m synthetic surfaces", "outer focal ring missing"),
  summarise_numeric("surface_area", "Slope-derived surface-area ratio", "Analytical plane and slope-secant reconstruction", "21 by 21 m plane", "inherits slope support"),
  functional_row("annular_bpi|normalized_bpi|partial_focal", "BPI geometry, CRS, and normalization", "Known non-square annulus, geographic CRS guard, zero-variance and partial-support conditions", "2 by 4 m cells and 7 by 7 fixtures", "documented partial support"),
  functional_row("transect|aspect_resultant", "Transects and orientation reliability", "Known planar direction, clipped lines, spacing, and multimodal aspect resultant", "40--100 m projected synthetic surfaces", "clipped to source polygon"),
  functional_row("isobath|corridor", "Isobaths and corridors", "Synthetic ramp contour, buffer width, and independent-overlap behavior", "100 m projected ramp", "independent corridors may overlap"),
  functional_row("polygon|depth_band|exact|custom_layer|metric_catalog", "Spatial summaries and extension", "Known cell values, fractional coverage, geometry rejection, and unmatched catalog name", "1--2 cell and 20 by 20 m fixtures", "documented exact coverage weighting")
)

utils::write.csv(table2, file.path(out_dir, "table2_verification_summary.csv"), row.names = FALSE, na = "")
utils::write.csv(raw, file.path(out_dir, "table2_numeric_source_records.csv"), row.names = FALSE, na = "")
utils::write.csv(functional, file.path(out_dir, "table2_functional_source_records.csv"), row.names = FALSE, na = "")
writeLines(capture.output(utils::sessionInfo()), file.path(out_dir, "table2_sessionInfo.txt"))
message("Wrote concise Table 2 and complete supplementary records to ", out_dir)
