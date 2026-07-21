#!/bin/bash
# Download the golden-era mirror from the Wayback Machine (raw bytes via the
# id_ modifier), resumably and politely. Reads the manifest emitted by
# build_manifest.py: tab-separated  timestamp<TAB>original-url<TAB>local-path.
#
#   usage: download_mirror.sh manifest.tsv output-dir
set -u
MANIFEST="${1:?usage: download_mirror.sh manifest.tsv output-dir}"
RAW="${2:?usage: download_mirror.sh manifest.tsv output-dir}"
mkdir -p "$RAW"
ok=0; fail=0
while IFS=$'\t' read -r ts url lp; do
  dest="$RAW/$lp"
  mkdir -p "$(dirname "$dest")"
  if [ -s "$dest" ]; then ok=$((ok+1)); continue; fi
  code=$(curl -sL --max-time 60 -w '%{http_code}' -o "$dest" "https://web.archive.org/web/${ts}id_/${url}")
  if [ "$code" != "200" ] || [ ! -s "$dest" ]; then
    sleep 6
    code=$(curl -sL --max-time 60 -w '%{http_code}' -o "$dest" "https://web.archive.org/web/${ts}id_/${url}")
  fi
  if [ "$code" = "200" ] && [ -s "$dest" ]; then
    ok=$((ok+1))
  else
    fail=$((fail+1)); echo "FAIL $code $ts $url" >&2; rm -f "$dest"
  fi
  sleep 0.7
done < "$MANIFEST"
echo "done ok=$ok fail=$fail"
