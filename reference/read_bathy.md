# Read a bathymetric or elevation raster

Reads a local raster file with
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)
and optionally validates that the result is usable as a bathymetric or
elevation surface.

## Usage

``` r
read_bathy(path, ..., check = TRUE)
```

## Arguments

- path:

  Local raster file path.

- ...:

  Additional arguments passed to
  [`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html).

- check:

  Logical. If `TRUE`, validate the raster before returning it.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

`read_bathy()` is data-source agnostic. The input can be any local
raster format supported by `terra`, including GeoTIFF and many
GDAL-readable files. The function treats the raster as a user-supplied
terrain surface and preserves its values, CRS, resolution, and vertical
sign convention.

## See also

[`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md),
[`validate_bathy()`](https://el-cordero.github.io/blueterra/reference/validate_bathy.md),
[`prepare_bathy()`](https://el-cordero.github.io/blueterra/reference/prepare_bathy.md)

## Examples

``` r
path <- blueterra_example("bathy")
bathy <- read_bathy(path)
bathy
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source      : laparguera_slope_bathy.tif
#> name        :     bathy_m
#> min value   : -427.298889
#> max value   :  -15.878815
```
