# Stage 9 Purifier SFX sources

Stage 9 uses dedicated runtime filenames, while reusing the already-downloaded Pixabay source bytes in this repository. This avoids another network download and keeps the source/license traceable.

- `purifier_basic_attack_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Basic holy projectile. Runtime pitch: 1.12.

- `purifier_shield_create_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Divine Protection activation. Dedicated filename reuses the existing Stage 8 downloaded Pixabay blob.

- `purifier_shield_break_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Divine Protection break/end. Runtime pitch is lowered so it reads as a heavier collapse instead of the basic attack.

- `purifier_crown_buff_pixabay.mp3`
  - powerful spell — SingularitysMarauder
  - https://pixabay.com/sound-effects/film-special-effects-powerful-spell-213833/
  - Crown of Courage stack application.

- `purifier_orb_create_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Purification Orb creation/launch. Reuses the already-downloaded `purifier_shield_create_pixabay.mp3` source bytes under a skill-specific runtime filename.

- `purifier_orb_explosion_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Purification Orb chain explosion. Reuses the already-downloaded `purifier_shield_break_pixabay.mp3` source bytes under a skill-specific runtime filename.

All linked Pixabay pages state free use under the Pixabay Content License. Check the current linked license terms when redistributing outside this project.
