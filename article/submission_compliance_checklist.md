# Earth Science Informatics software-article compliance checklist

Journal guidance was checked at https://link.springer.com/journal/12145/submission-guidelines on 2026-07-11. Classifications distinguish requirements stated by the journal, patterns observed in published software articles, and reproducibility practices adopted for this package. Statuses describe the present materials; they distinguish the public v0.2.0 GitHub release from a persistent archive DOI and from unresolved author-controlled declarations.

| Requirement or practice | Classification | Evidence / location | Status |
|---|---|---|---|
| Submitted as a Software article | Mandatory | Cover letter and manuscript title page identify the article type | Completed |
| Design and Implementation between Introduction and Results | Mandatory | Main manuscript sections 1–5 | Completed |
| Availability and Requirements after Conclusions, including URL, operating system, and hardware | Mandatory | Main manuscript, Availability and Requirements; GitHub v0.2.0 release | Completed; persistent DOI remains separately open |
| Software Files section | Mandatory | Main manuscript, Software Files; Online Resources 1–2 | Completed |
| Editable Word manuscript | Mandatory | `blueterra_ESI_manuscript.docx`; final 14-page rendered PDF and page images | Completed and visually inspected on 2026-07-11 |
| Plain 10-point Times Roman text | Mandatory | DOCX normal style; tables and references use readable compact formatting | Completed and visually inspected on 2026-07-11 |
| Automatic page numbers | Mandatory | DOCX footer | Completed and visually inspected on 2026-07-11 |
| Abstract of 150–250 words | Mandatory | Main manuscript Abstract (192 words) | Completed |
| Four to six keywords | Mandatory | Main manuscript Keywords | Completed |
| Title, author, affiliations, corresponding email, and ORCID if available | Mandatory | Separate title page; ORCID omitted because none is available | Completed |
| Acknowledgments on title page | Mandatory | Separate title page | Completed |
| Funding statement | Mandatory when applicable | Main manuscript Statements and Declarations | Completed |
| Competing-interests disclosure in the submission interface | Mandatory | Author confirmation was not supplied | Open — do not assert a competing-interests statement |
| Author-contribution information in the submission interface | Mandatory | Author contribution statement was not supplied | Open — do not assert an author-contribution statement |
| Generative-LLM use documented in Methods when its use exceeds copy editing | Mandatory when applicable | Author instructed that no AI statement be included; no factual author-approved disclosure was supplied | Open — no AI-use statement is asserted in the manuscript |
| References alphabetized, cited in text, and DOI links included where available | Mandatory | Main manuscript References; `reference_audit.csv`; revised BlueTopo source record | Completed and cross-checked in the final DOCX |
| Tables cited and numbered consecutively, created as Word tables | Mandatory | Three main-manuscript Word table objects | Completed and visually inspected in the final DOCX |
| Figures cited and numbered consecutively, captions supplied in manuscript | Mandatory | Regenerated Figs. 1–7 embedded in manuscript and supplied separately | Completed and visually inspected in the final DOCX |
| RGB color; 600 dpi TIFF for combination artwork; vector PDFs for line/diagram artwork | Mandatory / technical artwork guidance | `figures/` contains RGB TIFF, PDF, and PNG for Figs. 1–7 | Completed and visually inspected in the final DOCX |
| Accessible, descriptive captions; lowercase panel letters | Mandatory artwork guidance | Main manuscript captions and regenerated figure outputs | Completed and visually inspected in the final DOCX |
| Supplementary text supplied as PDF, each resource named and captioned | Mandatory when supplementary material is supplied | Online Resources 1–2 and captions file | Completed; three-page PDF inspected and 72-entry archive integrity-tested on 2026-07-11 |
| Software available for researchers' personal non-commercial use | Mandatory software-article condition | MIT license; public [GitHub release v0.2.0](https://github.com/el-cordero/blueterra/releases/tag/v0.2.0) | Completed |
| Corrected package changes documented, tested, and recorded in NEWS | Recommended reproducibility practice | `DESCRIPTION`, `NEWS.md`, source/Rd files, `data/metric_catalog.rda`, `tests/testthat/test-functional-verification.R`, and `article/validation/results/functional_verification.csv` | Completed in public v0.2.0 |
| Post-correction functional verification | Recommended reproducibility practice | `article/validation/run_functional_verification.R`; 21/21 rows passed in `article/validation/results/functional_verification.csv` using blueterra 0.2.0 and terra 1.9.27; clean tagged Route-B audit passed | Completed |
| Current package version and immutable source identifier fixed in manuscript and archive | Customary reproducibility practice | Public [GitHub release v0.2.0](https://github.com/el-cordero/blueterra/releases/tag/v0.2.0), annotated tag, and supplementary source-identifier manifest | Completed; complete SHA is confined to supplementary manifests |
| Persistent public archive/release DOI | Recommended reproducibility practice, not stated as a journal requirement | GitHub release v0.2.0 exists; no persistent archive DOI has been assigned or identified | Open — not required by the journal guidance |
| Route-B real-data provenance for article figures and results | Recommended data-provenance practice; needed for a source-specific data statement | `article/data_provenance/acquire_bluetopo_example.R`; raw tile/RAT/tile-scheme artifacts; `bluetopo_example_manifest.csv` and `.json` | Completed for the documented article input: BlueTopo `BH54S4ZB_20251117`, access date, checksums, CRS, tile-specific vertical metadata, preprocessing, and deterministic analysis windows are retained |
| Legacy bundled fixture provenance and reuse status | Recommended legal and data-provenance practice | `article/provenance_release_investigation.md`; `article/provenance_release_source_audit.csv` | Open — legacy southwest Puerto Rico package fixtures are excluded from the article real-data figures and results, but their original tile/vector provenance and redistribution status remain unresolved |
| Confirmed ownership or reuse rights for every bundled reduced raster/vector | Recommended legal and data-provenance practice | Route-B article source is documented as NOAA BlueTopo with product-level public-domain/CC0 evidence; legacy `inst/extdata` fixtures remain separate | Open — do not claim that Route-B documentation resolves ownership or redistribution status for the legacy bundled fixtures |
| Executed controlled validation, upstream-wrapper checks, clean-environment regeneration, sensitivity analysis, and benchmarking | Recommended reproducibility practice | `article/validation`, `article/reproducibility`, `article/sensitivity`, and `article/benchmark`; 15/15 paired clean-environment Route-B records matched for v0.2.0 | Completed |
| Scripts, result tables, figures, environments, manifests, and checksums retained | Recommended reproducibility practice | Public tag/release plus article directories including `data_provenance`, `environment`, `validation`, `reproducibility`, `sensitivity`, `benchmark`, `tables`, and `figures` | Completed in the 72-entry integrity-tested Online Resource 2 archive; DOI remains open |
| Structural/rhetorical models inspected | Customary journal-fit practice | X-Min Learn (2026, doi:10.1007/s12145-026-02149-z); OpenEOcubes (2024, doi:10.1007/s12145-024-01249-y, R-based); OpenBioMaps (2022, doi:10.1007/s12145-022-00818-3); EZ-InSAR (2023, doi:10.1007/s12145-023-00973-1); PYTAF (2022, doi:10.1007/s12145-020-00461-w) | Completed |

## Completion boundary

The public v0.2.0 release contains documented package corrections, a NEWS entry,
updated documentation and metric metadata, and executed functional verification.
The article’s real-data analyses use the documented Route-B BlueTopo input rather
than the legacy bundled southwest Puerto Rico fixtures. The final manuscript,
title page, and cover letter were rendered and visually inspected on 2026-07-11.
The final Online Resource PDF and archive were rebuilt and verified on
2026-07-11. The package and article are not described as submission-ready until
the open author-controlled declarations, AI-use disclosure decision,
persistent-DOI decision, and legacy-data reuse/provenance boundaries are
resolved.
