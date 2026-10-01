# Stage 5 Archmage SFX sources

Stage 5 is the elemental archmage (`archmage_elementalist`). Audio is mapped to the actual skill names and visual effects:
- basic elemental orb -> effect6/effect7 orb projectile
- `연소` -> effect2 fire charge + thrust/release
- `아이스볼트` -> effect4 ice projectile + impact/pillars
- `땅의 가시` -> effect1 repeated earth spikes
- `신성력` -> effect3 repeated holy bursts
- `체인대거` -> effect5 launch + chained hit/light effect
- `조화` -> effect7 orb/chime-like reset effect
- `폭풍` -> effect8 wind projectiles
- emergency blink augment -> effect8 wind movement effect

Pixabay candidates checked against those meanings:
- Magic Spell — Universfield
  - https://pixabay.com/sound-effects/film-special-effects-magic-spell-278824/
  - General spell/basic elemental projectile reference.
- Fire Spell Impact — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-fire-spell-impact-393921/
  - `연소` release reference.
- Ice Spell Impact — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/technology-ice-spell-impact-448563/
  - `아이스볼트` / ice-pillar impact reference.
- Earth Spell Impact 2 — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-earth-spell-impact-2-393922/
  - `땅의 가시` reference.
- Holy Spell Cast — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/musical-holy-spell-cast-450460/
  - `신성력` / `조화` reference.
- Elemental Spell Impact (Electric) — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/technology-elemental-spell-impact-electric-448567/
  - `체인대거` electric-chain reference.
- Elemental Spell Impact (Wind) — DRAGON-STUDIO
  - https://pixabay.com/sound-effects/film-special-effects-elemental-spell-impact-wind-478376/
  - `폭풍` / emergency blink reference.

The checked Pixabay pages identify the MP3s as free for use under the Pixabay Content License.

Runtime-byte note:
Direct binary download URLs for the newly compared pages are not exposed through the current connector. To avoid pretending those candidate files were downloaded, this commit uses already-tracked Pixabay source blobs in the repository under Stage 5-specific runtime filenames. Pitch, volume, and event timing separate their roles. The candidate list above is the semantic target for a later audio-quality swap without changing code hooks.

Runtime files and actual tracked source bytes:
- `stage5_archmage_basic_pixabay.mp3` -> existing Elemental Magic Spell Impact Outgoing blob
- `stage5_archmage_combustion_charge_pixabay.mp3` -> existing powerful spell blob
- `stage5_archmage_combustion_release_pixabay.mp3` -> existing Loud Explosion blob
- `stage5_archmage_ice_bolt_pixabay.mp3` -> existing Elemental Magic Spell Impact Outgoing blob
- `stage5_archmage_ice_impact_pixabay.mp3` -> existing Loud Explosion blob
- `stage5_archmage_earth_spike_pixabay.mp3` -> existing Loud Explosion blob
- `stage5_archmage_holy_burst_pixabay.mp3` -> existing powerful spell blob
- `stage5_archmage_chain_launch_pixabay.mp3` -> existing Elemental Magic Spell Impact Outgoing blob
- `stage5_archmage_chain_hit_pixabay.mp3` -> existing Sword Slash and Swing blob
- `stage5_archmage_harmony_pixabay.mp3` -> existing powerful spell blob
- `stage5_archmage_storm_pixabay.mp3` -> existing the portal blob
- `stage5_archmage_blink_pixabay.mp3` -> existing the portal blob
- `stage5_archmage_hit_pixabay.mp3` -> existing Elemental Magic Spell Impact Outgoing blob
- `stage5_archmage_death_pixabay.mp3` -> existing Fatal Body Fall Thud blob

Performance policy:
- Basic elemental attacks use a fixed 3-player pool.
- Repeated earth spikes, holy bursts, and chain-dagger hit cues use fixed 4-player pools at reduced gain.
- One-shot skill casts, blink, hit, and death reuse persistent AudioStreamPlayers.
- No AudioStreamPlayer is allocated per projectile hit or per physics frame.
