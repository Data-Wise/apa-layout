#!/bin/sh
# Render tests/fixture/fixture.qmd with the vendored apaquarto 7.0.0 (the
# release of 2026-10-06 or later; see tests/vendor/README.md) and this
# repo's apa-layout, then check that every fix holds. Exits 1 on any failure.
#
#   tests/run.sh
#
# Environment (used by tests/prove-fail.sh):
#   APA_LAYOUT_DISABLE  space-separated filter files to replace with a no-op
#                       in the temporary copy (the repo is never touched)
#   APA_LAYOUT_FIXTURE  a .qmd to render instead of tests/fixture/fixture.qmd
#   KEEP=1              keep the temporary project and print its path
#
# Check            Guards
#   docx_lists     docx-lists.lua       no list item in Word's Compact style
#   jou_floats     latex-header.lua     jou figures float [tbp], not [H]
#   jou_table_floats latex-header.lua   jou tables float [tbp], not [H]
#   jou_pockets    latex-header.lua     no blank pocket in a jou column (jou probe PDF)
#   typst_math     typst-math.lua       no \big scale boxes or \! negative kerns
#   jou_overfull   (sanity)             the jou build compiles, no overfull line
#
# Ported from pmed's layout-checks.sh. Each check fails closed when its input
# is missing or would make it vacuous, and tests/prove-fail.sh shows each one
# failing when the filter it guards is disabled.

set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE")
FIXTURE=${APA_LAYOUT_FIXTURE:-$HERE/fixture/fixture.qmd}
EXT=_extensions/dtofighi/apa-layout

WORK=$(mktemp -d)
cleanup() { if [ "${KEEP:-0}" = 1 ]; then echo "kept: $WORK"; else rm -rf "$WORK"; fi; }
trap cleanup EXIT

mkdir -p "$WORK/_extensions/dtofighi"
cp "$FIXTURE" "$WORK/fixture.qmd"
cp "$HERE/fixture/pockets.qmd" "$WORK/pockets.qmd"
cp -R "$HERE/vendor/wjschne" "$WORK/_extensions/"
cp -R "$ROOT/$EXT" "$WORK/$EXT"
for _f in ${APA_LAYOUT_DISABLE:-}; do
  [ -f "$WORK/$EXT/$_f" ] || { echo "no such filter: $_f" >&2; exit 2; }
  printf 'return {}\n' >"$WORK/$EXT/$_f"
  echo "disabled: $_f"
done

QMD="$WORK/fixture.qmd"
DOCX="$WORK/out/fixture.docx"
TYP="$WORK/out/fixture.typ"
TYPLOG="$WORK/out/typst.log"
TEXDIR="$WORK/out/jou"
POCKETS="$WORK/out/pockets.pdf"
POCKETS_TEX="$WORK/out/pockets.tex"
mkdir -p "$WORK/out" "$TEXDIR"

render() {
  _log="$WORK/out/render-$1.log"; shift
  if ! (cd "$WORK" && quarto render fixture.qmd "$@") >"$_log" 2>&1; then
    cat "$_log"
    echo "FAIL render: quarto render $*" >&2
    exit 1
  fi
}

echo "==> Rendering docx, typst, pdf (jou), pdf (jou, pocket probe)…"
render docx --to apaquarto-docx
mv "$WORK/fixture.docx" "$DOCX"
render typst --to apaquarto-typst -M keep-typ:true
cp "$WORK/out/render-typst.log" "$TYPLOG"
mv "$WORK/fixture.typ" "$TYP"
render jou --to apaquarto-pdf -M documentmode:jou -M keep-tex:true
cp "$WORK/fixture.tex" "$TEXDIR/"
cp -R "$WORK/fixture_files" "$TEXDIR/"
( cd "$WORK" && quarto render pockets.qmd --to apaquarto-pdf -M keep-tex:true ) \
  >"$WORK/out/render-pockets.log" 2>&1 \
  || { cat "$WORK/out/render-pockets.log"; echo "FAIL render: pockets.qmd" >&2; exit 1; }
mv "$WORK/pockets.pdf" "$POCKETS"
mv "$WORK/pockets.tex" "$POCKETS_TEX"

# --- docx --------------------------------------------------------------------

# No list paragraph (one with <w:numPr>) may use the single-spaced Compact
# style. Table cells are Compact by design, so only list items are counted.
check_docx_lists() {
  _paras=$(unzip -p "$DOCX" word/document.xml 2>/dev/null \
    | awk '{ gsub(/<\/w:p>/, "&\n"); print }' | grep '<w:numPr>' || true)
  _items=$(printf '%s' "$_paras" | grep -c '<w:numPr>' || true)
  if [ "${_items:-0}" -eq 0 ]; then
    echo "  FAIL docx_lists: no list items in the docx"
    return 1
  fi
  _compact=$(printf '%s' "$_paras" | grep -c 'w:val="Compact"' || true)
  if [ "$_compact" -gt 0 ]; then
    echo "  FAIL docx_lists: $_compact of $_items list items use the single-spaced Compact style"
    echo "       (docx-lists.lua no longer loosens tight lists?)"
    return 1
  fi
  echo "  OK: docx list items double-spaced ($_items items, none Compact)"
}

# --- pdf (jou) ---------------------------------------------------------------

