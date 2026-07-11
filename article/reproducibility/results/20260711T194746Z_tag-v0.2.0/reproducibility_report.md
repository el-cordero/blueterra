# Clean-environment reproducibility report

**Result:** PASS

## Source isolation

- Package source: clean archive of local release tag `v0.2.0` (blueterra 0.2.0).
- The package archive excluded the local working tree; the external Route-B data and harness files were separately hash-recorded.
- Archive contained 295 tagged files. Local checkout state at start: 0 tracked change(s) and 95 untracked file(s), neither included in the package archive.

## Documented Route-B inputs

- NOAA BlueTopo tile: `BH54S4ZB`; the elevation crop, author-created analysis windows, and provenance manifest were SHA-256 verified in both runs.
- The workflow used only the Route-B data root supplied to the worker; it did not call bundled legacy example fixtures.

## Execution environment

- R: R version 4.5.3 (2026-03-11) (`aarch64-apple-darwin20`).
- blueterra: 0.2.0; terra: 1.9.27.
- Random seed: `20260711` (Mersenne-Twister / Inversion / Rejection).
- Fresh `Rscript --vanilla` processes: 2.
- Platform differences between paired runs: 0; dependency-version differences: 0.

## Comparison

- Compared 15 deterministic input, output-table, and schema/inventory record(s) between run_01 and run_02.
- Matching SHA-256 records: 15/15.
- Binary raster and vector artifacts are represented by output schemas and inventory rather than claimed platform-independent binary hashes.
- Full tag commit and archive SHA-256 values are retained only in the supplementary source manifest and machine-readable reproducibility manifest.

