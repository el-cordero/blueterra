test_that("metric catalog and process assignments work", {
  catalog <- metric_catalog()
  expect_s3_class(catalog, "tbl_df")
  expect_true(all(c("metric", "process_group", "source_function") %in% names(catalog)))
  expect_true("seafloor_aspect" %in% process_groups())
  expect_true("accumulation_potential" %in% process_groups())
  expect_equal(
    catalog$process_group[catalog$metric == "wetness_index_wbt"],
    "accumulation_potential"
  )
  expect_equal(
    catalog$process_group[catalog$metric == "convergence_slope_index"],
    "accumulation_potential"
  )
  terrain <- derive_terrain(example_bathy(), metrics = c("slope", "bpi", "roughness"))
  assigned <- assign_process_groups(terrain)
  expect_true(all(assigned$matched))
  summary <- summarize_process_groups(terrain)
  expect_true("seafloor_position" %in% summary$process_group)

  external <- assign_process_groups(c(
    "fd8_flow_accumulation_wbt",
    "wetness_index_wbt",
    "stream_power_index_wbt",
    "downslope_distance_to_stream_wbt",
    "surface_area_ratio"
  ))
  expect_true(all(external$matched))
  expect_equal(
    external$process_group[external$metric == "wetness_index_wbt"],
    "accumulation_potential"
  )
  expect_equal(
    external$process_group[external$metric == "stream_power_index_wbt"],
    "transport_potential"
  )
  expect_equal(
    external$process_group[external$metric == "surface_area_ratio"],
    "seafloor_rugosity"
  )
})

test_that("representative selection and renaming are stable", {
  reps <- select_process_representatives(metrics_available = c("slope_deg", "bpi_3x3"))
  expect_true(all(reps$metric %in% c("slope_deg", "bpi_3x3")))
  custom_reps <- select_process_representatives(
    representatives = c(seafloor_aspect = "northness", slope_gradient = "slope_deg")
  )
  expect_true(all(c("seafloor_aspect", "slope_gradient") %in% custom_reps$process_group))
  expect_equal(standardize_metric_names(c("Slope (deg)", "Broad BPI")), c("slope_deg", "broad_bpi"))
  expect_equal(rename_metric_layers(c("old"), c(old = "new")), "new")
})

test_that("custom metrics and catalogs extend process groups", {
  bathy <- example_bathy()
  metrics <- derive_terrain(bathy, metrics = c("slope", "tri", "bpi"))
  slope_tri <- derive_custom_metric(
    metrics,
    name = "slope_tri_index",
    expression = quote(slope_deg * tri)
  )
  expect_s4_class(slope_tri, "SpatRaster")
  expect_equal(names(slope_tri), "slope_tri_index")

  relief <- derive_custom_metric(
    metrics,
    name = "relief_index",
    fun = function(r) {
      out <- r[["tri"]] + abs(r[["bpi_3x3"]])
      names(out) <- "relief_index"
      out
    }
  )
  expect_s4_class(relief, "SpatRaster")

  extended <- add_metric_layers(metrics, slope_tri, relief)
  expect_true(all(c("slope_tri_index", "relief_index") %in% names(extended)))
  expect_error(add_metric_layers(metrics, metrics[["slope_deg"]]), "already exist")

  shifted <- terra::aggregate(metrics[["tri"]], fact = 2)
  expect_error(add_metric_layers(metrics, shifted), "match the geometry")

  custom_row <- create_metric_catalog(
    metric = "slope_tri_index",
    label = "Slope-TRI index",
    process_group = "custom_relief",
    description = "Product of local slope and terrain ruggedness index.",
    units = "index",
    source_function = "derive_custom_metric",
    interpretation_notes = "Example custom index for tests."
  )
  expect_s3_class(custom_row, "tbl_df")
  custom_catalog <- extend_metric_catalog(metric_catalog(), custom_row)
  expect_s3_class(validate_metric_catalog(custom_catalog), "tbl_df")

  assigned <- assign_process_groups(extended, catalog = custom_catalog)
  expect_true("custom_relief" %in% assigned$process_group)
  override <- assign_process_groups(extended, groups = c(relief_index = "custom_relief"))
  expect_equal(override$process_group[override$metric == "relief_index"], "custom_relief")

  summary <- summarize_process_groups(extended, catalog = custom_catalog, groups = c(relief_index = "custom_relief"))
  expect_true("custom_relief" %in% summary$process_group)
})
