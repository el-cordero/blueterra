# Summarize sampled cross-sections

Summarizes raster values sampled along transects.

## Usage

``` r
summarize_cross_sections(
  samples,
  value_col = NULL,
  group_col = "transect_id",
  fun = c("mean", "sd", "min", "max", "median"),
  na.rm = TRUE,
  normalize_distance = FALSE,
  n_bins = 50
)
```

## Arguments

- samples:

  Output from
  [`sample_transects()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md)
  or
  [`extract_cross_sections()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md).

- value_col:

  Optional value column. Defaults to the first numeric column that is
  not an identifier or coordinate.

- group_col:

  Column used to group cross-section samples.

- fun:

  Summary functions.

- na.rm:

  Logical. Remove missing values.

- normalize_distance:

  Logical. If `TRUE`, summarize values by normalized position along each
  transect.

- n_bins:

  Number of normalized-distance bins when `normalize_distance = TRUE`.

## Value

A tibble with one row per group.

## See also

[`sample_transects()`](https://el-cordero.github.io/blueterra/reference/sample_transects.md)

## Examples

``` r
bathy <- read_bathy(blueterra_example("bathy"))
zones <- terra::vect(blueterra_example("zones"))
transects <- make_transects(zones[1, ], spacing = 100, bathy = bathy)
samples <- sample_transects(transects, bathy, n = 5)
summarize_cross_sections(samples)
#> # A tibble: 3 × 6
#>   transect_id bathy_m_mean bathy_m_sd bathy_m_min bathy_m_max bathy_m_median
#>   <chr>              <dbl>      <dbl>       <dbl>       <dbl>          <dbl>
#> 1 1_1                -114.       115.       -270.       -18.9          -59.5
#> 2 1_2                -112.       113.       -265.       -17.0          -61.3
#> 3 1_3                -106.       108.       -258.       -19.2          -52.3
```
