# Build isobath corridors

Buffers isobath contour lines to create depth-following corridor
polygons.

## Usage

``` r
make_isobath_corridors(
  x,
  depths,
  width,
  smooth = FALSE,
  as = c("SpatVector", "sf"),
  positive_depth = NULL,
  ...
)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- depths:

  Numeric contour levels.

- width:

  Buffer width in map units.

- smooth:

  Logical. If `TRUE`, apply a zero-width buffer after buffering to clean
  polygon topology.

- as:

  Output type: `"SpatVector"` or `"sf"`.

- positive_depth:

  Optional logical. If `TRUE`, `depths` are converted to positive
  values. If `FALSE`, they are converted to negative values. If `NULL`,
  `depths` are used exactly as supplied.

- ...:

  Additional arguments reserved for future extensions.

## Value

Isobath corridor polygons as
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
by default.

## Details

`width` is interpreted in the CRS map units. Projected CRS are strongly
recommended. If the raster uses longitude/latitude, the function warns
before buffering because distance interpretation may be misleading.

## See also

[`extract_isobaths()`](https://el-cordero.github.io/blueterra/reference/extract_isobaths.md),
[`summarize_isobath_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_isobath_terrain.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
make_isobath_corridors(bathy, depths = c(-40, -60), width = 5)
#> class       : SpatVector
#> geometry    : polygons
#> dimensions  : 2, 4  (geometries, attributes)
#> extent      : 134965.3, 138732.2, 204565.3, 205790.1  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> names       : level contour_value depth_label corridor_id
#> type        : <num>         <num>       <num>       <int>
#> values      :   -40           -40         -40           1
#>                 -60           -60         -60           2
```
