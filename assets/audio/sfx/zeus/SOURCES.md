# Zeus SFX — 2026-10-08

Downloaded from official Pixabay sound-effect players. Only edited game-integrated clips are shipped, not a standalone library of the original downloads.

| Source | Creator | ID | Use |
|---|---|---|---|
| [Lightning Spell](https://pixabay.com/sound-effects/film-special-effects-lightning-spell-386163/) | DRAGON-STUDIO | 386163 | Judgment, slash, hit |
| [energy charge (4)](https://pixabay.com/sound-effects/film-special-effects-energy-charge-4-482504/) | Yodguard | 482504 | Charge; source marked AI-generated |
| [Lightning Strike](https://pixabay.com/sound-effects/nature-lightning-strike-386161/) | DRAGON-STUDIO | 386161 | Thunder, summon, lowered-pitch death |
| [Magic Twinkle](https://pixabay.com/sound-effects/film-special-effects-magic-twinkle-244951/) | Universfield | 244951 | Crown, orb absorption |

License verified: [Pixabay Content License summary](https://pixabay.com/service/license-summary/). Free use and modification, attribution optional; standalone redistribution prohibited. These edited clips are part of the synchronized game presentation. Retain this source record.

## Audio reference and timings

Mono 44.1kHz PCM16 source WAVs, peaks normalized to -3 dBFS, short fades to avoid abrupt cuts. Godot imports are non-looping compressed WAVs. `manifest.json` records raw/edited checksums, exact processing filters, durations, peak and RMS; `src/data/zeus_audio_catalog.gd` records gains and timelines.

| Trigger | Gain before SFX bus |
|---|---|
| Judgment instant pillar | -14 dB |
| Thunder sphere charge start / stop on release | -15 dB, 2 game seconds |
| Thunder release large pillar | -7 dB |
| Crown starts, once per cast | -10 dB |
| Slash launch / accepted hit | -12 / -17 dB |
| Actual orb absorption, maximum once per 0.12 game seconds | -22 dB |
| Actual HP loss, maximum once per 0.2 game seconds | -19 dB |
| Death confirmed; cinematic owns sound after actor removal | -9 dB |
| Battle summon charge at 0s, lightning at 1.9/2.08/2.26 real seconds | -15 / -8 / -18 / -18 dB |
| Gacha Zeus reveal at existing 1.9s | -8 dB |

All players use existing **SFX** bus/settings. Default SFX level8 is -7dB, BGM at same setting is 8dB lower. No global balance or user configuration changes. Combat pitch follows slow game time so charge stays synchronized; cinematic cues use real time. Fixed cached players, no per-event allocations, dense hit/orb coalescing does not alter gameplay rewards. Cancellation stops cinematic audio; battle pause freezes actor cues, and death stops charge.

## Verification

Godot4.7.2 runtime checks: WAV loading/routing, duration, non-looping, bounded players, throttling, slow clock, pause/resume, cancellation and summon timeline. Actual WASAPI SFX mix capture with charge+thunder+crown+slash at **SFX 0dB** measured peak **0.352784 (-9.05dBFS)** without clipping in this fixture. Original bus state restored in memory, saved settings untouched. Waveform/routing verification, not subjective listening review. Full-combat loudness, Android speakers/headphones and export remain unverified.
