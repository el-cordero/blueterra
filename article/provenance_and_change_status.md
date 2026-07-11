# Data provenance and package-change status

This record separates the documented article input from older package fixtures
and records the corrections made for the 0.2.0 package working tree. It is not
a licence grant, a substitute for author declarations, or evidence that a
persistent DOI has been assigned.

## Documented article input

The real-data figures, sensitivity analysis, and computational assessment use
the NOAA BlueTopo tile `BH54S4ZB_20251117`, not the older reduced rasters in
`inst/extdata`. The retained raw tile, raster attribute table, tile-scheme
record, acquisition script, checksum manifest, prepared crop, and
author-created analytical windows are in `article/data_provenance/`.

| Item | Documented value |
|---|---|
| Product and tile | NOAA BlueTopo `BH54S4ZB_20251117` |
| Article access date | 2026-07-11 (UTC time retained in the JSON manifest) |
| Source horizontal CRS | EPSG:6348, NAD83(2011) / UTM zone 19N |
| Tile-specific vertical metadata | `MSL(GEOID12B) height`; no vertical transformation was applied |
| Article crop | 751 rows by 1,001 columns; 4 m by 4 m grid spacing |
| Crop extent | 707,998–712,002 m E; 1,976,498–1,979,502 m N |
| Article preprocessing | Grid-aligned crop of the elevation band; no smoothing for principal maps |
| Sampling windows | Two deterministic rectangles created by the author in `acquire_bluetopo_example.R` |
| Source and crop identity | SHA-256 hashes in `bluetopo_example_manifest.csv` and `.json` |

NOAA product context, acknowledgement guidance, and retained source metadata
are recorded in `article/data_provenance/README.md`. This documentation does
not claim author ownership of BlueTopo data.

## Legacy bundled fixtures

The reduced southwest Puerto Rico rasters and sampling geometry in
`inst/extdata` are retained package fixtures, but their original source-tile
inventory, acquisition date, vertical reference, processing lineage, vector
provenance, and reuse status are not established by the repository. They are
therefore excluded from the article's real-data figures and results. The
evidence boundary is detailed in
`article/provenance_release_investigation.md` and
`article/provenance_release_source_audit.csv`.

## Package corrections in the 0.2.0 working tree

The machine-readable change log is `article/package_modifications.csv`. The
working tree corrects map-unit annular BPI geometry for non-square cells,
requires projected coordinates for map-unit radii, records zero-variance
normalized BPI as `NA`, makes exact polygon summaries coverage-fraction
weighted, adds stable zone and corridor metadata, adds a transect orientation
concentration measure, and updates metric definitions and documentation.
Regression and functional checks are retained in `tests/testthat/` and
`article/validation/`.

The complete baseline SHA is retained only in the machine-readable change and
reproducibility records. The intended public release is version 0.2.0 with tag
`v0.2.0`; a persistent archive DOI remains unresolved until an archive is
actually deposited.

## Remaining boundaries

The author-controlled competing-interests statement, author-contribution
statement, and final disclosure decision concerning AI-assisted tools remain
unresolved. Neither the documented Route-B acquisition nor the package MIT
licence establishes redistribution rights for the historical bundled fixtures.
The submission materials must not be described as submission-ready until those
items, the immutable public release, persistent archival decision, and final
visual document quality assurance are completed.
