# Third-party licenses

This project's own code and quest data are MIT-licensed (see [LICENSE](LICENSE)).
That does not extend to bundled third-party assets, which keep their own
license. Currently that's just one font.

## Overpass (bundled font)

- **Files**: [`ForeverDungeonQuests/Fonts/Overpass-Regular.ttf`](ForeverDungeonQuests/Fonts/Overpass-Regular.ttf),
  [`ForeverDungeonQuests/Fonts/Overpass-Bold.ttf`](ForeverDungeonQuests/Fonts/Overpass-Bold.ttf)
- **License**: [SIL Open Font License 1.1](ForeverDungeonQuests/Fonts/LICENSE-Overpass.md)
  (full text bundled alongside the font, per the OFL's own requirement that
  the license travel with the font).
- **Source**: [github.com/googlefonts/overpass](https://github.com/googlefonts/overpass)
  (© 2015 Red Hat, Inc.), pulled from the official `Desktop Fonts/` release,
  unmodified.
- **Why it's here**: used as the addon's default UI font. It's a deliberate
  stand-in for "Expressway" (a common WoW UI font, and EllesmereUI's own
  default) — both Overpass and Expressway are independent interpretations of
  the same U.S. FHWA "Highway Gothic" letterforms, so they read as visually
  similar. Expressway itself is **not** bundled here: it's under a
  proprietary Fontspring EULA that doesn't grant redistribution rights for
  embedding in software without a separate paid license, whereas Overpass's
  OFL explicitly permits exactly that (OFL 1.1, condition 2). See
  [CLAUDE.md](CLAUDE.md) for the full reasoning and the runtime fallback
  chain (real Expressway is still preferred when something else on the
  user's system already provides it).
- **OFL compliance**: condition 2 requires the copyright notice and license
  text to travel with any redistributed copy. Satisfied by
  `Fonts/LICENSE-Overpass.md` sitting alongside the `.ttf` files. Neither
  file has been modified from the upstream release, and the name "Overpass"
  hasn't been changed, so no Reserved Font Name issue applies.
