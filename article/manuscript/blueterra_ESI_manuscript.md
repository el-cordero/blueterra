# Abstract

Submerged-terrain metrics support description of bathymetric form, but their values depend on grid spacing, coordinate reference system, vertical convention, preprocessing, and neighborhood support. `blueterra` is an R-centered workflow that prepares bathymetric rasters, derives a defined set of established terrain metrics, records metric metadata, and supports spatial summaries, transects, isobath corridors, exploratory tables, visualization, and aligned user layers. The evaluated package release was version 0.2.0. Controlled analytical checks (28), direct upstream-wrapper comparisons (22), and synthetic functional checks (21) all passed. The largest analytical difference was 2.84 × 10⁻¹⁴, below its 2.43 × 10⁻⁶ tolerance. In a documented 4 m NOAA BlueTopo example from southwest Puerto Rico, deriving slope after 8 m mean aggregation and then resampling the derivative for comparison produced a median absolute cellwise slope difference of 2.71 degrees; 3 × 3 smoothing changed fine-scale BPI by 0.285 m (Spearman’s rho = 0.233). A six-layer terrain stack on 12.0 million cells had median runtimes of 2.84 s in memory and 3.90 s with file-backed output. The contribution is a transparent R workflow around established calculations, not a new geomorphic algorithm or a physical-process model.

# Keywords

Bathymetry; marine geomorphometry; raster terrain analysis; R; reproducible geospatial computation; BlueTopo

# 1. Introduction

Bathymetric grids make seafloor relief available for quantitative description, yet the same grid can yield different terrain attributes when its support, preparation, and conventions change. Marine geomorphometry has therefore treated terrain attributes as scale-dependent descriptions of a digital surface rather than direct measurements of ecological or oceanographic processes (Lecours et al. 2016; Wilson et al. 2007). Slope, aspect, relative position, ruggedness, and curvature-style indices are useful for examining form and for structuring subsequent analyses, but their scientific interpretation depends on the data source, uncertainty, resolution, and intended question (Dolan and Lucieer 2014; Lecours et al. 2017).

The analytical settings that determine an attribute’s numerical support require the same care as the formula itself. Grid size controls the represented surface, smoothing changes local gradients, and focal-window dimensions specify the local reference for relative-position or roughness measures (Hengl 2006; Thompson et al. 2001; Misiuk et al. 2021). Coordinate systems are material when a calculation uses cell dimensions or map-unit radii, and vertical sign convention reverses the interpretation of elevation-difference indices even when gradient magnitude is unchanged. Source quality, horizontal and vertical reference systems, and processing lineage likewise need to be documented from the bathymetric product rather than inferred from a derivative (International Hydrographic Organization 2022; Lecours et al. 2016).

R provides mature raster and vector infrastructures through `terra` and `sf` (Hijmans et al. 2026; Pebesma 2018). WhiteboxTools, Benthic Terrain Modeler, and other marine terrain workflows offer broad algorithmic environments and classification-oriented capabilities (Lindsay 2016; Walbridge et al. 2018; Wu and Brown 2025). The narrower gap addressed here is an R workflow that keeps raster preparation, a limited terrain stack, metric metadata, summaries, transects, corridor analysis, and user extensions together while preserving the boundaries between upstream calls, local formulas, and externally supplied layers. That scope is complementary to R-based multiscale terrain tooling such as MultiscaleDTM rather than a replacement for it (Ilich et al. 2023).

`blueterra` implements that workflow for bathymetric or elevation rasters. It does not propose slope, aspect, TRI, TPI, BPI, VRM, curvature, or surface-area algorithms as new contributions, and it does not model currents, waves, sediment transport, habitat, or ecology. This article documents version 0.2.0, reports its corrected and tested implementation behavior, and uses a newly documented NOAA BlueTopo example to demonstrate how stated conventions and spatial support shape the resulting terrain descriptors.

# 2. Design and Implementation

## 2.1 Spatial data model and raster preparation

The package uses `terra::SpatRaster` objects as its raster data model and returns named rasters, rectangular tables, and vector geometries that remain available for inspection in R. Bathymetry can be read or converted through `read_bathy()` and `as_bathy()`, then checked with `validate_bathy()`. The preparation layer exposes cropping, masking, projection, resampling, depth filtering, sign conversion, and odd-window mean smoothing rather than applying hidden transformations. These operations preserve analyst responsibility for horizontal units, vertical reference, gridding history, and quality; the package does not correct survey artifacts or reconcile vertical datums.

