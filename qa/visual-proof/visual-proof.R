`%||%` <- function(x, y) if (is.null(x)) y else x

script_path <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA_character_)
if (is.na(script_path)) {
  script_path <- file.path("qa", "visual-proof", "visual-proof.R")
}
root <- normalizePath(file.path(dirname(script_path), "../.."), mustWork = TRUE)
setwd(root)

initial_status <- try(system2("git", c("status", "--short"), stdout = TRUE), silent = TRUE)
if (inherits(initial_status, "try-error")) {
  initial_status <- character()
}
initial_dirty <- length(initial_status) > 0

fig_dir <- file.path("qa", "visual-proof", "figures")
shot_dir <- file.path("qa", "visual-proof", "screenshots")
log_dir <- file.path("qa", "visual-proof", "logs")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(shot_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
unlink(list.files(fig_dir, pattern = "[.]png$", full.names = TRUE))
unlink(list.files(shot_dir, pattern = "[.]png$", full.names = TRUE))

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
  if (file.exists(path)) {
    unlink(path)
  }
  ggplot2::ggsave(path, plot = plot, width = width, height = height, dpi = 160)
  path
}

geom_path_data <- function(x) {
  out <- as.data.frame(terra::geom(x))
  out$group <- paste(out$geom, out$part, sep = "_")
  out
}

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(quiet = TRUE)
} else {
  library(blueterra)
}
library(terra)
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("The visual proof requires ggplot2.", call. = FALSE)
}

examples <- blueterra_examples()
hitw <- read_bathy(blueterra_example("hitw"))
hoyo <- read_bathy(blueterra_example("hoyo"))
slope <- read_bathy(blueterra_example("slope"))
rectangles <- vect(blueterra_example("sampling_rectangles"))
hitw_rect <- rectangles[rectangles$site_id == "hitw", ]
hoyo_rect <- rectangles[rectangles$site_id == "hoyo", ]

prepared <- prepare_bathy(hitw, depth_range = c(-220, -25), smooth = TRUE)
metrics <- derive_terrain(
  prepared,
  metrics = c(
    "slope", "aspect", "northness", "eastness", "tri", "rugosity",
    "bpi", "curvature", "surface_area_ratio"
  )
)
slope_metrics <- derive_terrain(slope, metrics = c("slope", "tri", "bpi", "curvature"))
terrain_summary <- summarize_terrain(slope_metrics, rectangles, fun = c("mean", "sd", "min", "max"))
terrain_summary_plot <- terrain_summary[is.finite(terrain_summary$slope_deg_mean), , drop = FALSE]
depth_summary <- summarize_depth_bands(
  prepared,
  metrics = metrics,
  breaks = c(-220, -150, -100, -60, -30, -20)
)
depth_summary_plot <- depth_summary[
  depth_summary$metric == "slope_deg" & is.finite(depth_summary$mean),
  ,
  drop = FALSE
]
transects <- make_transects(hitw_rect, spacing = 75)
samples <- sample_transects(transects, prepared, n = 12)
samples_plot <- samples[is.finite(samples$focal_mean), , drop = FALSE]
isobaths <- extract_isobaths(prepared, depths = c(-50, -80, -120))
corridors <- make_isobath_corridors(prepared, depths = c(-50, -80, -120), width = 20)
corridor_summary <- summarize_isobath_terrain(metrics, corridors)

hoyo_prepared <- prepare_bathy(hoyo, depth_range = c(-220, -25), smooth = TRUE)
hoyo_metrics <- derive_terrain(hoyo_prepared, metrics = c("slope", "tri", "bpi", "curvature"))
hitw_cells <- sample_terrain_cells(
  metrics[[c("slope_deg", "tri", "bpi_3x3", "curvature")]],
  size = 50,
  method = "regular"
)
hitw_cells$site <- "Hole-in-the-Wall"
hoyo_cells <- sample_terrain_cells(
  hoyo_metrics[[c("slope_deg", "tri", "bpi_3x3", "curvature")]],
  size = 50,
  method = "regular"
)
hoyo_cells$site <- "Hoyo Terrace"
comparison <- rbind(hitw_cells, hoyo_cells)
pca <- terrain_pca(comparison, vars = c("slope_deg", "tri", "bpi_3x3", "curvature"))
corr <- terrain_correlation(comparison, vars = c("slope_deg", "tri", "bpi_3x3", "curvature"))
effect <- terrain_effect_size(comparison, group = "site", vars = c("slope_deg", "tri", "bpi_3x3", "curvature"))
process_summary <- summarize_process_groups(metrics)

rect_df <- geom_path_data(rectangles)
transect_df <- geom_path_data(transects)
isobath_df <- geom_path_data(isobaths)

