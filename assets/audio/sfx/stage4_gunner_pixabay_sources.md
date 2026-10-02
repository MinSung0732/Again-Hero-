# Stage 4 Gunner SFX sources

Stage 4 is the pistol gunner. Runtime events are mapped to the actual combat actions:
- basic attack -> pistol shot
- reload -> short weapon-mechanism cue
- `백스텝` -> fast movement / whoosh cue
- `실린더타격` -> close-range impact cue
- `데드아이` -> focus/start cue + very fast repeated pistol shots
- hit / death -> subdued damage and body-fall feedback

Pixabay reference candidates checked for this pass:
- `pistol shot` — mrfriends
  - https://pixabay.com/sound-effects/film-special-effects-pistol-shot-233473/
  - Pixabay describes it as a realistic pistol shot and lists it as free for use under the Pixabay Content License.
- `Gun Reload 2` — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-gun-reload-2-511308/
  - Reload / chamber / magazine mechanism reference. Pixabay lists it as free for use under the Pixabay Content License.
- `Simple Whoosh` — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-simple-whoosh-382724/
  - Reference target for `백스텝`. Pixabay lists it as free for use under the Pixabay Content License.

To keep this pass fast and avoid introducing unverified external binary bytes through the connector, the runtime files below reuse Pixabay source blobs already tracked in this repository:
- `stage4_gunner_gunshot_pixabay.mp3` -> existing `Loud Explosion` blob, shortened perceptually by high runtime pitch / low gain
- `stage4_gunner_reload_pixabay.mp3` -> existing `Sword Slash and Swing` blob, low gain / lower pitch for a compact mechanical cue
- `stage4_gunner_backstep_pixabay.mp3` -> existing `the portal` blob, brighter pitch for movement
- `stage4_gunner_cylinder_pixabay.mp3` -> existing `Loud Explosion` blob, lower pitch for the ground/impact effect
- `stage4_gunner_deadeye_start_pixabay.mp3` -> existing `Sword Slash and Swing` blob, short focus/cocking cue
- `stage4_gunner_deadeye_shot_pixabay.mp3` -> existing `Loud Explosion` blob, high pitch and very low gain for 0.08s repeat density
- `stage4_gunner_hit_pixabay.mp3` -> existing `Sword Slash and Swing` blob, quiet hit cue
- `stage4_gunner_death_pixabay.mp3` -> existing `Fatal Body Fall Thud` blob

Tracked Pixabay sources reused here:
- Loud Explosion — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-loud-explosion-425457/
- Sword Slash and Swing — DavidDumaisAudio
  - https://pixabay.com/sound-effects/film-special-effects-sword-slash-and-swing-185432/
- the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
- Fatal Body Fall Thud — Universfield
  - https://pixabay.com/sound-effects/film-special-effects-fatal-body-fall-thud-352716/

Performance policy:
- Basic pistol shots use a fixed 3-player pool.
- Deadeye's 0.08-second repeated shots use a fixed 4-player pool and a much quieter mix.
- Reload, backstep, cylinder, deadeye-start, hit, and death use persistent AudioStreamPlayers.
- No per-shot/per-frame AudioStreamPlayer allocation is added.


## Clean impact replacement revision

The previously reused Pixabay `Loud Explosion` MP3 was retired project-wide because repeated/high-pitch playback produced objectionable compressed distortion.
Runtime explosion/impact aliases in this stage now use the already-tracked Kenney Sci-Fi Sounds CC0 `explosionCrunch` WAV sources instead:
- `explosionCrunch_000` / `alchemist_failed_boom_cauldron.wav` for compact/fast impacts.
- `explosionCrunch_001` / `alchemist_failed_boom_skill3.wav` for larger/heavier impacts.

Any older mapping in this document that names `Loud Explosion` is historical and is superseded by this revision.


## Clean Revolver Reload replacement revision

The Stage 4 gunner reload now uses the requested Pixabay asset directly instead of the older placeholder/reused cue:

- Clean Revolver Reload — Dredile (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-clean-revolver-reload-6889/
  - Pixabay asset ID: 6889
  - Runtime file: `stage4_gunner_reload_pixabay.mp3`

Mix update:
- previous runtime mix: `HERO_SFX_DB_REGULAR_SKILL - 5.0` (effective -17 dB), pitch 0.72
- current runtime mix: `HERO_SFX_DB_REGULAR_SKILL + 1.0` (effective -11 dB), pitch 1.0
- The +6 dB increase brings the relatively quiet mechanical reload closer to the established hero SFX band without touching the global SFX bus.


## Reload timing trim revision

The requested Clean Revolver Reload source is about 3.392 seconds long, while the Stage 4 in-game reload is 2.4 seconds. Instead of pitch-shifting the sound, runtime playback now starts 1.05 seconds into the source clip. This preserves the later cylinder/revolver mechanism section at natural pitch and gives about 2.34 seconds of audible reload, fitting the animation window without editing the source MP3 bytes.
