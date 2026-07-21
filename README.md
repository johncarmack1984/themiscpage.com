# themiscpage.com

The Miscellaneous Page — my first website, hand-written in eighth grade, live 1999-2005, and now live again, served exactly as the Wayback Machine remembers it.

This is a static resurrection. Every page in `site/` is the original HTML as captured between 2000 and 2003: the table layouts, the `<font>` tags, the nested `<html>` documents I didn't know were wrong, the hit counter that reset itself to 1 in 2002 and stays at 1 forever now, and three successive generations of Ultimate Bulletin Board frozen mid-conversation — UBB 5.44a (2000), UBB 6.0 (2001), and UBB.classic (2002), each with its Infopop Corporation footer intact. Infopop is not around to renew the license, so any attempt to post gets the answer it deserves: see `site/cgi-bin/error.html`.

The commit dates in this repo are accurate to the era the files come from. Git was released in 2005. The site declines to explain itself.

## Layout

- `site/` — the site, byte-faithful except where `CURATION.md` says otherwise. No build step. There was no build step in 1999 either.
- `infra/` — Terraform: private S3 origin, CloudFront with a viewer-request function (`infra/cf/router.js`) that emulates 1999 CGI query-string routing against the frozen pages, redirects www to the apex, and routes non-GET requests to the license page. Missing pages get the hosting provider's original IIS 404, served verbatim.
- `github-oidc/` — its own Terraform root: the plan-only CI role and the main-branch-only deploy role. No long-lived AWS keys.
- `tools/` — the reconstruction pipeline: Wayback CDX manifest builder, mirror downloader, curation engine (`sanitize.py`), and the deploy script. The site can be re-derived from the public archive with these; the curation rules are the only editorial layer.
- `.github/workflows/` — `terraform.yml` plans `infra/` on PRs; `deploy.yml` syncs `site/` on pushes to main.

## Curation

The mirror is not quite verbatim. Some things a fourteen-year-old published in 1999 don't get amplified by an adult in 2026: third parties' real names, contact details, a few jokes that aged badly, and some vocabulary I've since learned better than. `CURATION.md` records every removal and edit by category. The original, uncurated site remains publicly available in the Wayback Machine, which is also where this one came from.

## Operating it

Plan/apply from `infra/` (state in S3; CI plans, applies are manual). The ACM certificate validates via DNS records that live in `my-infra/dns`, so a first apply emits the validation CNAMEs, and the apex/www ALIAS records point at the CloudFront domain in the outputs. Content deploys automatically on push to main, or by hand with `tools/deploy.sh s3://themiscpage.com`.

`sentiment.themiscpage.com` is a separate app with separate infrastructure and does not pass through any of this.
