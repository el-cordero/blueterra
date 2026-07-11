#!/usr/bin/env Rscript

# Install one tagged blueterra source archive into a private R library and run
# the documented Route-B BlueTopo workflow twice in fresh Rscript --vanilla
# processes. The package under test comes only from the tag archive. The
# provenance-checked BlueTopo inputs remain external article inputs and are
# passed to both isolated workers by path and SHA-256-verified manifest.

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_argument)) sub("^--file=", "", script_argument[[1]]) else "run_clean_reproducibility.R"
script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
script_dir <- dirname(normalizePath(script_path, mustWork = TRUE))
source(file.path(script_dir, "reproducibility_helpers.R"))

args <- bt_repro_parse_args(commandArgs(trailingOnly = TRUE))
if (isTRUE(args$help)) {
  cat(paste(
    "Usage:",
    "  Rscript article/reproducibility/run_clean_reproducibility.R [--tag v0.2.0] [--data-root PATH] [--output PATH] [--seed INTEGER] [--runs 2]",
    "",
    "The specified local Git tag must exist. Results are written to a new UTC-stamped directory unless --output is supplied.",
    sep = "\n"
  ))
  quit(status = 0L)
}

repo_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = TRUE)
git <- Sys.which("git")
if (!nzchar(git)) stop("`git` is required to create the clean tagged archive.", call. = FALSE)

release_tag <- as.character(bt_repro_default(args$tag, "v0.2.0"))
if (!nzchar(release_tag) || grepl("[[:space:]]", release_tag)) {
  stop("`--tag` must be one non-empty local Git tag name without whitespace.", call. = FALSE)
}

run_command <- function(command, command_args, log_path = NULL, env = character()) {
  output <- system2(command, command_args, stdout = TRUE, stderr = TRUE, env = env)
  if (!is.null(log_path)) writeLines(output, log_path, useBytes = TRUE)
  status <- attr(output, "status")
  list(output = output, status = if (is.null(status)) 0L else as.integer(status))
}

tag_ref <- paste0("refs/tags/", release_tag)
tag_check <- run_command(
  git,
  c("-C", bt_repro_shell_quote(repo_dir), "show-ref", "--verify", "--quiet", bt_repro_shell_quote(tag_ref))
)
if (!identical(tag_check$status, 0L)) {
  stop(
    "Required local Git tag `", release_tag, "` was not found. Create and verify the tag before running this audit.",
    call. = FALSE
  )
}
tag_commit_result <- run_command(
  git,
  c("-C", bt_repro_shell_quote(repo_dir), "rev-parse", "--verify", bt_repro_shell_quote(paste0(release_tag, "^{commit}")))
)
tag_commit_sha <- trimws(tag_commit_result$output[[1]])
if (!identical(tag_commit_result$status, 0L) || !grepl("^[[:xdigit:]]{40}$", tag_commit_sha)) {
  stop("Could not resolve a commit for local tag `", release_tag, "`.", call. = FALSE)
}

seed <- suppressWarnings(as.integer(bt_repro_default(args$seed, "20260711")))
runs <- suppressWarnings(as.integer(bt_repro_default(args$runs, "2")))
if (is.na(seed)) stop("`--seed` must be an integer.", call. = FALSE)
if (is.na(runs) || runs != 2L) stop("`--runs` must be exactly 2 for this paired reproducibility audit.", call. = FALSE)

default_data_root <- file.path(repo_dir, "article", "data_provenance", "results")
data_root <- normalizePath(bt_repro_default(args[["data-root"]], default_data_root), mustWork = TRUE)
required_route_b_inputs <- c(
  "bluetopo_bh54s4zb_elevation_example.tif",
  "bluetopo_author_analysis_windows.gpkg",
  "bluetopo_example_manifest.csv"
)
missing_route_b_inputs <- required_route_b_inputs[!file.exists(file.path(data_root, required_route_b_inputs))]
if (length(missing_route_b_inputs)) {
  stop("Route-B data root is missing: ", paste(missing_route_b_inputs, collapse = ", "), call. = FALSE)
}

