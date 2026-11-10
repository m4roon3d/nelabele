"""
NelaBele – pull tables out of guidance value PDFs for review.

Writes one raw CSV per PDF (every table row, tagged with its page) so you
can see the layout and map it to guidance_template.csv. Pages with no
detectable table are saved as text instead.

Also writes <name>_roles.csv: which table column holds which rate (site,
apartment, villa, agricultural land, commercial), read from the column
headers at the start of each section and carried onto the pages after it
by x position. The gazette layouts differ from section to section (blank
spacer columns, two site columns, villa columns), so the column order
alone can't be trusted.

Usage:
  python extract_pdf_tables.py path/to/pdfs  out/
"""

import csv
import re
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


try:  # Kannada headers printed in the old Nudi font
    sys.path.insert(0, str(Path(__file__).parent))
    import nudi
except Exception:  # pragma: no cover
    nudi = None

# checked in this order: apartment and villa headers also say "site"
ROLE_WORDS = [
    ("apartment", r"apartment|flat|super\s*built|ಅಪಾರ್ಟ್|ಫ್ಲಾಟ್|ಪ್ಲಾಟ್|ಸೂಪರ್|ಬಿಲ್ಟ"),
    ("villa", r"villa(?!ge)|row\s*house|ವಿಲ್ಲಾ|ರೋ\s*ಹೌಸ್"),
    ("agricultural", r"agricult|acre|ಕೃಷಿ|ಎಕರೆ"),
    ("commercial", r"commercial|ವಾಣಿಜ್ಯ"),
    ("site", r"\bsites?\b|ನಿವ[ೇಾ]ಶನ|ನಿವೇಶ"),
]


def header_role(text):
    if not text:
        return None
    if nudi and not re.search(r"[\u0C80-\u0CFF]", text):
        try:
            text = (nudi.to_unicode(text) or "") + " " + text
        except Exception:
            pass
    for role, pat in ROLE_WORDS:
        if re.search(pat, text, re.I):
            return role
    return None


def column_spans(table):
    """x-span of each column index, from the first row that has a cell there."""
    n = max(len(r.cells) for r in table.rows)
    spans = [None] * n
    for r in table.rows:
        for i, c in enumerate(r.cells):
            if c and spans[i] is None:
                spans[i] = (c[0], c[2])
    return spans


def header_spans(table, text_rows):
    """[(x0, x1, role)] per column, from the header rows at the top of the table, or [].

    A header's words can wrap over several rows and a header cell can span
    several columns, so text is gathered per column before it is classified.
    """
    spans = column_spans(table)
    width = table.bbox[2] - table.bbox[0]
    texts = [""] * len(spans)
    for r, row_texts in list(zip(table.rows, text_rows))[:8]:
        # headers come before the first rate in the table
        if any(re.fullmatch(r"\d[\d,]{3,}", (t or "").strip()) for t in row_texts):
            break
        for c, t in zip(r.cells, row_texts):
            if not c or not t or re.fullmatch(r"[\d\s.,]+", t) or c[2] - c[0] > width / 2:
                continue          # empty, column numbers, or a title across the page
            for j, sp in enumerate(spans):
                if sp and c[0] - 1 <= (sp[0] + sp[1]) / 2 <= c[2] + 1:
                    texts[j] += " " + t
    found = [(sp[0], sp[1], header_role(t)) for sp, t in zip(spans, texts) if sp and t.strip()]
    found = [f for f in found if f[2]]
    kinds = {role for _, _, role in found}
    # a real header names the site column and at least one other rate
    return found if "site" in kinds and len(kinds) >= 2 else []


def extract(pdf_path, out_dir):
    rows, text_pages, garbled = [], [], 0
    roles, layout = [], []     # layout: header spans of the current section
    with pdfplumber.open(pdf_path) as pdf:
        for page_no, page in enumerate(pdf.pages, start=1):
            tables = page.find_tables()
            text = page.extract_text() or ""
            if looks_garbled(text):
                garbled += 1
            if tables:
                for t_no, t in enumerate(tables, start=1):
                    table = t.extract()
                    layout = header_spans(t, table) or layout
                    for i, span in enumerate(column_spans(t)):
                        if span and layout:
                            mid = (span[0] + span[1]) / 2
                            hit = sorted((x1 - x0, role) for x0, x1, role in layout if x0 - 1 <= mid <= x1 + 1)
                            if hit:
                                roles.append([page_no, t_no, i, hit[0][1]])
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
    with open(f"{stem}_roles.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["page", "table", "col", "role"])
        w.writerows(roles)
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
