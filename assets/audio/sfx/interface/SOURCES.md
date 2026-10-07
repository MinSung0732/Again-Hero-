> Superseded for growth/result on 2026-10-08: see `../contextual/SOURCES.md`. Shared fanfare, marimba denial/defeat and duplicate augment-open feedback below describe the previous revision and are no longer active. Click/summon/ultimate/chest and frontend BGM remain active.

# Frontend and gameplay audio polish — 2026-10-08

Edited game-integrated effects downloaded from Pixabay. Source recordings are not shipped as a standalone library. [Pixabay Content License summary](https://pixabay.com/service/license-summary/) permits free use and modification; attribution is optional. Titles, IDs, creators, SHA256, trims, fades, peaks and RMS are recorded in `manifest.json`.

| Source | Creator | Game use |
|---|---|---|
| [Soft UI Click / 147352](https://pixabay.com/sound-effects/film-special-effects-soft-ui-click-147352/) | Universfield | Button click |
| [Magic Teleport Whoosh / 352764](https://pixabay.com/sound-effects/film-special-effects-magic-teleport-whoosh-352764/) | Universfield | Ordinary summon, demon ultimate, quiet elite activation |
| [Level Up Fanfare / 151765](https://pixabay.com/sound-effects/musical-level-up-fanfare-151765/) | Universfield | Committed growth/formation, victory |
| [Coins Dropping into Wooden Box / 467468](https://pixabay.com/sound-effects/coins-dropping-into-wooden-box-467468/) | DRAGON-STUDIO | Chest reward |
| [Marimba Game Over / 250960](https://pixabay.com/sound-effects/film-special-effects-marimba-game-over-250960/) | Universfield | Defeat, soft rejected action |

## Coverage decisions

| Area | Decision |
|---|---|
| Title / lobby / results | Connect existing project-provided `mainlobby.wav` as a processed looping Vorbis track; preserve original WAV. This BGM is not a newly licensed Pixabay track. 191.28 seconds, about 1.7 MB, normalized to -18 LUFS / -3 dBTP; one-second seam crossfade, no runtime processing. Title-to-lobby keeps playback position; battle transition fades out; results play quieter. |
| Stage 1–10 BGM and hero skills | Preserve existing authored phase music, crossfades and SFX. |
| UI buttons / formation / research / monster upgrades | Soft press feedback, richer cue only after successful save/purchase. Reject cue on failed purchase. Hover, scrolling, typing and sliders remain silent. Placeholder relic upgrade has no false success sound. |
| Ordinary summoning | Quiet short cue, coalesced at 0.22 seconds. Transcendent summons retain their dedicated presentation audio. |
| Demon ultimate / elite active skill | One cue at activation, not one per spawned monster or projectile. Elite cue rate limited to once per second. |
| Chest / progression / augment / mutation | Chest once per destruction, progression once per level increase, choice feedback; no EXP-stone ticking. |
| Victory / defeat | SFX one-shot and quieter result BGM; clear combat players first. |
| Gacha / Zeus | Preserve approved sounds and levels. Hero reveal stinger now explicitly routes through SFX. |
| Repeated ordinary attacks, deaths and footsteps | Intentionally omit additional noise. Existing hero hurt/skill audio already carries combat feedback. |

All effects are mono 44.1 kHz PCM16 WAV with short fades. Individual gains are centralized in `src/data/game_audio_catalog.gd` (-10 to -24 dB); original source peaks were reduced before those gains. BGM and SFX follow their independent saved settings. Fixed players, shared stream cache, weak scene ownership, app background suspension, battle pause and exit cleanup prevent unbounded layering and stale audio. Pause-menu UI remains audible.

## Verification

Godot 4.7.2: real stream decoding/durations/bus routing, title-to-lobby continuity, dynamic button feedback without hover noise, duplicate battle attachment, burst summoning, transcendent exclusion, ultimate replacement, paused UI/combat separation, result sound after battle-over, background/resume and scene-exit ownership. Actual WASAPI SFX capture at bus 0 dB: ultimate + chest + victory simultaneous peak 0.31396544 (-10.06 dBFS), nonzero output without clipping in this sampled interval. This is waveform/playback verification, not subjective listening or a guarantee for every battle mixture. Android/export and complete manual playthrough are not verified.
