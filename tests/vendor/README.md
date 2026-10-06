# Vendored apaquarto

`wjschne/apaquarto` 7.0.0 and `wjschne/apanote` 6.0.0, by W. Joel Schneider
(<https://github.com/wjschne/apaquarto>), CC0-1.0. Used only by `tests/run.sh`,
which copies them into a temporary project's `_extensions/` beside apa-layout.

They live here, not under an `_extensions/` folder, so `quarto add
Data-Wise/apa-layout` installs apa-layout alone.

Provenance: copied 2026-10-06 from the apaquarto **v7.0.0 release**
(published 2026-10-06 11:21 UTC, `gh release download v7.0.0`). An install from
upstream's default branch before that time also reports `version: 7.0.0` but
lacks the fixes for wjschne/apaquarto#168, #169 and #170, so the version string
does not identify the code. An earlier copy of these tests used that
pre-release code (taken from pmed commit `bd35892`).

To test against a newer apaquarto, replace `wjschne/` here and run
`tests/run.sh`; a failing check names the filter whose workaround no longer
holds (or is no longer needed).
