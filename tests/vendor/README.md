# Vendored apaquarto

`wjschne/apaquarto` 7.0.0 and `wjschne/apanote` 6.0.0, by W. Joel Schneider
(<https://github.com/wjschne/apaquarto>), CC0-1.0. Used only by `tests/run.sh`,
which copies them into a temporary project's `_extensions/` beside apa-layout.

They live here, not under an `_extensions/` folder, so `quarto add
Data-Wise/apa-layout` installs apa-layout alone.

Provenance: copied 2026-10-05, byte-identical, from pmed commit `bd35892`
("upgrade apaquarto 5.0.18 -> 7.0.0"), which installed them with
`quarto update extension wjschne/apaquarto`. That command takes upstream's
default branch, which reported 7.0.0 ahead of the v6.0.0 GitHub release.

To test against a newer apaquarto, replace `wjschne/` here and run
`tests/run.sh`; a failing check names the filter whose workaround no longer
holds (or is no longer needed).
