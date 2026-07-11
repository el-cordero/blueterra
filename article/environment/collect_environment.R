#!/usr/bin/env Rscript

# Collect a machine-readable execution environment for the reproducibility
# bundle. The lock file covers the package and every package used by the
# article analyses in this local run.

suppressPackageStartupMessages(library(renv))

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("article/environment/collect_environment.R", mustWork = TRUE)
}
root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)
out_dir <- file.path(root, "article", "environment", "results")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

packages <- c(
  "blueterra", "terra", "sf", "exactextractr", "ggplot2", "dplyr",
  "tibble", "testthat", "pkgload", "devtools", "ragg", "jsonlite",
  "digest", "renv"
)

package_row <- function(package) {
  if (identical(package, "blueterra")) {
    description <- read.dcf(file.path(root, "DESCRIPTION"))
    return(data.frame(
      package = package,
      version = description[1, "Version"],
      source = "local evaluated checkout",
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    package = package,
    version = if (requireNamespace(package, quietly = TRUE)) as.character(utils::packageVersion(package)) else NA_character_,
    source = if (requireNamespace(package, quietly = TRUE)) "installed library" else "not installed",
    stringsAsFactors = FALSE
  )
}

versions <- do.call(rbind, lapply(packages, package_row))
utils::write.csv(versions, file.path(out_dir, "package_versions.csv"), row.names = FALSE, na = "")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
writeLines(capture.output(terra::libVersion()), file.path(out_dir, "spatial_libraries.txt"))

analysis_packages <- packages[packages != "blueterra"]
lock_packages <- analysis_packages[vapply(analysis_packages, requireNamespace, logical(1), quietly = TRUE)]
renv::snapshot(
  project = out_dir,
  library = .libPaths(),
  lockfile = file.path(out_dir, "renv.lock"),
  packages = lock_packages,
  prompt = FALSE,
  force = TRUE
)

system_info <- data.frame(
  field = c("operating_system", "R_version", "evaluated_commit", "package_version"),
  value = c(
    paste(Sys.info()[c("sysname", "release", "machine")], collapse = " | "),
    R.version.string,
    system2("git", c("-C", shQuote(root), "rev-parse", "HEAD"), stdout = TRUE),
    read.dcf(file.path(root, "DESCRIPTION"))[1, "Version"]
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(system_info, file.path(out_dir, "system_information.csv"), row.names = FALSE, na = "")
message("Wrote environment records to ", out_dir)
