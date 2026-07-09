# Terrain metric catalog data

A compact table describing the metrics returned by core `blueterra`
functions and their process-oriented interpretation groups.

## Usage

``` r
metric_catalog_data
```

## Format

A tibble with columns:

- metric:

  Stable metric name.

- label:

  Human-readable label.

- process_group:

  Process-oriented terrain group.

- description:

  Metric description.

- units:

  Expected units.

- source_function:

  Function that derives the metric.

- requires_optional_dependency:

  Whether an optional dependency is needed.

- scale_sensitive:

  Whether interpretation depends on raster scale.

- interpretation_notes:

  Important interpretation notes.

## Details

Use
[`metric_catalog()`](https://el-cordero.github.io/blueterra/reference/metric_catalog.md)
to retrieve this table in normal workflows.
