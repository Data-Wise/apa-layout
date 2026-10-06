# Changelog

All notable changes to apa-layout are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [0.1.2] - 2026-10-05

### Changed

- `latex-header.lua`: in `jou`, in-flow tables float `[tbp]` as figures already
  did. `floatsintext` sets them `[H]`, and a tall `[H]` table that misses the
  rest of a column jumps to the next one, leaving a blank pocket (jou columns are
  flush-bottom, so the space is spread inside the column). Found on a real
  manuscript: 187 pt blank on one page, 63% of a column on another. A table that
  spans both columns (`apa-twocolumn`) is untouched, and so is `man`.

### Added

- `jou_table_floats` check (the preamble floats tables `[tbp]`) and `jou_pockets`
  check: `tests/fixture/pockets.qmd` is a two-column `jou` probe with 16 tall
  tables after text of varying length, and `tests/pdf-gaps.py` counts column
  gaps over 25% of the text height. With the filter disabled the probe has 11
  pockets (worst 44%), with it none. Needs `python3`.
- Guide and refcard: how to make a wide `jou` table span both columns
  (`apa-twocolumn="true"`).
- `stranded_titles` check: `tests/fixture/stranded.qmd` puts a table after
  every offset from 0 to 29 filler lines in a `man` PDF; the check fails if a
  table title is left alone at a page foot. It fails when `latex-header.lua`
  is disabled (2 of 30 titles stranded locally) and passes with it, so it
  tests the `\Needspace` fix itself, not just its injection. Needs
  `pdftotext` (poppler).
- Upstream issues filed for three of the fixes
  ([#168](https://github.com/wjschne/apaquarto/issues/168),
  [#169](https://github.com/wjschne/apaquarto/issues/169),
  [#170](https://github.com/wjschne/apaquarto/issues/170)), linked from the
  README, guide and reference card.

## [0.1.1] - 2026-10-05

No change to the filters; installing 0.1.1 gives the same behavior as 0.1.0.
Documentation, CI and repo housekeeping.

### Added

- Guide (`docs/guide/apa-layout.md`) and one-page reference card
  (`docs/reference/REFCARD-APA-LAYOUT.md`), with a minimal mkdocs site
  (built locally, not deployed).
- Quick start, `CLAUDE.md`, `.STATUS`, and a PR template.
- GitHub Actions workflow running `tests/run.sh` and `tests/prove-fail.sh` on
  pull requests and on pushes to `main` and `dev`.

### Changed

- README "Use" leads with `quarto add Data-Wise/apa-layout`; the filter
  reference is `Data-Wise/apa-layout` (Quarto names the installed folder after
  the repo owner). The offline copy recipe keeps the `dtofighi/` namespace.
- README and the docs index open with an Install section
  (`quarto add Data-Wise/apa-layout`); the offline copy recipe moved to
  "Offline install".
- Branching is craft style: `main` <- `dev` <- `feature/*`.

## [0.1.0] - 2026-10-05

First release. Layout fixes for manuscripts built on apaquarto 7.0.0; requires
Quarto >= 1.9.0.

### Added

- `docx-tables.lua` (post-render, docx): data tables inside a figure/table
  float go back from apaquarto's borderless `FigureLayout` style to the ruled
  `Table` style.
- `docx-lists.lua` (docx): tight lists are loosened so list items are
  double-spaced like the body, not in Word's single-spaced `Compact` style.
- `latex-header.lua` (pdf): `jou` figures float `[tbp]` instead of `[H]`;
  `\Needspace` before an in-flow table title so its caption is not stranded at
  a page foot.
- `jou-float-notes.lua` (post-render, pdf `jou`): a code-chunk figure's
  `apa-note` stays inside its float.
- `typst-math.lua` (typst): `\bigl(`… and `\!\left(` no longer leave a gap or
  a collision in the Typst output.
- `tests/run.sh`: renders a fixture manuscript with a vendored apaquarto 7.0.0
  and checks every fix; `tests/prove-fail.sh` shows each check failing when
  its filter is disabled.
- MIT license.

[0.1.2]: https://github.com/Data-Wise/apa-layout/releases/tag/v0.1.2
[0.1.1]: https://github.com/Data-Wise/apa-layout/releases/tag/v0.1.1
[0.1.0]: https://github.com/Data-Wise/apa-layout/releases/tag/v0.1.0