Figure 1 shows the resulting architecture. The input raster passes through preparation into an aligned metric stack. Some layers are direct `terra` calls, while others are small local formulas. The metric catalog is accompanying metadata rather than a mandatory computational gateway. Polygon and depth-band summaries, terrain-oriented transects, and contour-buffered corridors operate on the stack; aligned external or custom layers may join it after geometry checks.

[FIGURE 1]

## 2.2 Terrain metrics, implementation sources, and metric metadata

The compact set of reported metrics and their constraints is defined in Table 1. Slope and aspect delegate to `terra::terrain()`, with northness and eastness obtained as the cosine and sine of aspect. Roughness, TRI, and TPI likewise use `terra`’s established terrain operations; agreement with direct `terra` calls is consequently described below as wrapper equivalence, not independent cross-implementation validation. Historical terrain literature provides the definitions and usage context for slope/aspect, TRI, TPI, and vector ruggedness measures, but does not make a package wrapper novel (Horn 1981; Riley et al. 1999; De Reu et al. 2013; Sappington et al. 2007).

[TABLE 1]

The BPI implementation is focal value minus focal-neighborhood mean. Square windows are specified in cells and include the focal cell in that mean. Annular configurations are distinct: radii are expressed in projected map units, their kernels use separate x and y cell dimensions, and the focal cell is included only when the inner radius permits it. A geographic raster now fails clearly when asked to interpret an annular radius in map units. Normalized BPI divides by local sample standard deviation and yields `NA`, rather than an accidental `NaN`, in zero-variance neighborhoods. At raster edges and beside missing values, BPI uses available cells in its partial focal support while a missing focal value remains missing.

`derive_rugosity()` is a VRM-style local index formed from slope/aspect-derived unit normals. Its focal component means can use partial valid normal-vector support, although the outer derivative ring and missing-data derivative boundaries can remain unavailable. `derive_curvature()` retains the legacy output layer name `curvature` but is described here and in the catalog as a four-neighbor Laplacian-style index: north + south + east + west − 4 × center. It is unscaled by cell dimensions and is therefore strongly resolution-dependent; it is not plan, profile, mean, or Gaussian curvature. `derive_surface_area_ratio()` uses 1/cos(slope), a slope-secant approximation rather than the triangulated surface-area method described by Jenness (2004).

Metric catalog entries assign names, units, implementation sources, and interpretation constraints to layers. Process-group labels organize the available descriptors and can guide transparent selection; they do not make a terrain layer a measurement of accumulation, transport, or ecological state. Custom layers are admitted only after grid-geometry checks and can receive an explicit user-defined catalog record.

## 2.3 Spatial summaries, transects, isobath corridors, and extension

Polygon and depth-band functions produce wide summary tables for selected layers. The ordinary polygon route extracts values at raster cells. The `exact = TRUE` route uses `exactextractr` intersections and now applies positive coverage fractions to the mean, population standard deviation, median, sum, and effective cell count; minima and maxima use positively covered cells (Baston 2025). The resulting mean is area-weighted when cells have equal area in the working projected CRS. This distinction is recorded because exact intersection alone would not justify an area-weighted statement.

Transects are regularly spaced candidate lines clipped to each source polygon. An analyst may supply a direction, use a bounding-box axis, or estimate a direction from mean aspect components. Surface-derived outputs retain the angle, source, number of contributing cells, weighting choice, and circular resultant length. A value near zero signals weakly concentrated or cancelling aspects and cautions against interpreting a mean direction as stable. Cross-sections are sampled along the line geometry and may be reoriented from shallower to deeper endpoint values for visual comparison.

Isobaths are contours of the supplied raster; corridor polygons are independent one-sided buffers whose nominal full width is twice the requested distance. They can overlap, so their summaries are not mutually exclusive or additive. The operation records the buffer distance, nominal width, and overlap policy and warns for longitude–latitude rasters. Like the other functions, corridor outputs are terrain summaries and not hydrodynamic or sediment-transport simulations.

# 3. Evaluation Methods

## 3.1 Numerical verification and wrapper equivalence

The analytical verification scripts used 1 m projected synthetic rasters with stated horizontal and vertical units. A plane, constant surface, center-relief fixture, convex and concave quadratics, non-square cells, and a synthetic ramp supplied reference behavior for the tested calculations. They covered planar slope/aspect, northness/eastness, roughness, TRI/TPI wrapper behavior, square and annular BPI with and without center inclusion, normalized BPI, VRM-style rugosity, the four-neighbor Laplacian-style index, and the slope-secant surface-area approximation. Reference tolerances were scaled to floating-point magnitude and the mathematical expectation rather than selected as a fixed universal threshold. Edges and missing-data support were recorded separately from complete interior cells.

