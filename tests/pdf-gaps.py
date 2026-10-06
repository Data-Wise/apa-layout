#!/usr/bin/env python3
"""Count blank pockets in a two-column PDF: columns of a non-final page with a
vertical gap, inside the column or at its foot, larger than THRESHOLD percent of
the text height.

    pdf-gaps.py FILE.pdf [THRESHOLD_PERCENT]   (default 25)

Jou columns are flush-bottom, so a float that jumps to the next column makes TeX
stretch glue and spread the blank space inside the column, not only at its foot;
both are measured. The probe has no images, which would otherwise read as gaps.

Prints "pockets=N pages=P worst=W%" and exits 0; the caller decides pass/fail.
Needs pdfinfo and pdftotext (poppler). The final page is skipped: a document
ends wherever its text ends.
"""
import re
import subprocess
import sys

pdf = sys.argv[1]
limit = float(sys.argv[2]) if len(sys.argv) > 2 else 25.0

info = subprocess.run(["pdfinfo", pdf], capture_output=True, text=True).stdout
m = re.search(r"Pages:\s+(\d+)", info)
if not m:
    print("pockets=-1 pages=0 worst=0%")
    sys.exit(0)
pages = int(m.group(1))

pockets, worst = 0, 0.0
for p in range(1, pages):  # not the final page
    s = subprocess.run(["pdftotext", "-f", str(p), "-l", str(p), "-bbox", pdf, "-"],
                       capture_output=True, text=True).stdout
    h = float(re.search(r'<page width="[\d.]+" height="([\d.]+)"', s).group(1))
    w = float(re.search(r'<page width="([\d.]+)"', s).group(1))
    boxes = [tuple(map(float, b)) for b in re.findall(
        r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)"', s)]
    body = [b for b in boxes if b[1] > 60 and b[3] < h - 55]  # drop running head, folio
    for left in (True, False):
        col = sorted((b for b in body if ((b[0] + b[2]) / 2 < w / 2) == left),
                     key=lambda b: b[1])
        run, widest = 0.0, 0.0
        for b in col:
            if run:
                widest = max(widest, b[1] - run)
            run = max(run, b[3])
        foot = h - 55 - (run or 60)
        gap = 100.0 * max(widest, foot) / (h - 115)
        worst = max(worst, gap)
        if gap > limit:
            pockets += 1
print("pockets=%d pages=%d worst=%.0f%%" % (pockets, pages, worst))
