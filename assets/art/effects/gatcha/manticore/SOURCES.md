# Manticore presentation assets

- `rig_v1/`: extracted without editing from `assets/art/Transcendent_monster/manticore/manticore_parts_v1.zip` at repository commit `4b63a0328767d7e29b5e5f49514d5a1c91023f08`. All13 visible partitions reconstruct `actual_reassembly.png` exactly. Manifest's static-partition status is preserved; the runtime adds a seam-continuous small-motion native mesh, not hidden painted surfaces.
- `venom_sanctuary.png`: newly generated background on2026-10-09. Brief: portrait mobile RPG dark pixel-art ruined beast sanctuary, black/violet/gold pillars, restrained green venom mist, empty center, no character/text/UI. Kept at its original generated dimensions; scaled by Godot at display time.
- Existing character effects and sourced audio are referenced in place, without copied or runtime Base64 payloads. See `docs/MANTICORE_GACHA.md` and `assets/audio/sfx/bulgasal/SOURCES.md`.

- `src/ui/manticore_venom_aura.gdshader`: original procedural Godot shader added2026-10-09 for venom runes/corona/charge rays/expanding shockwave/edge embers. No third-party images or audio added for this enhancement. Two reused quads; clock supplied by cutscene player.