Direct comparisons with `terra` reconstructed the same upstream calls, units, neighborhoods, and focal arguments. They are called upstream-wrapper equivalence because the wrapper and comparator share the same upstream implementation. Independent array formulas or analytical surfaces were reserved for the local calculations. Additional functional scripts tested transect direction, spacing, clipping, line count, orientation concentration, isobath location and corridor width, overlap behavior, known polygon values, depth-band order, exact-coverage weighting, custom-layer rejection, and unmatched catalog assignments. Table 2 summarizes these families; the test-by-test records remain in Online Resource 2.

[TABLE 2]

## 3.2 Example-data workflow and scale sensitivity

Example data. The real-data workflow used NOAA BlueTopo elevation tile `BH54S4ZB_20251117`, accessed on 11 July 2026 and delivered in the retained tile scheme on 19 December 2025. The setting lies on the southwest Puerto Rico insular slope, a region previously described in regional geomorphologic work (Sherman et al. 2010). The article crop spans 707,998–712,002 m E and 1,976,498–1,979,502 m N; it contains 751 rows by 1,001 columns at 4 m by 4 m grid spacing. The source horizontal reference is EPSG:6348, NAD83(2011) / UTM zone 19N. The tile-specific vertical metadata identify MSL(GEOID12B) height, described as Mean Sea Level using the NOAA hybrid geoid 2012 B model. Stored elevations are in meters and increasingly negative offshore; no vertical transformation was applied.

The workflow used the elevation band only, cropped it to the stated grid-aligned extent, and applied no smoothing before the principal maps. Two rectangular sampling windows were created by the author in the preparation script; they are analytical geometries, not externally sourced management or biological polygons. The raw tile, RAT, tile-scheme record, checksums, acquisition script, processing manifest, and author-created vector file are retained with the article materials. NOAA documents BlueTopo as public data and requests acknowledgement; the source terms and product context are recorded with the dataset rather than claimed as author ownership (NOAA Office of Coast Survey 2025; NOAA Office of Coast Survey n.d.). The legacy southwest Puerto Rico package fixtures were excluded from these real-data figures and results because their original tile and vector provenance remains unresolved.

Sensitivity analyses separated grid-resolution, preprocessing, focal-neighborhood, sign-representation, and coordinate-unit effects. For the grid comparison, elevation was mean-aggregated from 4 to 8 m, derivatives were calculated on the 8 m raster, and candidate derivative layers were bilinearly resampled to the 4 m grid only to calculate paired statistics. This compound procedure was not interpreted as a pure resolution effect. BPI and VRM were compared both with constant five-cell windows and with approximately constant map-unit support (4 m 7 × 7 versus 8 m 3 × 3; 28 versus 24 m side length). Preprocessing contrasted no smoothing with a 3 × 3 mean filter. Focal-window comparisons used 3, 7, and 11 cells at 4 m, and sign tests compared negative elevation with positive depth. A longitude–latitude diagnostic confirmed that map-unit annular BPI is rejected rather than silently interpreted in angular units.

Figure 2 presents the documented input and selected terrain outputs with a location inset and scale bar. Figure 3 uses the same stack to show catalog grouping, author-created analysis windows, and ordered elevation-band summaries. Figure 4 then applies the recorded surface-orientation calculation to transects, and Figure 5 summarizes slope distributions within documented isobath corridors.

[FIGURE 2]

## 3.3 Repeatability and computational assessment

Reproducibility scripts record input checksums, result schemas or deterministic hashes, random seeds, operating-system and dependency versions, package version, and data manifests. The documented BlueTopo preparation script and the article scripts are version-controlled alongside their generated records. The clean-environment harness is designed to install the exact source archive in a private R library and execute the documented example twice with `Rscript --vanilla`; it is rerun after the versioned tag is created.

Computational timing used the documented BlueTopo crop at 751,751 cells and nearest-neighbor disaggregations at 3,007,004 and 12,028,016 cells solely for computational scaling. Each metric-stack task requested slope, BPI at 3 × 3 and 11 × 11, VRM-style rugosity, a four-neighbor Laplacian-style index, and the surface-area ratio. One warm-up preceded 20 timed repetitions per configuration; the largest input was measured both in memory and with file-backed GeoTIFF output. Timing is reported as median, interquartile range, and range. An operating-system-level peak-resident-memory method was unavailable in the execution environment, so memory is omitted rather than estimated from R Vcells.

# 4. Results

## 4.1 Numerical verification and repeatability

