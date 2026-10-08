# Stage 8 audio correction — 2026-10-08

Existing licensed game recordings were edited offline, not newly downloaded or synthesized. The user's complaint is harsh basic attack and stacked portals. No claim of subjective listening is made.

| File | Existing Pixabay recording | Edit |
|---|---|---|
| basic.wav | [Elemental Magic Spell Impact Outgoing / 228342](https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/) — RescopicSound | 200ms onset, lowpass1700Hz, -12dBFS asset peak, -20dB player |
| portal.wav | [the portal / 90750](https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/) — CeebFrack (Freesound) | 700ms onset, lowpass2400Hz, -12dBFS asset peak, -21dB player |
| follower_attack.wav | [powerful spell / 213833](https://pixabay.com/sound-effects/film-special-effects-powerful-spell-213833/) — SingularitysMarauder | 180ms onset, lowpass2000Hz, -12dBFS peak, existing quiet -24/-26/-27/-28dB follower gains |

Sources remain integrated game effects under [Pixabay Content License](https://pixabay.com/service/license-summary/); original files remain preserved. Natural pitch, mono44.1k PCM16, 110Hz highpass, gentle compression and short edge fades. All source/output SHA256 and exact edits are in manifest.json. Shortening/filtering reduces tails and harsh frequency content; it cannot reconstruct distortion already baked into a source recording.

Previously the gatekeeper portal player was -6dB, open gate -13dB, and each actor could independently start the same long portal recording. The new per-owner shared budget admits one portal voice at a time, at least750ms apart, including the open-gate skill. Cooldown plus an active-voice check prevents stacking. It uses the existing persistent players; no group scan or audio allocation during basic attacks.

The actual HeroProfile points to basic.wav; fallback points to the same file. Basic audio has one voice, minimum220ms cadence, and does not restart while playing. Damage, animation, skill cooldown and summon activation remain unaffected. Drone spawn feedback stays quiet and single-voice; ordinary player summoning stays on its existing quiet cue.

Subjective listening, full manual playthrough, Android/export remain unverified. Runtime tests reproduce actual Stage8 hitscan damage and five summon activations, then combine basic/follower attacks, portals, ordinary summoning and BGM with Master/SFX/BGM at0dB to check output and headroom.

Verification: actual Godot Stage8 profile basic attack retains all three damage events while coalescing sound. Five summon/open-gate activate calls emit one shared portal; later portal still plays. WASAPI Master capture at Master/SFX/BGM 0dB combines basic + portal + four follower attacks + ordinary summon + BGM: peak0.37999848 (-8.40dBFS), nonzero/unclipped. SUMMONER_AUDIO PASS and common GAME_AUDIO_SMOKE PASS. Common fixture resource-use exit warning remains; no summoner runtime errors in the final run.

## Audibility correction — 2026-10-08
User reports inaudible basic/portal feedback. Previous source peak -12dBFS plus player -20/-21dB attenuated twice. Current basic/portal peaks -6dBFS with player -12/-13dB: both14dB louder than the previous revision, combined nominal peaks -18/-19dBFS. Follower effects unchanged. Original filters, durations, damage cadence and shared portal voice gate remain. Manifest hashes/normalization updated.
