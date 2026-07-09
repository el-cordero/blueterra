dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)

set.seed(42)

r <- terra::rast(
  nrows = 60,
  ncols = 60,
  xmin = 0,
  xmax = 600,
  ymin = 0,
  ymax = 600,
  crs = "EPSG:32620"
)

xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
x <- xy[, 1]
y <- xy[, 2]

shelf_gradient <- -20 - 0.10 * y
channel <- -18 * exp(-((x - 340)^2 / (2 * 70^2) + (y - 330)^2 / (2 * 180^2)))
mound <- 12 * exp(-((x - 210)^2 / (2 * 55^2) + (y - 240)^2 / (2 * 55^2)))
slope_break <- -8 / (1 + exp(-(y - 360) / 18))
ridge <- 7 * exp(-((x - 180)^2 / (2 * 35^2))) *
  exp(-((y - 420)^2 / (2 * 170^2)))
terrace <- 5 * sin(x / 55) * exp(-((y - 420)^2 / (2 * 130^2)))
values <- shelf_gradient + channel + mound + ridge + slope_break + terrace

terra::values(r) <- values
names(r) <- "bathy"
terra::writeRaster(r, "inst/extdata/synthetic_test_bathy.tif", overwrite = TRUE)

zones <- terra::vect(
  c(
    "POLYGON ((80 80, 300 80, 300 300, 80 300, 80 80))",
    "POLYGON ((310 280, 540 280, 540 520, 310 520, 310 280))"
  ),
  crs = "EPSG:32620"
)
terra::values(zones) <- data.frame(
  zone_id = c("zone_a", "zone_b"),
  setting = c("ridge_basin", "slope_break")
)

for (path in c(
  "inst/extdata/synthetic_test_zones.gpkg",
  "inst/extdata/example_zones.gpkg",
  "inst/extdata/example_sites.gpkg"
)) {
  if (file.exists(path)) {
    unlink(path)
  }
}
terra::writeVector(zones, "inst/extdata/synthetic_test_zones.gpkg", overwrite = TRUE)