All 28 analytical checks, 22 upstream-wrapper comparisons, and 21 functional checks passed. The largest analytical difference was 2.84 × 10⁻¹⁴ for planar aspect in degrees, below the 2.43 × 10⁻⁶ tolerance. Planar interiors produced the expected slope, aspect transforms, and slope-secant ratio; constant or constant-orientation interiors produced zero roughness, TRI/TPI departure, and VRM-style rugosity where defined. The convex and concave surfaces produced opposite four-neighbor Laplacian-style values, and the BPI fixtures confirmed focal-cell inclusion for square and zero-inner-radius annular windows. Functional tests confirmed the revised non-square annulus geometry, geographic-CRS guard, zero-variance `NA` behavior, exact coverage weighting, transect-resultant metadata, corridor geometry, and custom-layer/catalog conditions.

The wrapper comparisons had zero maximum difference for the tested direct calls and transparent formula reconstructions. These results establish the package behavior under the stated inputs and versions; they do not validate terrain attributes as physical-process predictors. The post-tag clean-environment repeatability record is supplied in Online Resource 2 rather than the main text, together with input/output hash and schema details.

## 4.2 Example workflow, scale sensitivity, and computational behavior

The documented 4 m example retained a broad shallow-to-deep transition and local linear texture in the input elevation map (Fig. 2). The metric catalog assigned slope, BPI, VRM-style rugosity, the Laplacian-style index, and the surface-area ratio to transparent descriptor groups; it did not create any external catalog-only metric. Across ordered elevation bands, the displayed slope distributions differed in both central tendency and spread (Fig. 3). The author-created slope window produced six surface-oriented transects at 250 m spacing. Their shared angle was 84.8 degrees, based on slope-weighted aspect components from 103,666 cells with a resultant length of 0.771; the plotted profiles are directed from shallower to deeper endpoint values (Fig. 4).

The −100, −300, and −600 m corridors used a one-sided 20 m buffer, equivalent to a nominal 40 m full width or ten 4 m cells. Their areas were 0.177, 0.174, and 0.195 km² and their contributing slope-cell counts were 11,000, 10,781, and 12,100, respectively. No corridor overlap was detected for these selected contours, although the output policy remains independent and permits overlap in other settings. The slope distributions are shown as box plots rather than unsupported mean-only bars (Fig. 5).

Sensitivity results demonstrate why grid and focal support must be reported. Deriving slope after 8 m aggregation and resampling the derivative for paired comparison produced a median absolute cellwise difference of 2.71 degrees (rho = 0.843) relative to the 4 m result. For BPI with approximately comparable map-unit support, the 4 m 7 × 7 versus 8 m 3 × 3 comparison produced a 0.362 m median absolute difference (rho = 0.692). A 3 × 3 mean smoother changed 3 × 3 BPI by 0.285 m (rho = 0.233), while increasing the native BPI window from 3 × 3 to 11 × 11 changed it by 0.363 m (rho = 0.756). Sign inversion produced BPI rho = −1.000; it is a representation change rather than a vertical-datum conversion. Figure 6 separates these maps and unit-specific statistics, while Table 3 combines the selected sensitivity and timing records.

[FIGURE 3]

[FIGURE 4]

[FIGURE 5]

[FIGURE 6]

[TABLE 3]

The native 751,751-cell stack had a median runtime of 0.270 s (IQR 0.007 s). At 12,028,016 cells, median runtime was 2.84 s in memory (IQR 0.019 s) and 3.90 s with file-backed output (IQR 0.161 s). These measurements describe one macOS configuration and the stated metric request; they are not a comparison against other software or a hardware requirement. Figure 7 displays the synthetic surfaces, observed-versus-expected results, and error-to-tolerance ratios without replacing exact zeros by artificial log-scale values.

[FIGURE 7]

# 5. Discussion

The demonstrated contribution is a traceable R workflow that connects raster preparation, a bounded set of terrain descriptors, metric metadata, and common spatial-analysis products. The analytical, wrapper, and functional checks establish that the tested source behaves as documented for the specified synthetic surfaces and geometry conditions. They do not validate the physical interpretation of a terrain descriptor, the quality of a survey, a vertical transformation, or any habitat, current, wave, sediment, or ecological prediction. This distinction is especially important for marine terrain analysis, where a derivative is one representation of a gridded survey product rather than direct evidence of a process (Lecours et al. 2016; Misiuk and Brown 2024).

