# apa-layout

Quarto filter add-on: layout fixes for apaquarto 7.0.0 manuscripts. Not a fork
(see README, "Why an add-on, not a fork"). Each filter is deleted when upstream
fixes the bug it works around.

## Layout

| Path | Contents |
|---|---|
| `_extensions/dtofighi/apa-layout/` | the extension: `_extension.yml` + three Lua filters |
| `tests/run.sh` | renders `tests/fixture/fixture.qmd` (docx, Typst, jou PDF), runs 8 checks |
| `tests/pdf-gaps.py` | counts blank pockets in a two-column PDF (used by `jou_pockets`) |
| `tests/prove-fail.sh` | negative controls: each filter disabled, each check must fail |
| `tests/vendor/wjschne/` | apaquarto v7.0.0 release + apanote 6.0.0 (CC0), tests only |
| `docs/` | quick start, site source |

## Commands

```bash
# needs quarto >= 1.9, lualatex, pdftotext, python3,
# R + knitr, rmarkdown, ragg, svglite
tests/run.sh          # about 8 s
tests/prove-fail.sh   # about 1 min
markdownlint-cli2 "*.md" "docs/**/*.md"
```

## Rules

- Branches (craft style): `main` (PR only, release) <- `dev` (integration) <-
  `feature/*`. Feature PRs target `dev` and squash-merge; releases are a
  `dev -> main` PR with a merge commit. `dev` has a deletion-only ruleset
  (`protect-dev-from-deletion`) because auto-delete of merged branches would
  otherwise remove it after a release PR.
- Keep apaquarto out of any `_extensions/` folder in the tree: `quarto add`
  would install it too. Vendored copies live under `tests/vendor/`.
- Every filter guards on `FORMAT` (and `documentmode` for jou) so one
  `filters:` line serves all formats. Keep that.
- A new filter needs a check in `tests/run.sh` and a case in
  `tests/prove-fail.sh` that fails when the filter is disabled.
- CI (`.github/workflows/test.yml`) installs TinyTeX with quarto, which looks up
  the latest release through the GitHub API: keep `GITHUB_TOKEN` on that step
  or runs fail intermittently with 403.
- Bump `version` in `_extension.yml` and add a CHANGELOG entry per release.
- `latex-header.lua` rewrites only `[H]` and empty float placements to `[tbp]`.
  apaquarto sets the author note as a `\begin{figure}[b]` float; rewriting every
  placement floats it under the abstract (check `jou_note`).
- After a release, consumers re-copy from the tag (`git show
  vX.Y.Z:_extensions/dtofighi/apa-layout/<file>`), never edit their vendored
  folder, and run their own `render-both.sh` gate before the PR.
- TeX in `\AtBeginDocument` (latex-header.lua): write `#1`, not `##1`.
- Overfull boxes: quarto's stdout shows no LaTeX warnings; compile the kept
  `.tex` with `lualatex -draftmode` and read that log.
- Word is the only trustworthy docx viewer; macOS Quick Look ignores table
  styles and drops equations.

## Install path

`quarto add Data-Wise/apa-layout` lands at `_extensions/Data-Wise/apa-layout/`
(owner folder), so consumers write `filters: [Data-Wise/apa-layout]`. A
vendored copy under `_extensions/dtofighi/` uses `dtofighi/apa-layout`.
