"""
NelaBele – pull tables out of guidance value PDFs for review.

Writes one raw CSV per PDF (every table row, tagged with its page) so you
can see the layout and map it to guidance_template.csv. Pages with no
detectable table are saved as text instead.

Usage:
  python extract_pdf_tables.py path/to/pdfs  out/
"""

import csv
import sys
import unicodedata
from pathlib import Path

import pdfplumber


def looks_garbled(text):
    """Kannada PDFs made with legacy fonts extract as Latin junk, not Kannada script."""
    letters = [c for c in text if c.isalpha()]
    if len(letters) < 50:
        return False
    kannada = sum(1 for c in letters if "KANNADA" in unicodedata.name(c, ""))
    ascii_letters = sum(1 for c in letters if c.isascii())
    odd = len(letters) - kannada - ascii_letters
    return odd / len(letters) > 0.3


def extract(pdf_path, out_dir):
    rows, text_pages, garbled = [], [], 0
    with pdfplumber.open(pdf_path) as pdf:
        for page_no, page in enumerate(pdf.pages, start=1):
            tables = page.extract_tables()
            text = page.extract_text() or ""
            if looks_garbled(text):
                garbled += 1
            if tables:
                for t_no, table in enumerate(tables, start=1):
                    for row in table:
                        cells = [(c or "").replace("\n", " ").strip() for c in row]
                        if any(cells):
                            rows.append([page_no, t_no] + cells)
            elif text.strip():
                text_pages.append(f"--- page {page_no} ---\n{text}")
        pages = len(pdf.pages)

    stem = out_dir / pdf_path.stem
    if rows:
        width = max(len(r) for r in rows)
        with open(f"{stem}.csv", "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["page", "table"] + [f"col{i}" for i in range(1, width - 1)])
            w.writerows(r + [""] * (width - len(r)) for r in rows)
    if text_pages:
        Path(f"{stem}.txt").write_text("\n\n".join(text_pages), encoding="utf-8")

    note = f"  WARNING: {garbled} page(s) look like garbled Kannada text" if garbled else ""
    print(f"{pdf_path.name}: {pages} pages, {len(rows)} table rows, "
          f"{len(text_pages)} text-only pages{note}")


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    pdfs = [src] if src.is_file() else sorted(src.glob("*.pdf"))
    if not pdfs:
        sys.exit(f"No PDFs found in {src}")
    for p in pdfs:
        extract(p, out_dir)


if __name__ == "__main__":
    main()
