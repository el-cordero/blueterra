# Create transects across polygon zones

Builds regularly spaced straight transects through polygon features.

## Usage

``` r
make_transects(
  area,
  spacing,
  angle = NULL,
  bathy = NULL,
  orientation = c("auto", "surface", "bbox", "manual"),
  orientation_weight = c("slope", "none"),
  min_slope = 0,
  length = NULL,
  id_field = NULL,
  as = c("SpatVector", "sf")
)
```

## Arguments

- area:

  A
  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html),
  local vector path, or optional `sf` polygon object.

- spacing:

  Distance between transects in map units.

- angle:

  Optional transect direction in degrees counterclockwise from the
  projected x axis. When supplied, this manual value overrides
  orientation estimation.

- bathy:

  Optional bathymetry raster used to estimate a terrain-based transect
  orientation when `angle = NULL`.

- orientation:

  Orientation strategy. `"auto"` uses surface orientation when `bathy`
  is supplied and otherwise falls back to the historical horizontal line
  angle with a warning. `"surface"` requires `bathy`, `"bbox"` uses the
  polygon bounding-box axis, and `"manual"` requires `angle`.

- orientation_weight:

  Weighting for surface orientation. `"slope"` gives steeper cells more
  influence; `"none"` averages aspect components equally.

- min_slope:

  Minimum slope, in degrees, used when `orientation_weight = "slope"`.

- length:

  Optional transect length in map units. If `NULL`, a length based on
  the polygon bounding box is used.

- id_field:

  Optional field in `area` used as the zone identifier.

- as:

  Output type: `"SpatVector"` or `"sf"`.

## Value

A
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
by default. If `as = "sf"`, an `sf` object is returned and the optional
`sf` package must be installed.

## Details

Transect spacing and length are interpreted in map units. Use a
projected CRS for metric distances. Candidate lines are created through
each polygon bounding box and clipped to the polygon with
[`terra::intersect()`](https://rspatial.github.io/terra/reference/intersect.html).

With `angle = NULL` and a supplied `bathy` raster, the default transect
direction is estimated from the mean surface aspect within each polygon.
Aspect is converted to northness and eastness, averaged as circular
components, and converted to the mathematical line angle used for
transect generation. For example, a south-facing mean aspect near 180
degrees yields a transect angle near 90 degrees, producing north-south
transects in projected coordinates. The estimated angle and source
metadata are stored on the output lines so the orientation can be
inspected.

## See also

[`estimate_surface_orientation()`](https://el-cordero.github.io/blueterra/reference/estimate_surface_orientation.md),
[`sample_transects()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md),
[`extract_cross_sections()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md)

## Examples

``` r
zones <- terra::vect(blueterra_example("zones"))
bathy <- read_bathy(blueterra_example("bathy"))
transects <- make_transects(zones[1, ], spacing = 50, bathy = bathy)
transects
#> class       : SpatVector
#> geometry    : lines
#> dimensions  : 6, 14  (geometries, attributes)
#> extent      : 137487.8, 137761.1, 205591, 205891  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> names       : site_id        site_name    feature_type      source_name width_m height_m angle_deg zone_id   offset angle_source   (and 4 more)
#> type        :   <chr>            <chr>           <chr>            <chr>   <num>    <num>     <num>   <chr>    <num>        <chr>
#> values      :    hitw Hole-in-the-Wall sampling_recta~ Hole In the Wall     300      300    94.311       1 -124.264      surface
#>                  hitw Hole-in-the-Wall sampling_recta~ Hole In the Wall     300      300    94.311       1 -74.2641      surface
#>                  hitw Hole-in-the-Wall sampling_recta~ Hole In the Wall     300      300    94.311       1 -24.2641      surface
#>               ...

manual <- make_transects(zones[1, ], spacing = 50, angle = 90)
manual[, c("angle_deg", "angle_source")]
#> class       : SpatVector
#> geometry    : lines
#> dimensions  : 6, 2  (geometries, attributes)
#> extent      : 137499.5, 137749.5, 205591, 205891  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83 / Puerto Rico & Virgin Is. (EPSG:32161)
#> names       : angle_deg angle_source
#> type        :     <num>        <chr>
#> values      :        90       manual
#>                      90       manual
#>                      90       manual
#>               ...
```
