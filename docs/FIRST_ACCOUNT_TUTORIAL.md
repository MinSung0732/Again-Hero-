# First-account tutorial

New social accounts (created after deployment) enter the existing mandatory
profile prologue, then receive a Skip / Proceed offer in the lobby.
Existing profile/snapshot/legacy-progress owners are seeded `legacy`; guests
and localtest do not receive a cloud account reward. No existing data is reset.

Proceed persists `active`, returns the main UI to Stage 1 / demon / easy,
then highlights the actual entry button. After the dialogue and hero reveal:
- first successful summon teaches the existing manual and auto placement;
- camera guide uses Menu → Settings → Gameplay → camera lock checkbox;
- real mutation selection event (Stage 1: 75 seconds) teaches elite summoning;
- real demon level-up event teaches card selection + explicit confirmation.

The guide pauses the existing battle with external_pause. Normal mutation and
augment pause reasons remain independent. Full overlays block field input;
target outlines and compact hints do not consume clicks. A short input guard
prevents the opening click from dismissing a guide. Lesson events queue rather
than replacing a guide being read. No alternate battle timer, forced augment,
free monster, victory, unlock or cheat currency is introduced in the live game.

All four learned actions offer return to lobby. An ordinary victory/defeat also
offers return. Early exit is treated as Skip; rewards are equal. Restart/crash
keeps `active` on the server and offers Proceed / Skip on the next lobby entry.

## Reward consistency

`docs/sql/first_account_tutorial.sql` is the deployed additive DDL source.
`account_tutorial` is an authenticated invoker endpoint; the private helper
authenticates auth.uid(), locks the owner-only tutorial ledger then the owner's
snapshot. Completion/Skip adds **1000 gold** (current MULTI_DRAW_COST), advances
snapshot revision and marks the reward claimed in ONE transaction. It cannot
accept a target account, reward amount or arbitrary save payload. Calls with a
stale revision fail, and retry after a committed request returns granted=0.
If the shop cost changes, update the SQL grant and client catalog together.

CloudStore serializes claims with snapshot writes, flushes unsaved gameplay
first and installs only a valid server response for the same account/generation
and unchanged local serial. Failed/offline claims do not award locally. Failed
local install can retry the same server claim without duplicating the reward.
Explicit save conflicts require re-login/normal conflict recovery.

## Checks

### Repeatable local first-account preview

Other → Account → Coupon → `tutorialtest` restarts into the same real startup
prologue, then the Proceed/Skip offer and battle coach. It uses a fresh random
guest directory under `user://local_test_tutorial_*`, Stage 1, the three starter
monsters and zero currency, without localtest's free draws/cheat unlocks.
Every invocation starts a new preview; app restart resumes the current preview.
The profile choices are saved only in that directory. Name syntax is validated,
but global nickname duplication/reservation is deliberately not performed;
the input UI explicitly labels that limitation. Real social registration and
server uniqueness still require a real new-account QA test.

Skip/Complete adds the catalog's draw cost to gold and records the claim in the
same local config save; repeat claims do not add gold. No tutorial/profile RPC
is sent in this mode. Normal guest/social accounts remain excluded from this
local reward route unless the isolated preview is active and its namespace
matches. Social progress is flushed before entry, the session vault is preserved,
and late OAuth callbacks/social login buttons cannot leave the preview.

`normaltest` **while inside this preview** restores the original guest namespace
and normal startup/login; it does not reset guest/social progress and never
sets pending_reset_id. Outside preview its old destructive reset meaning is
unchanged. To enter from localtest or a pending social reset, finish that old
workflow first. Settings such as sound/camera remain ordinary device settings.

`tests/tutorial_preview_smoke.gd` exercises the real startup and prologue choice
controls, persisted resume, Skip/Complete equality and idempotency, actual
battle coaching actions, fresh re-entry and non-destructive exit, no-profile-RPC
transport, and byte-identical original guest/social snapshots. No human saves
or server fixtures are reset. Existing tutorial/progression/settings tests are
run separately as regression checks. Android touch and real social session
restore remain manual QA.

`tests/tutorial_smoke.gd` uses random isolated UUID saves and a fake transport
through the real CloudStore operation. It renders offers, entry, battle guides,
reward return; tests successful actual summon, camera checkbox, mutation API,
real augment selection/confirmation, offline denial, Skip/Complete parity,
repeat claims and legacy suppression. Only fixtures accelerate command/EXP.
Server rollback tests use temporary auth fixture users, authenticate as the
ordinary role and test ownership/RLS/direct-write denial, CAS, equal rewards,
snapshot preservation and idempotency. Fixtures are rolled back, not real users.
Actual new Kakao/Google signup and Android touch are manual QA still required.

Security advisor found no new tutorial issues. The project retains an unrelated
[disabled leaked-password protection warning](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection);
password Auth settings were not changed as part of the tutorial feature.
