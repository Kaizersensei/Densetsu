# Densetsu Engine Rework Plan

Source: `docs/Engine_Rework.txt` (authoritative architecture + constraints).

## Current State & Gaps (Dec 2025)
- Actor runtime still script-default-driven: `engine/actors/ActorCharacter2D.gd` hardcodes movement/physics values; data is only partially applied via `SceneManager.apply_actor_data`, and stats/ai/combat bindings are absent.
- Stats are not resource-bound: `engine/stats/StatsComponent.gd` initializes from exported defaults and ignores `StatsData`/`ActorData.stats`/`ActorData.resistances`, so damage pipelines cannot use the data store.
- FSM stubs only set debug text: `engine/fsm/states/*.gd` do not drive movement/landing/hurt/death, and there is no per-state animation or transition policy.
- Combat/interaction scaffolding only logs hits: `engine/projectiles/ActorProjectile2D.gd` + actor hurtboxes lack hitbox definitions, damage resolution, knockback, or hitpause; there is no data-defined attack resource.
- AI runtime missing: `AIProfileData` exists, but no controller consumes it (no patrol/chase/aggro logic or hooks into the FSM).
- Resource coverage is thin: only base entries exist for `movement`, `stats`, `sprites`, `actors`, `polygon_templates`, and `prefabs`; canonical categories like `collision`, `traps`, `triggers`, `projectiles`, `spawners` have either empty or unused data paths.
- Editor is partially schema-driven: `engine/editor/DataEditor.gd` has hardcoded field maps per category; it does not reflect Resource class fields automatically and cannot yet edit all canonical categories (prefabs/collision/projectiles/traps are effectively placeholders).
- Prefab/scene application path is fragmented: `SceneManager` applies movement/sprite overrides, but not stats/ai/combat; prefabs (`data/prefabs/BasePrefab.tres`) are unused during stamping/runtime.

## Plan (ordered)
1) Resource-first bootstrap (priority)
   - Add a data-driven actor binder (autoload or SceneManager extension) that, on ready, reads `data_id`/`ActorData` and applies movement, stats, sprite, collider, AI profile, tags, and lifecycle flags to instances (no reliance on editor mode).
   - Wire `StatsComponent` to ingest `StatsData` (or `ActorData.stats/resistances`) and expose a small API for damage/regen/resistance so combat can call it.
   - Normalize `DataRegistry` lookups with typed helpers per canonical category and ensure `data_changed` reapplication covers non-editor sessions.

2) Movement systems
   - Keep `BaselinePlatformController` as the default backend; add a MovementProfile loader that populates `ActorCharacter2D` from `MovementData` (including glide/flight/swim flags) and supports swapping profiles at runtime.
   - Stub a Sonic-style backend entry point (separate controller class, switchable via MovementData flag) without changing baseline behavior.
   - Ensure WaterVolume/in-water flags flow through controller state (swim) and FSM transitions.

3) FSM + lifecycle
   - Replace placeholder states with functional ones: Idle/Walk/Run/Sprint/Jump/Fall/Land/Hurt/Death drive movement requests, timers, and animation intents; add transition conditions (coyote, buffers, fall caps) instead of manual debug_state writes.
   - Have `ActorInterface` broker lifecycle events (initialized, state change, damage, death) and expose a hook for AI/combat modules to subscribe.
   - Add animation intents (e.g., meta or signals) so sprite modules can react without embedding animation logic in states.

4) Combat + hit logic
   - Introduce data-defined attacks/projectiles (attack resource with damage, knockback, hitpause, tags) and a Hitbox component that emits hit events carrying that data.
   - Enhance hurtboxes to accept hits, resolve damage through `StatsComponent`, apply resistances/knockback, and trigger FSM Hurt/Death.
   - Update `ActorProjectile2D.gd` to consume projectile data (speed, gravity, pierce, damage payload) and reuse the hit pipeline; keep hitpause/juggle hooks stubbed but plumbed.

5) AI runtime
   - Implement a lightweight AI controller that reads `AIProfileData` (behavior type, patrol points, aggro radii, abilities) and drives FSM requests + movement inputs.
   - Leave a slot for exporting/importing behavior trees, but require profiles to be serializable resources and runnable at runtime per the handoff rules.

6) Editor & modding
   - Make `DataEditor` schema-driven: introspect Resource fields to render controls instead of hardcoded maps; cover canonical categories (actors, movement, stats, prefabs, polygon_templates, collision, platforms, spawners, sprites, projectiles, traps, triggers, ai_profiles).
   - Align prefab stamping in `EditorManager` with prefab resources: when stamping, pull scene + default data_id from the PrefabData and apply via `SceneManager`.
   - Ensure all editing flows avoid editor-only APIs and remain usable in-game (drag/drop placements, data editing, save/load through DataRegistry).

7) Content & fixtures
   - Author minimal but complete sample resources for each canonical category (one of each: actor, movement, stats, prefab, polygon_template, collision, platform, spawner, sprite, projectile, trap, trigger, ai_profile) to validate pipelines.
   - Update `game/levels/default_scene.tscn` (and prototypes) to rely solely on data-driven application (remove hardcoded physics values once binders land) and include a simple AI example.

8) QA & regression harness
   - Add headless/unit-style checks under `engine/tests` (or a lightweight Godot test scene) to verify data application (movement/stats), FSM transitions, hit resolution, and AI pathing.
   - Include a smoke-playable scene checklist (movement, jump buffers, wall jump, swim/glide toggles, projectile hit/kill, AI patrol/aggro) and wire it into the editor overlay for quick validation.

## Notes / Risk
- All steps stay within the handoff constraints: no tilemaps, no duplicate databases, plugins remain component providers only, and everything reads/writes Resource data.
- Greatest lift: combat + AI integration (needs careful signaling to avoid regressions). Schema-driven editor work is moderate but constrained to UI code. Movement/FSM refactor is medium since controller scaffolding already exists.
