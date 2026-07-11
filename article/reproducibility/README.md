# Clean-environment reproducibility audit

`run_clean_reproducibility.R` installs a clean archive of a local, versioned
`blueterra` Git tag into a private R library and runs the documented Route-B
BlueTopo workflow twice in fresh `Rscript --vanilla` processes. It is a
software-article evidence bundle, not a package-development shortcut.

The current default is `--tag v0.2.0`. The tag must already exist locally and
must resolve to package version 0.2.0. The driver refuses to substitute the
dirty working tree or an untagged `HEAD` for the release under test.

## Inputs and source isolation

The package under test is created with `git archive <tag>`, installed into a
new private library, and never loaded from the working tree. The Route-B data
remain external provenance-checked inputs:

- `bluetopo_bh54s4zb_elevation_example.tif`;
- `bluetopo_author_analysis_windows.gpkg`; and
- `bluetopo_example_manifest.csv`.

By default these files are read from `article/data_provenance/results/`. Each
worker verifies the raster and vector hashes against the manifest, confirms
BlueTopo tile `BH54S4ZB`, and records the three input hashes and schemas. No
legacy bundled southwest Puerto Rico fixtures are called by the Route-B
worker.

## Run

From the package root, after creating the local release tag:

```sh
Rscript article/reproducibility/run_clean_reproducibility.R --tag v0.2.0
```

Use `--data-root PATH` to point at another copy of the documented Route-B
input directory. `--output PATH` selects a new empty result directory, and
`--seed INTEGER` changes the recorded seed. The audit requires exactly two
runs.

## Recorded evidence

Each result directory contains:

- `reproducibility_report.md` — concise pass/fail summary using the release
  tag and package version, without printing the full commit SHA;
- `source_archive_manifest.csv` and `reproducibility_manifest.json` — the
  supplementary manifests that retain the release tag, full commit SHA,
  archive SHA-256, harness hashes, clean-source status, and Route-B input
  provenance hashes;
- `reproducibility_comparison.csv` — paired hashes for documented inputs,
  deterministic table outputs, schemas, and binary-output inventory;
- `platform_comparison.csv` and `dependency_comparison.csv` — paired platform
  and dependency-version records, including any differences;
- `run_01/` and `run_02/` — clean-process dependency versions, session
  information, seeds, input/output hashes, raster/vector/table schemas,
  deterministic tables, binary-output inventory, warnings, and run metadata;
  and
- archive-install and worker logs at the result-directory root.

The real-data workflow prepares the documented elevation grid, derives a
terrain stack, produces exact polygon and depth-band summaries, makes
terrain-oriented transects and cross-sections, and produces isobaths and
corridor summaries. Deterministic CSV tables are compared by SHA-256. Raster
and vector files are recorded by schema and inventory because binary hashes
are not claimed to be platform independent.

The private library contains the tagged `blueterra` installation. Existing
host installations of dependencies are recorded rather than silently copied or
downloaded, so this is a clean package/source audit rather than a containerized
operating-system image.
