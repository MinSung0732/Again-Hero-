# Mode unlock presentation

- Hero perspective / ranked preview: easy Stage 10 cleared, not simply accessible.
- Hard selector: easy clear of the selected stage.
- Existing clear entries are easy clears; preserve saves. Future actual hard gameplay
  must maintain its own clear ledger and cannot satisfy an easy-clear gate.
- LocalTestMode.active intentionally bypasses gates and announcements for existing
  full-game testing. tutorialtest follows normal progression.
- Locked buttons are disabled, carry a padlock/condition tooltip, and handler-level
  checks prevent programmatic bypass. Stage changes reset an ineligible hard selection.
- Announcements use a dimmed modal, opening shackle/sparks, then confirmation.
  Input stays blocked until opening finishes. Sequence waits for destination warmup,
  scene transition and tutorial overlays. The next pending mode follows confirmation.
- `[mode_unlock_seen]` in the existing scoped stage config stores `hero`, `rank`,
  and `hard:stage_N`. Existing snapshot sync includes these flags. A save failure
  prevents a same-session loop but permits retry on next session. No rewards altered.
- Unlocking does not implement PvP, hero controls, or hard difficulty battle rules.
- Tutorial Skip is a neutral gray secondary action; Proceed keeps violet/gold.

QA: tests/mode_unlock_smoke.gd covers fresh locks, direct calls, Stage 1 hard unlock,
per-stage reset, accessible-but-uncleared Stage 10, Stage 10 global unlock sequence,
once-only persistence/reload, account isolation, currency preservation, test override
and tutorial button colors. `-- --capture` captures the actual rendered screens.
Regression: lobby_main_modes_smoke, tutorial_smoke, tutorial_preview_smoke,
lobby_settings_smoke. Android interaction and live multi-device sync remain manual QA.
