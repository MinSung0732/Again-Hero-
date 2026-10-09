# Izanami gacha art

Original: user `assets/art/Transcendent_monster/Izanami/izanami_parts_v1.zip`; README/manifest and11 exact visible PNG partitions extracted without modifying pixels. RGBA reconstruction diff0. Full768×1280 reference texture used by one seam-continuous33×53-vertex/7-bone native Godot mesh; six partitions define wind weights. Fixed face/crown/prayer hands/knees; small hair/sleeve/robe wind only. Not Cubism; large joints, expression changes and hidden anatomy require restored occlusion/eye-mouth parts.

Built-in imagegen generated new project-bound PNGs2026-10-09:
- `yomi_shrine.png`: portrait dark Japanese Yomi shrine, distant purple torii/stone steps, crimson edge lanterns, muted gold/violet mist, empty central stage and dark name margin; crisp fantasy pixel environment, no character/text/UI.
- `spirit_vfx_atlas.png`: transparent four-piece violet spirit flame, crimson-violet talisman wreath, violet/red ribbon plume, gold-red petals. No letters/character. Named atlas pieces are independent static effects, not motion frames. Regions in1280-normalized coordinates: flame0/0/630/640, wreath640/0/640/640, ribbon0/650/850/620, petals850/650/430/620; actual1254×1254.
Existing original effect1/effect3 PNG animations remain secondary. All runtime resources are PNG/imported nearest textures; no Base64 decoding.
