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

Copy the extension into the manuscript (or `quarto add` once this repo is on
GitHub — from a local path, `quarto add` drops the `dtofighi/` folder):

```bash
mkdir -p _extensions/dtofighi
cp -R ~/projects/dev-tools/apa-layout/_extensions/dtofighi/apa-layout _extensions/dtofighi/
```

Then add a top-level key to the manuscript's front matter (not under a
format):

```yaml
filters:
  - dtofighi/apa-layout
```

## Verification

Developed and verified on `pmed` (`~/projects/research/pmed`), whose
`render-both.sh` ends in a layout gate (`layout-checks.sh`) that fails if any
of these fixes stops holding: docx tables carry the `Table` style, no `jou`
figure note sits outside its float, a fresh LuaLaTeX compile of the `jou` build
reports no overfull line, and the Typst output has no unconverted TeX, `\big`
scale boxes or negative kerns. Each check was shown to fail on a known-bad
build. Copy that gate into any manuscript that adopts this extension.

Not in this extension (manuscript-specific): math macros for docx/html/typst,
caption-to-note splits, and equation line breaks.
