bt_abort <- function(message) {
  cli::cli_abort(message, call = rlang::caller_env())
}

bt_warn <- function(message) {
  cli::cli_warn(message)
}

check_installed <- function(pkg, reason = NULL) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    return(invisible(TRUE))
  }
  msg <- paste0("Package '", pkg, "' is required")
  if (!is.null(reason)) {
    msg <- paste0(msg, " ", reason)
  }
  msg <- paste0(msg, ". Install it to use this function.")
  bt_abort(msg)
}

is_spatraster <- function(x) {
  inherits(x, "SpatRaster")
}

is_spatvector <- function(x) {
  inherits(x, "SpatVector")
}

is_sf <- function(x) {
  inherits(x, "sf") || inherits(x, "sfc")
}

has_filename <- function(filename) {
  is.character(filename) && length(filename) == 1 && nzchar(filename)
}

write_raster_if_requested <- function(x, filename = "", overwrite = FALSE) {
  if (has_filename(filename)) {
    x <- terra::writeRaster(x, filename = filename, overwrite = overwrite)
  }
  x
}

clean_layer_name <- function(x) {
  x <- tolower(as.character(x))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  make.unique(x, sep = "_")
}

set_clean_names <- function(x, names) {
  names(x) <- clean_layer_name(names)
  x
}

combine_rasters <- function(layers) {
  layers <- Filter(Negate(is.null), layers)
  if (length(layers) == 0) {
    bt_abort("No raster layers were supplied.")
  }
  out <- layers[[1]]
  if (length(layers) > 1) {
    for (i in seq.int(2, length(layers))) {
      out <- c(out, layers[[i]])
    }
  }
  out
}

first_layer <- function(x) {
  x <- as_bathy(x, check = TRUE)
  if (terra::nlyr(x) > 1) {
    bt_warn("Only the first raster layer is used for this operation.")
    x <- x[[1]]
  }
  x
}

as_spat_extent <- function(x) {
  if (inherits(x, "SpatExtent")) {
    return(x)
  }
  if (is.numeric(x) && length(x) == 4) {
    return(terra::ext(x[1], x[2], x[3], x[4]))
  }
  if (is_spatraster(x) || is_spatvector(x)) {
    return(terra::ext(x))
  }
  if (is_sf(x)) {
    check_installed("sf", "to use sf objects")
    return(terra::ext(terra::vect(x)))
  }
  bt_abort("`extent` must be a SpatExtent, numeric xmin/xmax/ymin/ymax vector, raster, or vector object.")
}

as_spatvector <- function(x) {
  if (is_spatvector(x)) {
    return(x)
  }
  if (is_sf(x)) {
    check_installed("sf", "to use sf objects")
    return(terra::vect(x))
  }
  if (is.character(x) && length(x) == 1) {
    if (!file.exists(x)) {
      bt_abort("Vector file does not exist.")
    }
    return(terra::vect(x))
  }
  bt_abort("Expected an sf object, SpatVector, or local vector file path.")
}

as_sf_object <- function(x) {
  check_installed("sf", "to use sf objects")
  if (inherits(x, "sf")) {
    return(x)
  }
  if (inherits(x, "sfc")) {
    return(sf::st_sf(geometry = x))
  }
  if (is_spatvector(x)) {
    return(sf::st_as_sf(x))
  }
  if (is.character(x) && length(x) == 1) {
    if (!file.exists(x)) {
      bt_abort("Vector file does not exist.")
    }
    return(sf::st_read(x, quiet = TRUE))
  }
  bt_abort("Expected an sf object, SpatVector, or local vector file path.")
}

is_lonlat <- function(x) {
  out <- try(terra::is.lonlat(x), silent = TRUE)
  if (inherits(out, "try-error") || is.na(out)) {
    return(FALSE)
  }
  isTRUE(out)
}

require_projected <- function(x, operation = "this operation") {
  if (!nzchar(terra::crs(x))) {
    bt_abort(paste0("A CRS is required for ", operation, "."))
  }
  if (is_lonlat(x)) {
    bt_abort(paste0(
      "A projected CRS with linear map units is required for ",
      operation, ". Reproject explicitly before continuing."
    ))
  }
  invisible(TRUE)
}

safe_global_range <- function(x) {
  mm <- try(terra::global(x, c("min", "max"), na.rm = TRUE), silent = TRUE)
  if (inherits(mm, "try-error") || nrow(mm) < 1) {
    return(c(min = NA_real_, max = NA_real_))
  }
  c(min = as.numeric(mm[1, "min"]), max = as.numeric(mm[1, "max"]))
}

