# Stage 3 Fighter SFX sources

Stage 3 maps sound by the actual combat effect/skill meaning:
- effect2 `slash` -> sword swing/slash
- effect3 `thrust` -> sharper sword attack
- effect4 `guard_aura` -> guard activation
- effect1 `guard_release` -> heavy block/release impact
- effect5 `charge_impact` -> ground-impact burst

Pixabay comparison notes:
- `Sword Slash and Swing` — DavidDumaisAudio
  - https://pixabay.com/sound-effects/film-special-effects-sword-slash-and-swing-185432/
  - Best fit for Stage 3 slash/basic weapon motion. The already-tracked Stage 2 source bytes are reused.
- `Shield Block Shortsword` — SectionSound
  - https://pixabay.com/sound-effects/film-special-effects-shield-block-shortsword-143940/
  - Compared as the closest semantic match for the physical shield-block cue.
- `Blade Piercing Body` — Universfield
  - https://pixabay.com/sound-effects/film-special-effects-blade-piercing-body-352462/
  - Compared as the closest semantic match for the thrust/stab cue.
- `the portal` — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Existing tracked Pixabay source reused for the guard-aura activation because the Stage 3 visual is an energy aura rather than only a metal clash.
- `Loud Explosion` — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-loud-explosion-425457/
  - Existing tracked Pixabay source reused at reduced gain for the chained ground-impact part of `검방 돌격`.
- `Fatal Body Fall Thud` — Universfield
  - https://pixabay.com/sound-effects/film-special-effects-fatal-body-fall-thud-352716/
  - Existing tracked Pixabay source reused for the armored fighter death cue.

Runtime files:
- `stage3_fighter_slash_pixabay.mp3` -> existing Sword Slash and Swing blob
- `stage3_fighter_thrust_pixabay.mp3` -> existing Sword Slash and Swing blob, differentiated by runtime pitch
- `stage3_fighter_guard_start_pixabay.mp3` -> existing portal blob
- `stage3_fighter_guard_release_pixabay.mp3` -> existing Sword Slash and Swing blob, lower pitch
- `stage3_fighter_charge_impact_pixabay.mp3` -> existing Loud Explosion blob
- `stage3_fighter_hit_pixabay.mp3` -> existing Sword Slash and Swing blob, quiet hit feedback
- `stage3_fighter_death_pixabay.mp3` -> existing Fatal Body Fall Thud blob

All linked Pixabay pages used or compared for this pass identify the media as free for use under the Pixabay Content License. Re-check the current linked license terms when redistributing outside this project.

Performance policy:
- Basic slash/thrust and chained charge impacts use fixed AudioStreamPlayer pools created once per Hero.
- Guard start/release, hit, and death use persistent players.
- No per-hit/per-frame AudioStreamPlayer allocation is added.
