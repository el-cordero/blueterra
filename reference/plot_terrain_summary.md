# Plot terrain summaries

Plots a summary column from
[`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)
or related functions.

## Usage

``` r
plot_terrain_summary(summary, value, group = NULL)
```

## Arguments

- summary:

  A summary data frame.

- value:

  Summary value column.

- group:

  Optional x-axis grouping column. Defaults to `zone_id` when present.

## Value

A `ggplot` object.

## See also

[`summarize_terrain()`](https://el-cordero.github.io/blueterra/reference/summarize_terrain.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  df <- data.frame(zone_id = 1:3, slope_mean = c(5, 7, 2))
  plot_terrain_summary(df, value = "slope_mean")
}

```
