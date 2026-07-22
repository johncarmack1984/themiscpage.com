#!/usr/bin/env python3
"""Build the download manifest for the themiscpage.com golden-era mirror.

Policy:
- Golden era = 1999-2003 classic site (three UBB generations coexist in URL space).
- Drop 2004-05 college-era sections entirely (calendar, index.php, Home, actives, Sweetheart, columns, style.css).
- Drop admin/privacy surfaces: get_ip, gbadmin, getbio (emails), reply/edit/delete/close actions.
- Only status-200 captures are downloadable; others logged.
"""
import csv, hashlib, re, sys
from urllib.parse import urlsplit, unquote

CDX = sys.argv[1]
OUT = sys.argv[2]

DROP_ERA_PREFIX = (
    "calendar/", "index.php", "Home/", "actives/", "Sweetheart/", "columns/",
    "style.css", "favicon.ico", "art/",
)
DROP_ADMIN_SUBSTR = (
    "ubb=get_ip", "ubb=reply", "gbadmin.cgi", "action=getbio", "action=editbio",
    "action=setprefs", "action=closethread", "action=deletepost", "action=edit",
    "action=transfer", "caladmin",
)

def local_path(path, query):
    p = path.lstrip("/")
    if p == "" or p.endswith("/"):
        p += "index.html"
    if query:
        # Sort pairs: CloudFront Functions expose the query as a parsed object
        # whose iteration order is not the wire order, so the object key must
        # be order-independent. infra/cf/router.js sorts identically.
        q = "&".join(sorted(unquote(query).split("&")))
        q = re.sub(r"[^0-9A-Za-z=&+._-]", "~", q)
        q = q.replace("&", "__").replace("=", "-").replace("+", "_")
        if len(q) > 120:
            q = q[:100] + "-" + hashlib.sha1(query.encode()).hexdigest()[:10]
        p += "__Q__" + q
        if not p.endswith(".html"):
            p += ".html"
    return p

rows, dropped = [], []
seen = {}
with open(CDX) as f:
    for line in f:
        parts = line.split()
        if len(parts) < 6:
            continue
        ts, orig, mime, status = parts[1], parts[2], parts[3], parts[4]
        u = urlsplit(orig)
        if "themiscpage.com" not in u.netloc:
            dropped.append(("offsite", orig)); continue
        path, query = u.path, u.query
        rel = path.lstrip("/")
        reason = None
        if status != "200":
            reason = "status-" + status
        elif any(rel.startswith(pfx) for pfx in DROP_ERA_PREFIX):
            reason = "era-2004"
        elif any(s in orig for s in DROP_ADMIN_SUBSTR):
            reason = "admin-privacy"
        if reason:
            dropped.append((reason, orig)); continue
        lp = local_path(path, query)
        # dedupe apex/www + first-capture duplicates on the same local path
        if lp in seen:
            continue
        seen[lp] = True
        rows.append((ts, orig, lp))

# Golden overrides: serve the mature 2002 face of pages that changed over time
OVERRIDES = {
    "index.html": ("20020526152223", "http://www.themiscpage.com:80/"),
}
final = []
for ts, orig, lp in rows:
    if lp in OVERRIDES:
        ts, orig = OVERRIDES[lp]
    final.append((ts, orig, lp))

with open(OUT, "w", newline="") as f:
    w = csv.writer(f, delimiter="\t")
    for r in final:
        w.writerow(r)

from collections import Counter
c = Counter(r for r, _ in dropped)
print(f"manifest rows: {len(final)}")
print("dropped:", dict(c))
for reason, url in dropped:
    if reason in ("era-2004", "admin-privacy"):
        pass
with open(OUT + ".dropped", "w") as f:
    for reason, url in dropped:
        f.write(f"{reason}\t{url}\n")
