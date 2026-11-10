"""
NelaBele – read Kannada printed in the old Nudi font.

Many gazette rows give a place name only in Kannada, set in the Nudi font,
which extracts as Latin junk ("CwÛUÀÄ¥Éà"). This turns it back into Unicode
Kannada (ಅತ್ತಿಗುಪ್ಪೆ) using Aravinda VK's ascii2unicode converter, and into
a plain English spelling (Attiguppe).

The converter is GPL-licensed and isn't copied into this repo. Get it with
  git clone --depth 1 https://github.com/aravindavk/ascii2unicode
and point KNCONVERTER at its `knconverter` file (default: ../a2u/knconverter
next to this repo). Without it, Kannada-only rows are skipped as before.
"""

import os
import re
import unicodedata
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path

_DEFAULT = Path(__file__).resolve().parents[2] / "a2u" / "knconverter"
_converter = None


def _load():
    global _converter
    if _converter is None:
        path = Path(os.environ.get("KNCONVERTER", _DEFAULT))
        if not path.exists():
            _converter = False
        else:
            loader = SourceFileLoader("knconverter", str(path))
            mod = module_from_spec(spec_from_loader("knconverter", loader))
            loader.exec_module(mod)
            _converter = mod
    return _converter


def available():
    return bool(_load())


KANNADA = re.compile(r"[ಀ-೿]")
_NUDI_HINT = re.compile(r"[ -ÿŒ-ƒ‘-›]")


def to_unicode(text):
    """Nudi-encoded text → Unicode Kannada, or None if it doesn't look like Nudi."""
    conv = _load()
    if not conv or not text or not _NUDI_HINT.search(text):
        return None
    try:
        out = conv.process_line(text)
    except Exception:  # the converter trips on a few odd glyph sequences
        return None
    out = re.sub(r"[^ಀ-೿0-9 ,./()-]", "", out)
    out = re.sub(r"\s+", " ", out).strip(" ,./-")
    # line-wrapped cells leave vowel signs and viramas cut off from their letter
    out = re.sub(r"\s+([\u0CBC-\u0CCD\u0C82\u0C83\u0CD5\u0CD6])", r"\1", out)
    out = re.sub(r"(^|\s)[\u0CBC-\u0CCD\u0C82\u0C83\u0CD5\u0CD6]+", r"\1", out).strip()
    # the converter writes ಳ್ಳಿ as ಳಿ್ಳ; and "-ಪುರ" loses its ರ to the next line
    out = out.replace("ಳಿ್ಳ", "ಳ್ಳಿ").replace("ಳಿ ್ಳ", "ಳ್ಳಿ")
    out = re.sub(r"ಪು(\s|$)", r"ಪುರ\1", out)
    # text from a different legacy font comes out as runs of ಚಿ/ಟ/ಃ: not a name
    if "ಃ" in out or out.count("ಚಿ") >= 2 or "ಚಿಟ" in out or "ಟಚಿ" in out:
        return None
    # mostly Kannada letters, or it wasn't Nudi after all
    letters = [c for c in out if KANNADA.match(c)]
    return out if len(letters) >= 3 and len(letters) >= 0.7 * len(out.replace(" ", "")) else None


# Kannada → plain English spelling, the way places are usually written in English
_V = {"ಅ": "a", "ಆ": "a", "ಇ": "i", "ಈ": "i", "ಉ": "u", "ಊ": "u", "ಋ": "ru", "ಎ": "e", "ಏ": "e",
      "ಐ": "ai", "ಒ": "o", "ಓ": "o", "ಔ": "au"}
_M = {"ಾ": "a", "ಿ": "i", "ೀ": "i", "ು": "u", "ೂ": "u", "ೃ": "ru", "ೆ": "e", "ೇ": "e", "ೈ": "ai",
      "ೊ": "o", "ೋ": "o", "ೌ": "au"}
_C = {"ಕ": "k", "ಖ": "kh", "ಗ": "g", "ಘ": "gh", "ಙ": "n", "ಚ": "ch", "ಛ": "ch", "ಜ": "j", "ಝ": "jh",
      "ಞ": "n", "ಟ": "t", "ಠ": "th", "ಡ": "d", "ಢ": "dh", "ಣ": "n", "ತ": "t", "ಥ": "th", "ದ": "d",
      "ಧ": "dh", "ನ": "n", "ಪ": "p", "ಫ": "ph", "ಬ": "b", "ಭ": "bh", "ಮ": "m", "ಯ": "y", "ರ": "r",
      "ಱ": "r", "ಲ": "l", "ವ": "v", "ಶ": "sh", "ಷ": "sh", "ಸ": "s", "ಹ": "h", "ಳ": "l", "ೞ": "l"}
_VIRAMA, _ANUSVARA, _VISARGA = "್", "ಂ", "ಃ"


def to_english(kn):
    """ಅತ್ತಿಗುಪ್ಪೆ → Attiguppe, ಕೊತ್ತನಹಳ್ಳಿ → Kottanahalli."""
    out = []
    chars = list(unicodedata.normalize("NFC", kn))
    i = 0
    while i < len(chars):
        c = chars[i]
        nxt = chars[i + 1] if i + 1 < len(chars) else ""
        if c in _C:
            out.append(_C[c])
            if nxt == _VIRAMA:
                i += 1
            elif nxt in _M:
                out.append(_M[nxt])
                i += 1
            else:
                out.append("a")
        elif c in _V:
            out.append(_V[c])
        elif c == _ANUSVARA:
            out.append("m" if nxt in ("ಪ", "ಫ", "ಬ", "ಭ", "ಮ") or not nxt.strip() else "n")
        elif c == _VISARGA:
            out.append("h")
        elif not KANNADA.match(c):
            out.append(c)
        i += 1
    word = "".join(out)
    word = re.sub(r"a(\s|$)", r"a\1", word)
    return " ".join(w[:1].upper() + w[1:] for w in word.split())


# Words marking a sub-row (survey numbers, road frontage) rather than a place
SUB_ROW_KN = re.compile(r"ಸರ್ವೆ|ಸರ್ವೇ|ರಸ್ತೆ|ಹೊಂದಿಕೊಂಡ|ಹೆದ್ದಾರಿ|ಜಮೀನು|ನಂಬರ್|ಮುಖ್ಯ")
