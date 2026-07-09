test_that("metric catalog and process assignments work", {
  catalog <- metric_catalog()
  expect_s3_class(catalog, "tbl_df")
  expect_true(all(c("metric", "process_group", "source_function") %in% names(catalog)))
  expect_true("orientation" %in% process_groups())
  terrain <- derive_terrain(example_bathy(), metrics = c("slope", "bpi", "roughness"))
  assigned <- assign_process_groups(terrain)
  expect_true(all(assigned$matched))
  summary <- summarize_process_groups(terrain)
  expect_true("seafloor_position" %in% summary$process_group)
})

test_that("representative selection and renaming are stable", {
  reps <- select_process_representatives(metrics_available = c("slope_deg", "bpi_3x3"))
  expect_true(all(reps$metric %in% c("slope_deg", "bpi_3x3")))
  expect_equal(standardize_metric_names(c("Slope (deg)", "Broad BPI")), c("slope_deg", "broad_bpi"))
  expect_equal(rename_metric_layers(c("old"), c(old = "new")), "new")
})
