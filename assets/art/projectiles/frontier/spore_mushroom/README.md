# spore_mushroom projectile

- Generated with built-in imagegen using this monster's existing art as palette/material reference.
- `spore_mushroom_source.png`: unmodified generated original.
- `spore_mushroom_spritesheet.png`: 2x2 flight loop; 4 individual PNGs in `frames/`.
- `spore_mushroom_animations.tres`: Godot SpriteFrames, projectile / 12fps / loop.
- `manifest.json`: exact prompt, provenance, native crop/anchor coordinates and shared display scale.
- Native RGB pixels preserved; alpha>=128 boundary cleanup and integer alignment only. No resizing, color-keying or palette compression.
- Both normal and elite attacks use this species profile through FrontierProjectileArtCatalog.
