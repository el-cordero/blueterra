# Computational benchmark methods

The task derived a six-layer metric stack from the documented BlueTopo elevation crop:
slope; BPI at 3x3 and 11x11 cells; VRM-style rugosity; four-neighbor Laplacian-style index; slope-based surface-area ratio

Three source-derived workloads were measured: the 751 x 1,001-cell documented crop,
a factor-two nearest-neighbour disaggregation (1,502 x 2,002 cells), and a factor-four
nearest-neighbour disaggregation (3,004 x 4,004 cells). Disaggregation was performed
once before timing solely to create larger computational workloads; it was not used for
scientific interpretation, map production, or scale-sensitivity results.

Every configuration received one warm-up run followed by 20 timed repetitions. Timing
started immediately before metric derivation and ended after all output layers were forced
to materialise. Package loading and one-time workload preparation were excluded. The large
workload was measured with both an in-memory output request and a file-backed GeoTIFF
output request. Peak RSS was not reported because OS-level memory tools were unavailable
in this execution environment; no R Vcell estimate was substituted.
