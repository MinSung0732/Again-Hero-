# Battle Castle V3 — asset provenance
Final artifacts are the copied PNG files in this directory; no original outputs were deleted.
Generated 2026-10-05 with the built-in image generation tool (not CLI). Original outputs copied unchanged; alpha preserved. No character artwork generated or replaced. All labels and gameplay remain native Godot controls/actors. Regions are assembled at runtime without raster editing.

- `castle_surround.png`: 1024×1536; transparent central aperture. Header and side regions used as passive screen framing, not world collision.
- `flagstone_floor.png`: 1254×1254; repeated at 684×700 world units. Seamless intent; low-contrast joins are visually checked, not mathematically guaranteed.
- `gold_panel.png`: 1774×887; corner/rail/center-jewel atlas regions assembled separately to preserve decorations.

## Final prompts

### Castle surround

Use case: stylized-concept
Asset type: production pixel-art castle architectural surround for a portrait mobile fantasy battle game, NOT a UI mockup.
Primary request: ornate sinister dark-purple castle interior FRAME. Portrait 1024x1536. A thick solid castle back wall spans the top 560 pixels, with chunky dark violet masonry, central gothic closed doorway at x512 y400, skull crest, hanging purple skull banners on both sides, bronze chains draped between sconces, warm orange torches. The top 300 pixels should be quieter dark masonry because live HUD is placed over it. Left and right stone architectural columns occupy ONLY outer 100 pixels below y560, with layered cracked stone bases and restrained torches around y850 and y1300. At bottom only a slim stone ledge 50 pixels tall. The central rectangle from x100 to924 and y560 to1486 must be COMPLETELY TRANSPARENT, an empty hole for the real moving battle viewport, NOT filled with floor/background. Frame perimeter itself opaque. Symmetrical weight, detailed bevels and cracks, subtle purple highlights and orange fire illumination, visually believable fortress architecture rather than a gold UI border.
Style/medium: premium hand-crafted crisp 2D pixel art, chunky clearly visible pixel clusters, limited dark navy/eggplant/violet stone palette, amber torch highlights. Straight front-facing orthographic architectural elevation. No perspective vanishing floor, no characters, no labels, no UI boxes, no numbers, no logo, no watermark. Actual alpha transparency in central aperture and outside any irregular outer silhouette. Do not render checkerboard.

### Flagstone floor

Use case: stylized-concept
Asset type: seamless top-down pixel-art dungeon flagstone floor texture for an actual moving 2D mobile battle world.
Primary request: square 1024x1024 texture that tiles seamlessly on all four edges. A 4x4 arrangement of large dark worn purple-black castle stone slabs, subtly varied in sizes and staggered horizontal joints. Thin low-contrast dark mortar seams, chipped corners, sparse small cracks, tiny dust and scratched stone details. Readable stone material but very subdued so colorful small fighting sprites stand out. Dark slate navy and muted eggplant-purple, not bright violet. Flat overhead orthographic view with absolutely no perspective, no walls or props. Restrained crisp pixel clusters and hand-crafted limited palette, premium detailed pixel dungeon environment style. No black thick checkerboard grid, no rugs, no glowing symbols, no characters, no text, no watermark, no lighting gradient/vignette, no transparent border. All edges seamlessly repeat. Uniform neutral illumination.

### Gold panel

Use case: stylized-concept
Asset type: single reusable blank nine-slice panel for a premium dark fantasy pixel-art mobile RPG battle HUD.
Primary request: a single wide rectangular panel, 1536x768, centered with 24px transparent exterior padding. Inner field entirely empty near-black midnight purple, very subtle restrained stone texture. Thick beautifully crafted gold metal frame with orange-gold shadows and pale amber highlights, triple layered bevel, angular stepped corner plates, tiny amethyst diamonds precisely at corners and midpoint of top and bottom edges. Straight continuous edge rails between corners that can be stretched by a nine-patch UI; all corner decorations confined within outer 130px each side, no ornaments protruding into text area. Gold edge thickness around 30px, restrained violet inner outline. Crisp intentional chunky pixel clusters, polished retro high-end fantasy interface. Orthographic front facing, perfectly axis aligned rectangular silhouette. It must be an asset, NOT a full interface or multiple panels. No text, no letters, no numbers, no logos, no characters, no icons in center. Actual transparent alpha outside the panel. Dark opaque center. No checkerboard.
