---
name: seo-fleet
description: Use when asked to audit SEO, fix SEO, add SEO to this repo, or bring a site to the Escoffier fleet SEO contract. Triggers on "audit SEO", "fix SEO", "add SEO to this repo", "bring this site to the fleet SEO contract", "is the head SEO-correct", "why is this page not indexing". For an Astro site fleet whose heads keep drifting.
---

# seo-fleet

A line check for the one station every page shares: the `<head>`. The fleet has 13 site
heads and they drift, so this skill walks any Astro repo against the single canonical
contract (`escoffier-fleet-kit/seo/`), scores it, and then, on request, brings it into
lockstep. Two passes: **AUDIT** reports what is wrong in leverage order, **FIX** adopts
the shared `<Seo>` and reports the before/after delta. The contract is the source of
truth; this skill enforces it, it does not invent rules.

The contract baked in (do not relitigate these): Twitter `@solomonneas`, `trailingSlash:'never'`
(canonical strips the trailing slash, `og:url` and sitemap agree), OG cards 2400x1260 with
dimensions emitted, theme colors `#0d1014` dark / `#f5f2ea` light, dev/preview auto-noindex,
and a cheap GEO layer (llms.txt + `markdownAlt`) because AI-citation lift is near zero so it
gets little effort. The full rationale lives in `escoffier-fleet-kit/seo/README.md`; read it
before reporting a "missing" tag the fleet deliberately dropped.

## AUDIT pass (read-only)

**Never modify the repo during an audit.** Find the head source first: a `BaseLayout.astro`
(or equivalent layout) and whether it imports the shared `src/components/Seo.astro`. A site
that imports `<Seo>` inherits most of the contract for free; a hand-rolled `<head>` must be
checked tag by tag. Walk all five stations. Score each 0-5 (5 = exemplary, 3 = functional with
real gaps, 1 = broken or absent, 0 = actively harmful, e.g. a live `noindex` on production).

| # | Station | What to check |
|---|---------|---------------|
| 1 | Head completeness | Shared `<Seo>` imported, or every tag it emits present by hand: `<title>`, meta description, author, robots, theme-color (dark+light), canonical, full Open Graph block (title/description/type/url/site_name/image + image:alt/width/height/type), Twitter `summary_large_image` card with site+creator `@solomonneas`, JSON-LD graph (`organizationLd` + `softwareApplicationLd`, or `websiteLd` for the hub). Exactly one of each, no duplicates. |
| 2 | Robots policy | `public/robots.txt` is allow-all with a correct `Sitemap:` line for this host (per `robots.txt.tmpl`). Production emits `index, follow`; dev/preview auto-noindex via `import.meta.env.DEV`/`VERCEL_ENV`. No accidental site-wide `noindex` shipped to prod. |
| 3 | Sitemap | `site:` set in `astro.config.mjs` (sitemap and canonical are wrong without it); `@astrojs/sitemap` wired; `trailingSlash:'never'` so sitemap URLs match canonical/`og:url`; `lastmod` present; no trailing slashes in emitted URLs. |
| 4 | Per-page hygiene | Exactly one `<H1>` per page; `<title>` <=60 chars; description 120-160 chars; no two pages sharing a title or description; `og:image` resolves; every `<img>` has meaningful `alt`. |
| 5 | GEO | `public/llms.txt` present; docs/article pages pass `markdownAlt` to a plain-markdown alternate. Cheap layer, low severity, never a critical. |

Station guidance:
- Station 1: a `<Seo>` import does not mean correct usage. Confirm `BaseLayout` still passes a real per-page `title`/`description` and uses `composeTitle`, not a hardcoded brand string on every page.
- Station 4 needs cross-page work, not one file: collect every page's title and description and diff them for duplicates. A single-page check cannot find a duplicate.
- Respect `.gitignore`; never audit `node_modules/`, `dist/`, or `.vercel/`.

### Report contract (AUDIT)

Severity: **critical** (deindexed, broken canonical, prod `noindex`) / **high** (drifted head, missing OG, no `site:`) / **medium** (duplicate titles, length violations) / **low** (alt text, GEO) / **info**. Effort: **S** (under 30 min) / **M** (under half a day) / **L** (multi-day).

