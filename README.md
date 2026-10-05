# apa-layout

A Quarto filter extension with layout fixes for manuscripts built on
[apaquarto](https://github.com/wjschne/apaquarto) **7.0.0**. Each fix works
around an upstream behavior; drop the matching filter once apaquarto fixes it.

| Filter | Format | Fixes |
|---|---|---|
| `docx-tables.lua` (post-render) | docx | `docxlayout.lua` gives every table inside a figure/table float the undefined, borderless `FigureLayout` style, so data tables lose their APA rules. Tables without an image go back to the reference document's `Table` style. |
| `docx-lists.lua` | docx | Tight lists use Word's single-spaced `Compact` style; list items become double-spaced like the body. |
| `latex-header.lua` | pdf | (1) `jou`: `floatsintext` sets every figure `[H]`, which leaves blank pockets in two columns; figures float `[tbp]`. (2) All modes: an in-flow table caption can be stranded at a page foot (`\addcontentsline` after `\nopagebreak` leaves a break before the `longtable`); `\Needspace{14\baselineskip}` before a non-float title. |
| `jou-float-notes.lua` (post-render) | pdf, `jou` | A code-chunk figure's `apa-note` is written after `\end{figure}`; once `jou` figures float, the note is left behind. Moves `\end{figure}` after the note. |
| `typst-math.lua` | typst | texmath writes `\bigl(`… as a `#scale()` box that keeps its unscaled width (gap inside the delimiter) and `\!\left(` as a negative kern that makes `\Phi` collide with the parenthesis. Both are dropped; Typst sizes matched delimiters itself. |

Every filter checks the output format (and `documentmode` for `jou`) itself,
so one line enables all of them.

## Why an add-on, not a fork

Decided 2026-10-05. Every fix here works on top of stock apaquarto, none edits
its source, and upstream moves fast (5.0.18 to 7.0.0 in weeks, including a new
LaTeX engine), so a fork would mean merging every release by hand. As an
add-on, each filter is deleted when upstream fixes the bug it works around.
Revisit only if a fix needs apaquarto's internals changed (its LaTeX
template, title page, or docx reference document).

## Use

Install from GitHub (needs Quarto 1.9 or later):

```bash
quarto add Data-Wise/apa-layout
```

Quarto names the installed folder after the repo owner, so the extension lands
at `_extensions/Data-Wise/apa-layout`. Add a top-level key to the manuscript's
front matter (not under a format):

```yaml
filters:
  - Data-Wise/apa-layout
```

Offline, copy the folder instead. This keeps the `dtofighi/` namespace, so the
filter reference is `dtofighi/apa-layout`; the two names are interchangeable,
since a filter reference is only a folder path:

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
PDF in a temporary project with the apaquarto 7.0.0 vendored in
`tests/vendor/` and this repo's filters, then checks:

| Check | Filter | Holds when |
|---|---|---|
| `docx_tables` | `docx-tables.lua` | every data table carries the ruled `Table` style |
| `docx_lists` | `docx-lists.lua` | no list item uses the single-spaced `Compact` style |
| `jou_notes` | `jou-float-notes.lua` | no figure note follows `\end{figure}` in the `jou` tex |
| `jou_floats` | `latex-header.lua` | the `jou` preamble redefines figures to float `[tbp]` |
| `needspace` | `latex-header.lua` | the preamble puts `\Needspace` before in-flow table titles |
| `typst_math` | `typst-math.lua` | the Typst output has no unconverted TeX, `\big` scale boxes or negative kerns |
| `jou_overfull` | (sanity) | a fresh LuaLaTeX compile of the `jou` tex reports no overfull line |

`jou_floats` and `needspace` confirm that the preamble code is present, not
where LaTeX ends up placing a float or a page break. `jou_overfull` guards no
filter; `prove-fail.sh` shows it failing on a planted overlong line. Every
check fails closed when its input is missing. Requires Quarto >= 1.9 (which
bundles Typst), R with knitr, rmarkdown, ragg and svglite, and LuaLaTeX.

The checks are ported from `pmed`'s layout gate (`layout-checks.sh`), where the
fixes were first developed. A manuscript that adopts this extension can copy
that gate to check its own builds.

Not in this extension (manuscript-specific): math macros for docx/html/typst,
caption-to-note splits, and equation line breaks.
