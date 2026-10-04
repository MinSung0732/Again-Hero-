# Gacha sound effects

Downloaded 2026-10-05 from Pixabay's normal download controls. These are integrated game presentation assets, not a standalone sound pack. No runtime network download, Base64 decoding, or generated PCM is used.

| Game asset | Work / creator | Content ID | Source |
|---|---|---|---|
| `door_open.mp3` | Elemental Magic Spell Impact Outgoing / RescopicSound | 228342 | https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/ |
| `door_creak.mp3` | Creepy Creaking Door / Universfield | 402155 | https://pixabay.com/sound-effects/horror-creepy-creaking-door-402155/ |
| `monster_reveal.mp3` | Sound Effect: Twinkle/Sparkle / ShidenBeatsMusic | 115095 | https://pixabay.com/sound-effects/film-special-effects-sound-effect-twinklesparkle-115095/ |

All item pages identify the files as usable under the Pixabay Content License. License summary: https://pixabay.com/service/license-summary/ ; full terms: https://pixabay.com/service/terms/ . The summary permits free use and adaptation without mandatory attribution, but prohibits standalone redistribution. These files remain subject to that license, not any repository code license. Do not extract/repackage them as a reusable sound library.

Original MP3 bytes retained, filenames changed only. Impact cue starts with the shake after anticipation. Creak starts once at zero-based sheet frame 7 (manifest's first moving hinge) and stops at the fullscreen flash/reveal. Reveal cue restarts once per monster. Three reusable players use the existing SFX bus and user mute/volume. Relative cue levels: impact -5 dB (unchanged), creak -2 dB, reveal 0 dB (+8 dB over the previous setting), in addition to the user bus level. Skip/results/close/hiding/reset stop all players; fast taps restart the reveal player instead of stacking voices.

On 2026-10-05 the earlier reveal source, Universfield's Magic Twinkle (244951, https://pixabay.com/sound-effects/film-special-effects-magic-twinkle-244951/), was replaced following the user's listening feedback. It is only present in earlier Git history, under the same license.

Selection is based on the source descriptions and short durations; subjective listening/mix approval is still required in the game.
