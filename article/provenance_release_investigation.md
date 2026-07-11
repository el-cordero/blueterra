# Provenance and Release Investigation

**Investigation date:** 2026-07-11  
**Scope:** bundled real-data examples in `inst/extdata/` and the evaluated
`blueterra` source state. This report records what was recovered from retained
local artifacts and authoritative NOAA records. It does not convert indirect
evidence into a source claim.

## Decision

Route A is **not yet sufficient** for the existing package examples. The
bundled rasters have an exact, recoverable immediate lineage to a retained
regional mosaic, and a locally retained historical NOAA BlueTopo tile covering
the Hole-in-the-Wall example was authenticated against an archived official
tile scheme. However, no immutable acquisition manifest, complete input-tile
inventory, original download log, or versioned processing run was retained for
the regional mosaic. The provenance and reuse status of the original sampling
polygons also remains undocumented.

Route B is **feasible now** and is the defensible route for a source-specific
real-data application: reacquire a publicly available, checksummed BlueTopo
tile; create analysis polygons in a new version-controlled script; retain the
tile scheme, metadata/RAT, inputs, checksums, and exact preparation code; then
regenerate every real-data result and artwork. The currently public candidate
tile is not the data used in the existing package, so it must not be described
as such until that regeneration is completed.

## What the package examples demonstrably contain

The package regeneration script
[`data-raw/create-analysis-examples.R`](../data-raw/create-analysis-examples.R)
uses these immediate source files:

| Bundled artifact | Immediate source and verified transformation | Verification |
|---|---|---|
| `laparguera_hitw_bathy.tif` | `Hole_In_the_Wall_bathy.tif`; GeoTIFF rewrite to FLT4S/DEFLATE | Same grid and all 5,625 values exactly equal |
| `laparguera_hoyo_bathy.tif` | `Hoyo_Terrace_bathy.tif`; GeoTIFF rewrite to FLT4S/DEFLATE | Same grid and all 15,252 values exactly equal |
| `laparguera_slope_bathy.tif` | `Slope_clip_bathy.tif`; 5 × 5 mean aggregation (`na.rm = TRUE`) before FLT4S/DEFLATE write | Source 449 × 946 at 3.996743 m; bundled raster 90 × 190 at 19.983716 m, as prescribed by the script |
| `laparguera_sampling_rectangles.gpkg` | `sampling_rect.shp`, plus an extent polygon derived from the slope clip | The script establishes this conversion, but not the original vector creator, source, or reuse terms |

The Hole-in-the-Wall package raster is 75 × 75 cells (5,625 cells), with a
distributed grid spacing of 3.996743 m in EPSG:32161, *NAD83 / Puerto Rico &
Virgin Islands*. Its projected extent is 137474.235835–137773.991576 m E and
205590.245867–205890.001608 m N. Transforming that extent with `sf` produced
an approximate WGS 84 bounding box of 17.88293–17.88565° N and
67.02334–67.02051° W. These are properties of the **distributed example
raster**, not evidence of its native source resolution.

The package values use a negative-elevation convention. The immediate regional
mosaic has only the generic band description `Elevation`; it does not retain a
vertical datum. Consequently, the final manuscript cannot assign a vertical
datum to the *existing bundled raster*.

## Recovered historical BlueTopo evidence

A retained external BlueTopo artifact and its official archived tile scheme
provide strong but incomplete evidence for a candidate input tile:

