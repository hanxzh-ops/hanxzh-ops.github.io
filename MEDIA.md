# Media asset policy

This site is served by GitHub Pages, which caps the repo at **1 GB**. Git stores every
version of every binary forever and cannot delta-compress them, so an unmanaged media
folder only ever grows. These rules keep it flat.

## The one rule

**Nothing enters `assets/` at its original size.** Run the ingest script first:

```bash
tools/optimize-media.sh path/to/new-clip.MOV assets/images/projects/<slug>/
```

It resizes, re-encodes, strips camera metadata, and writes a web-ready file. The
original stays where it was — do not move it into the repo.

## Tiers

| Tier | What | Where |
|---|---|---|
| 1 | Diagrams, plots, SVG, screenshots, photos, short loops | Committed in `assets/` |
| 2 | Demo video | Committed, but only after re-encoding (see budget below) |
| 3 | Camera originals (`.MOV`, `.HEIC`), CAD source, raw exports | **Never committed** — cloud storage |

Tier 3 extensions are in `.gitignore`. That is deliberate: if `git add` seems to skip
your file, it is Tier 3 and needs a derivative instead.

## Budgets

| Asset | Limit |
|---|---|
| Photo / screenshot | ≤ 1600 px long side, ≤ 500 KB, JPEG q82 progressive |
| Diagram / plot with transparency | PNG, ≤ 1600 px, else convert to JPEG |
| Video | ≤ 1280 px long side, H.264 CRF 26, `+faststart`, ≤ 12 MB |
| Animated loop | **mp4, never GIF** — see below |
| Any single page | ≤ 25 MB of total media |

## No GIFs

A GIF is an uncompressed flipbook. `side-walk.gif` was 4.7 MB at 320×240; the same clip
as mp4 is 320 KB — **15× smaller**. Use a muted autoplay video instead:

```html
<video src="/assets/images/projects/<slug>/clip.mp4"
       autoplay loop muted playsinline width="100%"
       aria-label="Describe what the clip shows"></video>
```

`muted` and `playsinline` are both required or mobile Safari will refuse to autoplay.

## Filenames

`lowercase-kebab-case.ext` only. **No spaces, `&`, or parentheses.**

This is not cosmetic. `Prototype GD&T drawing.jpg` shipped as a broken image because the
`&` was URL-encoded to `%26` in the link but not in the filename. Use one extension case
(`.mp4`, never `.MOV`) so references stay predictable.

Layout: `assets/images/projects/<project-slug>/`, where `<slug>` matches the page in
`_projects/`.

## Why not Git LFS

**GitHub Pages does not resolve LFS pointers.** Files tracked by LFS are served as their
pointer text, so every image would break. LFS solves clone size, not the Pages problem.
Do not add a `.gitattributes` filter for media here.

## If the repo gets heavy again

Check what is actually being served before adding storage:

```bash
tools/audit-media.sh
```

It reports per-page media weight, unreferenced files, and anything over budget.
