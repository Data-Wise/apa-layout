# apa-layout

A Quarto filter extension with layout fixes for manuscripts built on
[apaquarto](https://github.com/wjschne/apaquarto) **7.0.0** (the release of
2026-10-06 or later). Each fix works around an upstream behavior; drop the
matching filter once apaquarto fixes it.

## Install

```bash
quarto add Data-Wise/apa-layout
```

Needs Quarto 1.9 or later and the apaquarto **v7.0.0 release**: an install from
upstream's default branch before 2026-10-06 11:21 UTC also reports `7.0.0` but
lacks fixes this version no longer works around, so reinstall it
(`quarto update extension wjschne/apaquarto`). Then enable it with a
top-level key in the manuscript's front matter (not under a format):

```yaml
filters:
  - Data-Wise/apa-layout
```

Quarto names the installed folder after the repo owner, so the extension lands
at `_extensions/Data-Wise/apa-layout`. To pin a release, use
`quarto add Data-Wise/apa-layout@v0.2.1`.

## Filters

| Filter | Format | Fixes |
|---|---|---|
| `docx-lists.lua` | docx | Tight lists use Word's single-spaced `Compact` style; list items become double-spaced like the body. |
| `latex-header.lua` | pdf, `jou`; `man` on request | `floatsintext` sets every figure and in-flow table `[H]`, which leaves blank pockets in two columns; figures and tables float `[tbp]`. In `man`, figures float `[!htbp]` only under `man-floats` (below). |
| `man-floats.lua` | pdf, `man` on request | Under `man-floats`, a `man` table set as one box (it cannot break over pages) floats `[!htbp]`. Longtables stay in the text flow. |
| `typst-math.lua` | typst | texmath writes `\bigl(`… as a `#scale()` box that keeps its unscaled width (gap inside the delimiter) and `\!\left(` as a negative kern that makes `\Phi` collide with the parenthesis. Both are dropped; Typst sizes matched delimiters itself. |

Every filter checks the output format (and `documentmode` for `jou`) itself,
so one line enables all of them.

### `man-floats` (opt-in)

In `man`, apaquarto sets figures `[H]`: a figure taller than the rest of the
page moves to the next page and leaves the rest of this one blank. A table that
is set as one box does the same. To let such figures and tables float, so text
fills the page, add a top-level key beside `filters:`:

```yaml
apa-layout:
  man-floats: true
```

Figures float `[!htbp]` (here if it fits, otherwise the top of a later page),
so most stay near their first mention. Only a table that is already one box is
floated: a longtable inside a float is set as one box too, and LaTeX drops
whatever does not fit the page without a warning. apaquarto upstream sets no
`man` table as one box, so `man-floats.lua` acts only on a manuscript that
patches its tables that way (for example, to keep a short table off a page
break); with stock apaquarto only the figure half applies. The option is off by
default, and it has no effect in `jou`, which always floats.

Check the result in the PDF: a figure can land on the page after its first
mention, which APA allows, but a journal's production staff may still ask for
`[H]` placement.

## Retired filters

Three filters worked around bugs that apaquarto fixed in the v7.0.0 release
(2026-10-06). apa-layout 0.2.0 removed them; stay on 0.1.2 if you must use an
apaquarto from before that release.

