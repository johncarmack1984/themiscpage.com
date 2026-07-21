#!/usr/bin/env python3
"""Build site/ from the raw Wayback mirror by applying curation rules.

Usage: sanitize.py <mirror-raw> <site-out> <rules.json>

The rules file drives three passes:

  drop   — files that do not come back at all (whole pages about third
           parties, admin surfaces the crawler caught, etc.)
  edits  — byte-exact find/replace pairs, one per redaction, per file. A rule
           whose `find` string is absent is a hard error: rules must track the
           bytes they edit.
  forbid — verification patterns (regexes) that must not match anywhere in the
           output tree. Names, emails, ICQ/AIM numbers, IPs. `allow` lists the
           deliberate exceptions. Any residual match fails the build, so a
           missed page can't ship silently.

The unsanitized mirror never enters git; only the output of this script does.
"""
import json, os, re, shutil, sys

RAW, OUT, RULES = sys.argv[1], sys.argv[2], sys.argv[3]

rules = json.load(open(RULES))
drops = {d["path"]: d["reason"] for d in rules.get("drop", [])}
edits = rules.get("edits", [])
forbid = rules.get("forbid", [])
allow = [a.encode("latin-1") for a in rules.get("allow", [])]

log = []
errors = []

# Pass 1: copy everything except drops.
if os.path.exists(OUT):
    shutil.rmtree(OUT)
copied = 0
for root, dirs, files in os.walk(RAW):
    for fn in files:
        src = os.path.join(root, fn)
        rel = os.path.relpath(src, RAW)
        if rel in drops:
            log.append(("drop", rel, drops[rel]))
            continue
        dst = os.path.join(OUT, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        copied += 1

# Pass 2: apply per-file edits.
for e in edits:
    path = os.path.join(OUT, e["path"])
    if not os.path.exists(path):
        if e["path"] in drops:
            errors.append(f"edit targets dropped file: {e['path']}")
        else:
            errors.append(f"edit targets missing file: {e['path']}")
        continue
    data = open(path, "rb").read()
    find = e["find"].encode("latin-1")
    repl = e["replace"].encode("latin-1")
    n = data.count(find)
    want = e.get("count", 1)
    if n == 0:
        errors.append(f"find-string absent in {e['path']}: {e['find'][:60]!r}")
        continue
    if n != want:
        errors.append(f"count mismatch in {e['path']}: found {n}, expected {want}")
        continue
    open(path, "wb").write(data.replace(find, repl))
    log.append(("edit", e["path"], e["reason"]))

# Pass 3: verification sweep.
compiled = [(f["pattern"], re.compile(f["pattern"].encode("latin-1"), re.I)) for f in forbid]
hits = 0
for root, dirs, files in os.walk(OUT):
    for fn in files:
        p = os.path.join(root, fn)
        data = open(p, "rb").read()
        if data[:4] in (b"GIF8", b"\x89PNG") or data[:2] == b"\xff\xd8":
            continue
        for pat, rx in compiled:
            for m in rx.finditer(data):
                frag = m.group(0)
                if any(a in frag or frag in a for a in allow):
                    continue
                ctx = data[max(0, m.start() - 40):m.end() + 40]
                errors.append(f"FORBIDDEN [{pat}] in {os.path.relpath(p, OUT)}: ...{ctx!r}...")
                hits += 1

with open(os.path.join(os.path.dirname(RULES), "curation-log.tsv"), "w") as f:
    for kind, path, reason in log:
        f.write(f"{kind}\t{path}\t{reason}\n")

print(f"copied {copied} files, dropped {len([l for l in log if l[0]=='drop'])}, edited {len([l for l in log if l[0]=='edit'])}")
if errors:
    print(f"\n{len(errors)} ERRORS:")
    for e in errors:
        print("  " + e)
    sys.exit(1)
print("verification sweep clean")
