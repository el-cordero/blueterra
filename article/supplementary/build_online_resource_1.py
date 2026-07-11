#!/usr/bin/env python3
"""Create Online Resource 1 from the tagged v0.2.0 evidence records.

The report deliberately reads executed CSV/JSON artifacts instead of carrying
hand-copied results.  It will refuse to build until a clean-environment audit
for the local ``v0.2.0`` release has been completed.  The release tag is the
human-readable source identifier; the full commit SHA remains only in the
machine-readable supplementary manifests.
"""

from __future__ import annotations

import csv
import math
from html import escape
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


PACKAGE_ROOT = Path(__file__).resolve().parents[2]
WORKSPACE_ROOT = PACKAGE_ROOT.parents[1]
ARTICLE = PACKAGE_ROOT / "article"
OUT = WORKSPACE_ROOT / "blueterra_ESI_submission" / "supplementary" / "Online_Resource_1_Reproducible_Workflow.pdf"

RELEASE_TAG = "v0.2.0"
RELEASE_VERSION = "0.2.0"
TITLE = "blueterra: an R workflow for geomorphometric analysis of submerged terrain"


def read_csv(path: Path) -> list[dict[str, str]]:
    with Path(path).open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def require_file(path: Path) -> Path:
    if not path.is_file():
        raise FileNotFoundError(f"Required evidence file is missing: {path}")
    return path


def key_value_csv(path: Path) -> dict[str, str]:
    rows = read_csv(require_file(path))
    if not rows or not {"field", "value"}.issubset(rows[0]):
        raise ValueError(f"Expected field/value CSV: {path}")
    return {row["field"]: row["value"] for row in rows}


def source_manifest(path: Path) -> dict[str, str]:
    rows = read_csv(require_file(path))
    if not rows or not {"key", "value"}.issubset(rows[0]):
        raise ValueError(f"Expected source manifest with key/value columns: {path}")
    return {row["key"]: row["value"] for row in rows}


def as_bool(value: object) -> bool:
    return str(value).strip().lower() in {"true", "t", "1", "pass", "passed"}


def finite_number(value: object) -> float | None:
    try:
        number = float(str(value).strip())
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) else None


def format_number(value: object, digits: int = 3) -> str:
    number = finite_number(value)
    if number is None:
        return "Not reported"
    if number == 0:
        return "0"
    return f"{number:.{digits}g}"


def validation_summary(path: Path) -> dict[str, object]:
    rows = read_csv(require_file(path))
    if not rows or "pass" not in rows[0]:
        raise ValueError(f"Validation record lacks a pass column: {path}")
    errors = [finite_number(row.get("max_abs_error", "")) for row in rows]
    errors = [error for error in errors if error is not None]
    return {
        "checks": len(rows),
        "passed": sum(as_bool(row["pass"]) for row in rows),
        "maximum_error": max(errors, default=None),
    }


def current_release_reproducibility_dir() -> Path:
    root = ARTICLE / "reproducibility" / "results"
    candidates: list[Path] = []
    for directory in root.iterdir() if root.exists() else []:
        manifest_path = directory / "source_archive_manifest.csv"
        if not directory.is_dir() or not manifest_path.is_file():
            continue
        manifest = source_manifest(manifest_path)
        if (
            manifest.get("release_tag") == RELEASE_TAG
            and manifest.get("package_version") == RELEASE_VERSION
        ):
            candidates.append(directory)
    if not candidates:
        raise FileNotFoundError(
            "No clean-environment Route-B result exists for v0.2.0. Run "
            "Rscript article/reproducibility/run_clean_reproducibility.R --tag v0.2.0 "
            "before building Online Resource 1."
        )
    return max(candidates, key=lambda item: item.stat().st_mtime)


