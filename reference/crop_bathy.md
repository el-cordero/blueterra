# Crop, mask, resample, and project bathymetry

Small wrappers around `terra` raster-preparation operations with
bathymetry input validation.

## Usage

``` r
crop_bathy(x, extent, filename = "", overwrite = FALSE)

mask_bathy(x, mask, filename = "", overwrite = FALSE)

resample_bathy(x, y, method = "bilinear", filename = "", overwrite = FALSE)

project_bathy(x, crs, method = "bilinear", filename = "", overwrite = FALSE)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- extent:

  Crop extent.

- filename:

  Optional output raster path.

- overwrite:

  Logical. Allow overwriting `filename`.

- mask:

  Polygon/vector mask.

- y:

  Template raster used for resampling.

- method:

  Interpolation method passed to `terra`.

- crs:

  Target CRS.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

These helpers preserve depth sign and raster values except for
interpolation effects introduced by resampling or projection.

## See also

[`prepare_bathy()`](https://el-cordero.github.io/blueterra/reference/prepare_bathy.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
zones <- terra::vect(blueterra_example("zones"))
crop_bathy(bathy, terra::ext(zones[zones$site_id == "slope", ]))
#> class       : SpatRaster
#> size        : 90, 189, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138737.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        :     bathy_m
#> min value   : -427.298889
#> max value   :  -15.878815
```
