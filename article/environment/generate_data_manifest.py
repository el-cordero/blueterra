#!/usr/bin/env python3
"""Record identities and provenance boundaries for package-distributed data.

This script deliberately distinguishes a cryptographic file identity from
source-data provenance or redistribution permission.  The latter has not been
established for the historic southwest Puerto Rico examples in this evaluated
checkout; see ``article/provenance_and_change_status.md`` for the evidence
boundary.
"""

from __future__ import annotations

import csv
import hashlib
from pathlib import Path


PACKAGE_ROOT = Path(__file__).resolve().parents[2]
OUTPUT = PACKAGE_ROOT / "article" / "environment" / "results" / "data_manifest.csv"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def describe(relative_path: str) -> tuple[str, str, str, str]:
    if relative_path.startswith("inst/extdata/synthetic_test_"):
        return (
            "synthetic validation fixture",
            "generated from explicit equations in data-raw/create-example-data.R",
            "package-distributed fixture; no external bathymetric provenance required",
            "synthetic raster or polygons used in controlled checks",
        )
    if relative_path == "data/metric_catalog.rda":
        return (
            "package metric catalog",
            "package data object generated from data-raw/metric-catalog.R",
            "package-distributed data object",
            "inspectable metric metadata used by catalog workflows",
        )
    if relative_path.endswith("sampling_rectangles.gpkg"):
        return (
            "reduced real-world vector example",
            "historical source sampling geometry is not versioned in the evaluated package",
            "source ownership and reuse rights not established from repository records",
            "do not infer author ownership or unrestricted redistribution",
        )
    return (
        "reduced real-world bathymetry example",
        "historical source tile, survey lineage, datum, and access metadata are not retained in the evaluated package",
        "source ownership and reuse rights not established from repository records",
        "file identity is recorded here; it is not evidence of source provenance or permission",
    )


def main() -> None:
    candidates = [PACKAGE_ROOT / "data" / "metric_catalog.rda"]
    candidates.extend(sorted((PACKAGE_ROOT / "inst" / "extdata").glob("*")))
    rows = []
    for path in candidates:
        if not path.is_file():
            continue
        relative = path.relative_to(PACKAGE_ROOT).as_posix()
        role, source_status, redistribution_status, note = describe(relative)
        rows.append(
            {
                "artifact_path": relative,
                "role": role,
                "bytes": path.stat().st_size,
                "sha256": sha256(path),
                "source_status": source_status,
                "redistribution_status": redistribution_status,
                "note": note,
            }
        )
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {OUTPUT} ({len(rows)} records)")


if __name__ == "__main__":
    main()