tag_label <- gsub("[^A-Za-z0-9._-]", "-", release_tag)
default_output <- file.path(
  script_dir,
  "results",
  paste0(format(Sys.time(), tz = "UTC", format = "%Y%m%dT%H%M%SZ"), "_tag-", tag_label)
)
output_dir <- normalizePath(bt_repro_default(args$output, default_output), mustWork = FALSE)
if (dir.exists(output_dir) && length(list.files(output_dir, all.files = TRUE, no.. = TRUE))) {
  stop("Refusing to overwrite an existing reproducibility result directory: ", output_dir, call. = FALSE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

git_status <- run_command(
  git,
  c("-C", bt_repro_shell_quote(repo_dir), "status", "--porcelain=v1", "--untracked-files=all")
)$output
untracked_count <- sum(startsWith(git_status, "?? "))
tracked_change_count <- length(git_status) - untracked_count
tracked_files_result <- run_command(
  git,
  c("-C", bt_repro_shell_quote(repo_dir), "ls-tree", "-r", "--name-only", bt_repro_shell_quote(release_tag))
)
if (!identical(tracked_files_result$status, 0L)) {
  stop("Could not list files in tag `", release_tag, "`.", call. = FALSE)
}
tracked_files <- tracked_files_result$output

work_dir <- tempfile("blueterra-clean-repro-", tmpdir = "/private/tmp")
dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(work_dir, recursive = TRUE, force = TRUE), add = TRUE)
archive_path <- file.path(work_dir, paste0("blueterra-", tag_label, ".tar"))
clean_source_dir <- file.path(work_dir, "clean-source")
private_library <- file.path(work_dir, "R-library")
dir.create(clean_source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(private_library, recursive = TRUE, showWarnings = FALSE)

archive_result <- run_command(
  git,
  c(
    "-C", bt_repro_shell_quote(repo_dir), "archive",
    paste0("--output=", archive_path), "--format=tar",
    bt_repro_shell_quote(release_tag)
  ),
  file.path(output_dir, "create_clean_archive.log")
)
if (!identical(archive_result$status, 0L)) {
  stop("`git archive` failed for tag `", release_tag, "`.", call. = FALSE)
}
utils::untar(archive_path, exdir = clean_source_dir)
if (!file.exists(file.path(clean_source_dir, "DESCRIPTION"))) {
  stop("The clean tag archive did not contain a package DESCRIPTION file.", call. = FALSE)
}
clean_description <- read.dcf(file.path(clean_source_dir, "DESCRIPTION"))
package_version <- as.character(clean_description[1L, "Version"])
if (identical(release_tag, "v0.2.0") && !identical(package_version, "0.2.0")) {
  stop("Tag `v0.2.0` contains DESCRIPTION version ", package_version, ", not 0.2.0.", call. = FALSE)
}
archive_sha256 <- bt_repro_sha256_file(archive_path)

r_bin <- file.path(R.home("bin"), "R")
rscript_bin <- file.path(R.home("bin"), "Rscript")
install_status <- run_command(
  r_bin,
  c(
    "CMD", "INSTALL", bt_repro_shell_quote(paste0("--library=", private_library)),
    bt_repro_shell_quote(clean_source_dir)
  ),
  file.path(output_dir, "install_clean_archive.log")
)$status
if (!identical(install_status, 0L)) {
  stop("Clean tagged-archive package installation failed; see install_clean_archive.log.", call. = FALSE)
}

worker <- file.path(script_dir, "run_route_b_examples.R")
if (!file.exists(worker)) stop("Missing Route-B worker script: ", worker, call. = FALSE)

for (i in seq_len(runs)) {
  run_id <- sprintf("run_%02d", i)
  run_dir <- file.path(output_dir, run_id)
  run_status <- run_command(
    rscript_bin,
    c(
      "--vanilla", bt_repro_shell_quote(worker),
      "--library", bt_repro_shell_quote(private_library),
      "--output", bt_repro_shell_quote(run_dir),
      "--run-id", bt_repro_shell_quote(run_id),
      "--seed", as.character(seed),
      "--data-root", bt_repro_shell_quote(data_root),
      "--tag", bt_repro_shell_quote(release_tag),
      "--package-version", bt_repro_shell_quote(package_version)
    ),
    file.path(output_dir, paste0(run_id, ".log")),
    env = paste0("R_LIBS_USER=", bt_repro_shell_quote(private_library))
  )$status
  if (!identical(run_status, 0L)) {
    stop("Route-B workflow failed for ", run_id, "; see ", paste0(run_id, ".log"), call. = FALSE)
  }
}

compare_hash_manifest <- function(filename, comparison_scope) {
  first <- utils::read.csv(file.path(output_dir, "run_01", filename), stringsAsFactors = FALSE, check.names = FALSE)
  second <- utils::read.csv(file.path(output_dir, "run_02", filename), stringsAsFactors = FALSE, check.names = FALSE)
  if (!all(c("artifact", "sha256") %in% names(first)) || !all(c("artifact", "sha256") %in% names(second))) {
    stop("Hash manifest is missing expected columns: ", filename, call. = FALSE)
  }
  first$key <- if ("scope" %in% names(first)) paste(first$scope, first$artifact, sep = "/") else first$artifact
  second$key <- if ("scope" %in% names(second)) paste(second$scope, second$artifact, sep = "/") else second$artifact
  keys <- sort(unique(c(first$key, second$key)))
  first_hash <- first$sha256[match(keys, first$key)]
  second_hash <- second$sha256[match(keys, second$key)]
  data.frame(
    comparison_scope = comparison_scope,
    artifact = keys,
    run_01_sha256 = first_hash,
    run_02_sha256 = second_hash,
    identical_sha256 = !is.na(first_hash) & !is.na(second_hash) & first_hash == second_hash,
    stringsAsFactors = FALSE
  )
}

compare_file <- function(filename, comparison_scope) {
  first <- file.path(output_dir, "run_01", filename)
  second <- file.path(output_dir, "run_02", filename)
  first_hash <- bt_repro_sha256_file(first)
  second_hash <- bt_repro_sha256_file(second)
  data.frame(
    comparison_scope = comparison_scope,
    artifact = filename,
    run_01_sha256 = first_hash,
    run_02_sha256 = second_hash,
    identical_sha256 = identical(first_hash, second_hash),
    stringsAsFactors = FALSE
  )
}

compare_key_values <- function(filename, key_column, value_column, comparison_scope, ignore_keys = character()) {
  first <- utils::read.csv(file.path(output_dir, "run_01", filename), stringsAsFactors = FALSE, check.names = FALSE)
  second <- utils::read.csv(file.path(output_dir, "run_02", filename), stringsAsFactors = FALSE, check.names = FALSE)
  if (!all(c(key_column, value_column) %in% names(first)) || !all(c(key_column, value_column) %in% names(second))) {
    stop("Comparison file is missing expected columns: ", filename, call. = FALSE)
  }
  first <- first[!first[[key_column]] %in% ignore_keys, c(key_column, value_column), drop = FALSE]
  second <- second[!second[[key_column]] %in% ignore_keys, c(key_column, value_column), drop = FALSE]
  keys <- sort(unique(c(first[[key_column]], second[[key_column]])))
  left <- first[[value_column]][match(keys, first[[key_column]])]
  right <- second[[value_column]][match(keys, second[[key_column]])]
  data.frame(
    comparison_scope = comparison_scope,
    key = keys,
    run_01_value = left,
    run_02_value = right,
    identical_value = !is.na(left) & !is.na(right) & left == right,
    stringsAsFactors = FALSE
  )
}

comparison <- rbind(
  compare_hash_manifest("input_hashes.csv", "documented_route_b_inputs"),
  compare_hash_manifest("output_hashes.csv", "deterministic_workflow_tables"),
  compare_file("input_schema.csv", "input_schema"),
  compare_file("output_schema.csv", "output_schema"),
  compare_file("output_binary_inventory.csv", "binary_output_inventory")
)
comparison_passed <- nrow(comparison) > 0L && all(comparison$identical_sha256)
bt_repro_write_csv(comparison, file.path(output_dir, "reproducibility_comparison.csv"))

platform_comparison <- compare_key_values(
  "platform_details.csv", "key", "value", "platform", ignore_keys = "run_id"
)
bt_repro_write_csv(platform_comparison, file.path(output_dir, "platform_comparison.csv"))

dependency_comparison <- compare_key_values(
  "dependency_versions.csv", "package", "version", "dependency_version"
)
bt_repro_write_csv(dependency_comparison, file.path(output_dir, "dependency_comparison.csv"))

platform <- utils::read.csv(file.path(output_dir, "run_01", "platform_details.csv"), stringsAsFactors = FALSE)
platform_value <- function(key) {
  value <- platform$value[match(key, platform$key)]
  if (length(value) && !is.na(value)) value else ""
}
route_b_inputs <- utils::read.csv(file.path(output_dir, "run_01", "input_hashes.csv"), stringsAsFactors = FALSE)
route_b_tile <- "BH54S4ZB"

source_manifest <- data.frame(
  key = c(
    "release_tag", "source_commit_sha", "source_commit_short_sha", "source_archive_sha256",
    "source_archive_format", "source_archive_method", "tracked_file_count",
    "local_tracked_change_count", "local_untracked_file_count",
    "working_tree_used_for_package", "package_version", "harness_sha256",
    "worker_sha256", "helpers_sha256", "route_b_data_root", "route_b_tile_id",
    "route_b_input_manifest_sha256", "random_seed", "fresh_r_processes"
  ),
  value = c(
    release_tag, tag_commit_sha, substr(tag_commit_sha, 1L, 8L), archive_sha256,
    "tar", paste0("git archive ", release_tag), as.character(length(tracked_files)),
    as.character(tracked_change_count), as.character(untracked_count),
    "false", package_version, bt_repro_sha256_file(script_path),
    bt_repro_sha256_file(worker), bt_repro_sha256_file(file.path(script_dir, "reproducibility_helpers.R")),
    data_root, route_b_tile,
    route_b_inputs$sha256[route_b_inputs$input_name == "provenance_manifest"],
    as.character(seed), as.character(runs)
  ),
  stringsAsFactors = FALSE
)
bt_repro_write_csv(source_manifest, file.path(output_dir, "source_archive_manifest.csv"))

run_status_files <- file.path(output_dir, sprintf("run_%02d", seq_len(runs)), "workflow_status.csv")
run_status <- do.call(rbind, lapply(run_status_files, function(path) utils::read.csv(path, stringsAsFactors = FALSE)))
bt_repro_write_csv(run_status, file.path(output_dir, "run_status.csv"))

platform_differences <- sum(!platform_comparison$identical_value)
dependency_differences <- sum(!dependency_comparison$identical_value)
report <- c(
  "# Clean-environment reproducibility report",
  "",
  paste0("**Result:** ", if (comparison_passed) "PASS" else "FAIL"),
  "",
  "## Source isolation",
  "",
  paste0("- Package source: clean archive of local release tag `", release_tag, "` (blueterra ", package_version, ")."),
  "- The package archive excluded the local working tree; the external Route-B data and harness files were separately hash-recorded.",
  paste0("- Archive contained ", length(tracked_files), " tagged files. Local checkout state at start: ", tracked_change_count, " tracked change(s) and ", untracked_count, " untracked file(s), neither included in the package archive."),
  "",
  "## Documented Route-B inputs",
  "",
  paste0("- NOAA BlueTopo tile: `", route_b_tile, "`; the elevation crop, author-created analysis windows, and provenance manifest were SHA-256 verified in both runs."),
  "- The workflow used only the Route-B data root supplied to the worker; it did not call bundled legacy example fixtures.",
  "",
  "## Execution environment",
  "",
  paste0("- R: ", platform_value("r_version"), " (`", platform_value("r_platform"), "`)."),
  paste0("- blueterra: ", platform_value("package_version"), "; terra: ", platform_value("terra_version"), "."),
  paste0("- Random seed: `", seed, "` (Mersenne-Twister / Inversion / Rejection)."),
  paste0("- Fresh `Rscript --vanilla` processes: ", runs, "."),
  paste0("- Platform differences between paired runs: ", platform_differences, "; dependency-version differences: ", dependency_differences, "."),
  "",
  "## Comparison",
  "",
  paste0("- Compared ", nrow(comparison), " deterministic input, output-table, and schema/inventory record(s) between run_01 and run_02."),
  paste0("- Matching SHA-256 records: ", sum(comparison$identical_sha256), "/", nrow(comparison), "."),
  "- Binary raster and vector artifacts are represented by output schemas and inventory rather than claimed platform-independent binary hashes.",
  "- Full tag commit and archive SHA-256 values are retained only in the supplementary source manifest and machine-readable reproducibility manifest.",
  ""
)
writeLines(report, file.path(output_dir, "reproducibility_report.md"), useBytes = TRUE)

bt_repro_write_json(
  list(
    generated_at_utc = bt_repro_utc(),
    status = if (comparison_passed) "PASS" else "FAIL",
    source = list(
      release_tag = release_tag,
      commit_sha = tag_commit_sha,
      archive_sha256 = archive_sha256,
      archive_method = paste0("git archive ", release_tag),
      working_tree_used_for_package = FALSE,
      tracked_file_count = length(tracked_files),
      local_tracked_change_count = tracked_change_count,
      local_untracked_file_count = untracked_count
    ),
    route_b_inputs = list(
      tile_id = route_b_tile,
      data_root = data_root,
      input_hashes = as.list(stats::setNames(route_b_inputs$sha256, route_b_inputs$input_name))
    ),
    execution = list(
      random_seed = seed,
      fresh_r_processes = runs,
      r_version = platform_value("r_version"),
      r_platform = platform_value("r_platform"),
      blueterra_version = platform_value("package_version"),
      terra_version = platform_value("terra_version")
    ),
    comparison = list(
      artifacts_compared = nrow(comparison),
      artifacts_matching = sum(comparison$identical_sha256),
      all_hashes_match = comparison_passed,
      platform_differences = platform_differences,
      dependency_differences = dependency_differences
    )
  ),
  file.path(output_dir, "reproducibility_manifest.json")
)

if (!comparison_passed) {
  stop("The two clean-environment Route-B runs did not reproduce deterministic records; see reproducibility_comparison.csv.", call. = FALSE)
}

cat("Clean-environment Route-B reproducibility workflow passed. Results: ", output_dir, "\n", sep = "")
