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
  profile_direction = c("min_to_max", "max_to_min", "as_sampled", "low_to_high",
    "high_to_low"),
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

  Direction used to orient distance before plotting. `"min_to_max"` (the
  default) orients each profile so the selected value column begins with
  its lower numeric endpoint and ends with its higher numeric endpoint.
  `"max_to_min"` reverses that convention. `"as_sampled"` preserves the
  sampled line order. Legacy values `"low_to_high"` and `"high_to_low"`
  are accepted as aliases for `"min_to_max"` and `"max_to_min"`.

- positive_depth:

  Logical depth convention for `value_col`. This affects y-axis display
  for depth-like variables; profile direction is based on numeric
  endpoint order.

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
