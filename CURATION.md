# Curation record

The site in `site/` is the Wayback Machine's capture of themiscpage.com (1999-2003), reproduced byte-for-byte except as recorded here. The uncurated original remains public at web.archive.org; this file documents how the resurrection differs from it, and why. Rules are machine-applied by `tools/sanitize.py` from a rules file kept out of the repo (the rules necessarily contain the strings being removed; publishing them would defeat the point).

## Categories

**Not mirrored — later-era content.** The 2004-2005 pages (a PHP portal, `/calendar/`, `/Sweetheart/`, `/actives/`) are a different site that happened to live at the same domain after this one ended, and are out of scope.

**Not mirrored — administrative and privacy surfaces.** The crawler captured pages that were never meant as content: guestbook admin screens, moderator IP-reveal pages, member-profile editors, per-member email forms. These exposed third-party details (IP addresses, contact details) and are not part of the resurrection.

**Removed — third-party identity.** Real names, email addresses, ICQ/AIM numbers, and photographs of people other than the site's author. Pseudonymous handles stay; the community was pseudonymous by design, and the handles are the community.

**Removed or edited — content curation.** A small number of jokes and passages whose premise or vocabulary the author does not care to republish a quarter-century later. Edits are minimal and word-level where possible; whole pages were removed only where the page's premise was the problem. Links to removed pages are left intact and resolve to the site's period 404 page, which is indistinguishable from ordinary linkrot, because that is what it is.

**Insertions.** Exactly two files are not from the archive: `404.html` (the hosting provider's own IIS error page, taken verbatim from a 2003 capture of a missing page) and `cgi-bin/error.html` (new, in period style — the answer to any attempt to post to a board whose Ultimate Bulletin Board license lapsed while nobody was looking).

**Gaps the archive left.** Never captured, so never restored: `/images/divide.gif` (the navigation divider), the boards' `title.gif`, all audio (the MP3s the Music section describes), the `directory.html` frame, several interior pages that were already dead links in 2002, and the 2005 state of the PHP boards' topic list. Where a gap makes a page render imperfectly, it renders imperfectly.

## Ledger

The mirror is 337 archived files; 260 ship. Counts by category, current with the rules file:

| Category | Dropped files | Applied edits |
|----------|---------------|---------------|
| Later-era content (2004-05 capture that slipped the URL filter) | 1 | — |
| Admin, account, and privacy surfaces (profiles, email/post forms, IP-reveal, control panels, login stubs) | 69 | — |
| Third-party identity (names, emails, ICQ/AIM links, member cities, identity rows, one photograph) | 1 | ~390 |
| Content curation (joke pages and lines whose premise was the problem, slur vocabulary) | 6 | ~30 |
| The author's own street address, ICQ, and AIM identifiers | — | 3 |

Every edit is byte-exact and logged with a reason at build time; the build fails if any of sixty-odd forbidden patterns (each removed name, address, number, school, and slur) survives anywhere in the output.

The counter on the homepage reads "1 people have visited this page since July 25th, 2000." It said exactly that in the May 2002 capture, after saying 2676 in December 2000. Nothing was done about this, and nothing will be.
