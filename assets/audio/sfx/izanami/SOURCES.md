# Izanami gacha SFX

- Prayer charge: [energy charge (4)](https://pixabay.com/sound-effects/film-special-effects-energy-charge-4-482504/), Yodguard, ID482504, source marked AI generated. Reuses the already licensed/edited `zeus/charge.wav`, then trims/filter/fades for this presentation. No new synthetic PCM.
- Spirit release: [Magical Whoosh](https://pixabay.com/sound-effects/film-special-effects-magical-whoosh-148459/), u_hyed0v3ux9, ID148459; downloaded from official Pixabay CDN on2026-10-09 and edited to1.1s.
- [Pixabay Content License](https://pixabay.com/service/license-summary/): use/adaptation permitted subject to terms; these edited sounds are integrated with the game, never distributed as a standalone sound library.
- Processing, durations, peaks and hashes: manifest.json. Two fixed SFX players; charge0.7s/-18dB, release2.4s/-12dB. Release stops charge; cancel/skip/completion stop both; user's SFX bus remains authoritative.
- Runtime routing/timeline/stop and waveform tests performed in isolated Godot fixture. Subjective listening, Android playback and full game export unverified.
