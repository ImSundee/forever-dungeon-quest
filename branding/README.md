# Branding assets

A stylized arcane portal with the classic WoW "available quest" exclamation
mark in front of it.

| File | Use |
|---|---|
| `logo.svg` / `logo-512.png` | Has a filled dark rounded-square background. Use for GitHub (repo social preview image, README header) or anywhere a logo needs its own backdrop. |
| `icon.svg` / `icon-512.png` / `icon-256.png` | Same emblem, **transparent background**. Use for CurseForge's project icon (CurseForge frames/crops icons itself, so it wants transparency, not another background baked in) or anywhere else that supplies its own frame. |

Both are hand-authored SVG (no external image assets, so no licensing
question — see [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md), which
doesn't need an entry for these). PNGs were rasterized with `rsvg-convert`.
To regenerate after editing the SVGs:

```
rsvg-convert -w 512 -h 512 logo.svg -o logo-512.png
rsvg-convert -w 512 -h 512 icon.svg -o icon-512.png
rsvg-convert -w 256 -h 256 icon.svg -o icon-256.png
```

CurseForge's minimum project icon size is 256x256; 512x512 is provided for
anywhere higher resolution is useful (e.g. GitHub social preview, which
wants 1280x640 — these square logos aren't a full social preview banner,
just the mark itself, in case that's wanted later).
