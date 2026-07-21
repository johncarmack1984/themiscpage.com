#!/usr/bin/env python3
"""Strip HTML to readable text for the content audit. Emits one .txt per .html
under extracts/, mirroring the tree, and a combined per-directory digest."""
import os, re, sys
from html.parser import HTMLParser

SRC = sys.argv[1]
DST = sys.argv[2]

class Stripper(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
        self.skip = 0
    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self.skip += 1
        if tag in ("br", "p", "tr", "li", "hr", "div", "td"):
            self.parts.append("\n")
        for k, v in attrs:
            if k in ("href", "src") and v and ("mailto:" in v or "@" in v):
                self.parts.append(f" [[attr:{k}={v}]] ")
    def handle_endtag(self, tag):
        if tag in ("script", "style") and self.skip:
            self.skip -= 1
    def handle_data(self, data):
        if not self.skip:
            self.parts.append(data)

count = 0
for root, dirs, files in os.walk(SRC):
    for fn in files:
        if not (fn.endswith(".html") or fn.endswith(".shtml") or fn.endswith(".cgi") or fn.endswith(".php") or "." not in fn):
            continue
        p = os.path.join(root, fn)
        rel = os.path.relpath(p, SRC)
        try:
            raw = open(p, "rb").read()
        except Exception:
            continue
        if raw[:4] in (b"GIF8", b"\x89PNG", b"\xff\xd8\xff\xe0"):
            continue
        text = raw.decode("latin-1")
        if "<" not in text[:2000]:
            continue
        s = Stripper()
        try:
            s.feed(text)
        except Exception:
            pass
        out = "".join(s.parts)
        out = re.sub(r"[ \t]+", " ", out)
        out = re.sub(r"\n\s*\n+", "\n", out)
        dst = os.path.join(DST, rel + ".txt")
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "w") as f:
            f.write(out.strip() + "\n")
        count += 1
print(f"extracted {count} files")
