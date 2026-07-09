# Principal components analysis for terrain tables

Runs PCA on numeric terrain variables and returns tidy scores, loadings,
variance explained, and the fitted model.

## Usage

``` r
terrain_pca(
  data,
  vars = NULL,
  center = TRUE,
  scale. = TRUE,
  metadata_cols = NULL,
  keep_metadata = TRUE,
  ...
)
```

## Arguments

- data:

  A data frame.

- vars:

  Optional character vector of numeric variables.

- center:

  Logical passed to
  [`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html).

- scale.:

  Logical passed to
  [`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html).

- metadata_cols:

  Optional non-PCA columns appended to the score table.

- keep_metadata:

  Logical. Preserve non-PCA columns in `scores`.

- ...:

  Additional arguments passed to
  [`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html).

## Value

A list with `scores`, `loadings`, `variance`, `model`, `vars`, and
`complete_rows`.

## Details

Rows with incomplete values in selected variables are omitted before
PCA. PCA is descriptive and should be interpreted with scale, CRS, and
sampling design in mind.

## See also

[`prepare_model_matrix()`](https://el-cordero.github.io/blueterra/reference/prepare_model_matrix.md),
[`terrain_correlation()`](https://el-cordero.github.io/blueterra/reference/terrain_correlation.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
terrain <- derive_terrain(bathy, metrics = c("slope", "bpi", "roughness"))
cells <- sample_terrain_cells(terrain, size = 30)
terrain_pca(cells)
#> $scores
#> # A tibble: 30 × 7
#>    row_id    PC1     PC2      PC3     PC4       x       y
#>     <int>  <dbl>   <dbl>    <dbl>   <dbl>   <dbl>   <dbl>
#>  1      1 -1.32  -0.993   0.436   -0.218  136789. 205541.
#>  2      2  0.174  1.10   -0.322   -0.154  135370. 204481.
#>  3      3 -4.38  -0.917  -1.05     0.0138 138288. 205720.
#>  4      4 -2.71   2.68    1.65     0.549  135790. 204801.
#>  5      5  1.36  -1.46    0.331    0.0784 137988. 205840.
#>  6      6  1.62  -1.26    0.138    0.155  135550. 204941.
#>  7      7  0.383  1.13   -0.428   -0.209  138667. 205620.
#>  8      8  0.329  0.0279  0.210   -0.0434 136509. 205021.
#>  9      9 -1.70  -0.253   1.32    -0.594  138387. 205760.
#> 10     10  0.248  0.332  -0.00901  0.0312 136069. 204921.
#> # ℹ 20 more rows
#> 
#> $loadings
#> # A tibble: 4 × 5
#>   variable     PC1    PC2     PC3     PC4
#>   <chr>      <dbl>  <dbl>   <dbl>   <dbl>
#> 1 slope_deg -0.552  0.458 -0.0225 -0.696 
#> 2 bpi_3x3   -0.463 -0.490 -0.736   0.0684
#> 3 bpi_11x11 -0.382 -0.639  0.653  -0.138 
#> 4 roughness -0.578  0.377  0.178   0.701 
#> 
#> $variance
#> # A tibble: 4 × 3
#>   component proportion cumulative
#>   <chr>          <dbl>      <dbl>
#> 1 PC1          0.596        0.596
#> 2 PC2          0.303        0.900
#> 3 PC3          0.0911       0.991
#> 4 PC4          0.00913      1    
#> 
#> $model
#> Standard deviations (1, .., p=4):
#> [1] 1.5445220 1.1015314 0.6038024 0.1910576
#> 
#> Rotation (n x k) = (4 x 4):
#>                  PC1        PC2         PC3         PC4
#> slope_deg -0.5520933  0.4584280 -0.02245547 -0.69608373
#> bpi_3x3   -0.4630247 -0.4898564 -0.73551040  0.06836129
#> bpi_11x11 -0.3823500 -0.6387073  0.65321627 -0.13845565
#> roughness -0.5784545  0.3767459  0.17840604  0.70115919
#> 
#> $vars
#> [1] "slope_deg" "bpi_3x3"   "bpi_11x11" "roughness"
#> 
#> $complete_rows
#>  [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
#> [16] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
#> 
```
