---
name: again-hero-pixel-art
description: Create, edit, extract, package, or review character pixel-art sprites and portraits for 「용사, 또 너야? / Again, Hero?」 using the project's shared 32×32 SD sprite, 64×64 portrait, animation, anchor, transparency, and delivery standards. Use only for character art in MinSung0732/Again-Hero-; do not use for UI art or unrelated pixel-art projects.
---

# Again, Hero Character Pixel Art

Use this skill only for character pixel-art work in the `MinSung0732/Again-Hero-` repository.

## Required source

Before generating, editing, extracting, packaging, or reviewing assets, read `docs/PIXEL_ART_CHARACTER_STANDARD.md` completely. Also read `HERO_RESOURCE_STANDARD.txt` when the asset is a Hero or lobby portrait. The repository documents are authoritative over this installed skill.

Inspect these files as visual style references when available:

- `assets/art/heroes/stage8_summoner/stage8_hero_spritesheet.png`
- `assets/art/heroes/stage8_summoner/8stage_hero_portrait.png`
- the current Stage 1 mage sprite used as the screen-size baseline

The Stage 8 character is not a design template. Match pixel density, facial readability, colored outlines, three-step shading, SD proportions, silhouette clarity, and portrait composition while following the new character's own design brief.

## Non-negotiable output rules

- Make game-ready pixel art with no antialiasing, blur, bilinear interpolation, semi-transparent outline pixels, text, numbers, UI, grid, or cell borders.
- Use fully transparent PNG backgrounds, top-left lighting, restrained clear colors, and dark colored outlines rather than pure black everywhere.
- Target a 32×32 character body and the Stage 1 mage's on-screen mass. Keep the body-center X and foot Y stable across frames; enlarge the cell rather than the character when attacks or equipment need space.
- Default to right-facing side view and `idle 4 / walk 6 / attack 6 / hit 3 / death 4`, unless the brief explicitly replaces or adds `run`, `cast`, `summon`, or `special`.
- Make portraits as native 64×64 upper-body pixel art with the face centered and enough head and shoulders visible. Do not downscale a high-resolution illustration.
- Preserve the requested character's unique hair, eyes, clothing, equipment, colors, profession, and silhouette.

## Delivery and verification

When practical, deliver a Sprite Sheet PNG, individual frame PNGs, a 64×64 portrait, `manifest.json`, and a ZIP. Use names such as `idle_01.png`, `walk_01.png`, `attack_01.png`, `hit_01.png`, and `death_01.png`.

Verify RGBA transparency, frame counts, body-center X, foot Y, loop continuity, nearest-neighbor integrity, sprite-sheet/frame equality, Stage 1 screen-size consistency, portrait dimensions/composition, manifest paths, and ZIP contents. Do not claim visual or runtime verification that was not actually performed.
