# Stage 6 Berserker SFX sources

Stage 6 is the madness berserker (`madness_hero`, `berserker_madness`).

Gameplay / visual mapping used for audio hooks:
- basic attack -> melee slash; during madness the same attack can run at 3x attack-speed multiplier
- `혈검술 제1식` -> three emitted blood sword waves
- `혈검술 제2식` -> ground slam followed by branching blood paths
- `혈검술 제3식` -> fast blood dash, then blood-orb recovery
- `혈검술 제4식` -> circular spin slash / knockback
- madness entry -> persistent rage visual starts at `_start_berserker_madness()`

Pixabay references checked:
- Sword Slash and Swing — DavidDumaisAudio
  - https://pixabay.com/sound-effects/film-special-effects-sword-slash-and-swing-185432/
  - 0:02 MP3; realistic sword slash/swing; Pixabay Content License.
- Heavy Swing search / Heavy greatsword slash candidates
  - https://pixabay.com/sound-effects/search/heavy%20swing/
  - Used as the tonal reference for `혈검술 제1식` and the heavier spin slash.
- Ground Impact / Boulder Impact candidates
  - https://pixabay.com/sound-effects/search/ground%20impact/
  - Used as the reference for `혈검술 제2식` ground slam.
- Sword Whoosh / swipe candidates
  - https://pixabay.com/sound-effects/search/sword%20whoosh/
  - Used as the reference for `혈검술 제3식` dash.
- Human Roar — Universfield
  - https://pixabay.com/sound-effects/people-human-roar-250239/
  - 0:01 MP3; Human Roar / Battle Cry; Pixabay Content License.
- Male Angry Growl — freesound_community (usamah)
  - https://pixabay.com/sound-effects/people-male-angry-growl-6932/
  - 0:04 MP3; Growl / Grumble / Angry / Human / Man; Pixabay Content License.
  - The original Freesound source is CC0 and describes it as a male angry growl with closed mouth.
- Fatal Body Fall Thud — existing tracked Pixabay source
  - Reused for Stage 6 death.

Runtime-byte note:
The current connector can inspect Pixabay pages and license metadata but does not expose the direct downloadable MP3 bytes for newly selected pages. This commit therefore does not claim the new Human Roar / Male Angry Growl MP3 was downloaded.

For combat skills, already-tracked Pixabay source bytes are reused under Stage 6-specific runtime paths:
- `stage6_berserker_basic_slash_pixabay.mp3` -> existing Sword Slash and Swing blob
- `stage6_berserker_blood_wave_pixabay.mp3` -> existing Sword Slash and Swing blob
- `stage6_berserker_ground_slam_pixabay.mp3` -> existing Loud Explosion blob, low-pitched as a heavy slam
- `stage6_berserker_dash_pixabay.mp3` -> existing the portal blob, pitched as a fast movement cue
- `stage6_berserker_spin_slash_pixabay.mp3` -> existing Sword Slash and Swing blob
- `stage6_berserker_hit_pixabay.mp3` -> existing Sword Slash and Swing blob
- `stage6_berserker_death_pixabay.mp3` -> existing Fatal Body Fall Thud blob

Madness-entry limitation:
- `Human Roar` and `Male Angry Growl` are the selected vocal targets.
- Because their direct Pixabay bytes are not available through this connector, `stage6_berserker_madness_roar_pixabay.mp3` temporarily aliases the already-tracked Pixabay `the portal` source at a very low pitch (0.56) to create a dark growl-like entry layer.
- This is intentionally documented as a temporary tonal stand-in, not as the downloaded male voice file. The runtime hook is final, so swapping in the true Pixabay vocal later only requires replacing this one asset.

Performance:
- Basic attacks use a fixed 4-player pool because madness can triple attack speed.
- Blood Sword First Form waves use a fixed 3-player pool.
- Other skills, madness entry, hit, and death reuse persistent players.
- No per-hit/per-frame AudioStreamPlayer creation is added.


## Clean impact replacement revision

The previously reused Pixabay `Loud Explosion` MP3 was retired project-wide because repeated/high-pitch playback produced objectionable compressed distortion.
Runtime explosion/impact aliases in this stage now use the already-tracked Kenney Sci-Fi Sounds CC0 `explosionCrunch` WAV sources instead:
- `explosionCrunch_000` / `alchemist_failed_boom_cauldron.wav` for compact/fast impacts.
- `explosionCrunch_001` / `alchemist_failed_boom_skill3.wav` for larger/heavier impacts.

Any older mapping in this document that names `Loud Explosion` is historical and is superseded by this revision.
