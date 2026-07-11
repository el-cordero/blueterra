#!/usr/bin/env python3
"""Assemble the v0.2.0 code-and-results archive and checksum manifests.

The package source is obtained only with ``git archive v0.2.0``.  The archive
contains the current Route-B evidence tree but excludes pre-v0.2.0 clean-run
directories, which are retained locally only as superseded work records.
"""

from __future__ import annotations

import csv
import hashlib
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path


PACKAGE_ROOT = Path(__file__).resolve().parents[2]
WORKSPACE_ROOT = PACKAGE_ROOT.parents[1]
ARTICLE_ROOT = PACKAGE_ROOT / "article"
SUBMISSION_ROOT = WORKSPACE_ROOT / "blueterra_ESI_submission"
SUPPLEMENTARY = SUBMISSION_ROOT / "supplementary"
ZIP_PATH = SUPPLEMENTARY / "Online_Resource_2_Code_and_Results.zip"
MANIFEST_PATH = SUPPLEMENTARY / "Online_Resource_2_manifest.csv"
SOURCE_IDENTIFIER_PATH = SUPPLEMENTARY / "Online_Resource_2_source_identifier_manifest.csv"

RELEASE_TAG = "v0.2.0"
RELEASE_VERSION = "0.2.0"
SOURCE_ARCHIVE_NAME = "v0.2.0_v0.2.0.tar"
GIT = shutil.which("git") or "git"


def digest(path: Path) -> str:
    hash_ = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            hash_.update(block)
    return hash_.hexdigest()


