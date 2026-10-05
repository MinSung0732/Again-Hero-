# Main mode UI icons and selector frames

Project-authored native SVG artwork for Again, Hero?, 2026-10-05.
No downloaded or third-party artwork; no generated character portraits.

Design brief: match the existing crisp pixel-shaped violet / gold lobby.
- demon: horned crowned skull, ivory / amethyst / gold
- hero: medieval helmet, lavender metal / gold crest
- ranked: gold trophy with amethyst inset
- easy: shield and light check mark
- hard: amethyst flame with gold core
- idle / active: stepped clipped-corner nine-patch frames, muted metal versus purple gold highlight

64×64 icons have true transparent padding. Nearest filtering is inherited from
the pixel UI. Selector frames are 320×92 SVGs with 22-pixel nine-patch borders.
Use `lobby_main_modes_view.style_button` so text stays native, translatable and
independent of icons. Frame and icon textures are cached once at install;
`PresentationWarmup` retains the seven assets before the lobby opens.
Existing UI behavior, progression and preparation-only mode gates are unchanged.
