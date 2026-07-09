# Extract isobaths from a raster

Converts raster contour levels to line features.

## Usage

``` r
extract_isobaths(
  x,
  depths,
  positive_depth = NULL,
  as = c("SpatVector", "sf"),
  ...
)
```

## Arguments

- x:

  A raster-like object accepted by
  [`as_bathy()`](https://el-cordero.github.io/blueterra/reference/as_bathy.md).

- depths:

  Numeric contour levels.

- positive_depth:

  Optional logical. If `TRUE`, `depths` are converted to positive
  values. If `FALSE`, they are converted to negative values. If `NULL`,
  `depths` are used exactly as supplied.

- as:

  Output type: `"SpatVector"` or `"sf"`.

- ...:

  Additional arguments reserved for future extensions.

## Value

Isobath line features as
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
by default.

## Details

Depth convention is explicit. For rasters stored as negative elevation,
either pass negative `depths` or set `positive_depth = FALSE` when
passing positive depth labels.

## See also

[`make_isobath_corridors()`](https://el-cordero.github.io/blueterra/reference/make_isobath_corridors.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
extract_isobaths(bathy, depths = c(-40, -60))
#> class       : SpatVector
#> geometry    : lines
#> dimensions  : 2, 3  (geometries, attributes)
#> extent      : 134970.3, 138727.2, 204570.3, 205785.1  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> names       : level contour_value depth_label
#> type        : <num>         <num>       <num>
#> values      :   -40           -40         -40
#>                 -60           -60         -60
```
