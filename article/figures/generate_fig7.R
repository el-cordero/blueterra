#!/usr/bin/env Rscript

# Figure 7: controlled synthetic surfaces, observed-versus-expected values,
# and maximum error relative to justified numerical tolerances. Exact zero
# differences remain at zero on a linear scale; no artificial log-scale floor
# is introduced.

suppressPackageStartupMessages({
  library(terra)
  library(ggplot2)
  library(patchwork)
  library(ragg)
})

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/figures/generate_fig7.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
source(file.path(root, "article", "validation", "helpers.R"))
load_blueterra_source()
out_dir <- file.path(root, "article", "figures", "output")
data_dir <- file.path(root, "article", "figures", "data")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

figure_theme <- function() {
  theme_minimal(base_family = "Arial", base_size = 9) +
    theme(
      plot.margin = margin(4, 4, 4, 4),
      plot.title = element_text(size = 9, face = "bold"),
      axis.title = element_text(size = 9),
      axis.text = element_text(size = 7.5, colour = "black"),
      legend.title = element_text(size = 8),
      legend.text = element_text(size = 7),
      strip.text = element_text(size = 8.5, face = "bold"),
      panel.grid.major = element_line(colour = "grey88", linewidth = 0.25),
      panel.grid.minor = element_blank()
    )
}

save_figure <- function(plot, name, width, height) {
  pdf_path <- file.path(out_dir, paste0(name, ".pdf"))
  tif_path <- file.path(out_dir, paste0(name, ".tiff"))
  png_path <- file.path(out_dir, paste0(name, ".png"))
  ggsave(pdf_path, plot = plot, width = width, height = height, units = "in", device = grDevices::cairo_pdf, bg = "white")
  ragg::agg_tiff(tif_path, width = width, height = height, units = "in", res = 600, compression = "lzw", background = "white")
  print(plot)
  grDevices::dev.off()
  ragg::agg_png(png_path, width = width, height = height, units = "in", res = 300, background = "white")
  print(plot)
  grDevices::dev.off()
  data.frame(figure = name, pdf = pdf_path, tiff = tif_path, png = png_path, width_in = width, height_in = height, stringsAsFactors = FALSE)
}

raster_map <- function(x, title, legend, midpoint = NULL) {
  d <- as.data.frame(x, xy = TRUE, na.rm = FALSE)
  names(d)[3] <- "value"
  p <- ggplot(d, aes(x = x, y = y, fill = value)) +
    geom_raster() + coord_equal(expand = FALSE) +
    labs(title = title, x = NULL, y = NULL, fill = legend) +
    figure_theme() +
    theme(axis.text = element_blank(), axis.ticks = element_blank(), panel.grid = element_blank(), legend.position = "bottom")
  if (is.null(midpoint)) {
    p + scale_fill_viridis_c(option = "C", na.value = "transparent")
  } else {
    limit <- as.numeric(stats::quantile(abs(d$value), 0.98, na.rm = TRUE))
    p + scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7", high = "#B2182B", midpoint = midpoint, limits = c(-limit, limit), oob = scales::squish, na.value = "transparent")
  }
}

template <- make_projected_raster(nrows = 21L, ncols = 21L, resolution = 1)
plane <- make_plane(template, ax = 2, ay = 1)
xy <- terra::xyFromCell(template, seq_len(terra::ncell(template)))
convex <- template
terra::values(convex) <- xy[, "x"]^2 + xy[, "y"]^2
names(convex) <- "convex"
bpi_fixture <- make_bpi_fixture()$raster

panel_a <- raster_map(plane, "Planar elevation", "stored units")
panel_b <- raster_map(derive_curvature(convex), "Convex-surface Laplacian index", "stored units", midpoint = 0)
panel_c <- raster_map(derive_bpi(bpi_fixture, window = 3L), "Centre-relief BPI", "stored units", midpoint = 0)

