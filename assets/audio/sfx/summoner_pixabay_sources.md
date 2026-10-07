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

- Stage 8 Skill 5 gate opening reuses `summoner_gatekeeper_summon_pixabay.mp3` directly.
- `summoner_drone_spawn.mp3`
  - Dedicated short, faint dimensional pop used only for rapid suicide-drone spawns.
  - This is a separate custom-generated SFX, not a duplicate of the gate-opening sound.

2026-10-08: Runtime basic/portal/follower attack now use edited WAVs in summoner_clean. See summoner_clean/SOURCES.md and manifest.json; original MP3s above remain preserved.
