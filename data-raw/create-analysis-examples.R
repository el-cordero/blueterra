## Regenerate package example data from the local geomorphometry project.
##
## This script is for maintainers. It reads local analysis rasters and sampling
## rectangles from study sites along the southwest Puerto Rico shelf margin near
## La Parguera, writes reduced CRAN-safe examples to inst/extdata, and reports
## file sizes. The installed package never uses these source paths.

library(terra)

project_dir <- "/Users/ec/Documents/Data/MCE Geomorphometry HW v HY/Geomorphic_Analysis_Project"

source_rasters <- c(
  hitw = file.path(
    project_dir,
    "data/raw/bathymetry/site_clips/Hole_In_the_Wall_bathy.tif"
  ),
  hoyo = file.path(
    project_dir,
    "data/raw/bathymetry/site_clips/Hoyo_Terrace_bathy.tif"
  ),
  slope = file.path(
    project_dir,
    "data/raw/bathymetry/site_clips/Slope_clip_bathy.tif"
  )
)

sampling_rectangles_path <- file.path(
  project_dir,
  "data/raw/vectors/sampling_rect.shp"
)

required <- c(source_rasters, sampling_rectangles_path)
missing <- required[!file.exists(required)]
if (length(missing) > 0) {
  stop(
    "Cannot regenerate blueterra example data. Missing source file(s):\n",
    paste(missing, collapse = "\n"),
    call. = FALSE
  )
}

out_dir <- file.path("inst", "extdata")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

compress_opts <- c(
  "COMPRESS=DEFLATE",
  "PREDICTOR=3",
  "ZLEVEL=9",
  "TILED=YES"
)

write_example_raster <- function(name, path) {
  r <- rast(path)
  names(r) <- "bathy_m"

  longest_side <- max(nrow(r), ncol(r))
  if (longest_side > 250) {
    fact <- ceiling(longest_side / 220)
    r <- aggregate(r, fact = fact, fun = mean, na.rm = TRUE)
  }

  out <- file.path(out_dir, paste0("laparguera_", name, "_bathy.tif"))
  writeRaster(
    r,
    out,
    overwrite = TRUE,
    datatype = "FLT4S",
    gdal = compress_opts
  )
  out
}

raster_outputs <- vapply(
  names(source_rasters),
  function(nm) write_example_raster(nm, source_rasters[[nm]]),
  character(1)
)

rects <- vect(sampling_rectangles_path)
target_crs <- crs(rast(source_rasters[["hitw"]]))
if (!same.crs(rects, target_crs)) {
  rects <- project(rects, target_crs)
}

rect_values <- as.data.frame(rects)
rect_site <- rect_values$site
site_id <- c(
  "Hole In the Wall" = "hitw",
  "Hoyo Terrace" = "hoyo"
)[rect_site]
site_name <- c(
  "Hole In the Wall" = "Hole-in-the-Wall",
  "Hoyo Terrace" = "El Hoyo"
)[rect_site]

rects <- rects[, 0]
values(rects) <- data.frame(
  site_id = unname(site_id),
  site_name = unname(site_name),
  feature_type = "sampling_rectangle",
  source_name = rect_site,
  width_m = rect_values$width_m,
  height_m = rect_values$height_m,
  angle_deg = rect_values$angle_deg
)

slope_poly <- as.polygons(ext(rast(source_rasters[["slope"]])), crs = target_crs)
slope_poly <- slope_poly[, 0]
values(slope_poly) <- data.frame(
  site_id = "slope",
  site_name = "Slope Clip",
  feature_type = "analysis_extent",
  source_name = "Slope_clip_bathy.tif_extent",
  width_m = NA_real_,
  height_m = NA_real_,
  angle_deg = NA_real_
)

sampling_rectangles <- rbind(rects, slope_poly)
vector_output <- file.path(out_dir, "laparguera_sampling_rectangles.gpkg")
if (file.exists(vector_output)) {
  unlink(vector_output)
}
writeVector(sampling_rectangles, vector_output, overwrite = TRUE)

example_files <- c(raster_outputs, sampling_rectangles = vector_output)
sizes <- file.info(example_files)$size
report <- data.frame(
  name = names(example_files),
  path = unname(example_files),
  bytes = sizes,
  mb = round(sizes / 1024^2, 3),
  row.names = NULL
)
print(report)

extdata_files <- list.files(out_dir, full.names = TRUE)
extdata_size <- sum(file.info(extdata_files)$size, na.rm = TRUE)
cat("inst/extdata total:", extdata_size, "bytes\n")

max_extdata_size <- 6 * 1024^2
if (extdata_size > max_extdata_size) {
  stop(
    "inst/extdata is larger than the maintainer limit of ",
    max_extdata_size,
    " bytes. Reduce example rasters before building.",
    call. = FALSE
  )
}
