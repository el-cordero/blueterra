#!/usr/bin/env Rscript

# Generate Figures 1--6 from the documented BlueTopo Route-B example and
# executed package analyses. Vector linework is exported to PDF and all mixed
# raster/vector figures are additionally exported as 600 dpi RGB TIFF files.

suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(ggplot2)
  library(patchwork)
  library(ragg)
  library(rnaturalearth)
  library(pkgload)
})
suppressMessages(terra::projNetwork(FALSE))

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/figures/generate_figures_1_to_6.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
out_dir <- file.path(root, "article", "figures", "output")
data_dir <- file.path(root, "article", "figures", "data")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
set.seed(20260711)

okabe_ito <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9", "#000000")
divergent_low <- "#2166AC"
divergent_mid <- "#F7F7F7"
divergent_high <- "#B2182B"

figure_theme <- function() {
  theme_minimal(base_family = "Arial", base_size = 9) +
    theme(
      plot.margin = margin(4, 4, 4, 4),
      plot.title = element_text(size = 9, face = "bold", hjust = 0),
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
  ggplot2::ggsave(
    pdf_path, plot = plot, width = width, height = height, units = "in",
    device = grDevices::cairo_pdf, bg = "white"
  )
  ragg::agg_tiff(
    tif_path, width = width, height = height, units = "in", res = 600,
    compression = "lzw", background = "white"
  )
  print(plot)
  grDevices::dev.off()
  ragg::agg_png(png_path, width = width, height = height, units = "in", res = 300, background = "white")
  print(plot)
  grDevices::dev.off()
  data.frame(
    figure = name, pdf = pdf_path, tiff = tif_path, png = png_path,
    width_in = width, height_in = height, stringsAsFactors = FALSE
  )
}

raster_frame <- function(x, value_name = "value") {
  out <- as.data.frame(x, xy = TRUE, na.rm = FALSE)
  names(out)[3] <- value_name
  out
}

vector_paths <- function(x, id_field = NULL) {
  object <- sf::st_as_sf(x)
  coords <- sf::st_coordinates(object)
  feature <- if ("L1" %in% colnames(coords)) as.integer(coords[, "L1"]) else rep(1L, nrow(coords))
  part_cols <- intersect(c("L1", "L2", "L3"), colnames(coords))
  group <- apply(coords[, part_cols, drop = FALSE], 1, paste, collapse = "_")
  attrs <- sf::st_drop_geometry(object)
  label <- if (!is.null(id_field) && id_field %in% names(attrs)) as.character(attrs[[id_field]][feature]) else as.character(feature)
  data.frame(x = coords[, "X"], y = coords[, "Y"], group = group, id = label, stringsAsFactors = FALSE)
}

map_plot <- function(
    x, title, legend, midpoint = NULL, limits = NULL,
    scale_bar = FALSE, scale_length = 500
) {
  d <- raster_frame(x)
  ext <- terra::ext(x)
  p <- ggplot(d, aes(x = x, y = y, fill = value)) +
    geom_raster(interpolate = FALSE) +
    coord_equal(expand = FALSE) +
    labs(title = title, x = NULL, y = NULL, fill = legend) +
    figure_theme() +
    theme(
      axis.text = element_blank(), axis.ticks = element_blank(),
      panel.grid = element_blank(), legend.position = "bottom",
      legend.key.width = grid::unit(14, "mm"), legend.key.height = grid::unit(2.5, "mm")
    )
  if (is.null(midpoint)) {
    p <- p + scale_fill_viridis_c(option = "C", na.value = "transparent", guide = guide_colorbar(barwidth = grid::unit(25, "mm")))
  } else {
    p <- p + scale_fill_gradient2(
      low = divergent_low, mid = divergent_mid, high = divergent_high,
      midpoint = midpoint, limits = limits, oob = scales::squish, na.value = "transparent",
      guide = guide_colorbar(barwidth = grid::unit(25, "mm"))
    )
  }
  if (isTRUE(scale_bar)) {
    x0 <- ext[1] + 0.07 * (ext[2] - ext[1])
    y0 <- ext[3] + 0.08 * (ext[4] - ext[3])
    p <- p +
      annotate("segment", x = x0, xend = x0 + scale_length, y = y0, yend = y0, linewidth = 1.3, colour = "white") +
      annotate("segment", x = x0, xend = x0 + scale_length, y = y0, yend = y0, linewidth = 0.55, colour = "black") +
      annotate("text", x = x0 + scale_length / 2, y = y0 + 0.045 * (ext[4] - ext[3]), label = paste0(scale_length, " m"), size = 2.6, family = "Arial", colour = "black")
  }
  p
}

add_raster_panel_label <- function(plot, x, label) {
  ext <- terra::ext(x)
  plot + annotate(
    "label",
    x = ext[2] - 0.035 * (ext[2] - ext[1]),
    y = ext[4] - 0.055 * (ext[4] - ext[3]),
    label = label, family = "Arial", size = 3.0, linewidth = 0,
    fill = scales::alpha("white", 0.78)
  )
}

add_path <- function(plot, path, colour = "black", linewidth = 0.6, linetype = "solid", alpha = 1) {
  plot + geom_path(
    data = path, aes(x = x, y = y, group = group), inherit.aes = FALSE,
    colour = colour, linewidth = linewidth, linetype = linetype, alpha = alpha
  )
}

example_path <- file.path(root, "article", "data_provenance", "results", "bluetopo_bh54s4zb_elevation_example.tif")
zones_path <- file.path(root, "article", "data_provenance", "results", "bluetopo_author_analysis_windows.gpkg")
if (!file.exists(example_path) || !file.exists(zones_path)) {
  stop("Run article/data_provenance/acquire_bluetopo_example.R before figure generation.", call. = FALSE)
}
bathy <- terra::rast(example_path)
names(bathy) <- "elevation_m"
zones <- terra::vect(zones_path)
prepared <- prepare_bathy(bathy, smooth = FALSE)
terrain <- c(
  derive_slope(prepared, units = "degrees"),
  derive_bpi(prepared, window = 3L),
  derive_rugosity(prepared, window = 3L),
  derive_curvature(prepared),
  derive_surface_area_ratio(prepared)
)
names(terrain) <- c("slope_deg", "bpi_3x3", "rugosity_vrm_3x3", "laplacian_index", "surface_area_ratio")

# Figure 1: native vector architecture. The catalog is a metadata companion,
# not a required computational gateway.
nodes <- data.frame(
  id = c("input", "prepare", "stack", "analyses", "outputs", "catalog", "external"),
  x = c(0.8, 2.65, 4.65, 6.7, 8.8, 4.65, 4.65),
  y = c(2.55, 2.55, 2.55, 2.55, 2.55, 4.2, 0.85),
  label = c(
    "input\nraster", "preparation\nand conventions", "aligned\nmetric stack",
    "spatial analyses", "tables, maps,\nand profiles", "metric catalog\n(metadata)",
    "aligned custom\nor external layers"
  ),
  fill = c("#D9EAF7", "#D9EAF7", "#E6F2DF", "#FCE4D6", "#D9EAF7", "#FFF2CC", "#F4CCCC"),
  stringsAsFactors = FALSE
)
edges <- data.frame(
  from = c("input", "prepare", "stack", "analyses", "catalog", "external"),
  to = c("prepare", "stack", "analyses", "outputs", "stack", "stack"),
  linetype = c("solid", "solid", "solid", "solid", "dashed", "solid"),
  stringsAsFactors = FALSE
)
edges <- merge(edges, nodes[, c("id", "x", "y")], by.x = "from", by.y = "id")
edges <- merge(edges, nodes[, c("id", "x", "y")], by.x = "to", by.y = "id", suffixes = c("", "_end"))
fig1 <- ggplot() +
  geom_segment(
    data = edges, aes(x = x, y = y, xend = x_end, yend = y_end, linetype = linetype),
    arrow = grid::arrow(length = grid::unit(2.2, "mm")), linewidth = 0.55, colour = "#4D4D4D"
  ) +
  geom_label(
    data = nodes, aes(x = x, y = y, label = label, fill = fill), family = "Arial", size = 3.25,
    linewidth = 0.25, lineheight = 0.95, show.legend = FALSE
  ) +
  annotate("text", x = 4.65, y = 3.4, label = "terra-wrapped derivatives + local formulas", family = "Arial", size = 2.8, colour = "#333333") +
  annotate("text", x = 6.7, y = 1.55, label = "polygon and depth-band summaries • transects • isobath corridors", family = "Arial", size = 2.55, colour = "#333333") +
  scale_fill_identity() +
  scale_linetype_identity() +
  coord_cartesian(xlim = c(0, 9.6), ylim = c(0.1, 4.8), expand = FALSE) +
  theme_void(base_family = "Arial") + theme(plot.margin = margin(6, 6, 6, 6))

# Figure 2: Route-B BlueTopo example. All maps share the documented 4 m grid.
bpi_limit <- as.numeric(stats::quantile(abs(numeric_values <- terra::values(terrain[["bpi_3x3"]], mat = FALSE)), 0.98, na.rm = TRUE))
lap_limit <- as.numeric(stats::quantile(abs(terra::values(terrain[["laplacian_index"]], mat = FALSE)), 0.98, na.rm = TRUE))
elevation_map <- add_raster_panel_label(
  map_plot(prepared, "Elevation", "m", scale_bar = TRUE, scale_length = 500),
  prepared, "a"
)
location_bbox <- sf::st_as_sfc(sf::st_bbox(sf::st_transform(sf::st_as_sf(terra::as.polygons(terra::ext(bathy), crs = terra::crs(bathy))), 4326)))
puerto_rico <- rnaturalearth::ne_countries(country = "Puerto Rico", scale = "medium", returnclass = "sf")
location_inset <- ggplot() +
  geom_sf(data = puerto_rico, fill = "grey88", colour = "grey40", linewidth = 0.25) +
  geom_sf(data = location_bbox, fill = "#D55E00", colour = "#7F2704", linewidth = 0.3) +
  coord_sf(xlim = c(-67.4, -65.1), ylim = c(17.6, 18.65), expand = FALSE) +
  theme_void(base_family = "Arial") +
  theme(plot.background = element_rect(fill = scales::alpha("white", 0.9), colour = "grey40", linewidth = 0.25))
elevation_map <- elevation_map + patchwork::inset_element(location_inset, left = 0.05, bottom = 0.10, right = 0.45, top = 0.46, align_to = "panel", ignore_tag = TRUE)
fig2 <- patchwork::wrap_plots(
  list(
    elevation_map,
    add_raster_panel_label(map_plot(terrain[["slope_deg"]], "Slope", "degrees"), terrain[["slope_deg"]], "b"),
    add_raster_panel_label(map_plot(terrain[["bpi_3x3"]], "BPI (3 by 3)", "m", midpoint = 0, limits = c(-bpi_limit, bpi_limit)), terrain[["bpi_3x3"]], "c"),
    add_raster_panel_label(map_plot(terrain[["rugosity_vrm_3x3"]], "VRM-style rugosity (3 by 3)", "unitless"), terrain[["rugosity_vrm_3x3"]], "d"),
    add_raster_panel_label(map_plot(terrain[["laplacian_index"]], "Laplacian-style index", "m", midpoint = 0, limits = c(-lap_limit, lap_limit)), terrain[["laplacian_index"]], "e"),
    add_raster_panel_label(map_plot(terrain[["surface_area_ratio"]], "Surface-area ratio", "ratio"), terrain[["surface_area_ratio"]], "f")
  ),
  ncol = 3, byrow = TRUE
)

# Figure 3: catalog assignment plus actual structured summaries. No
# implementation-source matrix is repeated here because Table 1 provides it.
selected_metrics <- c("slope_deg", "bpi_3x3", "rugosity_vrm_3x3", "laplacian_index", "surface_area_ratio")
catalog_metrics <- ifelse(selected_metrics == "laplacian_index", "curvature", selected_metrics)
assignment <- assign_process_groups(catalog_metrics)
assignment$metric <- selected_metrics
metric_labels <- c(
  slope_deg = "Slope", bpi_3x3 = "Fine BPI", rugosity_vrm_3x3 = "VRM-style rugosity",
  laplacian_index = "Laplacian-style index", surface_area_ratio = "Surface-area ratio"
)
assignment$metric_label <- unname(metric_labels[assignment$metric])
assignment$process_label <- gsub("_", " ", assignment$process_group)
assignment$x <- seq_len(nrow(assignment))
catalog_plot <- ggplot(assignment, aes(x = x, y = 1, fill = process_label)) +
  geom_tile(colour = "white", linewidth = 0.8, height = 0.72) +
  geom_text(aes(label = metric_label), family = "Arial", size = 2.65, lineheight = 0.9) +
  geom_text(aes(y = 0.35, label = process_label), family = "Arial", size = 2.2, colour = "#333333") +
  scale_fill_manual(values = c(
    "slope gradient" = "#B3CDE3", "seafloor position" = "#FDCDAC",
    "seafloor rugosity" = "#CCEBC5", "curvature" = "#DECBE4"
  )) +
  scale_x_continuous(breaks = NULL) + scale_y_continuous(limits = c(0, 1.45), breaks = NULL) +
  labs(x = NULL, y = NULL, fill = "process group") + figure_theme() +
  theme(legend.position = "bottom", panel.grid = element_blank(), axis.text = element_blank(), axis.ticks = element_blank())
zone_paths <- vector_paths(zones, "zone_id")
zones_map <- add_path(map_plot(prepared, "Author-created analysis windows", "m"), zone_paths, colour = "white", linewidth = 0.8)
elevation_values <- terra::values(prepared, mat = FALSE)
slope_values <- terra::values(terrain[["slope_deg"]], mat = FALSE)
breaks <- c(-1200, -800, -400, -200, -80, 0)
bands <- cut(elevation_values, breaks = breaks, include.lowest = TRUE, right = FALSE)
band_levels <- levels(bands)
band_labels <- c("−1200 to −800", "−800 to −400", "−400 to −200", "−200 to −80", "−80 to 0")
band_counts <- as.data.frame(table(bands), stringsAsFactors = FALSE)
names(band_counts) <- c("depth_band", "n_cells")
band_counts$depth_band <- factor(band_counts$depth_band, levels = band_levels, labels = band_labels, ordered = TRUE)
band_frame <- data.frame(depth_band = bands, slope_deg = slope_values)
band_frame <- band_frame[is.finite(band_frame$slope_deg) & !is.na(band_frame$depth_band), , drop = FALSE]
if (nrow(band_frame) > 30000L) band_frame <- band_frame[sample(seq_len(nrow(band_frame)), 30000L), , drop = FALSE]
band_frame$depth_band <- factor(band_frame$depth_band, levels = band_levels, labels = band_labels, ordered = TRUE)
depth_plot <- ggplot(band_frame, aes(x = depth_band, y = slope_deg)) +
  geom_boxplot(fill = "#B3CDE3", colour = "#2166AC", outlier.shape = NA, linewidth = 0.35) +
  geom_point(data = aggregate(slope_deg ~ depth_band, band_frame, stats::median), aes(x = depth_band, y = slope_deg), shape = 21, fill = "white", colour = "black", size = 1.7, inherit.aes = FALSE) +
  geom_text(data = band_counts, aes(x = depth_band, y = Inf, label = paste0("n=", format(n_cells, big.mark = ","))), inherit.aes = FALSE, vjust = 1.25, size = 2.25, family = "Arial") +
  labs(x = "Elevation band (m)", y = "Slope (degrees)") + figure_theme() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
zone_summary <- summarize_terrain(terrain[[c("slope_deg", "bpi_3x3")]], zones, fun = c("mean", "median", "count"))
fig3 <- catalog_plot / (zones_map + depth_plot) + plot_layout(heights = c(0.72, 1.45)) + plot_annotation(tag_levels = "a")

# Figure 4: surface-derived transects. Cross-sections are explicitly reversed
# where necessary so distance begins at the shallower endpoint.
transect_zone <- zones[zones$zone_id == "slope_window", ]
transects <- make_transects(transect_zone, spacing = 250, bathy = prepared, orientation = "surface", orientation_weight = "slope")
profiles <- sample_transects(transects, prepared, n = 100L)
profile_value <- setdiff(
  names(profiles)[vapply(profiles, is.numeric, logical(1))],
  c("distance", "x", "y", "offset", "angle_deg", "mean_aspect_deg", "n_orientation_cells", "orientation_resultant_length")
)[1]
profiles <- do.call(rbind, lapply(split(profiles, profiles$transect_id), function(one) {
  one <- one[order(one$distance), , drop = FALSE]
  if (one[[profile_value]][1] < one[[profile_value]][nrow(one)]) {
    one <- one[nrow(one):1, , drop = FALSE]
    one$distance <- max(one$distance) - one$distance
    one <- one[order(one$distance), , drop = FALSE]
  }
  one$depth_m <- -one[[profile_value]]
  one
}))
profiles$transect_id <- factor(profiles$transect_id, levels = unique(profiles$transect_id))
transect_paths <- vector_paths(transects, "transect_id")
zone_path <- vector_paths(transect_zone)
transect_map <- add_path(map_plot(prepared, "Transects and source polygon", "m"), zone_path, colour = "white", linewidth = 0.95)
transect_map <- transect_map +
  geom_path(data = transect_paths, aes(x = x, y = y, group = group, colour = id), inherit.aes = FALSE, linewidth = 0.72) +
  scale_colour_manual(values = setNames(rep(okabe_ito, length.out = length(unique(transect_paths$id))), unique(transect_paths$id)), guide = "none")
profile_plot <- ggplot(profiles, aes(x = distance, y = depth_m, group = transect_id, colour = transect_id)) +
  geom_line(linewidth = 0.65, na.rm = TRUE) +
  scale_colour_manual(values = setNames(rep(okabe_ito, length.out = length(levels(profiles$transect_id))), levels(profiles$transect_id)), name = "transect") +
  scale_y_reverse() +
  labs(x = "Distance from shallow endpoint (m)", y = "Depth below MSL (m)") + figure_theme() +
  theme(legend.position = "bottom")
fig4 <- transect_map + profile_plot + plot_layout(widths = c(1.15, 1)) + plot_annotation(tag_levels = "a")

# Figure 5: source contours, one-sided buffers, and actual slope-value
# distributions by independent corridor.
corridor_depths <- c(-100, -300, -600)
isobaths <- extract_isobaths(prepared, depths = corridor_depths)
corridors <- make_isobath_corridors(prepared, depths = corridor_depths, width = 20)
corridor_paths <- vector_paths(corridors, "corridor_id")
isobath_paths <- vector_paths(isobaths, "depth_label")
corridor_map <- add_path(map_plot(prepared, "Isobath corridors", "m"), corridor_paths, colour = "#D55E00", linewidth = 0.75)
corridor_map <- add_path(corridor_map, isobath_paths, colour = "black", linewidth = 0.62, linetype = "dashed")
corridor_cells <- terra::extract(terrain[["slope_deg"]], corridors, ID = TRUE)
corridor_attr <- as.data.frame(corridors)
corridor_attr$ID <- seq_len(nrow(corridor_attr))
corridor_attr$area_m2 <- terra::expanse(corridors, unit = "m")
corridor_summary <- merge(corridor_attr, corridor_cells, by = "ID", all.y = TRUE)
corridor_summary$depth_label <- factor(corridor_summary$depth_label, levels = corridor_attr$depth_label[order(corridor_attr$depth_label)])
corridor_plot_data <- corridor_summary[is.finite(corridor_summary$slope_deg), , drop = FALSE]
if (nrow(corridor_plot_data) > 30000L) corridor_plot_data <- corridor_plot_data[sample(seq_len(nrow(corridor_plot_data)), 30000L), , drop = FALSE]
cell_counts <- aggregate(slope_deg ~ depth_label, corridor_summary, function(x) sum(is.finite(x)))
names(cell_counts)[2] <- "n_cells"
area_labels <- unique(corridor_attr[, c("depth_label", "area_m2")])
corridor_labels <- merge(cell_counts, area_labels, by = "depth_label")
corridor_labels$label <- paste0("n=", format(corridor_labels$n_cells, big.mark = ","), "\nA=", format(round(corridor_labels$area_m2 / 1e6, 3), nsmall = 3), " km²")
corridor_distribution <- ggplot(corridor_plot_data, aes(x = depth_label, y = slope_deg)) +
  geom_boxplot(fill = "#F4A582", colour = "#B2182B", outlier.shape = NA, linewidth = 0.35) +
  geom_point(data = aggregate(slope_deg ~ depth_label, corridor_plot_data, stats::median), aes(x = depth_label, y = slope_deg), shape = 21, fill = "white", colour = "black", size = 1.7, inherit.aes = FALSE) +
  geom_text(data = corridor_labels, aes(x = depth_label, y = Inf, label = label), inherit.aes = FALSE, vjust = 1.15, size = 2.25, family = "Arial") +
  labs(x = "Source isobath (m)", y = "Slope (degrees)") + figure_theme()
overlap_exists <- FALSE
if (nrow(corridors) > 1L) {
  pairs <- utils::combn(seq_len(nrow(corridors)), 2L)
  overlap_exists <- any(apply(pairs, 2L, function(index) nrow(suppressWarnings(terra::intersect(corridors[index[1], ], corridors[index[2], ]))) > 0L))
}
fig5 <- corridor_map + corridor_distribution + plot_layout(widths = c(1.15, 1)) + plot_annotation(tag_levels = "a")

# Figure 6: separated sensitivity evidence. Comparable BPI maps use identical
# symmetric limits; quantitative facets retain their own metric units.
sensitivity_path <- file.path(root, "article", "sensitivity", "results", "sensitivity_artifacts.rds")
if (!file.exists(sensitivity_path)) stop("Run article/sensitivity/run_sensitivity.R before Figure 6.", call. = FALSE)
sensitivity <- readRDS(sensitivity_path)
native_sens <- terra::rast(sensitivity$paths[["native_3"]])
smoothed_sens <- terra::rast(sensitivity$paths[["smoothed_3"]])
wide_sens <- terra::rast(sensitivity$paths[["native_11"]])
bpi_maps <- c(native_sens[["bpi"]], smoothed_sens[["bpi"]], wide_sens[["bpi"]])
sensitivity_bpi_limit <- as.numeric(stats::quantile(abs(terra::values(bpi_maps, mat = FALSE)), 0.98, na.rm = TRUE))
fig6_maps <- map_plot(native_sens[["bpi"]], "BPI: unsmoothed, 3 by 3", "m", midpoint = 0, limits = c(-sensitivity_bpi_limit, sensitivity_bpi_limit)) +
  map_plot(smoothed_sens[["bpi"]], "BPI: 3 by 3 smoothing, 3 by 3", "m", midpoint = 0, limits = c(-sensitivity_bpi_limit, sensitivity_bpi_limit)) +
  map_plot(wide_sens[["bpi"]], "BPI: unsmoothed, 11 by 11", "m", midpoint = 0, limits = c(-sensitivity_bpi_limit, sensitivity_bpi_limit))
sens <- sensitivity$sensitivity
quant <- sens[
  sens$scenario_class %in% c("grid resolution", "preprocessing", "focal neighborhood") &
    sens$metric %in% c("slope_deg", "bpi", "vrm"),
  , drop = FALSE
]
quant$scenario_short <- ifelse(
  quant$scenario_class == "grid resolution", "grid comparison",
  ifelse(quant$scenario_class == "preprocessing", "3 by 3 smoothing", "focal window")
)
metric_facet <- c(
  slope_deg = "Slope (degrees)", bpi = "BPI (m)", vrm = "VRM (unitless)"
)
quant$metric_label <- factor(unname(metric_facet[quant$metric]), levels = unname(metric_facet))
difference_plot <- ggplot(quant, aes(x = scenario_short, y = median_absolute_cellwise_difference, shape = scenario_class)) +
  geom_point(size = 2.4, colour = "#2166AC") +
  facet_wrap(~metric_label, scales = "free_y", ncol = 1) +
  scale_shape_manual(values = c("grid resolution" = 15, "preprocessing" = 16, "focal neighborhood" = 17), guide = "none") +
  labs(x = NULL, y = "Median absolute cellwise difference") + figure_theme() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1), strip.text = element_text(size = 8))