| Field | Recovered fact |
|---|---|
| Tile identifier | `BH54S4ZB` |
| Historical filename | `BlueTopo_BH54S4ZB_20240726.tiff` |
| Official historical tile-scheme record | `BlueTopo_Tile_Scheme_20241118_105559.gpkg` |
| Tile-scheme delivery timestamp | 2024-08-08 12:19:29 |
| Tile resolution and horizontal CRS | 4 m; EPSG:6348, *NAD83(2011) / UTM zone 19N* |
| Tile extent | 706518–714618 m E; 1974638–1983090 m N (UTM 19N) |
| GeoTIFF SHA-256 recorded in tile scheme and re-computed locally | `e6b4680f23746a5eb147866c4c26ed2599b8474d0d170a71d8d482bd9c8420d5` |
| RAT SHA-256 recorded in tile scheme | `662236d66e56f2751686f24f4c01dd12f4afc3743500d93bd5b8c9191197b108` |
| Embedded vertical metadata | `MSL(GEOID12B) height` / Mean Sea Level, NOAA hybrid geoid 2012, B model |
| License metadata | CC0 1.0 in the GeoTIFF copyright tag; the official BlueTopo FAQ describes BlueTopo products as U.S. public-domain products |
| Current online status of historical URL | 404 on 2026-07-11; the locally retained, checksummed file remains evidence but is not a current public download |

The example bounding box is wholly within this tile’s geographic footprint
(-67.050 to -66.975° E/W and 17.850 to 17.925° N/S). A retained
18.1-GB regional mosaic, `hr_bathy_PR_spcs.tif`, has the same EPSG:32161
coordinate system and 3.996743-m spacing. The package Hole-in-the-Wall source
clip matches that mosaic exactly at all 5,625 cell centres. The recovered
historical tile was present locally before the mosaic was created, and retained
processing code describes extracting `Elevation`, reprojecting BlueTopo input
to EPSG:32161, and mosaicking it. These facts establish a plausible processing
chain, but the code was not versioned with the mosaic and no run manifest names
the exact input-tile set or execution parameters. They therefore do **not**
establish a complete Route-A lineage.

