# apa-layout Reference Card

> One-page reference for apa-layout 0.2.0 (apaquarto v7.0.0 release, Quarto >= 1.9)

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
| `docx-lists.lua` | docx | list items double-spaced, not `Compact` |
| `latex-header.lua` | pdf `jou` | figures and tables float `[tbp]` |
| `typst-math.lua` | typst | no `\big` gap, no `\!` collision |

## Checks (`tests/run.sh`)

| Check | Guards | Passes when |
|---|---|---|
| `docx_lists` | `docx-lists.lua` | no list item is `Compact` |
| `jou_floats` | `latex-header.lua` | preamble floats figures `[tbp]` |
| `jou_table_floats` | `latex-header.lua` | preamble floats tables `[tbp]` |
| `jou_pockets` | `latex-header.lua` | no blank gap over 25% in a jou column |
| `jou_note` | `latex-header.lua` | correspondence note at the foot of page 1 |
| `typst_math` | `typst-math.lua` | no raw TeX, `\big` boxes or kerns |
| `man_floats` | (apaquarto#171) | no figure title or note clipped at a man page foot |
| `jou_overfull` | (sanity) | no overfull line wider than 1 pt |

## Retired in 0.2.0 (fixed in apaquarto v7.0.0)

| Removed | Issue |
|---|---|
| `docx-tables.lua` | [#168](https://github.com/wjschne/apaquarto/issues/168) |
| `jou-float-notes.lua` | [#169](https://github.com/wjschne/apaquarto/issues/169) |
| `\Needspace` fix in `latex-header.lua` | [#170](https://github.com/wjschne/apaquarto/issues/170) |

Open upstream: [#171](https://github.com/wjschne/apaquarto/issues/171), a long
code-chunk figure note clipped at a `man` page foot.

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
| jou table overprints the next column | add `apa-twocolumn="true"` to its caption attributes |
| No fix applies | `filters:` must be top level, not under a format |
| `macro parameter character #` | write `#1`, not `##1`, in injected TeX |
| No overfull warnings in stdout | `lualatex -draftmode` on the kept `.tex` |
| docx looks wrong on macOS | open it in Word |

## See Also

- [Full guide](../guide/apa-layout.md)
- [Quick start](../QUICK-START.md)
