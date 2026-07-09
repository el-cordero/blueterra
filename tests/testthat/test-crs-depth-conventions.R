test_that("slope on a simple plane is interpretable", {
  r <- terra::rast(nrows = 20, ncols = 20, xmin = 0, xmax = 20, ymin = 0, ymax = 20, crs = "EPSG:32620")
  xy <- terra::xyFromCell(r, seq_len(terra::ncell(r)))
  terra::values(r) <- xy[, "x"]
  names(r) <- "plane"

  slope <- derive_slope(r, units = "degrees")
  slope_mean <- terra::global(slope, "mean", na.rm = TRUE)[1, 1]
  expect_equal(as.numeric(slope_mean), 45, tolerance = 1)
})

test_that("northness and eastness match aspect trigonometry", {
  bathy <- example_bathy()
  aspect <- derive_aspect(bathy, units = "radians")
  northness <- derive_northness(bathy)
  eastness <- derive_eastness(bathy)

  expect_equal(
    terra::values(northness, mat = FALSE),
    terra::values(cos(aspect), mat = FALSE),
    tolerance = 1e-8
  )
  expect_equal(
    terra::values(eastness, mat = FALSE),
    terra::values(sin(aspect), mat = FALSE),
    tolerance = 1e-8
  )
})

test_that("BPI sign follows the stored vertical convention", {
  bathy_negative <- example_bathy()
  bathy_positive <- set_depth_positive(bathy_negative)
  bpi_negative <- derive_bpi(bathy_negative, window = 5)
  bpi_positive <- derive_bpi(bathy_positive, window = 5)

  expect_true(terra::all.equal(bpi_positive, -bpi_negative, tolerance = 1e-8))
})

test_that("depth bands work with positive and negative depth conventions", {
  bathy_negative <- example_bathy()
  bathy_positive <- set_depth_positive(bathy_negative)

  neg <- summarize_depth_bands(bathy_negative, breaks = c(-90, -60, -30, 0))
  pos <- summarize_depth_bands(
    bathy_positive,
    breaks = c(0, 30, 60, 90),
    positive_depth = TRUE
  )

  expect_s3_class(neg, "tbl_df")
  expect_s3_class(pos, "tbl_df")
  expect_true(all(pos$n_cells >= 0))
})

test_that("projected CRS is required for distance-based corridors", {
  bathy <- example_bathy()
  expect_true(check_bathy_crs(bathy)$is_projected)
  corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
  expect_equal(terra::geomtype(corridors), "polygons")
})
