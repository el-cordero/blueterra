test_that("polygon, depth-band, point, and cell summaries work", {
  bathy <- example_bathy()
  terrain <- derive_terrain(bathy, metrics = c("slope", "bpi", "roughness"))
  zones <- example_zones()
  zone_summary <- summarize_terrain(terrain, zones)
  expect_true("slope_deg_mean" %in% names(zone_summary))
  zones2 <- summarize_terrain_by_zone(terrain, zones)
  expect_equal(names(zones2), names(zone_summary))
  bands <- summarize_depth_bands(bathy, metrics = terrain, breaks = c(-90, -60, -30, 0))
  expect_s3_class(bands, "tbl_df")
  pts <- terra::centroids(zones)
  point_values <- extract_terrain_points(terrain, pts)
  expect_true("slope_deg" %in% names(point_values))
  cells <- sample_terrain_cells(terrain, size = 15)
  expect_equal(nrow(cells), 15)
  seeded_a <- sample_terrain_cells(terrain, size = 10, seed = 11)
  seeded_b <- sample_terrain_cells(terrain, size = 10, seed = 11)
  expect_equal(seeded_a, seeded_b)
})

test_that("modeling helpers return structured objects", {
  terrain <- derive_terrain(example_bathy(), metrics = c("slope", "bpi", "roughness"))
  cells <- sample_terrain_cells(terrain, size = 40)
  pca <- terrain_pca(cells)
  expect_true(all(c("scores", "loadings", "variance", "model") %in% names(pca)))
  expect_true(all(c("vars", "complete_rows") %in% names(pca)))
  corr <- terrain_correlation(cells)
  expect_s3_class(corr, "tbl_df")
  df <- data.frame(group = rep(c("a", "b"), each = 5), slope = 1:10)
  eff <- terrain_effect_size(df, group = "group", vars = "slope")
  expect_equal(eff$method, "cohens_d")
  mm <- prepare_model_matrix(df, response = "group", vars = "slope")
  expect_equal(nrow(mm$x), nrow(df))
  balanced <- balance_samples(data.frame(group = rep(c("a", "b"), c(2, 5)), v = 1:7), "group")
  expect_equal(as.integer(table(balanced$group))[1], as.integer(table(balanced$group))[2])
})

test_that("PCA preserves metadata and supports group-specific fits", {
  set.seed(1)
  df <- data.frame(
    site = rep(c("Hole-in-the-Wall", "El Hoyo"), each = 8),
    slope_deg = rnorm(16),
    tri = rnorm(16),
    bpi_3x3 = rnorm(16),
    curvature = rnorm(16)
  )
  pca <- terrain_pca(
    df,
    vars = c("slope_deg", "tri", "bpi_3x3", "curvature"),
    metadata_cols = "site"
  )
  expect_true("site" %in% names(pca$scores))
  labels <- pca_axis_labels(pca)
  expect_true(all(c("PC1", "PC2") %in% names(labels)))
  expect_match(labels[["PC1"]], "%")

  grouped <- terrain_pca_by_group(
    df,
    group = "site",
    vars = c("slope_deg", "tri", "bpi_3x3", "curvature"),
    min_rows = 5
  )
  expect_true(all(c("overall", "groups") %in% names(grouped)))
  expect_true(all(c("Hole-in-the-Wall", "El Hoyo") %in% names(grouped$groups)))
})

test_that("package citation uses 2026", {
  citation_text <- paste(capture.output(utils::citation("blueterra")), collapse = "\n")
  expect_match(citation_text, "2026")
})