figures <- character()
figures <- c(figures, save_plot(plot_bathy(hitw), "01-hitw-bathymetry.png"))
figures <- c(figures, save_plot(plot_bathy(hoyo), "02-hoyo-bathymetry.png"))
figures <- c(figures, save_plot(plot_bathy(slope), "03-slope-clip-bathymetry.png"))
figures <- c(figures, save_plot(
  plot_bathy(slope) +
    ggplot2::geom_path(
      data = rect_df,
      ggplot2::aes(x = x, y = y, group = group),
      inherit.aes = FALSE,
      color = "white",
      linewidth = 0.5
    ),
  "04-sampling-rectangles-over-bathymetry.png",
  width = 8,
  height = 4.5
))
figures <- c(figures, save_plot(plot_bathy(prepared), "05-prepared-depth-filtered-bathymetry.png"))
figures <- c(figures, save_plot(plot_hillshade(prepared), "06-hillshade.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "slope_deg"), "07-slope.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "northness"), "08-northness.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "rugosity_vrm_3x3"), "09-rugosity.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "bpi_3x3"), "10-bpi.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "curvature"), "11-curvature.png"))
figures <- c(figures, save_plot(plot_metric(metrics, "surface_area_ratio"), "12-surface-area-ratio.png"))
figures <- c(figures, save_plot(
  plot_metric_stack(metrics[[c("slope_deg", "tri", "bpi_3x3", "curvature")]]),
  "13-metric-stack-preview.png",
  width = 8,
  height = 5
))
figures <- c(figures, save_plot(
  ggplot2::ggplot(process_summary, ggplot2::aes(x = n_metrics, y = reorder(process_group, n_metrics))) +
    ggplot2::geom_col() +
    ggplot2::labs(x = "Metric count", y = "Process group"),
  "14-process-group-summary.png"
))
figures <- c(figures, save_plot(
  plot_terrain_summary(terrain_summary_plot, value = "slope_deg_mean", group = "site_id"),
  "15-sampling-rectangle-summary.png"
))
figures <- c(figures, save_plot(
  ggplot2::ggplot(depth_summary_plot, ggplot2::aes(x = depth_band, y = mean)) +
    ggplot2::geom_col() +
    ggplot2::labs(x = "Depth band", y = "Mean slope") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)),
  "16-depth-band-summary.png"
))
figures <- c(figures, save_plot(
  plot_bathy(prepared) +
    ggplot2::geom_path(
      data = transect_df,
      ggplot2::aes(x = x, y = y, group = group),
      inherit.aes = FALSE,
      color = "white",
      linewidth = 0.4
    ),
  "17-transects-over-bathymetry.png"
))
figures <- c(figures, save_plot(plot_cross_sections(samples_plot), "18-cross-sections.png"))
figures <- c(figures, save_plot(
  plot_bathy(prepared) +
    ggplot2::geom_path(
      data = isobath_df,
      ggplot2::aes(x = x, y = y, group = group),
      inherit.aes = FALSE,
      color = "white",
      linewidth = 0.5
    ),
  "19-isobaths-over-bathymetry.png"
))
figures <- c(figures, save_plot(plot_isobath_corridors(corridors, prepared), "20-isobath-corridors.png"))
figures <- c(figures, save_plot(
  ggplot2::ggplot(corridor_summary, ggplot2::aes(x = factor(contour_value), y = slope_deg_mean)) +
    ggplot2::geom_col() +
    ggplot2::labs(x = "Contour value", y = "Mean slope"),
  "21-isobath-terrain-summary.png"
))
figures <- c(figures, save_plot(plot_process_pca(pca), "22-pca-plot.png"))
figures <- c(figures, save_plot(
  ggplot2::ggplot(corr, ggplot2::aes(x = var1, y = var2, fill = correlation)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient2(limits = c(-1, 1)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = NULL, y = NULL, fill = "r"),
  "23-correlation-plot.png"
))

readme_result <- capture_command(
  rmarkdown::render(
    "README.Rmd",
    output_format = rmarkdown::github_document(html_preview = FALSE),
    clean = TRUE,
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  ),
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
  if (requireNamespace("devtools", quietly = TRUE)) {
    devtools::check(args = "--as-cran")
  },
  file.path(log_dir, "devtools-check.log")
)

tarball_result <- capture_command({
  old_tarballs <- list.files(pattern = "^blueterra_.*[.]tar[.]gz$")
  if (length(old_tarballs)) unlink(old_tarballs)
  system2("R", c("CMD", "build", "."), stdout = TRUE, stderr = TRUE)
}, file.path(log_dir, "r-cmd-build.log"))
tarballs <- list.files(pattern = "^blueterra_.*[.]tar[.]gz$")
tarball <- if (length(tarballs)) tarballs[[which.max(file.info(tarballs)$mtime)]] else NA_character_
tarball_size <- if (!is.na(tarball)) file.info(tarball)$size else NA_real_

tidy_path <- Sys.which("tidy")
tidy_log <- file.path(log_dir, "html-tidy.log")
tidy_status <- NA_integer_
if (nzchar(tidy_path) && file.exists("docs/index.html")) {
  tidy_result <- system2(tidy_path, c("-errors", "-q", "docs/index.html"), stdout = TRUE, stderr = TRUE)
  tidy_status <- attr(tidy_result, "status") %||% 0L
  writeLines(as.character(tidy_result), tidy_log)
} else {
  writeLines("HTML Tidy not available.", tidy_log)
}

xml_result <- capture_command(
  if (requireNamespace("xml2", quietly = TRUE) && dir.exists("docs")) {
    html_files <- list.files("docs", pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
    invisible(lapply(html_files, xml2::read_html))
    paste("Parsed", length(html_files), "HTML files with xml2.")
  },
  file.path(log_dir, "xml2-html.log")
)

screenshots <- character()
screenshot_note <- "Screenshot tooling was not available in this environment."
if (requireNamespace("webshot2", quietly = TRUE)) {
  screenshot_note <- "webshot2 was available."
  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    readme_html <- file.path(shot_dir, "README.html")
    try(
      rmarkdown::render(
        "README.Rmd",
        output_format = rmarkdown::html_document(),
        output_file = basename(readme_html),
        output_dir = shot_dir,
        quiet = TRUE
      ),
      silent = TRUE
    )
    if (file.exists(readme_html)) {
      out <- file.path(shot_dir, "24-readme-screenshot.png")
      webshot2::webshot(paste0("file://", normalizePath(readme_html)), out)
      screenshots <- c(screenshots, out)
    }
  }
  if (file.exists("docs/index.html")) {
    out <- file.path(shot_dir, "25-pkgdown-home-screenshot.png")
    webshot2::webshot(paste0("file://", normalizePath("docs/index.html")), out)
    screenshots <- c(screenshots, out)
  }
  if (file.exists("docs/reference/index.html")) {
    out <- file.path(shot_dir, "26-pkgdown-reference-screenshot.png")
    webshot2::webshot(paste0("file://", normalizePath("docs/reference/index.html")), out)
    screenshots <- c(screenshots, out)
  }
}

commit <- try(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), silent = TRUE)
if (inherits(commit, "try-error")) commit <- NA_character_
desc <- tools:::.read_description("DESCRIPTION")
example_sizes <- file.info(examples$path)$size
examples_for_report <- data.frame(
  name = examples$name,
  file = basename(examples$path),
  bytes = example_sizes,
  mb = round(example_sizes / 1e6, 3),
  stringsAsFactors = FALSE
)

