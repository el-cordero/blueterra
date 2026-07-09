test_that("example data are available", {
  expect_true(file.exists(blueterra_example("bathy")))
  expect_true(file.exists(blueterra_example("zones")))
  expect_true(file.exists(blueterra_example("sites")))
  expect_match(blueterra_extdata("example_bathy.tif"), "example_bathy.tif")
  expect_match(blueterra_example("zones"), "example_zones.gpkg")
})

test_that("bathymetry input helpers read and validate rasters", {
  path <- blueterra_example("bathy")
  bathy <- read_bathy(path)
  expect_s4_class(bathy, "SpatRaster")
  expect_true(terra::compareGeom(as_bathy(path), bathy, stopOnError = FALSE))
  expect_no_error(validate_bathy(bathy))
  info <- bathy_info(bathy)
  expect_equal(info$ncell, terra::ncell(bathy))
  expect_true(check_bathy_crs(bathy)$is_projected)
  units <- check_bathy_units(bathy, units = "m", positive_depth = FALSE)
  expect_equal(units$units, "m")
})

test_that("input helpers fail clearly", {
  expect_error(read_bathy(file.path(tempdir(), "missing.tif")), "does not exist")
  expect_error(as_bathy(1), "SpatRaster")
})

test_that("vector helpers accept SpatVector and local vector paths", {
  zones <- terra::vect(blueterra_example("zones"))
  expect_s4_class(zones, "SpatVector")
  bathy <- example_bathy()
  expect_s4_class(mask_bathy(bathy, blueterra_example("zones")), "SpatRaster")
})
