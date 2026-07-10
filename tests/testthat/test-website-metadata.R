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
