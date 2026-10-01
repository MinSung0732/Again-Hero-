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

The MP3 runtime assets above are committed directly under `assets/audio/sfx/`; Godot loads the checked-in file from `res://` and does not depend on a remote URL at runtime.


- `sage_astra_radiance_create_pixabay.mp3`
  - powerful spell — SingularitysMarauder
  - https://pixabay.com/sound-effects/film-special-effects-powerful-spell-213833/
  - Skill 2 "광휘의 특이점" cast/creation cue. Reuses the already-committed Pixabay source bytes from `purifier_crown_buff_pixabay.mp3`.
- `sage_astra_radiance_explosion_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Skill 2 orb explosion cue. Reuses the already-committed Pixabay source bytes from `purifier_basic_attack_pixabay.mp3`.

Both Skill 2 runtime MP3s are committed directly under `assets/audio/sfx/` and use the Stage 10 SFX playback reference of `-10 dB`.


- `sage_astra_condensation_stack_pixabay.mp3`
  - powerful spell — SingularitysMarauder
  - https://pixabay.com/sound-effects/powerful-spell-213833/
  - Skill 3 "마력응축" stack-add cue. Reuses the already-committed Pixabay source bytes with a brighter runtime pitch.
- `sage_astra_condensation_release_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Skill 3 8-stack consume / empowerment cue. Reuses the already-committed Pixabay source bytes.

Both Skill 3 MP3 runtime files are committed directly under `assets/audio/sfx/` and use the Stage 10 SFX playback reference of `-10 dB`.


- Stage 10 Skill 4 "스타라이트" meteor impacts reuse `sage_astra_radiance_explosion_pixabay.mp3`.
  - Source: Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - The existing checked-in Pixabay MP3 is reused directly to avoid another runtime binary and preserve pooling/audio-tail behavior.


- `sage_astra_annihilation_create_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Skill 5 "소멸" point creation cue. Reuses the already-tracked Pixabay source bytes from `sage_astra_condensation_release_pixabay.mp3`, played lower for a darker portal/void opening.
- `sage_astra_annihilation_execute_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
  - Skill 5 execution cue. Reuses the already-tracked Pixabay source bytes from `purifier_gungnir_explosion_pixabay.mp3`, played lower for a heavier consume/execute impact.

Both source pages currently state free use under the Pixabay Content License. The dedicated runtime filenames keep Skill 5 audio wiring explicit while reusing already-downloaded source blobs.


- `sage_astra_blackspot_explosion_pixabay.mp3`
  - Loud Explosion — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-loud-explosion-425457/
  - Stage 10 Skill 6 "흑점폭발" detonation cue.
  - Source page lists the MP3 for free use under the Pixabay Content License.


## Clean impact replacement revision

The previously reused Pixabay `Loud Explosion` MP3 was retired project-wide because repeated/high-pitch playback produced objectionable compressed distortion.
Runtime explosion/impact aliases in this stage now use the already-tracked Kenney Sci-Fi Sounds CC0 `explosionCrunch` WAV sources instead:
- `explosionCrunch_000` / `alchemist_failed_boom_cauldron.wav` for compact/fast impacts.
- `explosionCrunch_001` / `alchemist_failed_boom_skill3.wav` for larger/heavier impacts.

Any older mapping in this document that names `Loud Explosion` is historical and is superseded by this revision.
