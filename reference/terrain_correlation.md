# Correlation table for terrain variables

Computes pairwise correlations among numeric terrain variables.

## Usage

``` r
terrain_correlation(
  data,
  vars = NULL,
  method = "pearson",
  use = "pairwise.complete.obs"
)
```

## Arguments

- data:

  A data frame.

- vars:

  Optional character vector of numeric variables.

- method:

  Correlation method passed to
  [`stats::cor()`](https://rdrr.io/r/stats/cor.html).

- use:

  Missing-value handling passed to
  [`stats::cor()`](https://rdrr.io/r/stats/cor.html).

## Value

A tibble with variable pairs and correlation coefficients.

## See also

[`terrain_pca()`](https://el-cordero.github.io/blueterra/reference/terrain_pca.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
terrain <- derive_terrain(bathy, metrics = c("slope", "bpi", "roughness"))
cells <- sample_terrain_cells(terrain, size = 30)
terrain_correlation(cells)
#> # A tibble: 6 × 3
#>   var1      var2      correlation
#>   <chr>     <chr>           <dbl>
#> 1 slope_deg bpi_3x3        -0.185
#> 2 slope_deg bpi_11x11      -0.104
#> 3 bpi_3x3   bpi_11x11       0.560
#> 4 slope_deg roughness       0.937
#> 5 bpi_3x3   roughness      -0.221
#> 6 bpi_11x11 roughness      -0.144
```