The vertical metadata deserve particular care. The historical candidate tile
itself declares `MSL(GEOID12B) height`, while the general current
[BlueTopo specifications](https://www.nauticalcharts.noaa.gov/data/bluetopo_specs.html)
state NAVD88 for the product. The per-file metadata are the only recovered
record for the historical tile; no vertical transformation from that tile to
the retained regional mosaic is documented. A manuscript about the existing
example must state that its vertical datum is unresolved, rather than select
one of these references.

## Public, reproducible Route-B input candidate

On 2026-07-11, the current official BlueTopo tile scheme
`BlueTopo_Tile_Scheme_20260626_132625.gpkg` was downloaded from NOAA’s public
bucket (SHA-256
`dc854cc98608eaae19e5cc8e4ccf92f9f61af998cc135c61c649d2052c3fc319`). It
identifies this public tile covering the same example extent:

| Field | Current-public candidate |
|---|---|
| Tile identifier | `BH54S4ZB` |
| Filename | `BlueTopo_BH54S4ZB_20251117.tiff` |
| Official tile URL | <https://noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH54S4ZB/BlueTopo_BH54S4ZB_20251117.tiff> |
| Official metadata/RAT URL | <https://noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH54S4ZB/BlueTopo_BH54S4ZB_20251117.tiff.aux.xml> |
| Tile-scheme delivery timestamp | 2025-12-19 14:56:59 |
| Source horizontal reference system | EPSG:6348, *NAD83(2011) / UTM zone 19N* |
| Grid | 2,025 × 2,113 cells at 4 × 4 m |
| File SHA-256 | `3625a8ef3df3e81a31467ab35e7ec589285d91a41daee12627448b10dd108d23` |
| RAT SHA-256 | `2d73d705e843387313668b66c3b92a18764bafabe25839c7fa52b49afa8cc8c2` |
| Download access date for this investigation | 2026-07-11 |
| Embedded vertical metadata | `MSL(GEOID12B) height`; negative values increase with water depth |
| Redistribution / attribution | Tile copyright tag CC0 1.0; NOAA asks users to acknowledge NOAA Office of Coast Survey BlueTopo |

NOAA’s [FAQ](https://nauticalcharts.noaa.gov/data/bluetopo_faq.html) identifies
the dated tile scheme as the means to find a tile and its GeoTIFF/RAT, explains
that the contributor layer carries source and license information, and states
that BlueTopo is public-domain with no product-level restrictions. The
[specifications](https://www.nauticalcharts.noaa.gov/data/bluetopo_specs.html)
state that BlueTopo is a three-layer GeoTIFF (elevation, uncertainty, and
contributors), is not for navigation, and includes interpolation and
uncertainty information. A Route-B acquisition must retain all three layers
and the RAT, even if the package analysis uses only elevation.

Before using this current candidate, resolve the documented general-page versus
per-file vertical-reference wording with the NOAA product contact or preserve
the per-file `VERTICALDATUMWKT` verbatim and declare the product-level
discrepancy. Do not convert vertical values unless a transformation is itself
documented and executed.

## Route-B execution requirements

1. Add a version-controlled acquisition script that downloads the exact dated
   tile-scheme GeoPackage, the tile, and its RAT; validates both SHA-256 values;
   writes UTC access time; and preserves the original CRS and vertical metadata.
2. Add a version-controlled preparation script that creates new analysis
   polygons from stated coordinates or documented selection rules. It must
   record polygon geometry, creator, date, license, and role; it must not reuse
   the unproven `sampling_rect.shp` as if its ownership were known.
3. Produce a small distribution-ready example raster and vector layer from
   those inputs. The manifest must record transformations, resampling method,
   output grid spacing, package-file hashes, and the source tile/RAT checksums.
4. Regenerate every real-data figure, table, sensitivity result, and
   reproducibility hash from the new input. The old and current BlueTopo tile
   versions differ, so results cannot be carried forward without rerunning.
5. Cite NOAA Office of Coast Survey BlueTopo, the exact dated tile, access date,
   attribution language, and the data manifest in the manuscript. Do not call a
   3.996743-m distributed grid native resolution unless a source-specific
   metadata record establishes that claim.

## Software release investigation

The evaluated package source is `blueterra` version 0.1.0 at local `HEAD`
`4afb4b58a95a657a7bebd996d159691ec0cc69fc`. This is an untagged Git snapshot,
not a release:

- `git tag --list` returned no local tags.
- `git ls-remote --tags origin` returned no remote tags; the remote had only
  `main` and `gh-pages` branches.
- `DESCRIPTION` and `inst/CITATION` name version 0.1.0 but provide only a
  mutable GitHub URL; the repository contains no Zenodo DOI or versioned
  archive identifier.

Accordingly, there is **no existing versioned release corresponding exactly to
the evaluated source**. A release cannot be truthfully reported in Availability
and Requirements or the cover letter until the author creates and publishes an
immutable tag/release (and, if desired, an archive DOI). The release should
contain the exact evaluated package source, its test and article-reproduction
assets, and a supplementary manifest with the complete commit SHA. The
manuscript itself should use the package version in prose and reserve the tag
and DOI for Availability and Requirements.

## Evidence retained outside the package repository

The retained files below were inspected read-only; they are not currently
versioned in `blueterra` and must be copied into a new documented archive or
reacquired for a fully reproducible data record.

| Artifact | SHA-256 / evidence |
|---|---|
| Historical tile scheme `BlueTopo_Tile_Scheme_20241118_105559.gpkg` | `ce2b786ce36d2aa33165bd8243a398377e29a2c9ad71a6a0dae74031ff361ecd` |
| Historical candidate tile `BlueTopo_BH54S4ZB_20240726.tiff` | `e6b4680f23746a5eb147866c4c26ed2599b8474d0d170a71d8d482bd9c8420d5` |
| Retained BlueTopo preparation script `HighRes_bathymetry_PR.R` | `29fb748b7b0b113e42399aa405b4e89d6533214cbfcf6e25b6412054cd99a4de` |
| Retained BlueTopo downloader `BlueTopoTile_Downloads.R` | `73b1458c3eafb831c3e34a9c6a2c27df39d2a7830a2c52ea76bb370d5e3548d7` |

These artifacts are useful recovery evidence, not a substitute for a
version-controlled rerun or a public archive.
