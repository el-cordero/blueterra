# Derive bathymetric position index

Computes a local bathymetric position index from the difference between
each cell and its focal-neighborhood mean.

## Usage

``` r
derive_bpi(
  x,
  inner_radius = NULL,
  outer_radius = NULL,
  window = NULL,
  scale = c("fine", "broad", "custom"),
  normalize = FALSE,
  filename = "",
  overwrite = FALSE,
  ...
)

derive_multiscale_bpi(
  x,
  windows = c(3, 11),
  normalize = FALSE,
  filename = "",
  overwrite = FALSE,
  ...
)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- inner_radius:

  Optional inner radius for an annulus window in map units.

- outer_radius:

  Optional outer radius for an annulus window in map units.

- window:

  Optional odd integer square window size in cells.

- scale:

  Preset scale when `window` and `outer_radius` are not supplied.

- normalize:

  Logical. If `TRUE`, divide BPI by local focal standard deviation.
  Zero-variance or unavailable focal neighborhoods return `NA`.

- filename:

  Optional output raster path.

- overwrite:

  Logical. Allow overwriting `filename`.

- ...:

  Reserved for future extensions.

- windows:

  Integer vector of odd square window sizes.

## Value

A single-layer
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

The calculation is `cell value - focal mean`. Positive values therefore
mean higher-than-neighborhood values when the raster is elevation-like.
For positive-depth rasters, interpretation is reversed unless users
convert the sign convention first. Square windows are measured in cells
and include the focal cell. Annular windows are measured in map units,
require a projected CRS with linear units, and use separate x- and
y-cell resolutions when cells are not square. At raster edges and next
to missing cells, BPI uses the available cells in its partial focal
support; a missing focal value remains missing.

## See also

`derive_multiscale_bpi()`,
[`derive_tpi()`](https://el-cordero.github.io/blueterra/reference/derive_slope.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
derive_bpi(bathy, window = 5)
#> class       : SpatRaster
#> size        : 90, 190, 1  (nrow, ncol, nlyr)
#> resolution  : 19.98372, 19.98372  (x, y)
#> extent      : 134960.3, 138757.2, 204151.7, 205950.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> source(s)   : memory
#> varname     : laparguera_slope_bathy
#> name        :    bpi_5x5
#> min value   : -26.339658
#> max value   :  35.789692
```
