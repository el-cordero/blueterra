# Documented BlueTopo example data

The article's real-data maps, summaries, and sensitivity analyses use the
derived elevation raster in `results/bluetopo_bh54s4zb_elevation_example.tif`.
They do **not** use the older southwest Puerto Rico fixtures distributed in
`inst/extdata/`; those legacy fixtures remain separately documented as having
incomplete source-tile and vector provenance in
`../provenance_release_investigation.md`.

## Source and acquisition

The source is NOAA BlueTopo tile `BH54S4ZB_20251117`, distributed through the
NOAA Office of Coast Survey public bucket. It was accessed on 2026-07-11. The
authoritative tile-scheme record retained in `raw/` reports a delivery time of
2025-12-19 14:56:59, 4 m resolution, and the source checksum. The raw tile and
its accompanying Raster Attribute Table are retained unmodified, with their
SHA-256 checksums verified by `acquire_bluetopo_example.R`:

| Artifact | SHA-256 |
|---|---|
| `BlueTopo_BH54S4ZB_20251117.tiff` | `3625a8ef3df3e81a31467ab35e7ec589285d91a41daee12627448b10dd108d23` |
| `BlueTopo_BH54S4ZB_20251117.tiff.aux.xml` | `2d73d705e843387313668b66c3b92a18764bafabe25839c7fa52b49afa8cc8c2` |
| `BlueTopo_Tile_Scheme_20260626_132625.gpkg` | `dc854cc98608eaae19e5cc8e4ccf92f9f61af998cc135c61c649d2052c3fc319` |

The NOAA BlueTopo [specification](https://nauticalcharts.noaa.gov/data/bluetopo_specs.html)
and [FAQ](https://nauticalcharts.noaa.gov/data/bluetopo_faq.html) are the
authoritative product and reuse records. The FAQ describes BlueTopo as freely
available public data without restrictions and asks users to acknowledge NOAA.
The retained tile RAT also contains contributor-license records, including
CC0 entries. This archive records the product source and its terms; it does
not claim ownership of NOAA data.

## Derived article raster

`acquire_bluetopo_example.R` selects only the source tile's elevation band and
then crops it to the requested UTM 19N rectangle. The crop was snapped to the
4 m source grid and is not smoothed, vertically transformed, aggregated, or
resampled. Its exact extent is 707,998--712,002 m E and
1,976,498--1,979,502 m N in EPSG:6348, *NAD83(2011) / UTM zone 19N + MSL
height*. It contains 751 rows by 1,001 columns at 4 m by 4 m grid spacing.
The approximate WGS 84 bounds are 17.866015--17.893535 degrees N and
67.036995--66.998920 degrees W. Values are elevations in meters and are
negative below sea level.

The tile-specific GeoTIFF metadata reports the vertical reference as
`MSL(GEOID12B) height`, described in the embedded WKT as Mean Sea Level using
the NOAA hybrid geoid 2012 B model. This tile-specific record is retained even
though general BlueTopo product information uses other vertical-reference
wording; no vertical datum conversion was made by the article scripts.

## Vectors and lineage

`results/bluetopo_author_analysis_windows.gpkg` contains two deterministic
rectangular analysis windows, `shelf_window` and `slope_window`. They were
created by the article preparation script, not obtained from an external
vector provider. The script writes their source, creation method, and expected
geometry to `results/bluetopo_example_manifest.csv` and `.json`.

The full reproducible chain is:

`public tile scheme + tile + RAT` -> `checksum verification` -> `elevation
band selection` -> `grid-aligned crop` -> `author-created rectangular windows`
-> `article analyses and figures`.

Run `Rscript article/data_provenance/acquire_bluetopo_example.R` from the
package root to reproduce and verify the acquisition. The script refuses a
checksum mismatch and records the software environment with the outputs.
