test_that("isobaths and corridors can be extracted", {
  bathy <- example_bathy()
  iso <- extract_isobaths(bathy, depths = -50)
  expect_s4_class(iso, "SpatVector")
  corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
  expect_s4_class(corridors, "SpatVector")
  expect_equal(terra::geomtype(corridors), "polygons")
})

test_that("isobath corridor extraction and summaries work", {
  bathy <- example_bathy()
  terrain <- derive_terrain(bathy, metrics = c("slope", "bpi"))
  corridors <- make_isobath_corridors(bathy, depths = -50, width = 20)
  cells <- extract_isobath_corridors(terrain, corridors)
  expect_s3_class(cells, "tbl_df")
  expect_true("slope_deg" %in% names(cells))
  summary <- summarize_isobath_terrain(terrain, corridors)
  expect_true("slope_deg_mean" %in% names(summary))
})
