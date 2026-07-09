test_that("example data are available", {
  expect_true(file.exists(blueterra_example("hitw")))
  expect_true(file.exists(blueterra_example("hoyo")))
  expect_true(file.exists(blueterra_example("slope")))
  expect_true(file.exists(blueterra_example("sampling_rectangles")))
  expect_true(file.exists(blueterra_example("bathy")))
  expect_true(file.exists(blueterra_example("zones")))
  expect_true(file.exists(blueterra_example("sites")))
  expect_true(file.exists(blueterra_example("synthetic_bathy")))
  expect_true(file.exists(blueterra_example("synthetic_zones")))
  expect_match(blueterra_example("zones"), "laparguera_sampling_rectangles.gpkg")

  catalog <- blueterra_examples()
  expect_s3_class(catalog, "tbl_df")
  expect_true(all(c("hitw", "hoyo", "slope", "sampling_rectangles") %in% catalog$name))
})

test_that("bathymetry input helpers read and validate rasters", {
  path <- blueterra_example("hitw")
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
  bathy <- read_bathy(blueterra_example("hitw"))
  expect_s4_class(mask_bathy(bathy, blueterra_example("zones")), "SpatRaster")
})
