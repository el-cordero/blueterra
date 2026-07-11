#!/usr/bin/env python3
"""Build the primary reference audit and manuscript-ready bibliography source.

The revision audit is the human-maintained, authoritative source.  This script
copies all reviewed rows to ``reference_audit.csv`` and emits ``references.csv``
only for records with an explicitly verified status.  Blocked citation targets
remain visible in the audit but cannot silently enter the manuscript bibliography.
"""

from __future__ import annotations

import csv
from pathlib import Path


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "reference_audit_revision.csv"
AUDIT = HERE / "reference_audit.csv"
BIBLIOGRAPHY = HERE / "references.csv"

FIELDS = [
    "citation_key",
    "authors",
    "year",
    "title",
    "container_title",
    "volume_issue",
    "pages_or_article",
    "doi_or_official_url",
    "record_type",
    "authoritative_verification_source",
    "specific_manuscript_claim_scope",
    "scope_limit_or_discrepancy",
    "audit_status",
]


def read_rows() -> list[dict[str, str]]:
    with SOURCE.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != FIELDS:
            raise ValueError(
                "reference_audit_revision.csv headers changed; update the builder "
                "rather than writing an unchecked primary audit."
            )
        rows = list(reader)

    keys = [row["citation_key"] for row in rows]
    if len(keys) != len(set(keys)):
        raise ValueError("Citation keys must be unique.")
    for row in rows:
        if not row["citation_key"] or not row["audit_status"]:
            raise ValueError("Every reference-audit row needs a citation key and status.")
        if row["audit_status"].startswith("verified"):
            for field in (
                "authors",
                "year",
                "title",
                "doi_or_official_url",
                "authoritative_verification_source",
            ):
                if not row[field]:
                    raise ValueError(
                        f"Verified record {row['citation_key']} lacks {field}."
                    )
    return rows


def tidy(text: str) -> str:
    return " ".join(text.split())


def bibliography_entry(row: dict[str, str]) -> str:
    """Render a compact, traceable bibliography string from verified fields."""
    key = row["citation_key"]
    if key == "NOAA_BlueTopo_BH54S4ZB_20251117":
        return (
            "National Oceanic and Atmospheric Administration, Office of Coast "
            "Survey (2025). BlueTopo elevation tile BH54S4ZB, dated 2025-11-17 "
            "[dataset; 4 m GeoTIFF; accessed 2026-07-11]. Available at "
            "https://noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/"
            "BH54S4ZB/BlueTopo_BH54S4ZB_20251117.tiff."
        )

    parts = [f"{tidy(row['authors'])} ({row['year']}).", f"{tidy(row['title'])}."]
    container = tidy(row["container_title"])
    volume = tidy(row["volume_issue"])
    pages = tidy(row["pages_or_article"])
    if container:
        detail = container
        if volume:
            detail += f" {volume}"
        if pages:
            detail += f":{pages}" if volume else f" {pages}"
        parts.append(f"{detail}.")
    parts.append(f"Available at {row['doi_or_official_url']}.")
    return " ".join(parts)


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    rows = read_rows()
    write_csv(AUDIT, FIELDS, rows)

    bibliography_rows = []
    for row in rows:
        if row["audit_status"].startswith("verified"):
            bibliography_rows.append(
                {
                    "citation_key": row["citation_key"],
                    "bibliography_entry": bibliography_entry(row),
                    "record_type": row["record_type"],
                    "doi_or_official_url": row["doi_or_official_url"],
                    "authoritative_verification_source": row[
                        "authoritative_verification_source"
                    ],
                    "citation_status": row["audit_status"],
                }
            )

    bibliography_rows.sort(key=lambda row: row["bibliography_entry"].casefold())
    write_csv(
        BIBLIOGRAPHY,
        [
            "citation_key",
            "bibliography_entry",
            "record_type",
            "doi_or_official_url",
            "authoritative_verification_source",
            "citation_status",
        ],
        bibliography_rows,
    )
    print(
        f"Wrote {len(rows)} audit rows to {AUDIT.name}; "
        f"{len(bibliography_rows)} verified entries to {BIBLIOGRAPHY.name}."
    )


if __name__ == "__main__":
    main()
