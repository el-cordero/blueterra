# Balance samples across groups

Down-samples or samples with replacement so each group has the same
number of rows.

## Usage

``` r
balance_samples(data, group, n = NULL, replace = FALSE, seed = NULL)
```

## Arguments

- data:

  A data frame.

- group:

  Character name of the grouping column.

- n:

  Optional number of rows per group. Defaults to the smallest group size
  when `replace = FALSE`.

- replace:

  Logical. Sample with replacement.

- seed:

  Optional random seed.

## Value

A tibble.

## See also

[`prepare_model_matrix()`](https://el-cordero.github.io/blueterra/reference/prepare_model_matrix.md)

## Examples

``` r
df <- data.frame(group = rep(c("a", "b"), c(2, 5)), value = seq_len(7))
balance_samples(df, group = "group")
#> # A tibble: 4 × 2
#>   group value
#>   <chr> <int>
#> 1 a         1
#> 2 a         2
#> 3 b         6
#> 4 b         5
```
