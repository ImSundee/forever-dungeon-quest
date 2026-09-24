# Branding assets

A stylized arcane portal with the classic WoW "available quest" exclamation
mark in front of it.

| File | Use |
|---|---|
| `logo.svg` / `logo-512.png` | Emblem with a filled dark rounded-square background. Use anywhere a logo needs its own backdrop. |
| `icon.svg` / `icon-512.png` / `icon-256.png` | Same emblem, **transparent background**. Use for CurseForge's project icon (CurseForge frames/crops icons itself, so it wants transparency, not another background baked in) or anywhere else that supplies its own frame. |
| `banner.svg` / `banner.png` | Full 1280x640 GitHub social preview card: emblem + "Forever Dungeon Quests" title + tagline. Set this at **GitHub repo Settings → General → Social preview**. |

All hand-authored SVG (no external image assets, so no licensing question —
see [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md), which doesn't
need an entry for any of these). The banner's text uses Overpass (the same
OFL-licensed font bundled for the addon itself, `ForeverDungeonQuests/Fonts/`)
via `font-family="Overpass"` — regenerating the PNG requires Overpass to be
installed/discoverable by whatever SVG renderer you use (e.g. copy
`ForeverDungeonQuests/Fonts/Overpass-*.ttf` into `~/.local/share/fonts/` and
run `fc-cache -f` before running `rsvg-convert`, on Linux).

PNGs were rasterized with `rsvg-convert`. To regenerate after editing the
SVGs:

```
rsvg-convert -w 512 -h 512 logo.svg -o logo-512.png
rsvg-convert -w 512 -h 512 icon.svg -o icon-512.png
rsvg-convert -w 256 -h 256 icon.svg -o icon-256.png
rsvg-convert -w 1280 -h 640 banner.svg -o banner.png
```

CurseForge's minimum project icon size is 256x256; 512x512 is provided for
anywhere higher resolution is useful. GitHub's social preview image wants
exactly 1280x640, which `banner.png` already matches.
