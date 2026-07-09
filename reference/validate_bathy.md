# Validate a bathymetric or elevation raster

Checks that an object is a readable
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
with dimensions, layers, and values suitable for terrain analysis.

## Usage

``` r
validate_bathy(
  x,
  require_crs = FALSE,
  require_values = TRUE,
  allow_multi = FALSE
)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- require_crs:

  Logical. If `TRUE`, require a declared CRS.

- require_values:

  Logical. If `TRUE`, require raster values.

- allow_multi:

  Logical. If `FALSE`, warn when more than one layer is supplied.

## Value

Invisibly returns the input raster.

## Details

Validation does not decide whether values represent positive depth or
negative elevation. Use
[`check_bathy_units()`](https://el-cordero.github.io/blueterra/reference/check_bathy_units.md),
[`set_depth_positive()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md),
or
[`set_depth_negative()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md)
when sign convention matters.

## See also

[`check_bathy_crs()`](https://el-cordero.github.io/blueterra/reference/check_bathy_crs.md),
[`check_bathy_units()`](https://el-cordero.github.io/blueterra/reference/check_bathy_units.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
validate_bathy(bathy)
```
