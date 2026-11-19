#!/usr/bin/env python3
"""Count blank page remainders in a single-column (man) PDF: body pages whose
tallest vertical blank run, inside the text block or at its foot, is larger
than THRESHOLD percent of the body height.

    man-gaps.py FILE.pdf [THRESHOLD_PERCENT] [SKIP_PAGES]   (defaults 25, 2)

An [H] figure taller than the rest of a man page moves to the next page and
leaves the rest of this one blank. Unlike pdf-gaps.py this reads pixels, not
text boxes, so a figure counts as content: each page is rendered in gray at
36 dpi (pdftoppm) and a row is ink when any pixel in it is darker than 200.
The running head and folio (top and bottom 9%) are ignored.

The first SKIP_PAGES pages (man's title page and abstract page) and the final
page (a document ends wherever its text ends) are skipped.

Prints "gaps=N pages=P worst=W%" and exits 0; the caller decides pass/fail.
Needs pdfinfo and pdftoppm (poppler).
"""
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

pdf = sys.argv[1]
limit = float(sys.argv[2]) if len(sys.argv) > 2 else 25.0
skip = int(sys.argv[3]) if len(sys.argv) > 3 else 2

info = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
m = re.search(r"Pages:\s+(\d+)", info)
if not m:
    print("gaps=-1 pages=0 worst=0%")
    sys.exit(0)
pages = int(m.group(1))

td = tempfile.mkdtemp()
try:
    subprocess.run(["pdftoppm", "-gray", "-r", "36", pdf, os.path.join(td, "p")],
                   check=True)
    files = sorted(glob.glob(os.path.join(td, "p-*.pgm")))
    gaps, worst = 0, 0.0
    for i, f in enumerate(files, 1):
        if i <= skip or i == pages:
            continue
        d = open(f, "rb").read()
        h = re.match(rb"P5\s+(\d+)\s+(\d+)\s+(\d+)\s", d)
        w, ht, px = int(h.group(1)), int(h.group(2)), d[h.end():]
        top, bot = int(ht * 0.09), int(ht * 0.91)
        x0, x1 = int(w * 0.06), int(w * 0.94)
        widest, run = 0, None
        for y in range(top, bot):
            if any(px[y * w + x] < 200 for x in range(x0, x1)):
                if run is not None:
                    widest = max(widest, y - run)
                run = None
            elif run is None:
                run = y
        if run is not None:
            widest = max(widest, bot - run)
        gap = 100.0 * widest / (bot - top)
        worst = max(worst, gap)
        if gap > limit:
            gaps += 1
finally:
    shutil.rmtree(td)
print("gaps=%d pages=%d worst=%.0f%%" % (gaps, pages, worst))
