# Configure blueterra runtime options

Returns or sets package options used by examples and helper functions.

## Usage

``` r
blueterra_options(...)
```

## Arguments

- ...:

  Named option values. Currently supported options are
  `blueterra.progress` and `blueterra.max_plot_cells`.

## Value

A named list with current option values, invisibly when setting.

## Details

Options affect only local package behavior and do not write outside
paths provided by the user.

## Examples

``` r
blueterra_options()
#> $blueterra.progress
#> [1] TRUE
#> 
#> $blueterra.max_plot_cells
#> [1] 10000
#> 
old <- blueterra_options(blueterra.progress = FALSE)
blueterra_options(blueterra.progress = old$blueterra.progress)
```
