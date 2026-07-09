# Filter or convert bathymetric depth values

Keeps raster values within a depth or elevation range, or explicitly
changes sign convention.

## Usage

``` r
depth_filter(
  x,
  depth_range,
  positive_depth = NULL,
  filename = "",
  overwrite = FALSE
)

invert_depth(x, filename = "", overwrite = FALSE)

set_depth_positive(x, filename = "", overwrite = FALSE)

set_depth_negative(x, filename = "", overwrite = FALSE)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- depth_range:

  Numeric length-two retained range.

- positive_depth:

  Optional logical. If `TRUE`, filtering is applied to absolute depth
  values. If `FALSE` or `NULL`, filtering is applied to the stored
  raster values.

- filename:

  Optional output raster path.

- overwrite:

  Logical. Allow overwriting `filename`.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

`depth_filter()` does not flip signs. Use `set_depth_positive()`,
`set_depth_negative()`, or `invert_depth()` for explicit sign changes.

## See also

[`check_bathy_units()`](https://el-cordero.github.io/blueterra/reference/check_bathy_units.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
depth_filter(bathy, c(-80, -30))
#> class       : SpatRaster
#> size        : 62, 189, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138737.2, 204551.3, 205790.3  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        :    bathy_m
#> min value   : -79.972115
#> max value   : -30.007963
set_depth_positive(bathy)
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        :    bathy_m
#> min value   :  15.878815
#> max value   : 427.298889
```