`blueterra` adds workflow integration and visible conventions beyond invoking isolated `terra` functions, but it neither replaces `terra` nor claims a faster or more accurate implementation. `terra` remains the computational source for several core derivatives. WhiteboxTools and Benthic Terrain Modeler provide broader algorithmic and classification-oriented environments, whereas `blueterra` centers on a compact R raster-and-vector workflow with metadata, summaries, transects, and corridor products (Erdey-Heydorn 2008; Walbridge et al. 2018; Wu and Brown 2025). BPI and multiscale terrain approaches have long been used in marine terrain characterization, but the selected support and threshold remain analysis-specific (Lundblad et al. 2006; Misiuk et al. 2018).

The example results quantify the practical consequence of scale choices rather than endorse one correct resolution or focal window. Aggregation, smoothing, differentiation, and interpolation affect the support of a derivative in different ways, so their effects should not be collapsed into a single “resolution” result. The BPI and VRM comparisons show that both the number of cells and the map-unit footprint matter. CRS, sign convention, and the unscaled Laplacian-style index impose additional interpretive constraints. Published marine studies likewise report sensitivity of terrain attributes to grid resolution, method, and artifacts; those studies motivate reporting choices, not claims that a package resolves them automatically (Dolan and Lucieer 2014; Lecours et al. 2017; Misiuk et al. 2021).

The workflow remains limited by input-data quality, uncertain or product-specific vertical references, partial neighborhoods, missing-data boundaries, and the distinction between a terrain description and a process model. The documented BlueTopo tile provides a reproducible source and declared vertical metadata for this article, but it does not remove the need to evaluate local survey quality or uncertainty. The legacy package fixtures remain excluded from the article’s real-data evidence until their provenance and redistribution status are recovered. Future work can add complete-window controls, richer uncertainty propagation, additional terrain descriptors, and wider platform testing without changing the present scope. Versioned scripts, manifests, and supplementary records support repeatability in the documented environment, consistent with research-compendium practice (Marwick et al. 2018).

# 6. Conclusions

`blueterra` provides an R workflow for preparing bathymetric rasters, deriving a stated terrain stack, organizing metric metadata, and producing reproducible summaries, transects, corridors, and visual outputs. The evaluation demonstrated numerical, wrapper, and functional behavior under declared synthetic and BlueTopo example conditions. Its appropriate use is transparent descriptive geomorphometry with reported CRS, vertical convention, grid spacing, preprocessing, and focal support. Its primary limitation is that it cannot establish data quality or turn terrain descriptors into validated physical or ecological process models.

# Availability and Requirements

Software name: blueterra. Evaluated version: 0.2.0. Release tag: v0.2.0 (Cordero 2026). A persistent archive DOI has not yet been assigned; this unresolved release item is recorded in the submission compliance checklist. Maintained repository: https://github.com/el-cordero/blueterra. Documentation: https://el-cordero.github.io/blueterra/. Installation uses `remotes::install_github("el-cordero/blueterra@v0.2.0")`. The package requires R 4.1 or later and imports `cli`, `dplyr`, `rlang`, `stats`, `terra`, `tibble`, and `utils`; `exactextractr`, `sf`, `ggplot2`, and related documentation/testing packages are optional. The evaluated execution used R 4.5.3, `terra` 1.9.27, and macOS 26.2. This article demonstrates testing on that operating system only; it does not establish support on untested systems. Hardware requirements scale with raster size and file-backed temporary storage; the Apple M4 Max/128 GB benchmark computer is not a minimum requirement. The package license is MIT. The versioned source, documented BlueTopo acquisition materials, scripts, result tables, figures, session records, and checksums are supplied in Online Resource 2; a persistent DOI remains pending.

# Statements and Declarations

## Funding

Funding, resources, and technical assistance were provided by SeaMount Geospatial Labs.

## Competing interests

A competing-interests declaration has not been supplied by the author and remains unresolved.

## Author contributions

An author-contributions statement has not been supplied by the author and remains unresolved.

## Data and code availability

Bathymetric data used to generate the analyses and figures were obtained from NOAA BlueTopo, distributed by the NOAA National Centers for Environmental Information and Office of Coast Survey. The documented article input is tile `BH54S4ZB_20251117`; the processing manifest records source URLs, checksums, access date, CRS, tile-specific vertical metadata, and the author-created analysis windows. The `blueterra` source code, documentation, and reduced example data are available through the project repository and package website. The older bundled southwest Puerto Rico fixtures are not the source of the article’s real-data figures or results, and their separate provenance and reuse status remain unresolved.

# References

References are generated from the verified audit records in `article/references/references.csv`.

# Software Files

Online Resource 1 contains the reproducible BlueTopo workflow report. Online Resource 2 contains the source scripts, generated results, figures, tables, environment records, manifests, checksums, and documented article data subset.
