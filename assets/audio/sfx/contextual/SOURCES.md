# Contextual SFX replacement — 2026-10-08

The source action/material and actual event determine the sound. These are 17 newly downloaded, distinct Pixabay source recordings, not copies of existing game sounds with renamed files or changed pitch. Edited mono 44.1 kHz PCM16 WAVs are integrated into this game; original recordings are not distributed as a standalone library. [Pixabay Content License](https://pixabay.com/service/license-summary/) permits free use and modification, with optional attribution. Full SHA256, source IDs, edits, durations and levels are in `manifest.json`.

| Runtime cue | Action / material | Source / creator |
|---|---|---|
| `mage_hit.wav` | Stage 1 body collision, not magic casting | [Punch 03 / 352040](https://pixabay.com/sound-effects/film-special-effects-punch-03-352040/) — Universfield |
| `rogue_hit.wav` | Stage 2 body collision, not blade swing | [Punch 02 / 123106](https://pixabay.com/sound-effects/film-special-effects-punch-02-123106/) — Universfield |
| `fighter_block.wav` | Physical guard absorbs/reduces a strike; no body cue layered over it | [Shield Block Shortsword / 143940](https://pixabay.com/sound-effects/film-special-effects-shield-block-shortsword-143940/) — SectionSound |
| `gunner_shot.wav` | One pistol muzzle flash/shot | [pistol shot / 233473](https://pixabay.com/sound-effects/film-special-effects-pistol-shot-233473/) — mrfriends |
| `berserker_roar.wav` | Madness visual/buff entry, one restrained human voice | [Human Roar / 250239](https://pixabay.com/sound-effects/people-human-roar-250239/) — Universfield |
| `upgrade.wav` | Successful monster strengthening and glow/absorption feedback | [Magic charge mana 2 / 186628](https://pixabay.com/sound-effects/film-special-effects-magic-charge-mana-2-186628/) — FxProSound |
| `confirm.wav` | Committed formation registration/removal/slot save | [Soft Interface Click / 126517](https://pixabay.com/sound-effects/film-special-effects-soft-interface-click-126517/) — Universfield |
| `fighter_hit.wav` | Stage 3 body collision outside guard | [Punch / 140236](https://pixabay.com/sound-effects/film-special-effects-punch-140236/) — Universfield |
| `gunner_hit.wav` | Stage 4 body collision, not metal scrape | [Punch 04 / 383965](https://pixabay.com/sv/sound-effects/film-och-specialeffekter-punch-04-383965/) — Universfield |
| `berserker_hit.wav` | Stage 6 body collision, not sword attack | [Hard Punch SFX / 515251](https://pixabay.com/sound-effects/film-special-effects-hard-punch-sfx-515251/) — DRAGON-STUDIO |
| `demon_level.wav` | Actual demon level increase, one dark energy swell | [Dark magic (1) / 378650](https://pixabay.com/sound-effects/film-special-effects-dark-magic-1-378650/) — Yodguard |
| `victory.wav` | Battle victory/result transition, one subdued closing impact | [Cinematic Impact Boom 05 / 352465](https://pixabay.com/sound-effects/film-special-effects-cinematic-impact-boom-05-352465/) — Universfield |
| `deadeye_shot.wav` | One fast pistol muzzle flash/shot at the existing 0.08s cadence | [9mm pistol shoot short reverb / 7152](https://pixabay.com/sound-effects/film-special-effects-9mm-pistol-shoot-short-reverb-7152/) — gattoangus (Freesound) |
| `archmage_hit.wav` | Stage 5 body collision, separate from outgoing spells | [Punch Impact Hit / 567196](https://pixabay.com/sound-effects/film-special-effects-punch-impact-hit-567196/) — Universfield |
| `deadeye_cock.wav` | Deadeye focus/weapon preparation starts | [Cocking a revolver / 6279](https://pixabay.com/sound-effects/film-special-effects-cocking-a-revolver-6279/) — acidsnowflake (Freesound) |
| `research.wav` | Committed research completion and UI record update | [Flipping Book Page / 499646](https://pixabay.com/sound-effects/film-special-effects-flipping-book-page-499646/) — DRAGON-STUDIO |
| `magic_block.wav` | Magical shield energy contact, including the hit that breaks it | [Impact Plasma Sci-Fi Energy Hit / 601137](https://pixabay.com/sound-effects/film-special-effects-impact-plasma-sci-fi-energy-hit-601137/) — Vadim_Makes_Sound |

## Selection and exclusions

- Six normal damage recordings come from body/punch impacts. Metal shield resonance is confined to actual sword/shield guard. The initially downloaded `Combat Impact / 352458` candidate was rejected because its weapon-hit description did not cleanly distinguish body contact from weapon collision; the final fighter cue is `Punch / 140236`.
- Original Stage 2/3/4/6 damage sources were identical to Sword Slash and Swing. Stage 1/5 damage duplicated their magic attack. These are retired from damage dispatch; the original weapon attacks remain unchanged.
- Actual pistol/revolver recordings replace explosion and sword stand-ins. The approved existing cylinder-spin reload remains unchanged. Short-reverb Deadeye uses its own source, not the ordinary-shot clip sped up. Existing muzzle-flash/attack hooks and 0.08-second cadence determine playback.
- The voice replaces a portal shifted to 0.56 pitch; it plays at natural pitch with reduced peak/gain. No roar is layered on ordinary hits or attacks.
- Reject bright melodic/retro references such as `Power Up Game Sound Effect / 359224` (8-bit/chiptune tags), `Power Up Sparkle 3 / 177985` (arcade/retro tags), and the former `Level Up Fanfare / 151765`. Formation, research, strengthening, demon level and victory now have separate origins. Extra augment-open fanfare is omitted because it follows the same level event. Augment/mutation choices retain a simple UI press, without an invented growth animation.
- Marimba rejected-action and defeat jingles are omitted. Failures retain visual feedback; defeat keeps the quieter result BGM. Silence is preferable to an unrelated musical motif.

## Timing, spectrum and mix

- PCM envelopes reveal >0.25 seconds of encoded leading silence in several hit sources. Trim to the actual transient, not an arbitrary animation-length slice. Keep natural pitch and event cadence. Preserve voice/charge envelope; remove long room-noise tails. No runtime resampling/stretching, synthesis or Base64 decoding.
- High-pass at 65 Hz removes excess rumble; context-specific low-pass at 2.6–5.5 kHz limits shrill edges. Gentle offline compression and final peaks -9/-12 dBFS leave headroom. Runtime body/physical-block gain -15 dB, magical-block -13 dB; growth/result -9 to -11 dB. Values follow the independent SFX bus setting.
- Confirm/strengthening happen after the committed save or purchase. Demon level plays only on an increase, not each EXP update, and is not doubled by the augment window. Death, invulnerability rejection and poison/status ticks do not emit ordinary collision audio. Capture shield material before it breaks. Burst contact interval 140 ms prevents repeated transient restarts.
- Existing fixed shot pools and persistent hero players are reused. Relevant hit/guard players are prepared at hero startup. No added per-frame tree/group scan or per-hit audio player allocation. Dedicated Zeus and BGM sources stay intact.

## Verification

- Manifest audit: 17 distinct content IDs and raw hashes, edited WAV SHA matches, mono PCM16/44.1 kHz, peak headroom, first-20ms energy for collisions. Raw source download completion was verified.
- Godot 4.7.2 actual Stage 1–6 hero profiles: damage dispatch, guard/body separation, shield-breaking contact, status/rejected hits silent, bounded rapid hits, real Deadeye preparation/shot and madness entry. Growth sources differ; ordinary EXP does not trigger level sound.
- WASAPI actual Master capture with Master/SFX/BGM buses at 0 dB: six hero contacts, existing mage attack and sword swing, existing frontend BGM, growth and 12.5 shots/second. Peak 0.40833277 (-7.78 dBFS), nonzero and unclipped in this sampled interval. Test restores all temporary bus settings without persisting them.
- GameAudio ownership/pause/buttons/result, lobby settings save/restore, startup transition and Zeus SFX regression checks. Existing raw-image warnings and some fixture resource-leak exit warnings remain. This is event/source/waveform/output verification; subjective listening, full manual gameplay, Android and export are not verified.


## 2026-10-08 repetition correction (supersedes mix/cadence above)

User gameplay feedback supersedes source-title matching: automatic all-button beeps were excessive. UI is silent by default, with explicit navigation/selection opt-in. Quiet presses now use the existing interface-confirm recording 126517 at -20dB / 220ms, not the previous 147352 beep. Closing, details, sorting, placeholder actions and sliders remain unmarked/silent. Committed formation is -18dB; successful growth remains event-specific. Deferred presses are suppressed by committed feedback.

Six existing body recordings are now 120ms / lowpass1600Hz / -21dB / 650ms minimum interval. Source IDs are unchanged; manifest SHA/duration/levels are updated. This reduces repetition and tails without changing HP or attack timing.

Rogue combo, storm and assassination now reference offline trimmed sword assets (160/500/180ms) derived from the existing licensed Sword Slash and Swing / DavidDumaisAudio / [185432](https://pixabay.com/sound-effects/film-special-effects-sword-slash-and-swing-185432/). These share an existing source deliberately because they are blade actions; they are not advertised as three new recordings. `repetition_edits.json` records source/output hashes, filters, trim and durations. Combo pitch is fixed at 1.0, with 280ms sound cadence; assassination contacts 220ms. Main skill activation remains audible.

Ordinary monsters have no per-attack or per-hit audio dispatch. Existing occasional elite activations and Zeus basic/major-skill cues are preserved. No generic monster collision sounds were added. Subjective listening and full manual battle verification remain unverified.


## User-selected results — 2026-10-08

The earlier victory/defeat descriptions are historical. Current victory is [Gaming victory / 464016](https://pixabay.com/ko/sound-effects/gaming-victory-464016/) by EAGLAXLE, and current defeat is [fail / 234710](https://pixabay.com/ko/sound-effects/영화-및-특수-효과-fail-234710/) by u_8g40a9z0la. Both were explicitly supplied by the user; actual browser pages state free use under Pixabay Content License. Raw files downloaded successfully, decoded to mono44.1k PCM16, full cues retained at natural pitch; no melody substitution. Offline50Hz highpass/limiter and runtime -12/-14dB provide headroom. Result dispatch is once per owner and resets for the next battle. Manifest records source/output hashes, full durations and levels.

Verification for this correction: Godot runtime button opt-in/default silence/rapid coalescing/deferred committed feedback and once-only victory/defeat PASS; actual first six hero damage paths and rogue major-skill retention PASS. WASAPI Master mixture peak 0.37634721; Stage2 40 contact/attack requests in 2s emitted 4 body and 7 attack cues, peak 0.35714665. Separate result/SFX mixture peak 0.17663352. All sampled output unclipped. Startup, lobby settings and Zeus regression PASS; existing fixture resource-in-use exit warnings remain. Full manual gameplay, subjective listening, Android/export not verified. Result files additionally normalized offline to -9dBFS peak; natural timing preserved.
