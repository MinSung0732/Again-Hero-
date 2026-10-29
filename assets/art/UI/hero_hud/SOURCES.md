# Ranked hero HUD and augment controls

Created for Again, Hero? with the built-in `image_gen` tool on 2026-10-28.
Style reference: the existing `hero_hud_atlas.png` (antique gold, violet stone, cyan gems).
Text, slot numbers, hover/pressed/disabled states and input behavior are supplied by Godot.
Original PNGs are retained without bitmap resizing; the lower button uses an AtlasTexture region to omit the outer matte. All controls use nearest filtering and cached textures.

| File | Role |
|---|---|
| `ranked_top_backdrop.png` | Opaque full-height ranked hero top HUD backing; solo backing retained |
| `held_augment_badge.png` | Numbered stored-augment button; 84x84 logical touch target |
| `augment_lower_button.png` | Shared lower/collapse button; source region `(0,85,1983,620)` |

## Final prompts

### ranked_top_backdrop.png

Edit target: this single generated hero HUD background panel. Preserve the panel design, position, proportions, navy stone interior, antique gold/purple frame and cyan gemstones. This asset must cover the ENTIRE top HUD with an opaque background. Change only the background/alpha handling: remove all transparency by filling every transparent outer margin and every partially transparent area with a matching flat dark navy (#101e2c) matte behind the existing panel. Fully opaque rectangular image from edge to edge; no checkerboard, no black empty border, no alpha transparency, no semi-transparent pixels, no soft glow, no blur. Keep sharp pixel-art shapes. Do not add UI, text, health bars, symbols, logos, or any objects. Output a single wide HUD backing asset with the current composition, not a mockup or an atlas.

### held_augment_badge.png

Create ONE production pixel-art UI button background for the fantasy mobile game Again, Hero?. Reference image is palette/style only. Asset: square badge used for a COLLAPSED STORED AUGMENT button at only 72x72 screen pixels. A very simple chunky square medallion with slightly clipped corners, antique gold outer rim, dark violet/navy flat inset, tiny cyan gem accents in the four corners. Large quiet blank center, at least 55% of square area, to overlay a readable 1-4 number in engine. Coarse clear pixel clusters, thick 2-4 logical pixel edges, limited palette matching reference purple stone/gold/cyan. Keep design simple enough at 72px. FRONT view, one button centered filling 96% of image, transparent only outside square/clipped corners. No text, no numbers, no dots, no symbols in center, no arrows, no glow bloom, no blur, no gradients, no mockup, no UI sheet, no characters. Single square button asset.

### augment_lower_button.png

Create ONE production pixel-art UI button background for Again, Hero?, a dark fantasy pixel-art mobile game. Asset: wide rectangular LOWER/COLLAPSE button for the demon augment selection panel, used at about 360x72 logical display size. Match reference antique gold edges and dark violet stone; hero cyan can appear only as tiny corner accents. Shape: restrained rectangular 9-slice friendly button with clipped square corners, modest antique gold bevel trim; left/right straight edges, top/bottom straight repeatable bands, wide completely quiet dark aubergine center occupying at least 75% width and 60% height for the engine's Korean label. Single finished button, not a frame sheet. Strict coarse pixel clusters, sharp hard edges, no blur or soft glow, no text or characters, NO arrows, no central emblem, no labels, no counters, no separate UI parts, no mockup. Fully opaque rectangular background edge to edge, no margins or alpha. Wide approximately 4:1 aspect ratio. It should fit a gothic purple-and-gold augment panel without excessive ornament.
