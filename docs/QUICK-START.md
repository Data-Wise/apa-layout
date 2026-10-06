# apa-layout

> **TL;DR:** Quarto filter add-on that fixes layout bugs in the apaquarto v7.0.0
> release (docx lists, `jou` PDF floats, Typst).

## 30-Second Setup

```bash
quarto add Data-Wise/apa-layout
```

Then add to the manuscript's front matter (top level, not under a format):

```yaml
filters:
  - Data-Wise/apa-layout
```

Contributing? Clone and run the checks:

```bash
git clone https://github.com/Data-Wise/apa-layout.git
cd apa-layout
tests/run.sh
```

## What This Does

- docx: list items are double-spaced.
- `jou` PDF: figures and tables float `[tbp]`, so tall tables leave no blank
  pockets in a column.
- Typst: `\bigl(` and `\!\left(` no longer leave gaps or collisions.

## Common Tasks

| I want to... | Run this |
|---|---|
| Check every fix | `tests/run.sh` |
| Prove each check can fail | `tests/prove-fail.sh` |
| Lint the docs | `markdownlint-cli2 "*.md" "docs/**/*.md"` |
| Preview the docs site | `mkdocs serve` |

## Where Things Are

| Location | Contents |
|---|---|
| `_extensions/dtofighi/apa-layout/` | the extension (three Lua filters) |
| `tests/` | fixture, `run.sh`, `prove-fail.sh`, vendored apaquarto |
| `CHANGELOG.md` | release notes |

## Current Status

```text
version: 0.2.0
status:  unreleased (latest release: v0.1.2)
```

## Need Help?

- **Filters and checks:** [README](../README.md)
- **Issues:** <https://github.com/Data-Wise/apa-layout/issues>
