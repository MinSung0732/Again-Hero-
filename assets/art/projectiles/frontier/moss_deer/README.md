# moss_deer projectile

- Generated with built-in imagegen using this monster's existing art as palette/material reference.
- `moss_deer_source.png`: unmodified generated original.
- `moss_deer_spritesheet.png`: 2x2 flight loop; 4 individual PNGs in `frames/`.
- `moss_deer_animations.tres`: Godot SpriteFrames, projectile / 12fps / loop.
- `manifest.json`: exact prompt, provenance, native crop/anchor coordinates and shared display scale.
- Native RGB pixels preserved; alpha>=128 boundary cleanup and integer alignment only. No resizing, color-keying or palette compression.
- Both normal and elite attacks use this species profile through FrontierProjectileArtCatalog.
