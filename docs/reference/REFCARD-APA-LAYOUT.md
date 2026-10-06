# apa-layout Reference Card

> One-page reference for apa-layout 0.1.1 (apaquarto 7.0.0, Quarto >= 1.9)

## Install and Enable

| Task | Do this |
|---|---|
| Install | `quarto add Data-Wise/apa-layout` |
| Enable | top-level front matter: `filters: [Data-Wise/apa-layout]` |
| Hand-copied folder | `filters: [dtofighi/apa-layout]` |
| Remove a fix | delete its `.lua` and its line in `_extension.yml` |

## Filters

| Filter | Format | Fixes |
|---|---|---|
| `docx-tables.lua` | docx | data tables keep the ruled `Table` style |
| `docx-lists.lua` | docx | list items double-spaced, not `Compact` |
| `latex-header.lua` | pdf | `jou` figures float `[tbp]`; `\Needspace` before table titles |
| `jou-float-notes.lua` | pdf `jou` | figure note stays inside its float |
| `typst-math.lua` | typst | no `\big` gap, no `\!` collision |

## Checks (`tests/run.sh`)

| Check | Guards | Passes when |
|---|---|---|
| `docx_tables` | `docx-tables.lua` | every data table has the `Table` style |
| `docx_lists` | `docx-lists.lua` | no list item is `Compact` |
| `jou_notes` | `jou-float-notes.lua` | no note follows `\end{figure}` |
| `jou_floats` | `latex-header.lua` | preamble floats figures `[tbp]` |
| `needspace` | `latex-header.lua` | preamble adds `\Needspace` |
| `stranded_titles` | `latex-header.lua` | no table title alone at a page foot |
| `typst_math` | `typst-math.lua` | no raw TeX, `\big` boxes or kerns |
| `jou_overfull` | (sanity) | no overfull line wider than 1 pt |

## Upstream Issues

| Filter | Issue |
|---|---|
| `docx-tables.lua` | [#168](https://github.com/wjschne/apaquarto/issues/168) |
| `jou-float-notes.lua` | [#169](https://github.com/wjschne/apaquarto/issues/169) |
| `latex-header.lua` (`\Needspace`) | [#170](https://github.com/wjschne/apaquarto/issues/170) |

## Commands

```bash
tests/run.sh          # about 8 s
tests/prove-fail.sh   # about 1 min; each check must fail
mkdocs serve          # preview these docs
```

## Quick Examples

```bash
quarto render ms.qmd --to apaquarto-docx
quarto render ms.qmd --to apaquarto-pdf -M documentmode:jou
quarto render ms.qmd --to apaquarto-typst
```

## Troubleshooting

| Issue | Solution |
|---|---|
| Lands in `Data-Wise/` not `dtofighi/` | use `Data-Wise/apa-layout` |
| No fix applies | `filters:` must be top level, not under a format |
| `macro parameter character #` | write `#1`, not `##1`, in injected TeX |
| No overfull warnings in stdout | `lualatex -draftmode` on the kept `.tex` |
| docx looks wrong on macOS | open it in Word |

## See Also

- [Full guide](../guide/apa-layout.md)
- [Quick start](../QUICK-START.md)