rho_plot <- ggplot(quant, aes(x = scenario_short, y = spearman_rho, shape = scenario_class)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey55") +
  geom_point(size = 2.4, colour = "#D55E00") +
  facet_wrap(~metric_label, ncol = 1) +
  scale_shape_manual(values = c("grid resolution" = 15, "preprocessing" = 16, "focal neighborhood" = 17), guide = "none") +
  scale_y_continuous(limits = c(-1, 1), breaks = c(-1, 0, 1)) +
  labs(x = NULL, y = "Spearman's rho") + figure_theme() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1), strip.text = element_text(size = 8))
fig6 <- fig6_maps / (difference_plot + rho_plot) + plot_layout(heights = c(0.85, 1.35)) + plot_annotation(tag_levels = "a")

manifest <- do.call(rbind, list(
  save_figure(fig1, "Fig1_architecture_workflow", 7.1, 3.3),
  save_figure(fig2, "Fig2_end_to_end_terrain_workflow", 7.1, 5.6),
  save_figure(fig3, "Fig3_catalog_and_summaries", 7.1, 5.4),
  save_figure(fig4, "Fig4_transects_cross_sections", 7.1, 4.0),
  save_figure(fig5, "Fig5_isobath_corridors", 7.1, 4.0),
  save_figure(fig6, "Fig6_sensitivity", 7.1, 8.0)
))
utils::write.csv(manifest, file.path(out_dir, "figure_manifest.csv"), row.names = FALSE)
utils::write.csv(assignment, file.path(data_dir, "fig3_metric_catalog_assignment.csv"), row.names = FALSE)
utils::write.csv(band_counts, file.path(data_dir, "fig3_depth_band_counts.csv"), row.names = FALSE)
utils::write.csv(zone_summary, file.path(data_dir, "fig3_zone_summary.csv"), row.names = FALSE)
utils::write.csv(as.data.frame(transects), file.path(data_dir, "fig4_transects.csv"), row.names = FALSE)
utils::write.csv(profiles, file.path(data_dir, "fig4_profiles.csv"), row.names = FALSE)
utils::write.csv(corridor_summary, file.path(data_dir, "fig5_corridor_values.csv"), row.names = FALSE)
utils::write.csv(corridor_labels, file.path(data_dir, "fig5_corridor_summary.csv"), row.names = FALSE)
utils::write.csv(data.frame(corridors_overlap = overlap_exists, one_sided_buffer_m = 20, nominal_full_width_m = 40), file.path(data_dir, "fig5_corridor_overlap_status.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
message("Wrote revised Figures 1--6 to ", out_dir)
