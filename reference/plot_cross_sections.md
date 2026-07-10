# Plot sampled cross-sections

Plots raster values against transect distance.

## Usage

``` r
plot_cross_sections(
  samples,
  value_col = NULL,
  group_col = "transect_id",
  color_col = NULL,
  show_legend = TRUE,
  points = FALSE,
  mean_profile = FALSE,
  normalize_distance = FALSE,
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

- samples:

  Output from
  [`sample_transects()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md).

- value_col:

  Optional value column.

- group_col:

  Grouping column for transect lines.

- color_col:

  Optional column used to color profiles. Defaults to `group_col`.

- show_legend:

  Logical. Show the line-color legend.

- points:

  Logical. Draw sample points over profile lines.

- mean_profile:

  Logical. Overlay a binned mean profile across transects.

- normalize_distance:

  Logical. Plot distance as 0-1 normalized position along each transect.

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

## See also

[`sample_transects()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md),
[`plot_depth_profile()`](https://el-cordero.github.io/blueterra/reference/plot_depth_profile.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  bathy <- read_bathy(blueterra_example("bathy"))
  zones <- terra::vect(blueterra_example("zones"))
  transects <- make_transects(zones[1, ], spacing = 100, bathy = bathy)
  samples <- sample_transects(transects, bathy, n = 5)
  plot_cross_sections(samples)
}

```
