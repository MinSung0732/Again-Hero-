# Stage 8 Summoner SFX sources

Stage 8 summoner runtime filenames and the Pixabay source used for each file.

- `summoner_basic_attack_pixabay.mp3`
  - Elemental Magic Spell Impact Outgoing — RescopicSound
  - https://pixabay.com/sound-effects/film-special-effects-elemental-magic-spell-impact-outgoing-228342/
- `summoner_gatekeeper_summon_pixabay.mp3`
  - the portal — CeebFrack (Freesound)
  - https://pixabay.com/sound-effects/film-special-effects-the-portal-90750/
- `summoner_gatekeeper_attack_pixabay.mp3`
  - Powerful Spell
  - https://pixabay.com/sound-effects/powerful-spell-213833/

The files are stored directly in `assets/audio/sfx/` and loaded by Godot as MP3 resources.
Check the linked Pixabay pages/license terms when redistributing outside this project.

- `summoner_open_gate_pixabay.mp3`
  - Dedicated Stage 8 Skill 5 gate-opening asset path.
  - Reuses the bundled Pixabay portal source used by `summoner_gatekeeper_summon_pixabay.mp3`.
  - Kept as a separate file path so the gate-opening mix can be tuned independently later.
- `summoner_drone_spawn_pixabay.mp3`
  - Dedicated Stage 8 Skill 5 drone-spawn asset path.
  - Reuses the same Pixabay portal source at a much lower in-game volume for rapid repeated spawns.
