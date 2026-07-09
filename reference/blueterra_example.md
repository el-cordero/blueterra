# Locate package example files

Returns the path to a small file installed with `blueterra`.

## Usage

``` r
blueterra_example(
  name = c("hitw", "hoyo", "slope", "sampling_rectangles", "bathy", "zones", "sites",
    "synthetic_bathy", "synthetic_zones")
)

blueterra_examples()

blueterra_extdata(file = NULL)
```

## Arguments

- name:

  Example name. Use `"hitw"`, `"hoyo"`, or `"slope"` for reduced
  bathymetry rasters from the southwest Puerto Rico shelf margin near La
  Parguera; `"sampling_rectangles"` for the accompanying vector layer;
  `"bathy"` and `"zones"` as short aliases; or `"synthetic_bathy"` and
  `"synthetic_zones"` for test fixtures.

- file:

  File name under `inst/extdata`.

## Value

A normalized local file path.

`blueterra_examples()` returns a tibble describing installed example
files.

## Details

The primary examples are reduced analysis rasters and sampling
rectangles from the southwest Puerto Rico shelf margin near La Parguera.
The synthetic files are retained for numerical tests where a simple
known surface is useful.

## See also

[`read_bathy()`](https://el-cordero.github.io/blueterra/reference/read_bathy.md)

## Examples

``` r
hitw <- blueterra_example("hitw")
rectangles <- blueterra_example("sampling_rectangles")
file.exists(c(hitw, rectangles))
#> [1] TRUE TRUE
blueterra_examples()
#> # A tibble: 6 × 8
#>   name                path     type  description crs    nrow  ncol feature_count
#>   <chr>               <chr>    <chr> <chr>       <chr> <dbl> <dbl>         <dbl>
#> 1 hitw                /tmp/Rt… rast… Reduced Ho… +pro…    75    75            NA
#> 2 hoyo                /tmp/Rt… rast… Reduced El… +pro…   123   124            NA
#> 3 slope               /tmp/Rt… rast… Aggregated… +pro…    90   190            NA
#> 4 sampling_rectangles /tmp/Rt… vect… Sampling r… +pro…    NA    NA             3
#> 5 synthetic_bathy     /tmp/Rt… rast… Synthetic … +pro…    60    60            NA
#> 6 synthetic_zones     /tmp/Rt… vect… Synthetic … +pro…    NA    NA             2
```
