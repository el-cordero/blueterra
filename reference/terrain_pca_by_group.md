# Run PCA overall and within groups

Fits one terrain PCA across all rows and one PCA within each group
level.

## Usage

``` r
terrain_pca_by_group(
  data,
  group,
  vars = NULL,
  center = TRUE,
  scale. = TRUE,
  min_rows = 5,
  ...
)
```

## Arguments

- data:

  A data frame.

- group:

  Character name of the grouping column.

- vars:

  Optional numeric variables used in PCA.

- center, scale.:

  Logical values passed to
  [`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md).

- min_rows:

  Minimum rows required for a group-specific PCA.

- ...:

  Additional arguments passed to
  [`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md).

## Value

A named list with `overall` and `groups`. `groups` is a named list of
PCA objects.

## Details

Group-specific PCA is useful for checking whether ordination structure
is dominated by one site or sampling frame. Groups with fewer than
`min_rows` rows are omitted with a warning.

## See also

[`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md),
[`plot_process_pca()`](https://el-cordero.github.io/blueterra/reference/plot_process_pca.md)

## Examples

``` r
df <- data.frame(site = rep(c("a", "b"), each = 8), slope = rnorm(16),
                 tri = rnorm(16), bpi = rnorm(16))
terrain_pca_by_group(df, group = "site")
#> $overall
#> $overall$scores
#> # A tibble: 16 × 5
#>    row_id     PC1     PC2     PC3 site 
#>     <int>   <dbl>   <dbl>   <dbl> <chr>
#>  1      1 -0.311  -0.314  -0.554  a    
#>  2      2  1.01    1.10   -1.31   a    
#>  3      3  1.34    1.10   -0.241  a    
#>  4      4 -0.104  -0.393   0.360  a    
#>  5      5 -0.0822  2.33    0.664  a    
#>  6      6 -1.10    0.584  -0.144  a    
#>  7      7 -0.756  -0.616   2.04   a    
#>  8      8 -2.02   -0.357  -0.190  a    
#>  9      9 -0.177   0.0378  0.103  b    
#> 10     10 -0.506  -1.42   -0.0626 b    
#> 11     11  0.104   0.0398 -0.131  b    
#> 12     12 -0.989  -0.679  -2.02   b    
#> 13     13 -0.812   0.882   0.791  b    
#> 14     14  1.34   -0.742   1.06   b    
#> 15     15  1.04   -0.403  -0.526  b    
#> 16     16  2.02   -1.15    0.163  b    
#> 
#> $overall$loadings
#> # A tibble: 3 × 4
#>   variable    PC1      PC2    PC3
#>   <chr>     <dbl>    <dbl>  <dbl>
#> 1 slope     0.535 -0.715    0.450
#> 2 tri      -0.540 -0.699   -0.468
#> 3 bpi       0.650  0.00717 -0.760
#> 
#> $overall$variance
#> # A tibble: 3 × 3
#>   component proportion cumulative
#>   <chr>          <dbl>      <dbl>
#> 1 PC1            0.393      0.393
#> 2 PC2            0.317      0.710
#> 3 PC3            0.290      1    
#> 
#> $overall$model
#> Standard deviations (1, .., p=3):
#> [1] 1.0854760 0.9757059 0.9325984
#> 
#> Rotation (n x k) = (3 x 3):
#>              PC1          PC2        PC3
#> slope  0.5346664 -0.715085890  0.4503155
#> tri   -0.5403085 -0.698999861 -0.4684719
#> bpi    0.6497681  0.007166836 -0.7600987
#> 
#> $overall$vars
#> [1] "slope" "tri"   "bpi"  
#> 
#> $overall$complete_rows
#>  [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
#> [16] TRUE
#> 
#> 
#> $groups
#> $groups$a
#> $groups$a$scores
#> # A tibble: 8 × 5
#>   row_id     PC1     PC2     PC3 site 
#>    <int>   <dbl>   <dbl>   <dbl> <chr>
#> 1      1 -0.355  -0.175  -0.814  a    
#> 2      2  1.55    0.0290 -0.779  a    
#> 3      3  1.18    0.989  -0.264  a    
#> 4      4 -0.764   0.605  -0.401  a    
#> 5      5  1.37   -0.171   1.48   a    
#> 6      6 -0.0258 -0.951   0.235  a    
#> 7      7 -1.89    1.14    0.636  a    
#> 8      8 -1.06   -1.47   -0.0918 a    
#> 
#> $groups$a$loadings
#> # A tibble: 3 × 4
#>   variable    PC1    PC2    PC3
#>   <chr>     <dbl>  <dbl>  <dbl>
#> 1 slope    -0.507  0.813 -0.286
#> 2 tri      -0.580 -0.567 -0.585
#> 3 bpi       0.638  0.131 -0.759
#> 
#> $groups$a$variance
#> # A tibble: 3 × 3
#>   component proportion cumulative
#>   <chr>          <dbl>      <dbl>
#> 1 PC1            0.527      0.527
#> 2 PC2            0.274      0.802
#> 3 PC3            0.198      1    
#> 
#> $groups$a$model
#> Standard deviations (1, .., p=3):
#> [1] 1.2579591 0.9074517 0.7707596
#> 
#> Rotation (n x k) = (3 x 3):
#>              PC1        PC2        PC3
#> slope -0.5072700  0.8129170 -0.2860823
#> tri   -0.5796143 -0.5674922 -0.5848076
#> bpi    0.6377495  0.1308379 -0.7590501
#> 
#> $groups$a$vars
#> [1] "slope" "tri"   "bpi"  
#> 
#> $groups$a$complete_rows
#> [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
#> 
#> 
#> $groups$b
#> $groups$b$scores
#> # A tibble: 8 × 5
#>   row_id    PC1    PC2     PC3 site 
#>    <int>  <dbl>  <dbl>   <dbl> <chr>
#> 1      1  0.402  0.583 -0.134  b    
#> 2      2  0.647 -0.204  1.19   b    
#> 3      3  0.201  0.240 -0.368  b    
#> 4      4  1.78  -1.64  -0.175  b    
#> 5      5  0.880  1.95  -0.266  b    
#> 6      6 -1.43   0.594  0.343  b    
#> 7      7 -0.627 -0.738 -0.574  b    
#> 8      8 -1.85  -0.781 -0.0172 b    
#> 
#> $groups$b$loadings
#> # A tibble: 3 × 4
#>   variable    PC1    PC2    PC3
#>   <chr>     <dbl>  <dbl>  <dbl>
#> 1 slope    -0.760 -0.109  0.640
#> 2 tri       0.568 -0.589  0.575
#> 3 bpi      -0.314 -0.801 -0.510
#> 
#> $groups$b$variance
#> # A tibble: 3 × 3
#>   component proportion cumulative
#>   <chr>          <dbl>      <dbl>
#> 1 PC1            0.496      0.496
#> 2 PC2            0.402      0.899
#> 3 PC3            0.101      1    
#> 
#> $groups$b$model
#> Standard deviations (1, .., p=3):
#> [1] 1.2203309 1.0987236 0.5509982
#> 
#> Rotation (n x k) = (3 x 3):
#>              PC1        PC2        PC3
#> slope -0.7604402 -0.1093265  0.6401394
#> tri    0.5683328 -0.5889728  0.5745511
#> bpi   -0.3142110 -0.8007239 -0.5100124
#> 
#> $groups$b$vars
#> [1] "slope" "tri"   "bpi"  
#> 
#> $groups$b$complete_rows
#> [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
#> 
#> 
#> 
```
