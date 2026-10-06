# apa-layout

Layout fixes for apaquarto 7.0.0 manuscripts, as a Quarto filter add-on.

## Install

```bash
quarto add Data-Wise/apa-layout
```

Needs Quarto 1.9 or later. Then enable it with a top-level key in the
manuscript's front matter (not under a format):

```yaml
filters:
  - Data-Wise/apa-layout
```

Quarto names the installed folder after the repo owner, so the extension lands
at `_extensions/Data-Wise/apa-layout`. To pin a release, use
`quarto add Data-Wise/apa-layout@v0.1.1`.

## Next

- [Quick start](QUICK-START.md)
- [Guide](guide/apa-layout.md): what each filter fixes and why
- [Reference card](reference/REFCARD-APA-LAYOUT.md): one-page tables
- [README](https://github.com/Data-Wise/apa-layout#readme): why an add-on,
  not a fork
