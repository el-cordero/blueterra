#' blueterra: Process-oriented geomorphometry for submerged terrain
#'
#' @description
#' `blueterra` derives, organizes, summarizes, and visualizes terrain metrics
#' from user-supplied bathymetric or elevation rasters. It is intended for
#' submerged-landscape geomorphometry after a raster has already been obtained.
#'
#' @details
#' The package accepts `terra::SpatRaster` objects, local raster file paths, and
#' other raster inputs readable by `terra`. It does not download, discover,
#' mosaic, combine, cache, or otherwise acquire BlueTopo data or any other
#' remote bathymetry product.
#'
#' Depth convention is explicit. Some bathymetric rasters store depth as
#' negative elevation, while other workflows use positive depth. Functions
#' preserve the input sign unless a conversion function or argument asks for a
#' sign change.
#'
#' Terrain derivatives are sensitive to CRS, raster resolution, smoothing, and
#' focal-window scale. Use projected coordinate systems when distance, slope,
#' area, or buffering operations depend on linear units.
#'
#' @keywords internal
"_PACKAGE"
