# Plot a depth profile

Plots a sampled raster value along a transect profile.

## Usage

``` r
plot_depth_profile(
  data,
  distance_col = "distance",
  depth_col = NULL,
  value_col = NULL,
  group_col = NULL,
  points = TRUE,
  line = TRUE,
  profile_direction = c("top_to_bottom", "bottom_to_top", "as_sampled", "max_to_min",
    "min_to_max", "high_to_low", "low_to_high"),
  positive_depth = NULL,
  depth_increases_down = TRUE,
  title = NULL,
  subtitle = NULL,
  caption = NULL
)
```

## Arguments

- data:

  A data frame.

- distance_col:

  Distance column name.

- depth_col:

  Depth, elevation, or metric column name. If `NULL`, a raster value
  column is inferred while ignoring transect metadata.

- value_col:

  Alias for `depth_col`. Use this when plotting sampled variables such
  as slope, rugosity, BPI, or curvature.

- group_col:

  Optional grouping column.

- points:

  Logical. Draw profile points.

- line:

  Logical. Draw profile lines when at least two finite samples are
  available.

- profile_direction:

  Direction used to orient distance before plotting. `"top_to_bottom"`
  (the default) orients bathymetric or elevation profiles from the
  shallow or top endpoint toward the deeper or bottom endpoint. With
  negative-elevation bathymetry this means higher numeric values to
  lower numeric values. With positive-depth bathymetry, set
  `positive_depth = TRUE` so the profile runs from lower depth values to
  higher depth values. `"bottom_to_top"` reverses that convention.
  `"max_to_min"` and `"min_to_max"` provide explicit numeric endpoint
  controls for metrics, and `"as_sampled"` preserves the sampled line
  order. Legacy values `"high_to_low"` and `"low_to_high"` are accepted
  as aliases for `"top_to_bottom"` and `"bottom_to_top"`.

- positive_depth:

  Logical depth convention for `value_col`. This affects top-to-bottom
  profile orientation for depth-like variables and y-axis display for
  positive-depth values.

- depth_increases_down:

  Logical. If `TRUE`, positive-depth profiles are plotted with a
  reversed y-axis so larger depths appear lower in the panel.

- title, subtitle, caption:

  Plot text.

## Value

A `ggplot` object.

## Details

Despite the function name, the y-axis can be any sampled raster
variable: elevation, depth, slope, rugosity, BPI, curvature, or a custom
metric. Metadata columns such as transect angle, offset, width, and
height are ignored during automatic value-column inference.

## See also

[`sample_transects()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  df <- data.frame(distance = 1:5, depth = -c(10, 12, 20, 25, 30))
  plot_depth_profile(df, depth_col = "depth")
}

```
