# Stage 9 Purifier SFX sources

- `purifier_basic_attack_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Pixabay describes it as a designed magic-spell projectile sound effect.
  - Stored as a dedicated Stage 9 filename; bytes are reused from the already-downloaded Stage 8 Pixabay copy to avoid another external download.
  - Runtime uses a single cached AudioStreamPlayer at -13 dB and pitch_scale 1.12 so repeated basic attacks do not allocate or stack long tails.

Check the linked Pixabay page and Content License if redistributing outside this project.
