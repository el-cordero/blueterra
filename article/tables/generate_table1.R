#!/usr/bin/env Rscript

# Concise main-text Table 1. Definitions are sourced from executed package
# code and upstream terra documentation where the package delegates directly.

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/tables/generate_table1.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
out_dir <- file.path(root, "article", "tables", "results")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

table1 <- data.frame(
  metric = c(
    "Slope and aspect", "Northness and eastness", "Roughness", "Terrain ruggedness index (TRI)",
    "Topographic position index (TPI)", "Bathymetric position index (BPI)",
    "VRM-style rugosity", "Four-neighbor Laplacian-style index", "Slope-derived surface-area ratio"
  ),
  implementation_source = c(
    "terra::terrain wrappers", "Local cosine/sine transforms of terra aspect", "terra::terrain wrapper",
    "terra::terrain wrapper", "terra::terrain wrapper", "Local terra::focal formula",
    "Local slope/aspect normal-vector formula with terra::focal", "Local four-neighbor focal kernel",
    "Local slope-secant formula using terra slope"
  ),
  operational_definition = c(
    "Local steepness and downslope compass orientation using the selected terra neighborhood.",
    "cos(aspect) and sin(aspect), with aspect expressed in radians.",
    "Local maximum minus minimum elevation in terra's terrain neighborhood.",
    "terra's local terrain ruggedness index based on elevation differences.",
    "Focal value relative to terra's local neighborhood mean.",
    "Focal value minus focal-neighborhood mean; optional normalization divides by focal sample SD.",
    "1 minus the magnitude of the focal mean of slope/aspect-derived unit-normal components.",
    "Sum of four orthogonal neighbors minus four times the focal value.",
    "1/cos(local slope), after a lower cosine clamp of 1e-6."
  ),
  units = c(
    "degrees or radians", "unitless", "input vertical units", "input vertical units", "input vertical units",
    "input vertical units; normalized option unitless", "unitless", "input vertical units", "unitless ratio"
  ),
  neighbourhood_or_scale = c(
    "terra neighbors = 8 by default", "inherits aspect neighborhood", "terra default terrain neighborhood",
    "terra default terrain neighborhood", "terra default terrain neighborhood", "square 3 by 3 and 11 by 11 defaults; projected map-unit annulus optional",
    "odd square window; 3 by 3 default", "fixed 3 by 3 stencil", "inherits slope neighborhood"
  ),
  principal_interpretation_constraint = c(
    "Slope depends on grid spacing; aspect is circular and reverses after vertical-sign inversion.",
    "Directional transforms, not process measurements.",
    "Definition, grid resolution, and neighborhood support affect values.",
    "Compare only across compatible grid resolution and terrain support.",
    "Sign and interpretation depend on stored vertical convention.",
    "Square windows include the focal cell; map-unit annuli require a projected CRS and stated radii.",
    "Uses available normal-vector cells, but derivative boundaries can remain missing.",
    "Unscaled by cell dimensions; not plan, profile, mean, or Gaussian curvature.",
    "Approximation, not a triangulated or directly measured benthic surface area."
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(table1, file.path(out_dir, "table1_core_metric_definitions.csv"), row.names = FALSE, na = "")
writeLines(capture.output(utils::sessionInfo()), file.path(out_dir, "table1_sessionInfo.txt"))
message("Wrote concise Table 1 data to ", out_dir)