validation_dir <- file.path(root, "article", "validation", "results")
analytical <- utils::read.csv(file.path(validation_dir, "analytical_validation.csv"), stringsAsFactors = FALSE, check.names = FALSE)
wrapper <- utils::read.csv(file.path(validation_dir, "wrapper_agreement.csv"), stringsAsFactors = FALSE, check.names = FALSE)
functional <- utils::read.csv(file.path(validation_dir, "functional_verification.csv"), stringsAsFactors = FALSE, check.names = FALSE)

observed_cases <- c(
  "plane_slope_degrees", "plane_northness", "constant_roughness", "plane_tri",
  "plane_tpi", "constant_vrm_rugosity", "convex_laplacian_curvature", "plane_surface_area_ratio"
)
observed <- analytical[analytical$test_id %in% observed_cases, , drop = FALSE]
observed$label <- c(
  plane_slope_degrees = "Slope", plane_northness = "Northness", constant_roughness = "Roughness",
  plane_tri = "TRI", plane_tpi = "TPI", constant_vrm_rugosity = "VRM-style rugosity",
  convex_laplacian_curvature = "Laplacian-style index", plane_surface_area_ratio = "Surface-area ratio"
)[observed$test_id]
observed$expected <- observed$reference_max
observed$observed <- observed$observed_max
observed_plot <- ggplot(observed, aes(x = expected, y = observed, label = label)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey40") +
  geom_point(size = 2.6, shape = 21, fill = "#56B4E9", colour = "#0072B2") +
  ggrepel::geom_text_repel(size = 2.45, family = "Arial", max.overlaps = Inf, seed = 20260711) +
  labs(x = "Expected value", y = "Observed value") + figure_theme()

records <- rbind(analytical, wrapper)
records$family <- ifelse(
  grepl("slope|aspect|northness|eastness", records$test_id), "Slope and aspect",
  ifelse(grepl("roughness|tri|tpi", records$test_id), "Roughness, TRI, and TPI",
  ifelse(grepl("bpi", records$test_id), "BPI",
  ifelse(grepl("rugosity", records$test_id), "VRM-style rugosity",
  ifelse(grepl("curvature", records$test_id), "Laplacian-style index",
  ifelse(grepl("surface_area", records$test_id), "Surface-area ratio", "Hillshade"))))))
records$error_ratio <- ifelse(is.finite(records$max_abs_error) & is.finite(records$tolerance) & records$tolerance > 0, records$max_abs_error / records$tolerance, NA_real_)
ratio_summary <- aggregate(error_ratio ~ family, records, function(x) max(x, na.rm = TRUE))
ratio_summary$family <- factor(ratio_summary$family, levels = rev(c(
  "Slope and aspect", "Roughness, TRI, and TPI", "BPI", "VRM-style rugosity",
  "Laplacian-style index", "Surface-area ratio", "Hillshade"
)))
ratio_plot <- ggplot(ratio_summary, aes(x = error_ratio, y = family)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "#D55E00", linewidth = 0.5) +
  geom_segment(aes(x = 0, xend = error_ratio, yend = family), colour = "grey55", linewidth = 0.45) +
  geom_point(shape = 21, fill = "#009E73", colour = "#006D5B", size = 2.7) +
  scale_x_continuous(limits = c(0, 1.08), breaks = c(0, 0.5, 1)) +
  labs(x = "Maximum absolute error / tolerance", y = NULL) + figure_theme()

fig7 <- (panel_a + panel_b + panel_c) / (observed_plot + ratio_plot) +
  plot_layout(heights = c(0.95, 1.05)) + plot_annotation(tag_levels = "a")

manifest <- save_figure(fig7, "Fig7_validation_and_agreement", 7.1, 6.3)
utils::write.csv(manifest, file.path(out_dir, "figure7_manifest.csv"), row.names = FALSE)
utils::write.csv(records, file.path(data_dir, "fig7_validation_records.csv"), row.names = FALSE)
utils::write.csv(observed, file.path(data_dir, "fig7_observed_expected.csv"), row.names = FALSE)
utils::write.csv(ratio_summary, file.path(data_dir, "fig7_error_ratio_summary.csv"), row.names = FALSE)
utils::write.csv(functional, file.path(data_dir, "fig7_functional_verification_records.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "fig7_sessionInfo.txt"))
message("Wrote Figure 7 to ", out_dir)
