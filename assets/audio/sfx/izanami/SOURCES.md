# Izanami gacha SFX

- Prayer charge: [energy charge (4)](https://pixabay.com/sound-effects/film-special-effects-energy-charge-4-482504/), Yodguard, ID482504, source marked AI generated. Reuses the already licensed/edited `zeus/charge.wav`, then trims/filter/fades for this presentation. No new synthetic PCM.
- Spirit release: [Magical Whoosh](https://pixabay.com/sound-effects/film-special-effects-magical-whoosh-148459/), u_hyed0v3ux9, ID148459; downloaded from official Pixabay CDN on2026-10-09 and edited to1.1s.
- [Pixabay Content License](https://pixabay.com/service/license-summary/): use/adaptation permitted subject to terms; these edited sounds are integrated with the game, never distributed as a standalone sound library.
- Processing, durations, peaks and hashes: manifest.json. Two fixed SFX players; charge0.7s/-18dB, release2.4s/-12dB. Release stops charge; cancel/skip/completion stop both; user's SFX bus remains authoritative.
- Runtime routing/timeline/stop and waveform tests performed in isolated Godot fixture. Subjective listening, Android playback and full game export unverified.

## Battle skill audio correction (2026-10-11)

- Skill hooks use `izanami_audio_catalog.gd` / `event_sfx_bank.gd`; soundtrack/UI SFX settings stay authoritative.
- Previous bind/spirits/torii excerpts had peaks near -59dBFS and RMS below -87dBFS, making them nearly silent before cue attenuation. Replaced these sections rather than amplifying their noise floor.
- Bind and torii now derive from the audible, previously licensed `haunt.wav` excerpt of Yodguard's Dark Magic 5 (ID378651). Spirits derives from the already licensed `spirit_release.wav` Magical Whoosh (ID148459). Offline pitch/filter/fade/peak normalization only; no runtime decoding/synthetic PCM.
- Exact source paths, pinned input commit, SHA256, processing and measured output peaks/RMS are in `arthur_update_manifest.json`. Outputs remain mono PCM16/44.1kHz with peaks capped at -3dBFS.
- Battle cue levels: normal attack -24dB, haunt/fire/spirits -14dB, bind -13dB, torii -15dB. Per-slot fire sound guard; death stops retained players.
- Isolated Godot4.5.1 PCM decoding/audio bank smoke passed61 checks; a headless test verifies playback requests, not subjective listening or physical output. Full battle/Android/export unverified in this correction; ObjectDB exit warning remains in the isolated fixture.