| Removed filter | Upstream issue (fixed in v7.0.0) |
|---|---|
| `docx-tables.lua` | [wjschne/apaquarto#168](https://github.com/wjschne/apaquarto/issues/168) |
| `jou-float-notes.lua` | [wjschne/apaquarto#169](https://github.com/wjschne/apaquarto/issues/169) |
| `latex-header.lua` (`\Needspace` half) | [wjschne/apaquarto#170](https://github.com/wjschne/apaquarto/issues/170) |

The `\Needspace` fix gave the wrong cause: the stranded title came from
longtable's `\LT@start` fit test, not from `\addcontentsline`.

Open upstream: [wjschne/apaquarto#171](https://github.com/wjschne/apaquarto/issues/171).
With the #169 fix, a code-chunk figure's note sits inside `man`'s `[H]` float
and cannot break across pages, so a long note can run off the page foot and be
clipped, with exit 0. apa-layout does not work around it; shorten the figure
or the note. The `man_floats` check in `tests/run.sh` detects it (a planted
long note makes it fail); copy it to a manuscript's own gate.

No issue is filed for `docx-lists.lua`, the `[tbp]` filter, or
`typst-math.lua`; those are upstream behaviors or texmath output, not bugs
I could reproduce as such.

## Why an add-on, not a fork

Decided 2026-10-05. Every fix here works on top of stock apaquarto, none edits
its source, and upstream moves fast (5.0.18 to 7.0.0 in weeks, including a new
LaTeX engine), so a fork would mean merging every release by hand. As an
add-on, each filter is deleted when upstream fixes the bug it works around.
Revisit only if a fix needs apaquarto's internals changed (its LaTeX
template, title page, or docx reference document).

## Offline install

If `quarto add` is not an option, copy the folder instead. This keeps the
`dtofighi/` namespace, so the filter reference is `dtofighi/apa-layout`; the two
names are interchangeable, since a filter reference is only a folder path:

```bash
mkdir -p _extensions/dtofighi
cp -R path/to/apa-layout/_extensions/dtofighi/apa-layout _extensions/dtofighi/
```

## Verification

```bash
tests/run.sh          # render the fixture, check every fix (exit 1 on failure)
tests/prove-fail.sh   # disable each filter in turn; each check must fail
```

`tests/run.sh` renders `tests/fixture/fixture.qmd` to docx, Typst and `jou`
PDF, two probes (`tests/fixture/pockets.qmd`, `tests/fixture/man-pockets.qmd`)
to `jou` and `man` PDF, in a temporary
project with the apaquarto v7.0.0 release vendored in `tests/vendor/` and this repo's
filters, then checks:

| Check | Filter | Holds when |
|---|---|---|
| `docx_lists` | `docx-lists.lua` | no list item uses the single-spaced `Compact` style |
| `jou_floats` | `latex-header.lua` | the `jou` preamble redefines figures to float `[tbp]` |
| `jou_table_floats` | `latex-header.lua` | the `jou` preamble redefines tables to float `[tbp]` |
| `jou_pockets` | `latex-header.lua` | no column of the two-column `jou` probe has a blank gap over 25% (16 tall tables after text of varying length) |
| `jou_note` | `latex-header.lua` | the correspondence note starts in the bottom quarter of page 1 of the `jou` PDF (a `[b]` float must keep its placement) |
| `typst_math` | `typst-math.lua` | the Typst output has no unconverted TeX, `\big` scale boxes or negative kerns |
| `man_floats` | (apaquarto#171) | the end of every chunk `fig-cap` and `apa-note` in the fixture reaches the `man` PDF (not clipped at a page foot) |
| `man_pockets` | `latex-header.lua` | under `man-floats`, no page of the `man` probe has a blank run over 25% of the text block (six tall figures after text of varying length; measured from pixels by `tests/man-gaps.py`, so figures count as content) |
| `man_table_floats` | `man-floats.lua` | on a synthetic body (`tests/fixture/man-tables.md`), plain pandoc running the filter floats the one-box table, with `\begin{table}` and `\end{table}` on lines of their own, and leaves the longtable in the flow; with the option off nothing changes |
| `jou_overfull` | (sanity) | a fresh LuaLaTeX compile of the `jou` tex reports no overfull line |

`jou_floats` and `jou_table_floats` confirm that the preamble code is present;
`jou_pockets`, `jou_note` and `man_pockets` are the behavior checks for where a
float lands.
`man_floats` guards upstream rather than a filter, and `jou_overfull` guards no
filter;
`prove-fail.sh` shows it failing on a planted overlong line. Every
check fails closed when its input is missing. Requires Quarto >= 1.9 (which
bundles Typst), R with knitr, rmarkdown, ragg and svglite, LuaLaTeX, and
`pdftotext` (poppler) and `python3`. The three retired fixes
have no check here; the vendored v7.0.0 release is what shows they are not needed.

The checks are ported from `pmed`'s layout gate (`layout-checks.sh`), where the
fixes were first developed. A manuscript that adopts this extension can copy
that gate to check its own builds.

Not in this extension (manuscript-specific): math macros for docx/html/typst,
caption-to-note splits, and equation line breaks.
