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
  profile_direction = c("high_to_low", "as_sampled", "low_to_high"),
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

  Direction used to orient distance before plotting. `"high_to_low"`
  (the default) puts the shallow or higher-elevation end of each profile
  on the left. `"as_sampled"` preserves the sampled line order.
  `"low_to_high"` reverses the default.

- positive_depth:

  Logical depth convention for `value_col`. Use `TRUE` when larger
  positive values are deeper, `FALSE` when larger values are higher
  elevation, or `NULL` to infer from the value column.

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