```markdown
# seo-fleet audit: <repo> (<date>)

## Verdict
One paragraph: head adopted or hand-rolled, the single highest-leverage fix,
and whether the site is fleet-correct, drifted, or deindexed.

## Scorecard
| Station | Score (0-5) | Summary |

## Findings
Grouped by severity, descending. Each:
### [SEVERITY] Short imperative title
- **Station:** which station produced this
- **Where:** file:line or "repo-wide" (must be checkable)
- **What:** one or two sentences, concrete (cite the contract clause)
- **Why it matters:** the SEO consequence
- **Fix:** the specific action (the FIX-pass step that resolves it)
- **Effort:** S / M / L

## Backlog
Findings re-sorted by leverage, numbered, one line each:
`N. [SEVERITY/EFFORT] title (station)`. The deindex bugs float to the top.

## Not checked
What the audit skipped and why (e.g. live indexing status, Lighthouse).
```

## FIX pass

Branch first (`seo-fleet/<repo>-<date>`), clean tree, never the default branch. Work the audit
backlog in leverage order, smallest change per finding. Adoption steps (contract README steps 1-5):

1. **`astro.config.mjs`:** set `site: 'https://<domain>'` and `trailingSlash: 'never'`. Leave `build.format` at the default `directory` (`format:'file'` breaks `Astro.url.pathname`). Wire `@astrojs/sitemap` if absent.
2. **Bring in the shared component.** In the fleet, run `escoffier-fleet-kit/bin/fleet-sync.sh` once `src/components/Seo.astro` exists, or copy `seo/seo.ts` -> `src/lib/seo.ts` and `seo/Seo.astro` -> `src/components/Seo.astro`. Outside the fleet, vendor a copy of both and note the source in a header comment. Do **not** edit the copy inside a site repo; it is overwritten by fleet-sync.
3. **Convert the hand-rolled `<head>` to `<Seo>`.** Keep charset, viewport, favicon, analytics, and the theme-init script in `BaseLayout`. Replace the title/meta/OG/Twitter/JSON-LD block with `<Seo siteName=... title={composeTitle(...)} description=... jsonLd={graph([...])} />`. The hub uses `websiteLd`; app sites use `softwareApplicationLd`; docs/article pages pass `ogType="article"`, `publishedDate`, `modifiedDate`, `breadcrumbLd`.
4. **Fix robots + sitemap.** Write `public/robots.txt` from `robots.txt.tmpl` with this host's sitemap line. Confirm prod gets `index, follow` and preview stays noindexed.
5. **GEO, if cheap.** Add `public/llms.txt`; pass `markdownAlt` on doc pages.

After every fix, report the **before/after delta**: count of contract tags present before vs after, duplicate titles/descriptions resolved, canonical-slash form fixed, robots/sitemap corrected. One commit per finding, message naming the effect.

## Stop conditions (surface, do not guess)

Park and report, do not auto-apply, anything that is: changing the production `site:` domain on a repo you are unsure owns it, editing a fleet-synced copy by hand (edit the kit and re-sync instead), or a change that would alter live indexing in a way the contract does not settle. The user decides those.

## Before claiming done

- **REQUIRED SUB-SKILL:** run [check](../check/SKILL.md) before saying the head is fixed. "Adopted `<Seo>`" is proved by building the site and confirming exactly one of each meta tag, canonical with no trailing slash, and JSON-LD that parses, not by the import existing. A drifted head that "should be correct now" is not verified.
- Re-run the AUDIT pass after fixing; it should come back clean on what you changed.
- **Sub-skill:** any robots.txt, llms.txt, or README copy that goes public goes through [plate](../plate/SKILL.md) first; do not ship a real host in an example or leak an internal path.

## Common mistakes

- Reporting a "missing" tag the fleet deliberately dropped. Read the contract README first; baked-in decisions are info, not findings.
- Treating a `<Seo>` import as proof the head is correct, without confirming each page passes a real per-page title and description.
- Checking one page for duplicate titles. Duplicates only show across pages; collect them all.
- Leaving `trailingSlash` unset, so canonical, `og:url`, and the sitemap disagree on the slash form.
- Editing the synced copy of `seo.ts`/`Seo.astro` inside a site repo; the next `fleet-sync.sh` reverts it. Edit the kit.
- Adding the GEO layer with the urgency of a deindex bug. It is low-leverage by fleet decision; sequence it last.
- Claiming the head is fixed off the diff, never building. Run [check](../check/SKILL.md). Public copy ships through [plate](../plate/SKILL.md).
