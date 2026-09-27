---
name: again-hero-dev
description: Develop, patch, balance, optimize, or review the Godot game 「용사, 또 너야? / Again, Hero?」 while preserving its AI-build observation, manipulation, and counterplay loop, data-driven structure, mobile performance constraints, Git verification workflow, and audio sourcing rules. Use only for the MinSung0732/Again-Hero- project.
---

# Again, Hero Development

Use this skill only in the `MinSung0732/Again-Hero-` repository. Treat repository instructions and current source as authoritative over this installed copy.

## Start every repository task

1. Locate the repository root and confirm its remote or project identity.
2. Read `AGENTS.md`, `PROJECT_CONTEXT.md`, `README.md`, `docs/ROADMAP.md`, `CHANGELOG.md`, and `docs/AI_DEVELOPMENT_WORKFLOW.md` before editing.
3. Check the worktree, local `HEAD`, and the latest `origin/main` SHA. Preserve user changes and untracked files; update only with a safe fast-forward.
4. Inspect the relevant Catalog/Data, scene, script, and caller paths before changing code. When the user says `진행` or `해줘`, proceed after this inspection unless a genuinely outcome-changing choice is missing.

## Preserve the game

- The player is the demon king who summons monsters. The AI hero auto-battles, gains EXP, levels up, and selects augments.
- Protect the core loop: observe the AI build, steer it, then counter it.
- Keep AI fallible and explainable: recent observations + current monster composition + build inertia + hero personality + bounded randomness.
- Preserve existing gameplay meaning and validate the core fun before broad system or content expansion.
- Keep content values in Catalog/Data and use shared evaluators. Avoid scattering content IDs across unrelated runtime files.

## Engineer for mobile scale

- Do not add full group scans, per-frame temporary collections, repeated instantiate/free churn, or O(n²) work to hot paths.
- Prefer caches with explicit invalidation, pools, registries, spatial grids, and frame-distributed work.
- Keep visual/audio failures fail-soft when feasible so presentation loading cannot disable combat or AI.
- Make the smallest complete change; avoid speculative frameworks.

## Finish the task

- Update `CHANGELOG.md` for every feature, patch, improvement, removal, or balance change. Update `PROJECT_CONTEXT.md` when an important design decision changes.
- Run `git diff --check` and focused static checks. Use Godot headless validation when available, but never describe static parsing as runtime gameplay verification.
- If Godot was not actually run, say so explicitly.
- Commit only intended files and report the commit hash, checks performed, and remaining unverified behavior.

## Audio

For a new sound effect, search Pixabay first and time-box the search to a few viable candidates. Verify the license and record the source URL, creator, and content ID. If Base64 is needed, use it only to transport the asset, decode once to a real binary under `assets/audio/`, and reference that file from Godot. Never add runtime Base64 decoding merely to ship audio.

## Character pixel art

For character sprites, portraits, frame extraction, or pixel-art review, also read `docs/PIXEL_ART_CHARACTER_STANDARD.md` and use the dedicated `$again-hero-pixel-art` workflow. Treat the Stage 8 images named there as style-density and composition references, never as designs to copy.
