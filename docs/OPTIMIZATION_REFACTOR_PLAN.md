# Again-Hero Optimization / Refactor Pass

Base: main @ f22e3d358a412b94f06cfa47087f2ddfc329157c

## Goal

Preserve current gameplay meaning while reducing runtime cost, code duplication, lifecycle risk, and maintenance cost.

This branch is intentionally isolated from `main` until behavior is checked.

## Non-negotiable rules

- Do not change stage balance, hero AI intent, monster costs, damage, cooldowns, EXP flow, or spawn semantics unless a bug is proven.
- Avoid per-frame full group scans, temporary array churn, repeated scene/resource loading, and unnecessary instantiate/free cycles.
- Prefer registries, caches, fixed pools, spatial queries, and event-driven updates.
- Keep deterministic Stage 1~10 castle behavior and existing Y-sort/collision semantics.
- Every optimization commit should be small enough to bisect.
- Static validation is required after each change.
- Godot runtime/profiler validation must be reported separately; never claim it if it was not actually run.

## Static audit snapshot

| File | Lines | Notes |
| --- | ---: | --- |
| `src/hero/hero.gd` | 14,228 | Main architectural hotspot. Contains all hero archetypes, visuals, audio, AI adapters, projectiles, summon runtime, level-up, conditional skills. |
| `src/battle/battle.gd` | 3,738 | Battle orchestration, pools, stage events, spatial grid, spawning, pause domains, UI-facing signals. |
| `src/main/main.gd` | 2,156 | HUD/cutscene/control orchestration. |
| `src/battle/stage1_battlefield.gd` | 711 | Static castle construction; created once per stage configuration. |
| `src/monsters/bomb_rat.gd` | 618 | Monster-specific visual/resource setup plus combat logic. |
| `src/monsters/slime.gd` | 338 | Repeated target/status/death lifecycle code. |
| `src/monsters/spider.gd` | 364 | Repeated target/status/death lifecycle code; projectile instantiation remains. |
| `src/monsters/orc.gd` | 374 | Repeated target/status/death lifecycle code. |

Observed patterns from the current branch:

- EXP orbs already use a pool in `battle.gd`; hero projectiles also have pooling infrastructure.
- Damage numbers still instantiate a `DamageNumber.tscn` for each popup (capped at 48), then free it.
- Spider projectiles are instantiated directly from the monster script.
- Monster scripts duplicate hero target refresh, fallback group lookup, status visual attachment, LOD/far-tick setup, hit/death handling, and lifecycle code.
- Several monster/EXP objects call `get_first_node_in_group("hero")` as a fallback. This is not necessarily expensive by itself, but repeated fallback paths should be replaced by a battle-owned reference where practical.
- Slime pack logic has a spatial-query path and only falls back to `get_nodes_in_group("slimes")`; keep the spatial path and remove/limit fallback only after runtime coverage is confirmed.
- `battle.gd` still scans several groups when globally toggling physics processing. This is event-time work, not per-frame, so it is lower priority than allocation and hot-loop work.
- `hero.gd` is large enough that dead-code removal and archetype extraction should be done after behavior-preserving hot-path work, not as one giant rewrite.

## Work order

### Phase 0 — Measurement / safety harness

1. Add lightweight debug counters behind a debug flag:
   - active monsters
   - pooled/active EXP orbs
   - active hero/monster projectiles
   - active damage popups
   - stage summon count
2. Add optional periodic performance snapshot output (not every frame).
3. Record Godot profiler baselines on desktop and Android:
   - idle battlefield
   - 20 / 50 / 100 monsters
   - projectile-heavy Stage 4/5
   - summon-heavy Stage 8
   - late Stage 9
4. Capture frame time, physics time, object count, node count, and memory.

### Phase 1 — Safe allocation reductions

1. Pool damage-number popups.
2. Pool spider projectiles.
3. Audit remaining direct combat-time `instantiate()` / `queue_free()` pairs and move high-frequency ones to fixed pools.
4. Reuse temporary arrays/dictionaries in hot paths where it does not complicate correctness.
5. Keep hard pool limits and explicit reset methods to prevent stale state.

### Phase 2 — Registry / lookup cleanup

1. Make Battle the authoritative runtime registry for:
   - hero
   - monsters
   - summons
   - projectiles
   - EXP orbs
2. Pass/cache hero references into monsters instead of repeated SceneTree fallback lookup.
3. Keep group membership for editor/debug compatibility, but do not use groups as the primary hot-path registry.
4. Continue using the existing spatial grid for proximity queries.

### Phase 3 — Monster shared runtime

Extract only proven duplicated behavior into a shared component/base:

- target acquisition / refresh cadence
- far-AI tick scheduling
- status visual setup
- common death/recycle hook
- hit-flash lifecycle where compatible

Do not force monster-specific movement/attack logic into a generic abstraction.

### Phase 4 — Hero split without behavior rewrite

`hero.gd` is the largest maintenance and regression risk.

Extract by responsibility, keeping the Hero node as facade:

- common progression / EXP / augment state
- common visual resource cache
- projectile/pool adapter
- per-archetype runtime modules:
  - mage
  - rogue
  - fighter
  - gunner
  - archmage
  - berserker
  - alchemist
  - summoner
  - purifier

Move one archetype at a time and compare emitted signals/snapshot data before and after.

### Phase 5 — Dead code / resource lifecycle audit

For every candidate deletion:

1. Search references in code/scenes/resources.
2. Verify it is not loaded dynamically by string path.
3. Verify save/snapshot compatibility.
4. Delete only in isolated commits.

Audit:
- stale variables/timers
- duplicate texture/frame loaders
- duplicate audio loaders
- disconnected signals
- orphaned pools
- nodes that remain processing while hidden/inactive
- one-shot FX that are never recycled/stopped
- resources recreated per instance that can be static/shared

### Phase 6 — Main/UI cleanup

After combat runtime stabilizes:

- split `main.gd` UI responsibilities
- reduce repeated HUD formatting/update work
- ensure hidden panels do not process unnecessarily
- consolidate cutscene lifecycle helpers

## Commit strategy

Suggested commit sequence:

1. `Add optimization audit and counters`
2. `Pool combat damage popups`
3. `Pool spider projectiles`
4. `Centralize combat actor references`
5. `Share monster target runtime`
6. `Extract hero archetype runtime modules` (multiple commits, one archetype each)
7. `Remove verified dead combat code`
8. `Reduce inactive UI processing`

No mega-commit.

## Acceptance criteria

A change is accepted only if:

- static parse/reference checks pass,
- no known gameplay semantic changes are introduced,
- pool objects fully reset state before reuse,
- active-node counts do not grow continuously across a long run,
- repeated stage restart does not increase retained objects unexpectedly,
- Android does not regress visually or functionally,
- runtime profiling shows improvement or at least no measurable regression.

## Current first targets

Highest-value / lowest-risk first:

1. Damage number pooling.
2. Spider projectile pooling.
3. Battle-owned hero reference injection to monsters.
4. Shared monster target-refresh helper/component.
5. Only then begin decomposing `hero.gd`.
