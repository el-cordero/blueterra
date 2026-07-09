# Smooth a bathymetric or elevation raster

Applies a square moving-window mean filter.

## Usage

``` r
smooth_bathy(x, window = 3, na.rm = TRUE, filename = "", overwrite = FALSE)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- window:

  Odd integer focal-window size.

- na.rm:

  Logical. Remove missing values inside the focal window.

- filename:

  Optional output raster path.

- overwrite:

  Logical. Allow overwriting `filename`.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

Smoothing changes local gradients and can strongly affect slope,
curvature, rugosity, TPI, and BPI. Use it deliberately and report the
window size.

## See also

[`prepare_bathy()`](https://el-cordero.github.io/blueterra/reference/prepare_bathy.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
smooth_bathy(bathy, window = 3)
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        :     bathy_m
#> min value   : -420.895859
#> max value   :  -15.948482
```
