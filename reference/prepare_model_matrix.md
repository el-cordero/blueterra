# Prepare a model matrix from terrain data

Converts a terrain table to a numeric predictor matrix and optional
response vector.

## Usage

``` r
prepare_model_matrix(
  data,
  vars = NULL,
  response = NULL,
  scale = FALSE,
  na.rm = TRUE
)
```

## Arguments

- data:

  A data frame.

- vars:

  Optional predictor variable names.

- response:

  Optional response column name.

- scale:

  Logical. If `TRUE`, center and scale predictors.

- na.rm:

  Logical. Remove incomplete rows.

## Value

A list with `x`, `y`, and `data`.

## See also

[`sample_terrain_cells()`](https://el-cordero.github.io/blueterra/reference/sample_terrain_cells.md),
[`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md)

## Examples

``` r
df <- data.frame(y = c(0, 1, 0), slope = c(1, 2, 3), bpi = c(0.2, 0.1, 0.4))
prepare_model_matrix(df, response = "y")
#> $x
#>      slope bpi
#> [1,]     1 0.2
#> [2,]     2 0.1
#> [3,]     3 0.4
#> 
#> $y
#> [1] 0 1 0
#> 
#> $data
#>   y slope bpi
#> 1 0     1 0.2
#> 2 1     2 0.1
#> 3 0     3 0.4
#> 
```
