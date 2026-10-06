# Changelog

All notable changes to apa-layout are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

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

[0.1.1]: https://github.com/Data-Wise/apa-layout/releases/tag/v0.1.1
[0.1.0]: https://github.com/Data-Wise/apa-layout/releases/tag/v0.1.0
