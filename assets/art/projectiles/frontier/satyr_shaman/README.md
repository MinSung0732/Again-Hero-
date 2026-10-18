# satyr_shaman projectile

- Generated with built-in imagegen using this monster's existing art as palette/material reference.
- `satyr_shaman_source.png`: unmodified generated original.
- `satyr_shaman_spritesheet.png`: 2x2 flight loop; 4 individual PNGs in `frames/`.
- `satyr_shaman_animations.tres`: Godot SpriteFrames, projectile / 12fps / loop.
- `manifest.json`: exact prompt, provenance, native crop/anchor coordinates and shared display scale.
- Native RGB pixels preserved; alpha>=128 boundary cleanup and integer alignment only. No resizing, color-keying or palette compression.
- Both normal and elite attacks use this species profile through FrontierProjectileArtCatalog.
