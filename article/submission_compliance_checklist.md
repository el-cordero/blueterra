# Earth Science Informatics software-article compliance checklist

Journal guidance was checked at https://link.springer.com/journal/12145/submission-guidelines on 2026-07-11. Classifications distinguish requirements stated by the journal, patterns observed in published software articles, and reproducibility practices adopted for this package. Statuses describe the present working tree and assembled materials; they do not claim a public release, DOI, or final author-controlled declaration.

| Requirement or practice | Classification | Evidence / location | Status |
|---|---|---|---|
| Submitted as a Software article | Mandatory | Cover letter and manuscript title page identify the article type | Completed |
| Design and Implementation between Introduction and Results | Mandatory | Main manuscript sections 1–5 | Completed |
| Availability and Requirements after Conclusions, including URL, operating system, and hardware | Mandatory | Main manuscript, Availability and Requirements | Completed in the manuscript; public corrected-release details remain open |
| Software Files section | Mandatory | Main manuscript, Software Files; Online Resources 1–2 | Completed |
| Editable Word manuscript | Mandatory | `blueterra_ESI_manuscript.docx`; rendered PDF and page images | Completed for the current assembled document; final post-revision render review remains required |
| Plain 10-point Times Roman text | Mandatory | DOCX normal style | Completed for the prior rendered document; final post-revision render review remains required |
| Automatic page numbers | Mandatory | DOCX footer | Completed for the prior rendered document; final post-revision render review remains required |
| Abstract of 150–250 words | Mandatory | Main manuscript Abstract | Completed for the current manuscript source; confirm after final document build |
| Four to six keywords | Mandatory | Main manuscript Keywords | Completed |
| Title, author, affiliations, corresponding email, and ORCID if available | Mandatory | Separate title page; ORCID omitted because none is available | Completed |
| Acknowledgments on title page | Mandatory | Separate title page | Completed |
| Funding statement | Mandatory when applicable | Main manuscript Statements and Declarations | Completed |
| Competing-interests disclosure in the submission interface | Mandatory | Author confirmation was not supplied | Open — do not assert a competing-interests statement |
| Author-contribution information in the submission interface | Mandatory | Author contribution statement was not supplied | Open — do not assert an author-contribution statement |
| Generative-LLM use documented in Methods when its use exceeds copy editing | Mandatory when applicable | Author instructed that no AI statement be included; no factual author-approved disclosure was supplied | Open — no AI-use statement is asserted in the manuscript |
| References alphabetized, cited in text, and DOI links included where available | Mandatory | Main manuscript References; `reference_audit.csv`; revised BlueTopo source record | Completed for manuscript source; final citation/reference cross-check remains required after final build |
| Tables cited and numbered consecutively, created as Word tables | Mandatory | Main-manuscript table objects | Completed for manuscript source; final post-revision visual review remains required |
| Figures cited and numbered consecutively, captions supplied in manuscript | Mandatory | Regenerated Figs. 1–7 embedded in manuscript and supplied separately | Completed for manuscript source; final post-revision visual review remains required |
| RGB color; 600 dpi TIFF for combination artwork; vector PDFs for line/diagram artwork | Mandatory / technical artwork guidance | `figures/` contains RGB TIFF, PDF, and PNG for Figs. 1–7 | Completed for regenerated artwork; final embedded-artwork review remains required |
| Accessible, descriptive captions; lowercase panel letters | Mandatory artwork guidance | Main manuscript captions and regenerated figure outputs | Completed for manuscript source; final embedded-artwork review remains required |
| Supplementary text supplied as PDF, each resource named and captioned | Mandatory when supplementary material is supplied | Online Resources 1–2 and captions file | Completed for current supplementary files; final archive rebuild remains required |
| Software available for researchers' personal non-commercial use | Mandatory software-article condition | MIT license; public repository currently identifies version 0.1.0 baseline | Open — corrected 0.2.0 working tree has not yet been published as an immutable release |
| Corrected package changes documented, tested, and recorded in NEWS | Recommended reproducibility practice | `DESCRIPTION`, `NEWS.md`, source/Rd files, `data/metric_catalog.rda`, `tests/testthat/test-functional-verification.R`, and `article/validation/results/functional_verification.csv` | Completed in the 0.2.0 working tree; release validation remains open |
| Post-correction functional verification | Recommended reproducibility practice | `article/validation/run_functional_verification.R`; 21/21 rows passed in `article/validation/results/functional_verification.csv` using blueterra 0.2.0 and terra 1.9.27 | Completed for the documented working tree; rerun against the final tagged release |
| Current package version and immutable source identifier fixed in manuscript and archive | Customary reproducibility practice | Current working tree is version 0.2.0 atop committed baseline `4afb4b58a95a657a7bebd996d159691ec0cc69fc`; `article/package_modifications.csv` records the boundary | Open — no release tag or immutable public 0.2.0 source archive exists |
| Persistent public archive/release DOI | Recommended reproducibility practice, not stated as a journal requirement | No tag, public release, Zenodo record, or DOI is recorded for the corrected source | Open |
| Route-B real-data provenance for article figures and results | Recommended data-provenance practice; needed for a source-specific data statement | `article/data_provenance/acquire_bluetopo_example.R`; raw tile/RAT/tile-scheme artifacts; `bluetopo_example_manifest.csv` and `.json` | Completed for the documented article input: BlueTopo `BH54S4ZB_20251117`, access date, checksums, CRS, tile-specific vertical metadata, preprocessing, and deterministic analysis windows are retained |
| Legacy bundled fixture provenance and reuse status | Recommended legal and data-provenance practice | `article/provenance_release_investigation.md`; `article/provenance_release_source_audit.csv` | Open — legacy southwest Puerto Rico package fixtures are excluded from the article real-data figures and results, but their original tile/vector provenance and redistribution status remain unresolved |
| Confirmed ownership or reuse rights for every bundled reduced raster/vector | Recommended legal and data-provenance practice | Route-B article source is documented as NOAA BlueTopo with product-level public-domain/CC0 evidence; legacy `inst/extdata` fixtures remain separate | Open — do not claim that Route-B documentation resolves ownership or redistribution status for the legacy bundled fixtures |
| Executed controlled validation, upstream-wrapper checks, clean-environment regeneration, sensitivity analysis, and benchmarking | Recommended reproducibility practice | `article/validation`, `article/reproducibility`, `article/sensitivity`, and `article/benchmark`; post-correction functional verification is separately recorded | Completed for the assembled working-tree evidence; final-release reruns remain open |
| Scripts, result tables, figures, environments, manifests, and checksums retained | Recommended reproducibility practice | Article directories including `data_provenance`, `environment`, `validation`, `sensitivity`, `benchmark`, `tables`, and `figures` | Partial — materials are present in the working tree, but the corrected source and accompanying archive have not yet been immutably released |
| Structural/rhetorical models inspected | Customary journal-fit practice | X-Min Learn (2026, doi:10.1007/s12145-026-02149-z); OpenEOcubes (2024, doi:10.1007/s12145-024-01249-y, R-based); OpenBioMaps (2022, doi:10.1007/s12145-022-00818-3); EZ-InSAR (2023, doi:10.1007/s12145-023-00973-1); PYTAF (2022, doi:10.1007/s12145-020-00461-w) | Completed |

## Completion boundary

The 0.2.0 working tree contains documented package corrections, a NEWS entry,
updated documentation and metric metadata, and executed functional verification.
The article’s real-data analyses use the newly documented Route-B BlueTopo
input rather than the legacy bundled southwest Puerto Rico fixtures. The
package and article are not described as submission-ready until the corrected
source is committed and released, final source/archive identifiers are added,
all final document pages are rendered and inspected, and the open
author-controlled declarations, AI-use disclosure decision, and legacy-data
reuse/provenance boundaries are resolved.
