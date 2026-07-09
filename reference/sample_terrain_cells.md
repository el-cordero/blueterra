# Sample terrain raster cells

Draws random or regular samples from raster cells and returns a table.

## Usage

``` r
sample_terrain_cells(
  metrics,
  size,
  method = c("random", "regular"),
  na.rm = TRUE,
  xy = TRUE,
  seed = NULL
)
```

## Arguments

- metrics:

  A metric raster stack.

- size:

  Number of cells to sample.

- method:

  Sampling method, `"random"` or `"regular"`.

- na.rm:

  Logical. Omit rows with missing values.

- xy:

  Logical. Include cell coordinates.

- seed:

  Optional random seed used before sampling.

## Value

A tibble of sampled cell values.

## See also

[`extract_terrain_points()`](https://el-cordero.github.io/blueterra/reference/extract_terrain_points.md),
[`prepare_model_matrix()`](https://el-cordero.github.io/blueterra/reference/prepare_model_matrix.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
sample_terrain_cells(bathy, size = 10)
#> # A tibble: 10 × 3
#>          x       y bathy_m
#>      <dbl>   <dbl>   <dbl>
#>  1 135530. 204861.   -22.8
#>  2 138328. 205640.  -233. 
#>  3 136209. 205141.  -190. 
#>  4 138268. 205840.   -18.5
#>  5 137908. 205660.  -212. 
#>  6 136829. 205001.  -398. 
#>  7 136029. 205421.   -18.9
#>  8 135570. 204441.  -306. 
#>  9 136529. 205081.  -306. 
#> 10 134990. 204162.  -424. 
```