# The jou preamble must redefine figure to float [tbp]. This checks that
# latex-header.lua injected the redefinition, not where LaTeX placed a float.
check_jou_floats() {
  if ! grep -qF '\apalayout@figure[tbp]' "$TEXDIR/fixture.tex" 2>/dev/null; then
    echo "  FAIL jou_floats: jou preamble does not float figures [tbp]"
    echo "       (latex-header.lua no longer injects its jou block?)"
    return 1
  fi
  echo "  OK: jou figures float [tbp]"
}

# Compile a fresh copy of the jou tex with lualatex in draft mode and read THAT
# log; quarto's stdout carries no LaTeX warnings.
check_jou_overfull() {
  _dir=$(mktemp -d)
  cp -R "$TEXDIR"/. "$_dir"/
  ( cd "$_dir" && for _i in 1 2; do
      lualatex -draftmode -interaction=nonstopmode fixture.tex >/dev/null 2>&1 || true
    done )
  if ! grep -q 'LuaHBTeX' "$_dir/fixture.log" 2>/dev/null; then
    echo "  FAIL jou_overfull: no fresh LuaLaTeX log"
    rm -rf "$_dir"
    return 1
  fi
  _over=$(grep -E 'Overfull \\hbox \([1-9][0-9]*\.[0-9]+pt too wide\)' "$_dir/fixture.log" || true)
  rm -rf "$_dir"
  if [ -n "$_over" ]; then
    echo "  FAIL jou_overfull: lines wider than a jou column (>= 1pt):"
    printf '%s\n' "$_over" | sed 's/^/       /'
    return 1
  fi
  echo "  OK: jou has no line wider than its column (fresh LuaLaTeX log)"
}

# The jou preamble must redefine table to float [tbp], next to the figure
# redefinition. Like jou_floats, this checks the injection, not a placement.
check_jou_table_floats() {
  if ! grep -qF '\apalayout@table[tbp]' "$TEXDIR/fixture.tex" 2>/dev/null; then
    echo "  FAIL jou_table_floats: jou preamble does not float tables [tbp]"
    echo "       (latex-header.lua no longer injects its table block?)"
    return 1
  fi
  echo "  OK: jou tables float [tbp]"
}

# The probe is two-column jou with 16 tall in-flow tables after text of varying
# length. With tables [H] a table that misses the rest of a column jumps to the
# next one and leaves a blank pocket (spread inside the column, which is
# flush-bottom); tests/pdf-gaps.py counts them. Fails closed unless the probe
# is jou (the tex has \apajoufloats), has every table, and python3 and
# pdftotext exist.
check_jou_pockets() {
  command -v python3 >/dev/null 2>&1 || { echo "  FAIL jou_pockets: python3 not installed"; return 1; }
  command -v pdftotext >/dev/null 2>&1 || { echo "  FAIL jou_pockets: pdftotext not installed"; return 1; }
  if ! grep -q '^\\apajoufloats' "$POCKETS_TEX" 2>/dev/null; then
    printf '%s\n' "  FAIL jou_pockets: the pocket probe is not a jou build (no \apajoufloats call)"
    return 1
  fi
  _want=$(grep -c '{#tbl-p' "$WORK/pockets.qmd" || true)
  _have=$(pdftotext "$POCKETS" - 2>/dev/null | grep -c 'Pocket Table' || true)
  _res=$(python3 "$HERE/pdf-gaps.py" "$POCKETS")
  _pockets=${_res#pockets=}; _pockets=${_pockets%% *}
  if [ "${_want:-0}" -eq 0 ] || [ "${_have:-0}" -lt "$_want" ] || [ "${_pockets:--1}" -lt 0 ]; then
    echo "  FAIL jou_pockets: probe incomplete ($_have of $_want tables; $_res)"
    return 1
  fi
  if [ "$_pockets" -gt 0 ]; then
    echo "  FAIL jou_pockets: $_res"
    echo "       (latex-header.lua no longer floats jou tables?)"
    return 1
  fi
  echo "  OK: no blank pocket in a jou column ($_res)"
}

# --- typst -------------------------------------------------------------------

check_typst_math() {
  _src=$(grep -c -E '\\[Bb]ig[lr]?[^A-Za-z]|\\!' "$QMD" || true)
  _math=$(grep -c '\$' "$TYP" 2>/dev/null || true)
  if [ "${_src:-0}" -eq 0 ] || [ "${_math:-0}" -eq 0 ]; then
    printf '%s\n' "  FAIL typst_math: no \big or \! in the fixture, or no math in the Typst output"
    return 1
  fi
  _conv=$(grep -c 'Could not convert TeX math' "$TYPLOG" || true)
  _kern=$(grep -c '#h(-' "$TYP" || true)
  _scale=$(grep -c 'scale(x: 1[0-9][0-9]%' "$TYP" || true)
  if [ "$_conv" -gt 0 ] || [ "$_kern" -gt 0 ] || [ "$_scale" -gt 0 ]; then
    printf '%s\n' "  FAIL typst_math: $_conv unconverted TeX, $_kern negative kerns, $_scale \big scale boxes"
    echo "       (typst-math.lua no longer applies?)"
    return 1
  fi
  printf '%s\n' "  OK: typst math converted (no raw TeX, no \big boxes, no negative kerns)"
}

echo "==> Checking layout…"
FAIL=0
check_docx_lists || FAIL=1
check_jou_floats || FAIL=1
check_jou_table_floats || FAIL=1
check_jou_pockets || FAIL=1
check_jou_overfull || FAIL=1
check_typst_math || FAIL=1

if [ "$FAIL" -ne 0 ]; then
  echo "LAYOUT CHECKS FAILED"
  exit 1
fi
echo "All layout checks passed."
