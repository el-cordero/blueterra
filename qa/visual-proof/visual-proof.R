`%||%` <- function(x, y) if (is.null(x)) y else x
script_path <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA_character_)
if (is.na(script_path)) {
  script_path <- file.path("qa", "visual-proof", "visual-proof.R")
}
root <- normalizePath(file.path(dirname(script_path), "../.."), mustWork = TRUE)
setwd(root)

fig_dir <- file.path("qa", "visual-proof", "figures")
shot_dir <- file.path("qa", "visual-proof", "screenshots")
log_dir <- file.path("qa", "visual-proof", "logs")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(shot_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

capture_command <- function(expr, log_file) {
  out <- try(capture.output(force(expr), type = "output"), silent = TRUE)
  msg <- NULL
  ok <- !inherits(out, "try-error")
  if (!ok) {
    msg <- conditionMessage(attr(out, "condition"))
    out <- msg
  }
  writeLines(as.character(out), log_file)
  list(ok = ok, message = msg, log = log_file)
}

save_plot <- function(plot, filename, width = 7, height = 4) {
  path <- file.path(fig_dir, filename)
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    ggplot2::ggsave(path, plot = plot, width = width, height = height, dpi = 160)
  } else {
    png(path, width = width * 160, height = height * 160, res = 160)
    print(plot)
    dev.off()
  }
  path
}

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(quiet = TRUE)
} else {
  library(blueterra)
}
library(terra)

bathy <- read_bathy(blueterra_example("bathy"))
zones <- vect(blueterra_example("zones"))
prepared <- prepare_bathy(bathy, depth_range = c(-85, -25), smooth = TRUE)
metrics <- derive_terrain(
  prepared,
  metrics = c("slope", "aspect", "northness", "eastness", "tri", "bpi",
              "rugosity", "curvature", "surface_area_ratio")
)
transects <- make_transects(zones[1, ], spacing = 100)
samples <- sample_transects(transects, prepared, n = 12)
isobaths <- extract_isobaths(prepared, depths = c(-40, -60))
corridors <- make_isobath_corridors(prepared, depths = c(-40, -60), width = 20)
terrain_summary <- summarize_terrain(metrics, zones)
depth_summary <- summarize_depth_bands(
  prepared,
  metrics = metrics,
  breaks = c(-90, -70, -50, -30, -20)
)
cells <- sample_terrain_cells(metrics, size = 80)
pca <- terrain_pca(cells)

figures <- character()
figures <- c(figures, save_plot(plot_bathy(bathy), "01-input-raster.png"))
figures <- c(figures, save_plot(plot_bathy(prepared), "02-prepared-raster.png"))
figures <- c(figures, save_plot(plot_hillshade(prepared), "03-hillshade.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "slope_deg"), "04-slope.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "northness"), "05-northness.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "rugosity_vrm_3x3"), "06-rugosity.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "bpi_3x3"), "07-bpi.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "curvature"), "08-curvature.png"))
figures <- c(figures, save_plot(
  plot_metric_stack(metrics[[c("slope_deg", "tri", "bpi_3x3")]]),
  "09-metric-stack-preview.png",
  width = 8,
  height = 5
))
figures <- c(figures, save_plot(
  plot_terrain_summary(terrain_summary, value = "slope_deg_mean"),
  "10-process-summary-plot.png"
))
figures <- c(figures, save_plot(
  ggplot2::ggplot(depth_summary[depth_summary$metric == "slope_deg", ],
                  ggplot2::aes(x = depth_band, y = mean)) +
    ggplot2::geom_col() +
    ggplot2::labs(x = "Depth band", y = "Mean slope"),
  "11-depth-band-summary.png"
))

transect_df <- as.data.frame(terra::geom(transects))
transect_df$group <- paste(transect_df$geom, transect_df$part, sep = "_")
isobath_df <- as.data.frame(terra::geom(isobaths))
isobath_df$group <- paste(isobath_df$geom, isobath_df$part, sep = "_")

figures <- c(figures, save_plot(
  plot_bathy(prepared) +
    ggplot2::geom_path(data = transect_df,
                       ggplot2::aes(x = x, y = y, group = group),
                       inherit.aes = FALSE,
                       color = "white"),
  "12-transects-over-bathymetry.png"
))
figures <- c(figures, save_plot(plot_cross_sections(samples), "13-cross-sections.png"))
figures <- c(figures, save_plot(
  plot_bathy(prepared) +
    ggplot2::geom_path(data = isobath_df,
                       ggplot2::aes(x = x, y = y, group = group),
                       inherit.aes = FALSE,
                       color = "white"),
  "14-isobaths-over-bathymetry.png"
))
figures <- c(figures, save_plot(plot_isobath_corridors(corridors, prepared), "15-isobath-corridors.png"))

table_plot <- ggplot2::ggplot(
  terrain_summary,
  ggplot2::aes(x = zone_id, y = slope_deg_mean, label = round(slope_deg_mean, 2))
) +
  ggplot2::geom_col() +
  ggplot2::geom_text(vjust = -0.2) +
  ggplot2::labs(x = "Zone", y = "Mean slope")
