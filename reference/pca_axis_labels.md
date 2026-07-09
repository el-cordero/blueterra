# Label PCA axes with variance and dominant loadings

Builds axis labels for
[`plot_process_pca()`](https://el-cordero.github.io/blueterra/reference/plot_process_pca.md)
from a
[`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md)
object.

## Usage

``` r
pca_axis_labels(
  pca,
  components = c("PC1", "PC2"),
  top_n = 2,
  unique = TRUE,
  include_variance = TRUE
)
```

## Arguments

- pca:

  Output from
  [`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md).

- components:

  Components to label.

- top_n:

  Number of high-loading variables included per component.

- unique:

  Logical. Avoid repeating the same dominant variable across component
  labels when possible.

- include_variance:

  Logical. Include percent variance explained.

## Value

A named character vector of axis labels.

## Details

Variables are ranked by absolute loading for each component. These
labels are descriptive aids for ordination plots; they do not replace
inspection of the full loading table.

## See also

[`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md),
[`plot_process_pca()`](https://el-cordero.github.io/blueterra/reference/plot_process_pca.md)

## Examples

``` r
df <- data.frame(a = rnorm(10), b = rnorm(10), c = rnorm(10))
pca_axis_labels(terrain_pca(df))
#>                 PC1                 PC2 
#> "PC1 (60.2%; a, c)" "PC2 (30.6%; b, c)" 
```
