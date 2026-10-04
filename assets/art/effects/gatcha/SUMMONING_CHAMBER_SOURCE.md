# Summoning chamber background

- File: `summoning_chamber.png`
- Date: 2026-10-04
- Method: built-in image generation/edit tool, based on the user's supplied castle gacha reference (`d5cff3e0-1854-40e1-a632-5ee8a5760a21.png`).
- This background deliberately contains no game text, controls, monsters, or animated gate. Existing project door animation and UI frames are composited at runtime.
- Character icons continue to use the existing cached, cropped monster card textures.

## Production prompt

Use case: precise-object-edit. Production asset for a portrait 9:16 mobile Godot pixel-art gacha summoning chamber. Edit reference image: preserve the purple moon castle in the upper arch, dark stone side pillars, purple skull banners, warm orange torches and purple side braziers, foreground stone stairs and purple haze. REMOVE the whole central closed gate and its horned skull arch/pillars; rebuild behind it as an open dark stone chamber unobstructed from 25% to 72% of screen height, with a subdued purple magic circle on floor at 72% screen height. REMOVE all UI, SKIP button, window controls, text, icons, stars. Keep center fairly dark and empty to overlay an independently animated gate and game UI. This must be a seamless full portrait background, no frame or UI panels baked in. Keep crisp pixel clusters and original dark violet/gold medieval demon castle aesthetic. No characters or monsters. Portrait 9:16.
