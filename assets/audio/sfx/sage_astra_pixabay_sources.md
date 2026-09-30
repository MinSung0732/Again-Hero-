# Stage 10 Astra SFX sources

Stage 10 uses dedicated runtime filenames while reusing Pixabay source bytes already stored in this repository, avoiding a redundant network download while preserving the existing source/license trail.

- `sage_astra_basic_attack_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Reuses `purifier_basic_attack_pixabay.mp3`; runtime pitch is slightly brighter.
- `sage_astra_third_attack_pixabay.mp3`
  - powerful spell — SingularitysMarauder
  - https://pixabay.com/sound-effects/film-special-effects-powerful-spell-213833/
  - Reuses `purifier_crown_buff_pixabay.mp3` for the heavier every-third piercing shot.
- `sage_astra_phase_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Reuses `purifier_shield_create_pixabay.mp3` for fluidization entry.

These are the same Pixabay sources already documented by the Stage 8/9 SFX metadata. Check the current linked license terms when redistributing outside this project.


- `sage_astra_ice_pillar_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Used for Skill 1 "빙점폭발" ice-pillar creation. A skill-specific runtime filename reuses the already-stored Pixabay source bytes.

Stage 10 SFX playback reference: basic attack, third attack, fluidization, and ice-pillar creation are all played at `-10 dB` before their intentional pitch differences.
