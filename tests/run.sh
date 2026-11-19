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
#   APA_LAYOUT_HEADER   a file to copy over latex-header.lua in the temporary
#                       copy (plants an old or broken version)
#   KEEP=1              keep the temporary project and print its path
#
# Check            Guards
#   docx_lists     docx-lists.lua       no list item in Word's Compact style
#   jou_floats     latex-header.lua     jou figures float [tbp], not [H]
#   jou_table_floats latex-header.lua   jou tables float [tbp], not [H]
#   jou_pockets    latex-header.lua     no blank pocket in a jou column (jou probe PDF)
#   jou_note       latex-header.lua     the correspondence note sits at the foot of page 1
#   typst_math     typst-math.lua       no \big scale boxes or \! negative kerns
#   man_floats     (apaquarto #171)     no figure title or note clipped at a man page foot
#   man_pockets    latex-header.lua     man-floats: no blank page remainder (man probe PDF)
#   man_table_floats man-floats.lua     man-floats: a boxed man table floats, a longtable does not
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
cp "$HERE/fixture/man-pockets.qmd" "$WORK/man-pockets.qmd"
cp "$HERE/fixture/man-tables.md" "$WORK/man-tables.md"
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
MAN="$WORK/out/fixture-man.pdf"
POCKETS_TEX="$WORK/out/pockets.tex"
MAN_POCKETS="$WORK/out/man-pockets.pdf"
mkdir -p "$WORK/out" "$TEXDIR"

render() {
  _log="$WORK/out/render-$1.log"; shift
  if ! (cd "$WORK" && quarto render fixture.qmd "$@") >"$_log" 2>&1; then
    cat "$_log"
    echo "FAIL render: quarto render $*" >&2
    exit 1
  fi
}

if [ -n "${APA_LAYOUT_HEADER:-}" ]; then
  [ -f "$APA_LAYOUT_HEADER" ] || { echo "no such file: $APA_LAYOUT_HEADER" >&2; exit 2; }
  cp "$APA_LAYOUT_HEADER" "$WORK/$EXT/latex-header.lua"
  echo "latex-header.lua replaced by $APA_LAYOUT_HEADER"
fi

echo "==> Rendering docx, typst, pdf (jou), pdf (man), pdf (jou and man probes)…"
render docx --to apaquarto-docx
mv "$WORK/fixture.docx" "$DOCX"
render typst --to apaquarto-typst -M keep-typ:true
cp "$WORK/out/render-typst.log" "$TYPLOG"
mv "$WORK/fixture.typ" "$TYP"
render jou --to apaquarto-pdf -M documentmode:jou -M keep-tex:true
cp "$WORK/fixture.tex" "$WORK/fixture.pdf" "$TEXDIR/"
cp -R "$WORK/fixture_files" "$TEXDIR/"
render man --to apaquarto-pdf -M documentmode:man
mv "$WORK/fixture.pdf" "$MAN"
( cd "$WORK" && quarto render pockets.qmd --to apaquarto-pdf -M keep-tex:true ) \
  >"$WORK/out/render-pockets.log" 2>&1 \
  || { cat "$WORK/out/render-pockets.log"; echo "FAIL render: pockets.qmd" >&2; exit 1; }
mv "$WORK/pockets.pdf" "$POCKETS"
mv "$WORK/pockets.tex" "$POCKETS_TEX"
( cd "$WORK" && quarto render man-pockets.qmd --to apaquarto-pdf ) \
  >"$WORK/out/render-man-pockets.log" 2>&1 \
  || { cat "$WORK/out/render-man-pockets.log"; echo "FAIL render: man-pockets.qmd" >&2; exit 1; }
mv "$WORK/man-pockets.pdf" "$MAN_POCKETS"

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