def run_git(*arguments: str) -> str:
    result = subprocess.run(
        [GIT, "-C", str(PACKAGE_ROOT), *arguments],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


def read_key_value_csv(path: Path) -> dict[str, str]:
    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if not rows or not {"key", "value"}.issubset(rows[0]):
        raise ValueError(f"Expected a key/value source manifest: {path}")
    return {row["key"]: row["value"] for row in rows}


def resolve_release() -> tuple[str, str]:
    commit = run_git("rev-parse", "--verify", f"{RELEASE_TAG}^{{commit}}")
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError(f"Could not resolve a full commit SHA for {RELEASE_TAG}.")
    description = run_git("show", f"{RELEASE_TAG}:DESCRIPTION")
    version_match = re.search(r"^Version:\s*([^\s]+)\s*$", description, flags=re.MULTILINE)
    if version_match is None or version_match.group(1) != RELEASE_VERSION:
        observed = version_match.group(1) if version_match else "missing"
        raise ValueError(
            f"{RELEASE_TAG} must contain DESCRIPTION Version: {RELEASE_VERSION}; found {observed}."
        )
    return commit, version_match.group(1)


def current_release_reproducibility_dir(commit: str) -> Path:
    root = ARTICLE_ROOT / "reproducibility" / "results"
    candidates: list[Path] = []
    for directory in root.iterdir() if root.exists() else []:
        manifest_path = directory / "source_archive_manifest.csv"
        if not directory.is_dir() or not manifest_path.is_file():
            continue
        manifest = read_key_value_csv(manifest_path)
        if (
            manifest.get("release_tag") == RELEASE_TAG
            and manifest.get("package_version") == RELEASE_VERSION
            and manifest.get("source_commit_sha") == commit
        ):
            candidates.append(directory)
    if not candidates:
        raise FileNotFoundError(
            "No clean-environment result matches tag v0.2.0 and its full source commit. "
            "Run the tagged reproducibility audit before assembling Online Resource 2."
        )
    return max(candidates, key=lambda item: item.stat().st_mtime)


def append_manifest_entry(manifest: list[dict[str, str]], archive_path: str, source: Path) -> None:
    manifest.append(
        {
            "archive_path": archive_path,
            "bytes": str(source.stat().st_size),
            "sha256": digest(source),
        }
    )


def add_tree(
    zip_file: zipfile.ZipFile,
    root: Path,
    prefix: str,
    manifest: list[dict[str, str]],
    selected_reproducibility_dir: Path,
) -> None:
    selected_name = selected_reproducibility_dir.name
    for source in sorted(root.rglob("*")):
        if (
            not source.is_file()
            or source.name == ".DS_Store"
            or "__pycache__" in source.parts
            or source.suffix == ".pyc"
        ):
            continue
        relative = source.relative_to(root)
        # Retained intermediate audits and superseded table extracts are not
        # part of the final Route-B evidence package.
        if root == ARTICLE_ROOT and (
            relative == Path("functional_revision_audit.md")
            or relative.as_posix() in {
                "references/assemble_reference_audit.py",
                "references/reference_audit_foundational.csv",
                "references/reference_audit_marine.csv",
                "references/reference_audit_revision.csv",
                "references/reference_audit_software.csv",
                "tables/collect_tables_4_and_5.R",
                "tables/results/table1_core_metric_implementation.csv",
                "tables/results/table2_source_records.csv",
                "tables/results/table2_validation_wrapper_agreement.csv",
                "tables/results/table3_clean_environment_reproducibility.csv",
                "tables/results/table3_source_comparison.csv",
            }
        ):
            continue
        # Preserve the one current tagged clean-run result and omit every
        # historic result directory, including pre-v0.2.0 records.
        if (
            root == ARTICLE_ROOT
            and len(relative.parts) >= 3
            and relative.parts[0:2] == ("reproducibility", "results")
            and relative.parts[2] != selected_name
        ):
            continue
        archive_path = f"{prefix}/{relative.as_posix()}"
        zip_file.write(source, archive_path)
        append_manifest_entry(manifest, archive_path, source)


def write_source_identifier_manifest(
    commit: str,
    package_version: str,
    source_archive: Path,
    selected_reproducibility_dir: Path,
) -> None:
    rows = [
        {"identifier": "release_tag", "value": RELEASE_TAG},
        {"identifier": "package_version", "value": package_version},
        {"identifier": "source_commit_sha", "value": commit},
        {"identifier": "source_archive_path", "value": f"source/{SOURCE_ARCHIVE_NAME}"},
        {"identifier": "source_archive_sha256", "value": digest(source_archive)},
        {"identifier": "source_archive_method", "value": f"git archive {RELEASE_TAG}"},
        {"identifier": "included_reproducibility_result", "value": selected_reproducibility_dir.name},
        {"identifier": "stale_pre_v0_2_reproducibility_results", "value": "excluded"},
    ]
    with SOURCE_IDENTIFIER_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["identifier", "value"])
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    SUPPLEMENTARY.mkdir(parents=True, exist_ok=True)
    commit, package_version = resolve_release()
    selected_reproducibility_dir = current_release_reproducibility_dir(commit)

    with tempfile.TemporaryDirectory(prefix="blueterra-source-") as temporary_directory:
        temporary = Path(temporary_directory)
        source_archive = temporary / SOURCE_ARCHIVE_NAME
        subprocess.run(
            [
                GIT,
                "-C",
                str(PACKAGE_ROOT),
                "archive",
                "--format=tar",
                f"--output={source_archive}",
                RELEASE_TAG,
            ],
            check=True,
        )
        if not source_archive.is_file() or source_archive.stat().st_size == 0:
            raise RuntimeError(f"git archive {RELEASE_TAG} did not create {SOURCE_ARCHIVE_NAME}.")

        write_source_identifier_manifest(
            commit, package_version, source_archive, selected_reproducibility_dir
        )
        manifest: list[dict[str, str]] = []
        with zipfile.ZipFile(
            ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9
        ) as archive:
            archive_source_path = f"source/{SOURCE_ARCHIVE_NAME}"
            archive.write(source_archive, archive_source_path)
            append_manifest_entry(manifest, archive_source_path, source_archive)

            identifier_archive_path = "source/source_identifier_manifest.csv"
            archive.write(SOURCE_IDENTIFIER_PATH, identifier_archive_path)
            append_manifest_entry(manifest, identifier_archive_path, SOURCE_IDENTIFIER_PATH)

            add_tree(
                archive,
                ARTICLE_ROOT,
                "article",
                manifest,
                selected_reproducibility_dir,
            )

        with MANIFEST_PATH.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=["archive_path", "bytes", "sha256"])
            writer.writeheader()
            writer.writerows(manifest)

    print(f"Wrote {ZIP_PATH}")
    print(f"Wrote {MANIFEST_PATH} ({len(manifest)} entries)")
    print(f"Wrote {SOURCE_IDENTIFIER_PATH}")


if __name__ == "__main__":
    main()
