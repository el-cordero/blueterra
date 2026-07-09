# Terrain effect sizes

Computes standardized differences between two groups for numeric terrain
variables.

## Usage

``` r
terrain_effect_size(data, group, vars = NULL, method = "cohens_d", ...)
```

## Arguments

- data:

  A data frame.

- group:

  Character name of the grouping column.

- vars:

  Optional character vector of numeric variables.

- method:

  Effect-size method. Currently `"cohens_d"`.

- ...:

  Reserved for future methods.

## Value

A tibble with one row per variable.

## Details

Cohen's d is computed as the difference in group means divided by pooled
standard deviation. Exactly two non-missing groups are required.

## See also

[`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md)

## Examples

``` r
df <- data.frame(group = rep(c("a", "b"), each = 5), slope = 1:10)
terrain_effect_size(df, group = "group", vars = "slope")
#> # A tibble: 1 × 7
#>   variable group_1 group_2 mean_1 mean_2 effect_size method  
#>   <chr>    <chr>   <chr>    <dbl>  <dbl>       <dbl> <chr>   
#> 1 slope    a       b            3      8       -3.16 cohens_d
```
