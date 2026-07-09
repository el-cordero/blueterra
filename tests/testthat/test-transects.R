test_that("transects can be created and sampled", {
  bathy <- example_bathy()
  sites <- example_sites()
  transects <- make_transects(sites[1, ], spacing = 100)
  expect_s3_class(transects, "sf")
  samples <- sample_transects(transects, bathy, n = 5)
  expect_s3_class(samples, "tbl_df")
  expect_true(all(c("transect_id", "distance", "bathy") %in% names(samples)))
  sections <- extract_cross_sections(transects, bathy, n = 5)
  expect_equal(nrow(sections), nrow(samples))
})

test_that("cross-section summaries work", {
  bathy <- example_bathy()
  sites <- example_sites()
  samples <- sample_transects(make_transects(sites[1, ], spacing = 100), bathy, n = 5)
  summary <- summarize_cross_sections(samples)
  expect_true("bathy_mean" %in% names(summary))
})
