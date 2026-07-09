test_that("depth sign handling is explicit", {
  bathy <- example_bathy()
  positive <- set_depth_positive(bathy)
  negative <- set_depth_negative(positive)
  expect_true(terra::minmax(positive)[1] >= 0)
  expect_true(terra::minmax(negative)[2] <= 0)
  expect_true(terra::all.equal(invert_depth(positive), negative))
})

test_that("preparation helpers crop, filter, smooth, and write in tempdir", {
  bathy <- example_bathy()
  cropped <- crop_bathy(bathy, terra::ext(50, 250, 50, 250))
  expect_lt(terra::ncell(cropped), terra::ncell(bathy))
  filtered <- depth_filter(bathy, c(-80, -30))
  expect_s4_class(filtered, "SpatRaster")
  smoothed <- smooth_bathy(bathy, window = 3)
  expect_s4_class(smoothed, "SpatRaster")
  out <- file.path(tempdir(), "prepared_bathy.tif")
  prepared <- prepare_bathy(
    bathy,
    depth_range = c(-80, -30),
    smooth = TRUE,
    filename = out,
    overwrite = TRUE
  )
  expect_true(file.exists(out))
  expect_s4_class(prepared, "SpatRaster")
})

test_that("mask, resample, and project helpers work", {
  bathy <- example_bathy()
  sites <- example_sites()
  masked <- mask_bathy(bathy, sites[1, ])
  expect_s4_class(masked, "SpatRaster")
  template <- terra::aggregate(bathy, fact = 2)
  resampled <- resample_bathy(bathy, template)
  expect_equal(terra::ncell(resampled), terra::ncell(template))
  projected <- project_bathy(template, terra::crs(bathy))
  expect_s4_class(projected, "SpatRaster")
})
