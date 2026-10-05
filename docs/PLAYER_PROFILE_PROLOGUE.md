# First-account prologue and demon profile

## Flow

Validated social login → existing cloud snapshot initialization → canonical `read_player_profile` → mandatory prologue for required/incomplete profiles → gender → nickname registration → final act → `complete_player_prologue` → save flush → warmed lobby.

Guest remains a deliberately local-only identity and keeps its existing entry flow. Local test mode does not claim server nicknames. Existing saved accounts at deployment are grandfathered without changing gameplay or forcing a replay. They may choose **Other → Account → Demon Profile Setup** to run the same prologue voluntarily. Accounts without a save at deployment, and future accounts, receive the new mandatory flow. Once a name is confirmed it is immutable in this release.

The authored Korean sequence lives in `src/data/prologue_catalog.gd`. Touch first reveals the current typewriter text, and the next touch advances. Gender/name gates cannot be advanced by touching the background. The dice button changes the candidate only; uniqueness is atomically decided by the server on Confirm. Failed reservation leaves the field editable. Leaving after registration resumes at the final act; leaving before registration restarts without claiming any nickname. The last scene remains retryable if profile or snapshot save fails.

Nickname rules: 1–6 precomposed Korean syllables, ASCII letters or digits, without whitespace/symbols. Global case-insensitive uniqueness; the same account retrying its confirmed name/gender is idempotent. A duplicate random suggestion can occur before Confirm and does not reserve somebody else's name. Gender keys are `male`/`female`, mapped centrally to the existing portraits. All StageIntroCutscene demon labels use `마왕(닉네임)`; legacy/unconfigured profiles fall back to `마왕`/male.

## Mobile nickname entry

The name form tracks the physical virtual-keyboard inset and converts it through the canvas-to-screen transform. The unobscured bottom is captured before input focus; an OS-resized viewport is capped rather than subtracting the inset twice. Mobile focus initially places the form in the upper half while keyboard height is unavailable. After a reported keyboard closes, the original modal placement returns. A fixed readable content height inside a ScrollContainer keeps Confirm accessible on unusually short visible areas without recreating controls or losing typed text. Gender selection and nickname registration semantics remain unchanged.

`tests/player_prologue_keyboard_smoke.gd` exercises several physical pixel scales and keyboard heights, OS resize/insets, scroll access to Confirm, input/validation retention and layout restoration in the headless Godot engine. Real Android keyboard timing and touch/rendering still require device QA.

## Storage and security

Deployment SQL: `docs/sql/player_profile_prologue.sql`, applied through Supabase migration `player_profile_prologue` on 2026-10-05 to the existing Again-Hero project. Do not reapply CREATE statements manually to an already-migrated project.

`public.player_profiles` owns identity by validated `auth.uid()` and has RLS, own-row SELECT only, no client INSERT/UPDATE/DELETE grants. A partial unique index on `lower(nickname)` prevents concurrent claims. A private SECURITY DEFINER helper has empty search_path, fully qualified relations, explicit authentication and operation/field validation, row locking, no target-user argument, and no PUBLIC/anon execution. Public REST functions are restricted invoker wrappers. Collision responses expose no other user's profile. Auth metadata and locally cached profile fields are never authorization sources. There is no account-deletion RPC or handler.

Canonical rows seed only existing snapshot/legacy owners as completed/optional at migration time. New profile rows remain required even if initialization has just created an empty game snapshot, so crash/re-login cannot accidentally bypass onboarding. Identity is separate from gameplay resets/coupons. The client mirrors server results in the existing stage_progress.cfg `player_profile` section, retaining every gameplay section and the existing five-file snapshot format. Every authenticated startup reloads the canonical profile; an outage blocks entry and offers login retry instead of assuming a new/legacy account.

## Validation

- `tests/player_prologue_smoke.gd`: real Godot/OpenGL renders, isolated account/save paths and mock transport, darkness/typewriter, mandatory choice gates, six-character validation, dice changes, duplicate/offline retries, save preservation, restart/resume, final flush retry, female dialogue/caption, male mapping, account profile and inert withdrawal UI, legacy entry and profile outage.
- Supabase authenticated-role fixtures in a rolled-back transaction: new gate, registration/completion, unique nickname collisions including case, own-row RLS, immutable confirmation, newline/length rejection, missing-name completion and anonymous/direct-write denial. No fixture Auth user/profile remains; human account data was not modified.
- Regression: startup, five-page settings, cloud/auto-login, Windows loopback OAuth, dialogue controls, progression coupons and hero reveal.
- Security/performance advisors report no new schema issues. Existing Auth leaked-password-protection warning is unrelated to these social-login/profile changes and was not silently toggled. Optional existing Auth remediation: [Supabase password security](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).
- Pending: real newly-created Kakao/Google account walkthrough, Android soft keyboard/touch/aspect ratios. Existing OAuth providers are unchanged.

## Art

The generated ruined-throne background and exact prompt are recorded in `assets/art/UI/prologue/SOURCE.md`. It and both existing gender portraits are warmed before login. Lighting and portrait fade are lightweight tweens; dialogue text remains native, not baked into images. No battle hot path changes.