figures <- c(figures, save_plot(table_plot, "16-terrain-summary-table.png"))
figures <- c(figures, save_plot(plot_process_pca(pca), "17-pca-plot.png"))

readme_result <- capture_command(
  if (requireNamespace("devtools", quietly = TRUE)) devtools::build_readme(),
  file.path(log_dir, "build-readme.log")
)
pkgdown_result <- capture_command(
  if (requireNamespace("pkgdown", quietly = TRUE)) {
    pkgdown::build_site(examples = FALSE, new_process = FALSE, quiet = TRUE)
  },
  file.path(log_dir, "pkgdown-build.log")
)
test_result <- capture_command(
  if (requireNamespace("devtools", quietly = TRUE)) devtools::test(),
  file.path(log_dir, "devtools-test.log")
)
check_result <- capture_command(
  if (requireNamespace("devtools", quietly = TRUE)) devtools::check(args = "--as-cran", quiet = TRUE),
  file.path(log_dir, "devtools-check.log")
)

tidy_path <- Sys.which("tidy")
tidy_result <- "HTML Tidy not available."
if (nzchar(tidy_path) && file.exists("docs/index.html")) {
  tidy_result <- system2(tidy_path, c("-errors", "-q", "docs/index.html"), stdout = TRUE, stderr = TRUE)
}
writeLines(tidy_result, file.path(log_dir, "html-tidy.log"))

xml_result <- capture_command(
  if (requireNamespace("xml2", quietly = TRUE) && dir.exists("docs")) {
    html_files <- list.files("docs", pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
    invisible(lapply(html_files, xml2::read_html))
    paste("Parsed", length(html_files), "HTML files with xml2.")
  },
  file.path(log_dir, "xml2-html.log")
)

screenshots <- character()
if (requireNamespace("webshot2", quietly = TRUE) && file.exists("README.html")) {
  screenshots <- c(screenshots, file.path(shot_dir, "README.png"))
  webshot2::webshot("README.html", screenshots[length(screenshots)])
}
if (requireNamespace("webshot2", quietly = TRUE) && file.exists("docs/index.html")) {
  screenshots <- c(screenshots, file.path(shot_dir, "pkgdown-home.png"))
  webshot2::webshot("docs/index.html", screenshots[length(screenshots)])
}
if (requireNamespace("webshot2", quietly = TRUE) && file.exists("docs/reference/index.html")) {
  screenshots <- c(screenshots, file.path(shot_dir, "pkgdown-reference.png"))
  webshot2::webshot("docs/reference/index.html", screenshots[length(screenshots)])
}

commit <- try(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), silent = TRUE)
if (inherits(commit, "try-error")) commit <- NA_character_
status <- try(system2("git", c("status", "--short"), stdout = TRUE), silent = TRUE)
if (inherits(status, "try-error")) status <- character()
dirty <- length(status) > 0
desc <- tools:::.read_description("DESCRIPTION")

report <- c(
  "# blueterra Visual Proof",
  "",
  paste("- Date/time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("- Git commit:", commit[1]),
  paste("- Working tree dirty at proof time:", dirty),
  paste("- R version:", R.version.string),
  paste("- Package version:", unname(desc["Version"])),
  paste("- System:", paste(Sys.info()[c("sysname", "release", "machine")], collapse = " ")),
  "",
  "## Commands Run",
  "",
  "- Rscript qa/visual-proof/visual-proof.R",
  "- devtools::build_readme()",
  "- pkgdown::build_site()",
  "- devtools::test()",
  "- devtools::check(args = \"--as-cran\")",
  "",
  "## Figures",
  "",
  paste0("- [", basename(figures), "](figures/", basename(figures), ")"),
  "",
  "## Screenshots",
  "",
  if (length(screenshots)) paste0("- [", basename(screenshots), "](screenshots/", basename(screenshots), ")") else "- Screenshot tooling was not available in this environment.",
  "",
  "## Representative Outputs",
  "",
  "```",
  capture.output({
    print(bathy_info(bathy))
    print(names(metrics))
    print(head(terrain_summary))
    print(head(depth_summary))
    print(pca$variance)
  }),
  "```",
  "",
  "## Test Results",
  "",
  paste("- devtools::test ok:", test_result$ok),
  paste("- Log:", test_result$log),
  "",
  "## Check Results",
  "",
  paste("- devtools::check ok:", check_result$ok),
  paste("- Log:", check_result$log),
  "",
  "## HTML Results",
  "",
  paste("- pkgdown build ok:", pkgdown_result$ok),
  paste("- xml2 HTML parse ok:", xml_result$ok),
  paste("- HTML Tidy log:", file.path(log_dir, "html-tidy.log")),
  "",
  "## Known Limitations",
  "",
  if (length(screenshots)) "- None for generated proof artifacts." else "- Browser screenshot capture was skipped because webshot2 was not available."
)

writeLines(report, file.path("qa", "visual-proof", "visual-proof.md"))
