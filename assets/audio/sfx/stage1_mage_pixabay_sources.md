# Stage 1 Apprentice Mage SFX sources

Stage 1 uses dedicated runtime filenames while reusing Pixabay source bytes already stored in this repository. This avoids redundant binary downloads and keeps source/license tracing consistent with Stages 8-10.

- `stage1_mage_basic_attack_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Basic magic projectile. Reuses `purifier_basic_attack_pixabay.mp3`.

- `stage1_mage_barrier_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Arcane Barrier activation. Reuses `purifier_shield_create_pixabay.mp3`.

- `stage1_mage_arcane_field_pixabay.mp3`
  - powerful spell — SingularitysMarauder
  - https://pixabay.com/sound-effects/film-special-effects-powerful-spell-213833/
  - Arcane Field cast/channel start. Reuses `purifier_crown_buff_pixabay.mp3`.

- `stage1_mage_arcane_piercer_pixabay.mp3`
  - Loud Explosion — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-loud-explosion-425457/
  - Arcane Piercer launch cue. Reuses `sage_astra_blackspot_explosion_pixabay.mp3`.

- `stage1_mage_hit_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Low-volume, high-pitch hit feedback. Reuses `purifier_basic_attack_pixabay.mp3`.

- `stage1_mage_death_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Low-pitch magical collapse cue on death. Reuses `purifier_shield_create_pixabay.mp3`.

The linked Pixabay source pages are tracked for licensing. Check current Pixabay Content License terms when redistributing outside this project.


## Clean impact replacement revision

The previously reused Pixabay `Loud Explosion` MP3 was retired project-wide because repeated/high-pitch playback produced objectionable compressed distortion.
Runtime explosion/impact aliases in this stage now use the already-tracked Kenney Sci-Fi Sounds CC0 `explosionCrunch` WAV sources instead:
- `explosionCrunch_000` / `alchemist_failed_boom_cauldron.wav` for compact/fast impacts.
- `explosionCrunch_001` / `alchemist_failed_boom_skill3.wav` for larger/heavier impacts.

Any older mapping in this document that names `Loud Explosion` is historical and is superseded by this revision.