def reproducibility_summary(result_dir: Path) -> dict[str, object]:
    manifest = source_manifest(result_dir / "source_archive_manifest.csv")
    if manifest.get("release_tag") != RELEASE_TAG or manifest.get("package_version") != RELEASE_VERSION:
        raise ValueError(f"Reproducibility result does not identify {RELEASE_TAG}: {result_dir}")
    comparison = read_csv(result_dir / "reproducibility_comparison.csv")
    if not comparison or "identical_sha256" not in comparison[0]:
        raise ValueError("Reproducibility comparison lacks identical_sha256 records.")
    run_status = read_csv(result_dir / "run_status.csv")
    if len(run_status) != 2 or not all(row.get("status") == "PASS" for row in run_status):
        raise ValueError("The v0.2.0 reproducibility audit must contain two passing runs.")
    return {
        "comparisons": len(comparison),
        "matching": sum(as_bool(row["identical_sha256"]) for row in comparison),
        "scopes": ", ".join(sorted({row.get("comparison_scope", "record") for row in comparison})),
        "runs": len(run_status),
    }


def sensitivity_rows() -> list[list[str]]:
    rows = read_csv(require_file(ARTICLE / "sensitivity" / "results" / "sensitivity_results.csv"))

    selectors = [
        (
            "Grid resolution; constant cell count",
            lambda row: row["scenario"].startswith("constant 5-cell") and row["metric"] == "bpi",
        ),
        (
            "Grid resolution; approximately constant map support",
            lambda row: row["scenario"].startswith("approximately constant") and row["metric"] == "bpi",
        ),
        (
            "Preprocessing; no smoothing versus 3 x 3 mean",
            lambda row: row["scenario_class"] == "preprocessing" and row["metric"] == "slope_deg",
        ),
        (
            "Focal neighborhood; BPI 3 x 3 versus 11 x 11",
            lambda row: row["scenario"].startswith("bpi 3-cell versus 11-cell") and row["metric"] == "bpi",
        ),
        (
            "Vertical sign; elevation versus positive depth",
            lambda row: row["scenario_class"] == "vertical sign" and row["metric"] == "bpi",
        ),
        (
            "Coordinate-unit control",
            lambda row: row["scenario_class"] == "coordinate-unit control",
        ),
    ]
    selected: list[list[str]] = []
    for label, predicate in selectors:
        match = next((row for row in rows if predicate(row)), None)
        if match is None:
            raise ValueError(f"Current sensitivity results lack: {label}")
        metric = match["metric"]
        mad = format_number(match.get("median_absolute_cellwise_difference", ""))
        rho = format_number(match.get("spearman_rho", ""))
        result = (
            match["interpretation"]
            if match["scenario_class"] == "coordinate-unit control"
            else f"median absolute cellwise difference {mad}; Spearman rho {rho}"
        )
        selected.append([label, metric, match["focal_scale_metres"], result])
    return selected


def benchmark_rows() -> tuple[list[list[str]], dict[str, str]]:
    metadata = key_value_csv(ARTICLE / "benchmark" / "results" / "benchmark_metadata.csv")
    if metadata.get("blueterra_version") != RELEASE_VERSION:
        raise ValueError(
            "Benchmark evidence does not identify blueterra 0.2.0; rerun the v0.2.0 benchmark before building the supplement."
        )
    rows = read_csv(require_file(ARTICLE / "benchmark" / "results" / "table5_computational_evaluation.csv"))
    if not rows or not all(row.get("repetitions") == "20" for row in rows):
        raise ValueError("Benchmark evidence must contain 20 timed repetitions per configuration.")
    report_rows = []
    for row in rows:
        report_rows.append([
            row["raster_dimensions"],
            row["output_storage_mode"],
            row["repetitions"],
            row["runtime_summary"],
            "Not reported",
        ])
    return report_rows, metadata


