# Coerce common raster inputs to a bathymetry raster

Accepts a
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
or a local raster file path and returns a
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Usage

``` r
as_bathy(x, ..., check = TRUE)
```

## Arguments

- x:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  or local raster path.

- ...:

  Additional arguments passed to
  [`read_bathy()`](https://el-cordero.github.io/blueterra/reference/read_bathy.md)
  when `x` is a path.

- check:

  Logical. If `TRUE`, validate the raster before returning it.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

`as_bathy()` preserves raster values and metadata when possible. It does
not flip signs, project CRS, or filter depths unless another function
explicitly requests that behavior.

## See also

[`read_bathy()`](https://el-cordero.github.io/blueterra/reference/read_bathy.md),
[`validate_bathy()`](https://el-cordero.github.io/blueterra/reference/validate_bathy.md)

## Examples

``` r
as_bathy(blueterra_example("bathy"))
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
