test_that("package URLs prioritize the website and issues tracker", {
  desc_path <- system.file("DESCRIPTION", package = "blueterra")
  if (!nzchar(desc_path)) {
    desc_path <- normalizePath(file.path("..", "..", "DESCRIPTION"), mustWork = TRUE)
  }
  desc <- read.dcf(desc_path)[1, ]
  url <- gsub("\\s+", " ", unname(desc[["URL"]]))
  expect_equal(
    url,
    "https://el-cordero.github.io/blueterra/, https://github.com/el-cordero/blueterra"
  )
  expect_equal(unname(desc[["BugReports"]]), "https://github.com/el-cordero/blueterra/issues")
})

test_that("development scripts use current corridor and animation settings", {
  root_candidates <- c(".", file.path("..", ".."))
  root <- root_candidates[file.exists(file.path(root_candidates, "DESCRIPTION"))][1]
  testthat::skip_if(is.na(root))
  root <- normalizePath(root, mustWork = TRUE)

  readme_rmd <- file.path(root, "README.Rmd")
  testthat::skip_if_not(file.exists(readme_rmd))
  readme_text <- readLines(readme_rmd, warn = FALSE)
  expect_false(any(grepl("study-area-pr-southwest-shelf-margin.png", readme_text, fixed = TRUE)))
  expect_false(any(grepl("Study-area context for the example data", readme_text, fixed = TRUE)))

  visual_script <- file.path(root, "qa", "visual-proof", "visual-proof.R")
  testthat::skip_if_not(file.exists(visual_script))
  visual_text <- readLines(visual_script, warn = FALSE)
  expect_true(any(grepl("make_isobath_corridors\\(.*width = 5|width = 5", visual_text)))
  expect_false(any(grepl("width = 20", visual_text, fixed = TRUE)))

  animation_script <- normalizePath(
    file.path(root, "..", "..", "blueterra_linkedin_animation", "make_linkedin_animation.R"),
    mustWork = FALSE
  )
  testthat::skip_if_not(file.exists(animation_script))
  animation_text <- readLines(animation_script, warn = FALSE)
  expect_true(any(grepl("width = 5", animation_text, fixed = TRUE)))
  expect_false(any(grepl("terra-based", animation_text, fixed = TRUE)))
  expect_false(any(grepl('profile_direction = "high_to_low"', animation_text, fixed = TRUE)))
  expect_false(any(grepl('profile_direction = "min_to_max"', animation_text, fixed = TRUE)))
  expect_true(any(grepl('profile_direction = "top_to_bottom"', animation_text, fixed = TRUE)))
  expect_true(any(grepl("max_gif_bytes <- 4900000", animation_text, fixed = TRUE)))
  expect_true(any(grepl("fontsize = 12", animation_text, fixed = TRUE)))
})