def add_page_number(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.drawCentredString(letter[0] / 2, 0.48 * inch, f"Page {doc.page}")
    canvas.restoreState()


def paragraph(text: str, style: ParagraphStyle):
    return Paragraph(escape(text), style)


def simple_table(rows, widths, header=True, font_size=7):
    cell_style = ParagraphStyle(
        name=f"Cell{font_size}", fontName="Helvetica", fontSize=font_size,
        leading=font_size + 1.3, spaceAfter=0,
    )
    header_style = ParagraphStyle(
        name=f"Header{font_size}", fontName="Helvetica-Bold", fontSize=font_size,
        leading=font_size + 1.3, spaceAfter=0,
    )
    wrapped = []
    for row_index, row in enumerate(rows):
        style = header_style if header and row_index == 0 else cell_style
        wrapped.append([Paragraph(escape(str(value)), style) for value in row])
    table = Table(wrapped, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    commands = [
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#A9B3BE")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), font_size),
    ]
    if header:
        commands.extend([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E8EEF5")),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ])
    table.setStyle(TableStyle(commands))
    return table


def main():
    analytical = validation_summary(ARTICLE / "validation" / "results" / "analytical_validation.csv")
    wrapper = validation_summary(ARTICLE / "validation" / "results" / "wrapper_agreement.csv")
    functional = validation_summary(ARTICLE / "validation" / "results" / "functional_verification.csv")
    provenance = key_value_csv(ARTICLE / "data_provenance" / "results" / "bluetopo_example_manifest.csv")
    repro = reproducibility_summary(current_release_reproducibility_dir())
    benchmark_table, benchmark = benchmark_rows()
    sensitivity = sensitivity_rows()

    expected_checks = (28, 22, 21)
    observed_checks = (
        analytical["checks"],
        wrapper["checks"],
        functional["checks"],
    )
    if observed_checks != expected_checks or any(
        summary["checks"] != summary["passed"]
        for summary in (analytical, wrapper, functional)
    ):
        raise ValueError(
            "v0.2.0 Online Resource 1 requires 28/22/21 fully passing "
            f"analytical, wrapper, and functional checks; found {observed_checks}."
        )
    if provenance.get("tile_id") != "BH54S4ZB":
        raise ValueError("The Route-B provenance manifest does not identify tile BH54S4ZB.")
    if benchmark.get("source_tile_id") != provenance.get("tile_id"):
        raise ValueError("Benchmark and Route-B provenance records identify different BlueTopo tiles.")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name="Body10", parent=styles["BodyText"], fontName="Helvetica", fontSize=9, leading=12, spaceAfter=7))
    styles.add(ParagraphStyle(name="Heading", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=12, leading=15, spaceBefore=10, spaceAfter=5, textColor=colors.black))
    styles.add(ParagraphStyle(name="TitleCenter", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=16, leading=20, alignment=TA_CENTER, spaceAfter=8))
    styles.add(ParagraphStyle(name="Center", parent=styles["BodyText"], fontName="Helvetica", fontSize=9, leading=12, alignment=TA_CENTER, spaceAfter=3))

    doc = SimpleDocTemplate(
        str(OUT), pagesize=letter, topMargin=0.75 * inch, bottomMargin=0.75 * inch,
        leftMargin=0.75 * inch, rightMargin=0.75 * inch,
        title="Online Resource 1 - Reproducible Workflow", author="Elvin Cordero",
    )
    story = []
    story.append(paragraph(TITLE, styles["TitleCenter"]))
    story.append(paragraph("Earth Science Informatics - Online Resource 1", styles["Center"]))
    story.append(paragraph("Elvin Cordero", styles["Center"]))
    story.append(paragraph("Department of Marine Sciences, University of Puerto Rico at Mayaguez, Mayaguez, Puerto Rico, USA", styles["Center"]))
    story.append(paragraph("SeaMount Geospatial Labs, Brooklyn, New York, USA", styles["Center"]))
    story.append(paragraph("Correspondence: elvin.cordero1@upr.edu", styles["Center"]))
    story.append(Spacer(1, 12))

    story.append(paragraph("Purpose", styles["Heading"]))
    story.append(paragraph(
        "This online resource records the executed v0.2.0 workflow. It links the documented NOAA BlueTopo Route-B input, controlled verification, clean-environment regeneration, scale and preprocessing scenarios, computational records, and archived evidence in Online Resource 2. A persistent archive DOI is pending; the release is identified here by tag v0.2.0 rather than by a raw commit identifier.",
        styles["Body10"],
    ))

    story.append(paragraph("Release, data, and environment", styles["Heading"]))
    env_rows = [
        ["Item", "Recorded value"],
        ["Release under test", "tag v0.2.0; blueterra 0.2.0; persistent archive DOI pending"],
        ["Route-B data product", f"NOAA BlueTopo tile {provenance['tile_id']} ({provenance['tile_filename']}); accessed {provenance['accessed_utc']}"],
        ["Source grid", f"{provenance['tile_resolution']}; {provenance['tile_horizontal_crs']}"],
        ["Vertical convention", provenance["tile_vertical_reference_summary"]],
        ["Article grid", f"{provenance['study_rows']} rows x {provenance['study_columns']} columns; {provenance['study_grid_spacing_m']} m spacing; elevation values become more negative with depth"],
        ["Analysis polygons", "Author-created deterministic rectangular windows; documented in the Route-B provenance manifest"],
        ["R and dependencies", f"{benchmark['r_version']}; terra {benchmark['terra_version']}; benchmarked blueterra {benchmark['blueterra_version']}"],
        ["Benchmark platform", benchmark["operating_system"] + "; " + benchmark["hardware"]],
        ["Random seed", benchmark["random_seed"]],
    ]
    story.append(simple_table(env_rows, [1.7 * inch, 5.3 * inch], font_size=7.2))

    story.append(paragraph("Execution sequence", styles["Heading"]))
    commands = [
        "Rscript article/data_provenance/acquire_bluetopo_example.R",
        "Rscript article/validation/run_analytical_validation.R",
        "Rscript article/validation/run_wrapper_agreement.R",
        "Rscript article/validation/run_functional_verification.R",
        "Rscript article/reproducibility/run_clean_reproducibility.R --tag v0.2.0",
        "Rscript article/sensitivity/run_sensitivity.R",
        "Rscript article/benchmark/run_benchmark.R",
        "Rscript article/tables/generate_table1.R",
        "Rscript article/tables/generate_table2.R",
        "Rscript article/tables/generate_table3.R",
        "Rscript article/figures/generate_figures_1_to_6.R",
        "Rscript article/figures/generate_fig7.R",
        "Rscript article/environment/collect_environment.R",
    ]
    story.append(paragraph("The following version-controlled scripts generated the recorded evidence:", styles["Body10"]))
    story.append(simple_table([[f"{index:02d}", command] for index, command in enumerate(commands, start=1)], [0.35 * inch, 6.65 * inch], header=False, font_size=7.4))

    story.append(PageBreak())
    story.append(paragraph("Verification and agreement", styles["Heading"]))
    story.append(paragraph(
        "Controlled synthetic surfaces tested numerical expectations for slope, aspect, northness, eastness, roughness, TRI, TPI, square and annular BPI, normalized BPI, VRM-style rugosity, the four-neighbor Laplacian-style index, and the slope-based surface-area ratio. Separate functional checks exercised spatial-summary, transect, corridor, custom-layer, and metric-catalog behavior. Direct terra comparisons are upstream-wrapper agreement, not independent cross-implementation validation.",
        styles["Body10"],
    ))
    verification_rows = [
        ["Record group", "Checks", "Passed", "Maximum absolute error", "Scope"],
        ["Analytical verification", str(analytical["checks"]), str(analytical["passed"]), format_number(analytical["maximum_error"]), "Synthetic mathematical references and stated edge policies"],
        ["Upstream-wrapper agreement", str(wrapper["checks"]), str(wrapper["passed"]), format_number(wrapper["maximum_error"]), "Matched terra calls, grids, units, and parameters"],
        ["Functional verification", str(functional["checks"]), str(functional["passed"]), format_number(functional["maximum_error"]), "Transects, corridors, weighted summaries, custom layers, and catalog handling"],
    ]
    story.append(simple_table(verification_rows, [1.5 * inch, 0.55 * inch, 0.55 * inch, 1.15 * inch, 3.25 * inch], font_size=6.7))
    story.append(paragraph(
        "The executed records report 28 analytical checks, 22 upstream-wrapper checks, and 21 functional checks. The four-neighbor Laplacian-style index is unscaled by cell dimensions; it is not plan or profile curvature. The reported surface-area ratio is 1/cos(slope), a local secant approximation rather than a triangulated benthic-area measurement.",
        styles["Body10"],
    ))

    story.append(paragraph("Clean-environment regeneration", styles["Heading"]))
    story.append(paragraph(
        f"A clean git archive of tag v0.2.0 was installed into a new private library and the documented Route-B workflow was run twice in fresh Rscript --vanilla processes. The current comparison contains {repro['comparisons']} deterministic input, table, schema, and binary-inventory records; {repro['matching']} matched. The comparison scopes were {repro['scopes']}. The binary raster and vector artifacts are represented by schemas and inventory rather than claimed platform-independent binary hashes.",
        styles["Body10"],
    ))
    repro_rows = [
        ["Evidence", "Recorded result"],
        ["Release isolation", "Tagged source archive only; working tree excluded from the package under test"],
        ["Fresh processes", f"{repro['runs']} Rscript --vanilla runs"],
        ["Paired comparison", f"{repro['matching']} of {repro['comparisons']} records matched"],
        ["Route-B inputs", "BlueTopo elevation crop, author-created analysis windows, and provenance manifest hash-verified in both runs"],
    ]
    story.append(simple_table(repro_rows, [1.6 * inch, 5.4 * inch], font_size=7.1))

    story.append(PageBreak())
    story.append(paragraph("Scale and preprocessing sensitivity", styles["Heading"]))
    story.append(paragraph(
        "The sensitivity analysis used the documented 4 m Route-B elevation crop. Grid-resolution scenarios mean-aggregated elevation to 8 m, differentiated on the coarser grid, and bilinearly resampled the candidate derivatives to the 4 m grid only for cellwise comparison. Preprocessing, focal-neighborhood, vertical-sign, and coordinate-unit scenarios were evaluated separately; no scenario is presented as a universally correct scale.",
        styles["Body10"],
    ))
    sens_table = [["Scenario", "Metric", "Focal support", "Current result"]] + sensitivity
    story.append(simple_table(sens_table, [2.0 * inch, 0.78 * inch, 1.25 * inch, 2.97 * inch], font_size=6.5))

    story.append(paragraph("Computational assessment", styles["Heading"]))
    story.append(paragraph(
        "The benchmark used the documented BlueTopo crop and two nearest-neighbor disaggregations for computational scaling only. Each configuration had one warm-up run and 20 timed repetitions; timing covered stack derivation and forced output materialization, excluding package loading and one-time workload construction. Peak resident memory is omitted because OS-level RSS measurement was unavailable; no R Vcell estimate was substituted.",
        styles["Body10"],
    ))
    bench_table = [["Raster", "Output mode", "Repetitions", "Runtime", "Peak RSS"]] + benchmark_table
    story.append(simple_table(bench_table, [1.0 * inch, 1.35 * inch, 0.62 * inch, 2.45 * inch, 1.58 * inch], font_size=6.5))

    story.append(paragraph("Archive contents", styles["Heading"]))
    story.append(paragraph(
        "Online Resource 2 contains the v0.2.0 source archive, Route-B acquisition and preparation material, validation and functional-verification records, the selected clean-environment release result, sensitivity and benchmark outputs, generated tables and figures, and software/environment manifests. The archive includes a machine-readable source identifier manifest that records the release tag, full source commit identifier, and archive checksum. NOAA data are cited as a documented external Route-B input; this archive does not claim ownership of the NOAA source product.",
        styles["Body10"],
    ))
    archive_rows = [
        ["Included component", "Contents"],
        ["Tagged source", "git archive v0.2.0, named v0.2.0_v0.2.0.tar"],
        ["Route-B data lineage", "Official tile scheme, tile metadata, checksum-verified elevation crop, and author-created analysis windows"],
        ["Executed evidence", "Validation, agreement, functional verification, clean regeneration, sensitivity, benchmark, table, figure, and environment records"],
        ["Artwork and tables", "Submission figures, supplementary figures, and machine-readable CSV tables"],
        ["Machine-readable identifiers", "Source tag/commit/archive manifest, input/output manifests, dependency records, and checksums"],
    ]
    story.append(simple_table(archive_rows, [1.55 * inch, 5.45 * inch], font_size=7.0))

    doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
    print(OUT)


if __name__ == "__main__":
    main()
