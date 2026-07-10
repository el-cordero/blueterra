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
  attrs <- as.data.frame(x)
  if (nrow(attrs) > 0) {
    attr_names <- setdiff(names(attrs), names(geom))
    for (nm in attr_names) {
      geom[[nm]] <- attrs[[nm]][geom$geom]
    }
  }
  tibble::as_tibble(geom)
}

infer_profile_value_col <- function(
    data,
    value_col = NULL,
    preferred = NULL,
    exclude = character(),
    require_finite = TRUE,
    require_variation = TRUE
) {
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  numeric_cols <- names(data)[vapply(data, is.numeric, logical(1))]
  if (!is.null(value_col)) {
    if (!is.character(value_col) || length(value_col) != 1 || !value_col %in% names(data)) {
      bt_abort("`value_col` was not found in `data`.")
    }
    if (!is.numeric(data[[value_col]])) {
      bt_abort("`value_col` must identify a numeric column.")
    }
    values <- data[[value_col]]
    finite_values <- values[is.finite(values)]
    if (isTRUE(require_finite) && length(finite_values) == 0) {
      bt_abort(paste0("`", value_col, "` does not contain finite values."))
    }
    if (isTRUE(require_variation) && length(unique(finite_values)) < 2) {
      bt_abort(paste0("`", value_col, "` does not contain enough variation for a profile."))
    }
    return(value_col)
  }

  preferred <- preferred %||% c(
    "bathy_m", "bathy", "depth", "elevation", "z",
    "slope_deg", "slope_rad", "aspect_deg", "aspect_rad",
    "northness", "eastness", "tri", "roughness", "rugosity_vrm_3x3",
    "bpi_3x3", "bpi_11x11", "curvature", "surface_area_ratio"
  )
  default_exclude <- c(
    "distance", "normalized_distance", "x", "y", "ID", "id", "cell",
    "row", "col", "zone_id", "corridor_id", "transect_id", "site_id",
    "width_m", "height_m", "angle_deg", "angle_source", "mean_aspect_deg",
    "n_orientation_cells", "orientation_weight", "offset", "feature_type",
    "contour_value", "depth_label"
  )
  exclude <- unique(c(default_exclude, exclude))
  candidates <- setdiff(numeric_cols, exclude)
  if (length(candidates) > 0 && isTRUE(require_finite)) {
    finite <- vapply(candidates, function(nm) any(is.finite(data[[nm]])), logical(1))
    candidates <- candidates[finite]
  }
  if (length(candidates) > 0 && isTRUE(require_variation)) {
    varied <- vapply(candidates, function(nm) {
      values <- data[[nm]]
      values <- values[is.finite(values)]
      length(unique(values)) >= 2
    }, logical(1))
    if (any(varied)) {
      candidates <- candidates[varied]
    }
  }
  if (length(candidates) == 0) {
    available <- if (length(numeric_cols) == 0) "none" else paste(numeric_cols, collapse = ", ")
    bt_abort(paste0(
      "Could not identify a numeric profile value column. ",
      "Available numeric columns: ", available, "."
    ))
  }
  preferred_matches <- intersect(preferred, candidates)
  if (length(preferred_matches) > 0) {
    return(preferred_matches[[1]])
  }
  candidates[[1]]
}

terrain_value_column <- function(
    data,
    value_col = NULL,
    exclude = character(),
    context = "value"
) {
  infer_profile_value_col(
    data = data,
    value_col = value_col,
    exclude = exclude,
    require_finite = TRUE,
    require_variation = FALSE
  )
}

orient_profile_distance <- function(
    data,
    value_col,
    distance_col = "distance",
    group_col = NULL,
    profile_direction = c("high_to_low", "as_sampled", "low_to_high"),
    positive_depth = NULL
) {
  profile_direction <- match.arg(profile_direction)
  if (!is.data.frame(data)) {
    bt_abort("`data` must be a data frame.")
  }
  if (!value_col %in% names(data) || !is.numeric(data[[value_col]])) {
    bt_abort("`value_col` must identify a numeric column in `data`.")
  }
  if (!distance_col %in% names(data) || !is.numeric(data[[distance_col]])) {
    bt_abort("`distance_col` must identify a numeric column in `data`.")
  }
  if (!is.null(group_col) && !group_col %in% names(data)) {
    bt_abort("`group_col` was not found in `data`.")
  }
  if (!is.null(positive_depth) && (!is.logical(positive_depth) || length(positive_depth) != 1)) {
    bt_abort("`positive_depth` must be `TRUE`, `FALSE`, or `NULL`.")
  }

  if (!"distance_original" %in% names(data)) {
    data$distance_original <- data[[distance_col]]
  }
  data$profile_reversed <- FALSE

  groups <- if (is.null(group_col)) {
    rep("profile", nrow(data))
  } else {
    data[[group_col]]
  }
  pieces <- split(data, groups, drop = TRUE)
  pieces <- lapply(pieces, function(piece) {
    piece <- piece[order(piece[[distance_col]]), , drop = FALSE]
    if (profile_direction == "as_sampled") {
      return(piece)
    }

    finite <- is.finite(piece[[distance_col]]) & is.finite(piece[[value_col]])
    if (sum(finite) < 2) {
      return(piece)
    }
    finite_piece <- piece[finite, , drop = FALSE]
    first_value <- finite_piece[[value_col]][1]
    last_value <- finite_piece[[value_col]][nrow(finite_piece)]
    depth_positive <- infer_positive_depth_values(
      finite_piece[[value_col]],
      value_col = value_col,
      positive_depth = positive_depth
    )

    high_to_low_now <- if (isTRUE(depth_positive)) {
      first_value <= last_value
    } else {
      first_value >= last_value
    }
    should_reverse <- switch(
      profile_direction,
      high_to_low = !high_to_low_now,
      low_to_high = high_to_low_now
    )
    if (isTRUE(should_reverse)) {
      max_distance <- max(piece[[distance_col]], na.rm = TRUE)
      piece[[distance_col]] <- max_distance - piece[[distance_col]]
      piece$profile_reversed <- TRUE
      piece <- piece[order(piece[[distance_col]]), , drop = FALSE]
    }
    piece
  })
  dplyr::bind_rows(pieces)
}

