#!/bin/sh
# Show that every check in tests/run.sh can fail. Each case disables one
# filter (or plants a defect) in run.sh's temporary copy and expects run.sh to
# exit 1 with exactly the named checks failing and every other check OK.
# Exits 1 if any case does not behave so.
#
#   tests/prove-fail.sh

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ALL="docx_tables docx_lists jou_notes jou_floats needspace stranded_titles jou_overfull typst_math"
BAD=0

# $1 = VAR=value for run.sh, $2 = label, $3 = checks expected to fail. The
# variable goes through env: a prefix assignment on a shell function can leak
# into later cases in POSIX sh. $2 and $ALL are split on purpose.
# shellcheck disable=SC2086
expect() {
  _out=$(env "$1" "$HERE/run.sh" 2>&1); _rc=$?
  shift
  _failed=$(printf '%s\n' "$_out" | sed -n 's/^  FAIL \([a-z_]*\):.*/\1/p' | sort -u | tr '\n' ' ')
  _want=$(printf '%s\n' $2 | sort -u | tr '\n' ' ')
  _ok=$(printf '%s\n' "$_out" | grep -c '^  OK:' || true)
  _nall=$(printf '%s\n' $ALL | wc -l | tr -d ' ')
  _nwant=$(printf '%s\n' $2 | wc -l | tr -d ' ')
  if [ "$_rc" -eq 1 ] && [ "$_failed" = "$_want" ] && [ "$_ok" -eq $((_nall - _nwant)) ]; then
    echo "  PASS $1: exit 1, failed: $_failed"
  else
    echo "  MISS $1: exit $_rc, failed: [${_failed}], expected [${_want}], $_ok OK"
    printf '%s\n' "$_out" | sed 's/^/       /'
    BAD=1
  fi
}

echo "==> Disabling each filter in turn…"
expect APA_LAYOUT_DISABLE=docx-tables.lua     docx-tables.lua     docx_tables
expect APA_LAYOUT_DISABLE=docx-lists.lua      docx-lists.lua      docx_lists
expect APA_LAYOUT_DISABLE=jou-float-notes.lua jou-float-notes.lua jou_notes
expect APA_LAYOUT_DISABLE=latex-header.lua    latex-header.lua    "jou_floats needspace stranded_titles"
expect APA_LAYOUT_DISABLE=typst-math.lua      typst-math.lua      typst_math

echo "==> Planting a line wider than a jou column…"
PLANTED=$(mktemp)
trap 'rm -f "$PLANTED"' EXIT
cat "$HERE/fixture/fixture.qmd" >"$PLANTED"
cat >>"$PLANTED" <<'EOF'

\noindent\mbox{An unbreakable line that is far wider than one column of the two-column jou layout.}
EOF
expect APA_LAYOUT_FIXTURE="$PLANTED" "planted overfull line" jou_overfull

if [ "$BAD" -ne 0 ]; then
  echo "NEGATIVE CONTROLS FAILED: a check did not fail as expected"
  exit 1
fi
echo "Every check fails when its filter is disabled or its defect is planted."
