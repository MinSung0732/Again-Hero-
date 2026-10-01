# Stage 2 Rogue SFX sources

Stage 2 uses dedicated runtime filenames and the shared Hero SFX loudness policy documented in PROJECT_CONTEXT.md.

- `stage2_rogue_combo_slash_pixabay.mp3`
- `stage2_rogue_blade_storm_pixabay.mp3`
- `stage2_rogue_assassination_hit_pixabay.mp3`
- `stage2_rogue_hit_pixabay.mp3`
  - Sword Slash and Swing — DavidDumaisAudio
  - https://pixabay.com/sound-effects/film-special-effects-sword-slash-and-swing-185432/
  - Pixabay page describes the MP3 as free for use under the Pixabay Content License.
  - The same source bytes are reused under action-specific runtime filenames; pitch/volume distinguish combo, skill, assassination, and hit feedback.

- `stage2_rogue_assassination_start_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
  - Reuses the already-tracked Pixabay portal source bytes in this repository for the shadow-step/vanish cue.

- `stage2_rogue_death_pixabay.mp3`
  - Fatal Body Fall Thud — Universfield
  - https://pixabay.com/sound-effects/film-special-effects-fatal-body-fall-thud-352716/
  - Pixabay page describes the MP3 as free for use under the Pixabay Content License.
  - Used only for the Stage 2 rogue death cue.

Runtime policy:
- Fast combo and repeated assassination hits are quieter than one-shot skills to avoid stacking noise.
- All players use the `SFX` bus.
- Repeated attacks use fixed AudioStreamPlayer pools created once per hero; no per-hit player allocation.
