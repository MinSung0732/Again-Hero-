# Gacha sound effects

Downloaded 2026-10-05 from Pixabay's normal download controls. These are integrated game presentation assets, not a standalone sound pack. No runtime network download, Base64 decoding, or generated PCM is used.

| Game asset | Work / creator | Content ID | Source |
|---|---|---|---|
| `door_open.mp3` | Elemental Magic Spell Impact Outgoing / RescopicSound | 228342 | https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/ |
| `monster_reveal.mp3` | Magic Twinkle / Universfield | 244951 | https://pixabay.com/sound-effects/film-special-effects-magic-twinkle-244951/ |

Both item pages identify the files as usable under the Pixabay Content License. License summary: https://pixabay.com/service/license-summary/ ; full terms: https://pixabay.com/service/terms/ . The summary permits free use and adaptation without mandatory attribution, but prohibits standalone redistribution. These files remain subject to that license, not any repository code license. Do not extract/repackage them as a reusable sound library.

Original MP3 bytes retained, filenames changed only. Door cue starts with the shake/open animation after anticipation; reveal cue restarts once per monster. Separate reusable players use the existing SFX bus and user mute/volume. Relative cue levels: door -5 dB, reveal -8 dB, in addition to the user bus level. Skip/results/close/hiding/reset stop both players; fast taps restart the reveal player instead of stacking voices.

Selection is based on the source descriptions and short durations; subjective listening/mix approval is still required in the game.
