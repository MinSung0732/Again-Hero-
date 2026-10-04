# Gacha UI assets — 2026-10-04

Generated with the built-in image generation tool. User-provided castle gacha examples are style references, not flattened game screens. Text, icons, rarity colors and animation remain runtime layers. Original generated alpha is preserved.

## Files / final production prompts

- `gacha_panel_frame.png`: One standalone transparent portrait 3:4 pixel-art demon-castle UI frame. Gold double beveled rim, crisp stepped corners, purple cloth swags and skull pennants in side border zones, purple diamond and restrained horned-skull crest at top center, small purple diamond at bottom center. Large transparent inner opening; no text, monsters, buttons or scene backdrop. Restrict decoration to borders for usable runtime content.
- `gacha_button.png`: One transparent landscape purple/gold pixel-art button. Clipped stepped corners, lustrous gold double frame with orange shadows and pale highlights, inner violet outline, dark purple fill brighter toward bottom. Purple gems only at endcaps. Empty central 65% for runtime text; no letters, arrows or central X. Shared by SKIP and confirmation. `gacha_button_texture.tres` selects the alpha-visible bounds `(0, 115, 2172, 470)`; original PNG is unchanged and no runtime image scanning is needed.
- `gacha_reward_card.png`: One transparent-outside 3:4 pixel-art reward card. Narrow gold double rim, stepped corners, restrained filigree, small purple top-center diamond, dark-purple opaque inner fill with subtle upper glow. Large clean space for runtime monster icon, name and shard count. No baked text or monsters.

All current monsters retain Common rarity. Decorative violet gemstones do not imply Legendary rarity. Generated textures are reused and do not introduce per-frame image processing.
