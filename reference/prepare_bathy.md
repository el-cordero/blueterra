# Prepare a bathymetric or elevation raster

Applies common preprocessing steps for terrain analysis: optional
projection, resampling, cropping, masking, depth filtering, sign
conversion, smoothing, and optional file-backed output.

## Usage

``` r
prepare_bathy(
  x,
  crs = NULL,
  resolution = NULL,
  extent = NULL,
  mask = NULL,
  depth_range = NULL,
  positive_depth = NULL,
  method = "bilinear",
  smooth = FALSE,
  smooth_window = 3,
  filename = "",
  overwrite = FALSE
)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- crs:

  Optional target CRS passed to
  [`project_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md).

- resolution:

  Optional target cell size. A single value is used for both axes; two
  values are used as x and y resolution.

- extent:

  Optional crop extent: `SpatExtent`, numeric `xmin, xmax, ymin, ymax`,
  raster, or vector object.

- mask:

  Optional polygon/vector mask.

- depth_range:

  Optional numeric length-two range of retained depths or elevations.

- positive_depth:

  Optional logical. If `TRUE`, convert output to positive depth. If
  `FALSE`, convert output to negative depth/elevation. If `NULL`,
  preserve sign convention.

- method:

  Resampling and projection method passed to `terra`.

- smooth:

  Logical. If `TRUE`, apply
  [`smooth_bathy()`](https://el-cordero.github.io/blueterra/reference/smooth_bathy.md).

- smooth_window:

  Odd integer focal-window size for smoothing.

- filename:

  Optional output raster path.

- overwrite:

  Logical. Allow overwriting `filename`.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

`prepare_bathy()` never automatically reprojects or flips depth signs.
Those operations occur only when `crs` or `positive_depth` are supplied.
Distance- based geomorphometry should generally be performed in a
projected CRS with linear units.

## See also

[`crop_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md),
[`mask_bathy()`](https://el-cordero.github.io/blueterra/reference/crop_bathy.md),
[`depth_filter()`](https://el-cordero.github.io/blueterra/reference/depth_filter.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
prepared <- prepare_bathy(bathy, depth_range = c(-90, -20), smooth = TRUE)
prepared
#> class       : SpatRaster
#> size        : 70, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204531.4, 205930.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        :    bathy_m
#> min value   :  -87.28957
#> max value   : -20.039104
```
