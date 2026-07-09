# Plot process density

Plots density curves for one or more process-group metrics.

## Usage

``` r
plot_process_density(data, value, group = NULL)
```

## Arguments

- data:

  A data frame of terrain values.

- value:

  Character name of the numeric value column.

- group:

  Optional grouping column.

## Value

A `ggplot` object.

## See also

[`assign_process_groups()`](https://el-cordero.github.io/blueterra/reference/assign_process_groups.md)

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  df <- data.frame(value = rnorm(20), process = rep(c("a", "b"), each = 10))
  plot_process_density(df, value = "value", group = "process")
}

```