safe_summary_funs <- function(fun) {
  allowed <- c("mean", "sd", "min", "max", "median", "sum", "count")
  if (is.null(fun)) {
    fun <- c("mean", "sd", "min", "max", "median")
  }
  fun <- match.arg(fun, allowed, several.ok = TRUE)
  fun
}

apply_summary_fun <- function(x, fun, na.rm = TRUE) {
  x <- as.numeric(x)
  if (fun == "count") {
    return(sum(!is.na(x)))
  }
  if (na.rm) {
    x <- x[!is.na(x)]
  }
  if (length(x) == 0) {
    return(NA_real_)
  }
  switch(
    fun,
    mean = mean(x),
    sd = if (length(x) > 1) stats::sd(x) else NA_real_,
    min = min(x),
    max = max(x),
    median = stats::median(x),
    sum = sum(x),
    bt_abort("Unknown summary function.")
  )
}

standard_output <- function(df) {
  tibble::as_tibble(df)
}

optional_ggplot2 <- function() {
  check_installed("ggplot2", "for plotting")
}

raster_plot_data <- function(x, max_cells = 10000) {
  x <- as_bathy(x, check = FALSE)
  validate_bathy(x, allow_multi = TRUE)
  if (terra::ncell(x) > max_cells) {
    x <- terra::spatSample(x, size = max_cells, method = "regular", as.raster = TRUE)
  }
  df <- terra::as.data.frame(x, xy = TRUE, na.rm = TRUE)
  tibble::as_tibble(df)
}

vector_plot_data <- function(x) {
  x <- as_spatvector(x)
  geom <- as.data.frame(terra::geom(x))
  if (!all(c("geom", "part", "x", "y") %in% names(geom))) {
    bt_abort("Vector geometry could not be converted to plot coordinates.")
  }
  geom$group <- paste(geom$geom, geom$part, sep = "_")
  tibble::as_tibble(geom)
}

#' Locate package example files
#'
#' @description
#' Returns the path to a small file installed with `blueterra`.
#'
#' @param name Example name. Use `"bathy"` for the synthetic raster or `"zones"`
#'   for the synthetic polygon layer. `"sites"` is accepted as a compatibility
#'   alias.
#'
#' @return A normalized local file path.
#'
#' @details
#' The example files are synthetic and are intended for tests, examples, and
#' vignettes. The raster contains a depth gradient, ridge, basin, and slope
#' break; the vector file contains two polygon zones.
#'
#' @examples
#' blueterra_example("bathy")
#' blueterra_extdata("example_bathy.tif")
#'
#' @seealso [read_bathy()]
#' @export
blueterra_example <- function(name = c("bathy", "zones", "sites")) {
  name <- match.arg(name)
  file <- switch(
    name,
    bathy = "example_bathy.tif",
    zones = "example_zones.gpkg",
    sites = "example_zones.gpkg"
  )
  blueterra_extdata(file)
}

#' @rdname blueterra_example
#' @param file File name under `inst/extdata`.
#' @export
blueterra_extdata <- function(file = NULL) {
  if (is.null(file)) {
    return(system.file("extdata", package = "blueterra"))
  }
  path <- system.file("extdata", file, package = "blueterra", mustWork = TRUE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

#' Configure blueterra runtime options
#'
#' @description
#' Returns or sets package options used by examples and helper functions.
#'
#' @param ... Named option values. Currently supported options are
#'   `blueterra.progress` and `blueterra.max_plot_cells`.
#'
#' @return A named list with current option values, invisibly when setting.
#'
#' @details
#' Options affect only local package behavior and do not write outside paths
#' provided by the user.
#'
#' @examples
#' blueterra_options()
#' old <- blueterra_options(blueterra.progress = FALSE)
#' blueterra_options(blueterra.progress = old$blueterra.progress)
#'
#' @export
blueterra_options <- function(...) {
  opts <- list(...)
  valid <- c("blueterra.progress", "blueterra.max_plot_cells")
  if (length(opts) > 0) {
    bad <- setdiff(names(opts), valid)
    if (length(bad) > 0) {
      bt_abort(paste0("Unknown blueterra option: ", paste(bad, collapse = ", ")))
    }
    old <- options(opts)
    return(invisible(old))
  }
  defaults <- list(
    blueterra.progress = getOption("blueterra.progress", TRUE),
    blueterra.max_plot_cells = getOption("blueterra.max_plot_cells", 10000)
  )
  defaults
}
