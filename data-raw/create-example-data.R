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
terrace <- 5 * sin(x / 55) * exp(-((y - 420)^2 / (2 * 130^2)))
values <- shelf_gradient + channel + mound + terrace

terra::values(r) <- values
names(r) <- "bathy"
terra::writeRaster(r, "inst/extdata/example_bathy.tif", overwrite = TRUE)

poly1 <- sf::st_polygon(list(rbind(
  c(80, 80),
  c(300, 80),
  c(300, 300),
  c(80, 300),
  c(80, 80)
)))
poly2 <- sf::st_polygon(list(rbind(
  c(310, 280),
  c(540, 280),
  c(540, 520),
  c(310, 520),
  c(310, 280)
)))

sites <- sf::st_sf(
  site_id = c("site_a", "site_b"),
  setting = c("mound", "channel"),
  geometry = sf::st_sfc(poly1, poly2, crs = 32620)
)

if (file.exists("inst/extdata/example_sites.gpkg")) {
  unlink("inst/extdata/example_sites.gpkg")
}
sf::st_write(sites, "inst/extdata/example_sites.gpkg", quiet = TRUE)