infer_positive_depth_values <- function(values, value_col, positive_depth = NULL) {
  if (!is.null(positive_depth)) {
    return(isTRUE(positive_depth))
  }
  finite <- values[is.finite(values)]
  if (!length(finite)) {
    return(FALSE)
  }
  if (mean(finite < 0) > 0.5) {
    return(FALSE)
  }
  if (all(finite >= 0) && grepl("depth", value_col, ignore.case = TRUE)) {
    return(TRUE)
  }
  FALSE
}

#' Locate package example files
#'
#' @description
#' Returns the path to a small file installed with `blueterra`.
#'
#' @param name Example name. Use `"hitw"`, `"hoyo"`, or `"slope"` for
#'   reduced bathymetry rasters from the southwest Puerto Rico shelf margin
#'   near La Parguera; `"sampling_rectangles"` for the accompanying vector
#'   layer; `"bathy"` and `"zones"` as short aliases; or `"synthetic_bathy"`
#'   and `"synthetic_zones"` for test fixtures.
#'
#' @return A normalized local file path.
#'
#' @details
#' The primary examples are reduced analysis rasters and sampling rectangles
#' from the southwest Puerto Rico shelf margin near La Parguera. The synthetic
#' files are retained for numerical tests where a simple known surface is
#' useful.
#'
#' @examples
#' hitw <- blueterra_example("hitw")
#' rectangles <- blueterra_example("sampling_rectangles")
#' file.exists(c(hitw, rectangles))
#' blueterra_examples()
#'
#' @seealso [read_bathy()]
#' @export
blueterra_example <- function(
    name = c(
      "hitw",
      "hoyo",
      "slope",
      "sampling_rectangles",
      "bathy",
      "zones",
      "sites",
      "synthetic_bathy",
      "synthetic_zones"
    )
) {
  name <- match.arg(name)
  file <- switch(
    name,
    hitw = "laparguera_hitw_bathy.tif",
    hoyo = "laparguera_hoyo_bathy.tif",
    slope = "laparguera_slope_bathy.tif",
    sampling_rectangles = "laparguera_sampling_rectangles.gpkg",
    bathy = "laparguera_slope_bathy.tif",
    zones = "laparguera_sampling_rectangles.gpkg",
    sites = "laparguera_sampling_rectangles.gpkg",
    synthetic_bathy = "synthetic_test_bathy.tif",
    synthetic_zones = "synthetic_test_zones.gpkg"
  )
  blueterra_extdata(file)
}

#' @rdname blueterra_example
#'
#' @return `blueterra_examples()` returns a tibble describing installed example
#'   files.
#' @export
blueterra_examples <- function() {
  examples <- data.frame(
    name = c(
      "hitw",
      "hoyo",
      "slope",
      "sampling_rectangles",
      "synthetic_bathy",
      "synthetic_zones"
    ),
    file = c(
      "laparguera_hitw_bathy.tif",
      "laparguera_hoyo_bathy.tif",
      "laparguera_slope_bathy.tif",
      "laparguera_sampling_rectangles.gpkg",
      "synthetic_test_bathy.tif",
      "synthetic_test_zones.gpkg"
    ),
    type = c("raster", "raster", "raster", "vector", "raster", "vector"),
    description = c(
      "Reduced Hole-in-the-Wall bathymetry, southwest Puerto Rico shelf margin.",
      "Reduced El Hoyo bathymetry, southwest Puerto Rico shelf margin.",
      "Aggregated slope-clip bathymetry along the southwest Puerto Rico shelf margin.",
      "Sampling rectangles and slope analysis extent near La Parguera, Puerto Rico.",
      "Synthetic bathymetry surface retained for numerical tests.",
      "Synthetic polygon zones retained for numerical tests."
    ),
    stringsAsFactors = FALSE
  )

  examples$path <- vapply(examples$file, blueterra_extdata, character(1))
  examples$crs <- NA_character_
  examples$nrow <- NA_integer_
  examples$ncol <- NA_integer_
  examples$feature_count <- NA_integer_

  for (i in seq_len(nrow(examples))) {
    if (examples$type[[i]] == "raster") {
      r <- terra::rast(examples$path[[i]])
      examples$crs[[i]] <- terra::crs(r, proj = TRUE)
      examples$nrow[[i]] <- terra::nrow(r)
      examples$ncol[[i]] <- terra::ncol(r)
    } else {
      v <- terra::vect(examples$path[[i]])
      examples$crs[[i]] <- terra::crs(v, proj = TRUE)
      examples$feature_count[[i]] <- terra::nrow(v)
    }
  }

  tibble::as_tibble(examples[c(
    "name",
    "path",
    "type",
    "description",
    "crs",
    "nrow",
    "ncol",
    "feature_count"
  )])
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
