#!/bin/sh
# Render tests/fixture/fixture.qmd with the vendored apaquarto 7.0.0 and this
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
#   docx_tables    docx-tables.lua      data tables keep the ruled Table style
#   docx_lists     docx-lists.lua       no list item in Word's Compact style
#   jou_notes      jou-float-notes.lua  a figure's note stays inside its jou float
#   jou_floats     latex-header.lua     jou figures float [tbp], not [H]
#   needspace      latex-header.lua     \Needspace before an in-flow table title
#   stranded_titles latex-header.lua    no table title alone at a page foot (man PDF)
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
cp "$HERE/fixture/stranded.qmd" "$WORK/stranded.qmd"
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
STRANDED="$WORK/out/stranded.pdf"
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

echo "==> Rendering docx, typst, pdf (jou), pdf (man, stranded probe), pdf (jou, pocket probe)…"
render docx --to apaquarto-docx
mv "$WORK/fixture.docx" "$DOCX"
render typst --to apaquarto-typst -M keep-typ:true
cp "$WORK/out/render-typst.log" "$TYPLOG"
mv "$WORK/fixture.typ" "$TYP"
render jou --to apaquarto-pdf -M documentmode:jou -M keep-tex:true
cp "$WORK/fixture.tex" "$TEXDIR/"
cp -R "$WORK/fixture_files" "$TEXDIR/"
( cd "$WORK" && quarto render stranded.qmd --to apaquarto-pdf -M documentmode:man ) \
  >"$WORK/out/render-stranded.log" 2>&1 \
  || { cat "$WORK/out/render-stranded.log"; echo "FAIL render: stranded.qmd" >&2; exit 1; }
mv "$WORK/stranded.pdf" "$STRANDED"
( cd "$WORK" && quarto render pockets.qmd --to apaquarto-pdf -M keep-tex:true ) \
  >"$WORK/out/render-pockets.log" 2>&1 \
  || { cat "$WORK/out/render-pockets.log"; echo "FAIL render: pockets.qmd" >&2; exit 1; }
mv "$WORK/pockets.pdf" "$POCKETS"
mv "$WORK/pockets.tex" "$POCKETS_TEX"

# --- docx --------------------------------------------------------------------

# Every table the fixture declares must carry the Table style; apaquarto
# 7.0.0's docxlayout.lua gives them the borderless FigureLayout.
check_docx_tables() {
  _want=$(grep -c -E '\{#tbl-|^#\| label: tbl-' "$QMD" || true)
  _xml=$(unzip -p "$DOCX" word/document.xml 2>/dev/null || true)
  if [ "${_want:-0}" -eq 0 ] || [ -z "$_xml" ]; then
    echo "  FAIL docx_tables: no tables declared in the fixture or unreadable docx"
    return 1
  fi
  _got=$(printf '%s' "$_xml" | grep -o '<w:tblStyle w:val="Table"' | wc -l | tr -d ' ')
  if [ "$_got" -lt "$_want" ]; then
    echo "  FAIL docx_tables: $_got of $_want data tables carry the ruled Table style"
    echo "       (docx-tables.lua no longer undoes docxlayout.lua's FigureLayout?)"
    return 1
  fi
  echo "  OK: docx data tables ruled ($_got of $_want with the Table style)"
}

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

# No \begin{apafloatnote} may directly follow \end{figure}.
check_jou_notes() {
  _tex="$TEXDIR/fixture.tex"
  if ! grep -q '^\\apajoufloats' "$_tex" 2>/dev/null; then
    printf '%s\n' "  FAIL jou_notes: not a jou build (no \apajoufloats call)"
    return 1
  fi
  _want=$(grep -c '^#| apa-note:' "$QMD" || true)
  _notes=$(grep -c '\\begin{apafloatnote}' "$_tex" || true)
  if [ "${_want:-0}" -eq 0 ] || [ "${_notes:-0}" -lt "$_want" ]; then
    echo "  FAIL jou_notes: $_notes notes in the jou tex, the fixture declares $_want chunk notes"
    return 1
  fi
  _bad=$(awk '
    /^[[:space:]]*$/ { next }
    /^\\begin\{apafloatnote\}/ && prev ~ /^\\end\{figure\}/ { n++ }
    { prev = $0 }
    END { print n + 0 }' "$_tex")
  if [ "$_bad" -gt 0 ]; then
    printf '%s\n' "  FAIL jou_notes: $_bad figure note(s) set after \end{figure}, outside the float"
    echo "       (jou-float-notes.lua no longer applies?)"
    return 1
  fi
  echo "  OK: jou figure notes inside their floats ($_notes notes)"
}

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

# The preamble must wrap \apafloattitle with \Needspace. Like jou_floats, this
# checks the injection, not a page break.
check_needspace() {
  if ! grep -qF '\Needspace{14\baselineskip}' "$TEXDIR/fixture.tex" 2>/dev/null; then
    printf '%s\n' "  FAIL needspace: no \Needspace before in-flow table titles"
    echo "       (latex-header.lua no longer injects its needspace block?)"
    return 1
  fi
  printf '%s\n' "  OK: in-flow table titles ask for room (\Needspace)"
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

# The probe puts a table after 0..29 filler lines, so without latex-header.lua's
# \Needspace some table title lands alone at a page foot. A page whose last
# lines hold a "Probe Table" caption (the table body is on the next page)
# counts as stranded. Fails closed unless every probe table was rendered.
check_stranded_titles() {
  command -v pdftotext >/dev/null 2>&1 || { echo "  FAIL stranded_titles: pdftotext not installed"; return 1; }
  _want=$(grep -c '{#tbl-q' "$WORK/stranded.qmd" || true)
  _have=$(pdftotext "$STRANDED" - 2>/dev/null | grep -c 'Probe Table' || true)
  _pages=$(pdfinfo "$STRANDED" 2>/dev/null | awk '/^Pages:/ {print $2}')
  if [ "${_want:-0}" -eq 0 ] || [ "${_have:-0}" -lt "$_want" ] || [ "${_pages:-0}" -lt 3 ]; then
    echo "  FAIL stranded_titles: probe incomplete ($_have of $_want titles in ${_pages:-0} pages)"
    return 1
  fi
  _bad=0
  _p=1
  while [ "$_p" -le "$_pages" ]; do
    if pdftotext -f "$_p" -l "$_p" -layout "$STRANDED" - | sed '/^[[:space:]]*$/d' | tail -3 | grep -q 'Probe Table'; then
      _bad=$((_bad + 1))
    fi
    _p=$((_p + 1))
  done
  if [ "$_bad" -gt 0 ]; then
    echo "  FAIL stranded_titles: $_bad page(s) end with a table title, its table on the next page"
    echo "       (latex-header.lua no longer asks for room before in-flow titles?)"
    return 1
  fi
  echo "  OK: no table title stranded at a page foot ($_have tables, $_pages pages)"
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
check_docx_tables || FAIL=1
check_docx_lists || FAIL=1
check_jou_notes || FAIL=1
check_jou_floats || FAIL=1
check_needspace || FAIL=1
check_stranded_titles || FAIL=1
check_jou_table_floats || FAIL=1
check_jou_pockets || FAIL=1
check_jou_overfull || FAIL=1
check_typst_math || FAIL=1

if [ "$FAIL" -ne 0 ]; then
  echo "LAYOUT CHECKS FAILED"
  exit 1
fi
echo "All layout checks passed."