# apaquarto sets the author/correspondence note as a [b] float so it lands at
# the foot of the first column. A float rewrite that ignores its placement
# argument (the 0.1.x [tbp] override) puts it at the top, under the abstract.
# The fixture has a corresponding author; its note must start in the bottom
# quarter of page 1. Fails closed when the note is not found.
check_jou_note() {
  _pos=$(pdftotext -f 1 -l 1 -bbox "$TEXDIR/fixture.pdf" - 2>/dev/null | awk '
    /<page /   { match($0, /height="[0-9.]+"/); h = substr($0, RSTART + 8, RLENGTH - 9) }
    /Correspondence<\/word>/ && !y { match($0, /yMin="[0-9.]+"/); y = substr($0, RSTART + 6, RLENGTH - 7) }
    END        { if (y != "" && h != "") printf "%s %s", y, h }')
  if [ -z "$_pos" ]; then
    echo "  FAIL jou_note: no correspondence note on page 1 of the jou PDF"
    return 1
  fi
  if ! echo "$_pos" | awk '{ exit !($1 > 0.75 * $2) }'; then
    echo "  FAIL jou_note: the correspondence note starts at y=${_pos% *} of a ${_pos#* }-pt page, not at the foot"
    echo "       (latex-header.lua overrides the note's [b] placement?)"
    return 1
  fi
  echo "  OK: jou correspondence note at the foot of page 1 (y=${_pos% *} of ${_pos#* } pt)"
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

# --- pdf (man) ---------------------------------------------------------------

# The end of every chunk fig-cap and apa-note in the fixture must reach the man
# PDF. Since apaquarto v7.0.0 (the #169 fix) a figure's note sits inside man's
# [H] float, which cannot break across pages, so a long note runs off the page
# foot, clipped, with no warning (wjschne/apaquarto#171). apa-layout does not
# work around it; this check is how a manuscript finds out. The probe for each
# caption or note is its last math-free span of 3+ words, compared as lowercase
# letters and digits only. Ported from pmed's check_man_floats.
check_man_floats() {
  command -v pdftotext >/dev/null 2>&1 || { echo "  FAIL man_floats: pdftotext not installed"; return 1; }
  _pdf=$(pdftotext "$MAN" - 2>/dev/null | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cd '[:alnum:]')
  _tails=$(awk -v sq="'" '
    /^#\| (fig-cap|apa-note): / {
      s = $0; sub(/^#\| (fig-cap|apa-note): /, "", s)
      q = substr(s, 1, 1)
      if (q == "\"" || q == sq) { s = substr(s, 2); sub(/["'"'"'][[:space:]]*$/, "", s) }
      n = split(s, part, "$"); best = ""
      for (i = (n % 2 ? n : n - 1); i >= 1; i -= 2)
        if (split(part[i], w, " ") >= 3) { best = part[i]; break }
      print (best == "" ? "NO-PROBE" : best)
    }' "$QMD")
  if [ -z "$_pdf" ] || [ -z "$_tails" ]; then
    echo "  FAIL man_floats: unreadable man PDF or no chunk fig-cap/apa-note in the fixture"
    return 1
  fi
  _n=0; _miss=0
  while IFS= read -r _t; do
    _n=$((_n + 1))
    _l=$(printf '%s' "$_t" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cd '[:alnum:]')
    case "$_pdf" in
      *"$_l"*) [ "$_t" != NO-PROBE ] && continue ;;
    esac
    _miss=$((_miss + 1))
    echo "  FAIL man_floats: caption/note ending not in man: \"$_t\""
  done <<EOF
$_tails
EOF
  if [ "$_miss" -gt 0 ]; then
    echo "       (a figure title or note clipped at a page foot? shrink the figure; see apaquarto#171)"
    return 1
  fi
  echo "  OK: man figure titles and notes complete ($_n of $_n endings found)"
}

# The man probe (documentmode man, apa-layout: {man-floats: true}) has six tall
# figures after text of varying length. With figures [H], one that misses the
# rest of a page moves to the next and leaves the rest of the page blank;
# tests/man-gaps.py counts such pages from pixels, so figures count as content.
# Fails closed unless the probe has every figure, and python3 and pdftoppm exist.
check_man_pockets() {
  command -v python3 >/dev/null 2>&1 || { echo "  FAIL man_pockets: python3 not installed"; return 1; }
  command -v pdftoppm >/dev/null 2>&1 || { echo "  FAIL man_pockets: pdftoppm not installed"; return 1; }
  _want=$(grep -c '#| label: fig-m' "$WORK/man-pockets.qmd" || true)
  _have=$(pdftotext "$MAN_POCKETS" - 2>/dev/null | grep -c 'Man Probe Figure' || true)
  _res=$(python3 "$HERE/man-gaps.py" "$MAN_POCKETS")
  _gaps=${_res#gaps=}; _gaps=${_gaps%% *}
  if [ "${_want:-0}" -eq 0 ] || [ "${_have:-0}" -lt "$_want" ] || [ "${_gaps:--1}" -lt 0 ]; then
    echo "  FAIL man_pockets: probe incomplete ($_have of $_want figures; $_res)"
    return 1
  fi
  if [ "$_gaps" -gt 0 ]; then
    echo "  FAIL man_pockets: $_res"
    echo "       (latex-header.lua no longer floats man figures under man-floats?)"
    return 1
  fi
  echo "  OK: no blank page remainder in man with man-floats ($_res)"
}

# man-floats.lua on a synthetic body (tests/fixture/man-tables.md): the raw
# blocks floatlatex.lua writes for a man table that is one box (a minipage
# with \apalongtableastabular) and for a longtable. apaquarto upstream sets
# no man table as one box, so a render cannot exercise this; plain pandoc
# runs the filter (it skips its format check outside Quarto). With the option
# the boxed table must become a table[!htbp] float, \end{table} starting a
# line (Quarto's latex postprocessor drops the rest of the .tex otherwise),
# and the longtable must stay in the flow; without it nothing changes.
check_man_table_floats() {
  # Quarto bundles pandoc; CI runners have quarto but no standalone pandoc.
  if command -v pandoc >/dev/null 2>&1; then _pd=pandoc
  elif command -v quarto >/dev/null 2>&1; then _pd="quarto pandoc"
  else echo "  FAIL man_table_floats: neither pandoc nor quarto installed"; return 1; fi
  _f="$WORK/$EXT/man-floats.lua"
  printf -- '---\napa-layout: {man-floats: true}\n---\n' >"$WORK/out/on.yaml"
  printf -- '---\napa-layout: {man-floats: false}\n---\n' >"$WORK/out/off.yaml"
  _on=$($_pd "$WORK/out/on.yaml" "$WORK/man-tables.md" --lua-filter "$_f" -t latex 2>&1) || true
  _off=$($_pd "$WORK/out/off.yaml" "$WORK/man-tables.md" --lua-filter "$_f" -t latex 2>&1) || true
  _begin=$(printf '%s\n' "$_on" | grep -c '^\\begin{table}\[!htbp\]$' || true)
  _end=$(printf '%s\n' "$_on" | grep -c '^\\end{table}$' || true)
  _flow=$(printf '%s\n' "$_on" | grep -c '^\\par\\addvspace{\\baselineskip}\\begingroup$' || true)
  _offn=$(printf '%s\n' "$_off" | grep -c 'begin{table}' || true)
  if [ "$_begin" -ne 1 ] || [ "$_end" -ne 1 ] || [ "$_flow" -ne 1 ] || [ "$_offn" -ne 0 ]; then
    echo "  FAIL man_table_floats: on: $_begin table floats, $_end \\end{table} lines, $_flow in-flow tables (want 1, 1, 1); off: $_offn floats (want 0)"
    echo "       (man-floats.lua no longer floats a boxed man table, or floats a longtable?)"
    return 1
  fi
  echo "  OK: man-floats floats the boxed man table and leaves the longtable in the flow"
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
check_jou_note || FAIL=1
check_jou_pockets || FAIL=1
check_man_floats || FAIL=1
check_man_pockets || FAIL=1
check_man_table_floats || FAIL=1
check_jou_overfull || FAIL=1
check_typst_math || FAIL=1

if [ "$FAIL" -ne 0 ]; then
  echo "LAYOUT CHECKS FAILED"
  exit 1
fi
echo "All layout checks passed."
