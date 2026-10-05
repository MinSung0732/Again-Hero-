# Demon appearance and dialogue integration

Identity is not appearance: canonical `player_profile` gender/nickname never
change when a portrait is equipped. The two existing male/female portraits are
free baseline appearances for all players, independent of identity gender.
Other → Account → Change Demon Portrait exposes the data-driven owned picker.
No new character art, battle ability or paid draw has been added.

## Content and saved selection

`src/data/demon_appearance_catalog.gd` has stable IDs, order, name,
default_owned, avatar, dialogue and optional expressions. For a future skin,
add one entry and its order ID; keep IDs stable even when image paths change.
Avatar may later be a small headshot while dialogue is a full-size illustration.
`expressions` maps keys (e.g. angry) to images; authored demon dialogue lines
may set `demon_expression`. Missing expressions use the selected neutral art.

`src/systems/demon_appearance_store.gd` saves only `equipped_id` in the separate
`demon_appearance` section of stage_progress.cfg. Existing scoped save operations
preserve profile/currency/progress and use the same account bundle/cloud sync.
No schema or Supabase Auth changes are required. Canonical profile refresh
updates only player_profile, leaving equipped appearance untouched.
No selection, unowned IDs, unknown/removed entries fall back to identity gender.
Unavailable images fall back without blocking combat.

Profile view requests PlayerProfile.portrait_path("avatar"); StageIntroCutscene
requests portrait_path("dialogue", expression). Ranked demon preview and resumed
prologue use the same resolver. Initial prologue gender selection deliberately
shows that choice before registration. destination warmup loads the equipped
appearance's avatar/dialogue/expressions plus its fallback, not every owned skin.
The native picker validates identity again before saving if the account changes.
set_profile_avatar(Texture2D) remains display-only; callers must use
equip_profile_appearance(id) to persist and refresh visible UI.

## Future gacha boundary — not implemented yet

`owned_ids()` exposes catalog defaults today. `grant_local_preview(id)` supports
guest/local content development only. Social-account ownership explicitly
ignores snapshot local_owned values: a client save is not proof of a paid skin.
Before releasing a real skin gacha, add an authenticated server-owned entitlement
ledger, atomic currency/draw/grant operation, ownership read endpoint and a
validated owner-bound client cache. Do not turn local_owned into paid account
ownership or authorize grants from user_metadata. Duplicate compensation,
probabilities, season pools, new skin art and server operations are separate work.

## Verification

tests/demon_appearance_smoke.gd uses isolated random account namespaces and a
fake canonical-profile transport. It exercises old-profile gender defaults,
appearance/identity separation, invalid selection rejection, no-op re-equip,
social local-grant rejection, canonical refresh preservation, restart and cloud
bundle round-trip, currency preservation, actual owned picker, actual stage
dialogue and warmup, account isolation and removed-ID fallback. Real rendering
is available with --capture. Existing prologue/tutorial/settings/dialogue tests
cover regression. Real multi-device sync and Android touch remain manual QA.
