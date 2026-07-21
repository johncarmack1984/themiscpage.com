#!/bin/bash
# Sync site/ to the origin bucket with era-correct content types.
#
# The mirror's pages are Windows-1252-era HTML under extensions the AWS CLI
# won't guess (.shtml, .cgi, .php, and .cgi__Q__*.html frozen query-string
# pages), so HTML goes up in an explicit pass. Assets first, HTML second.
set -euo pipefail

BUCKET="${1:?usage: deploy.sh s3://bucket}"
cd "$(dirname "$0")/.."

# Pass 1: everything that isn't HTML, with guessed content types.
aws s3 sync site/ "$BUCKET/" \
  --delete \
  --exclude "*.html" --exclude "*.shtml" --exclude "*.cgi" --exclude "*.php"

# Pass 2: HTML in all its 1999 spellings.
aws s3 sync site/ "$BUCKET/" \
  --exclude "*" \
  --include "*.html" --include "*.shtml" --include "*.cgi" --include "*.php" \
  --content-type "text/html; charset=windows-1252" \
  --metadata-directive REPLACE

echo "deployed $(find site -type f | wc -l | tr -d ' ') files"