report <- c(
  "# blueterra Visual Proof",
  "",
  paste("- Date/time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste("- Git commit:", commit[1]),
  paste("- Working tree dirty at proof start:", initial_dirty),
  if (initial_dirty) paste("- Dirty paths at proof start:", paste(initial_status, collapse = "; ")) else "- Dirty paths at proof start: none",
  paste("- R version:", R.version.string),
  paste("- Package version:", unname(desc["Version"])),
  paste("- System:", paste(Sys.info()[c("sysname", "release", "machine")], collapse = " ")),
  paste("- Package tarball:", tarball),
  paste("- Package tarball size:", tarball_size, "bytes"),
  paste("- Package tarball size:", round(tarball_size / 1e6, 3), "MB"),
  "",
  "## Example Files",
  "",
  paste(capture.output(print(examples_for_report)), collapse = "\n"),
  "",
  "## Commands Run",
  "",
  "- Rscript qa/visual-proof/visual-proof.R",
  "- rmarkdown::render('README.Rmd', output_format = github_document)",
  "- pkgdown::build_site(examples = FALSE, new_process = FALSE)",
  "- devtools::test()",
  "- devtools::check(args = \"--as-cran\")",
  "- R CMD build .",
  "",
  "## Figures",
  "",
  paste0("- [", basename(figures), "](figures/", basename(figures), ")"),
  "",
  "## Screenshots",
  "",
  if (length(screenshots)) paste0("- [", basename(screenshots), "](screenshots/", basename(screenshots), ")") else paste("- ", screenshot_note),
  "",
  "## Representative Outputs",
  "",
  "```",
  capture.output({
    print(bathy_info(hitw))
    print(bathy_info(hoyo))
    print(bathy_info(slope))
    print(rectangles)
    print(names(metrics))
    print(terrain_summary[, c("site_id", "site_name", "slope_deg_mean", "bpi_3x3_mean")])
    print(depth_summary[depth_summary$metric == "slope_deg", ])
    print(corridor_summary[, c("contour_value", "slope_deg_mean", "bpi_3x3_mean")])
    print(pca$variance)
    print(effect)
    print(corr)
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
  paste("- R CMD build ok:", tarball_result$ok),
  paste("- Log:", tarball_result$log),
  "",
  "## HTML Results",
  "",
  paste("- pkgdown build ok:", pkgdown_result$ok),
  paste("- xml2 HTML parse ok:", xml_result$ok),
  paste("- HTML Tidy path:", if (nzchar(tidy_path)) tidy_path else "not available"),
  paste("- HTML Tidy status:", tidy_status),
  paste("- HTML Tidy log:", tidy_log),
  "",
  "## Known Limitations",
  "",
  if (length(screenshots)) "- None for generated proof artifacts." else paste("- ", screenshot_note)
)

writeLines(report, file.path("qa", "visual-proof", "visual-proof.md"))
