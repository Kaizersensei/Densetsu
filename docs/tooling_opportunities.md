# Tooling Opportunities & Strategies (living log)

Purpose: capture modular tool ideas that can evolve independently (instead of a monolithic editor), with clear runtime hooks so tools can be combined later if desired.

## Principles
- Tool = focused, single‑purpose UI/workflow (e.g., Movement Tuner, Prefab Browser).
- Tools talk to runtime via existing apply_* hooks and DataRegistry, not editor‑only APIs.
- Tools should be composable; a “unified editor” is optional aggregation of these tools later.

## Opportunities (current)
1) Movement Tuner (3D)
   - Scope: tune MovementData3D and apply to ActorCharacter3D live.
   - Hooks: ActorCharacter3D.apply_movement_data(id), DataRegistry.save_resource.
   - Outputs: MovementData3D presets; optional export to prefabs.

2) Camera Rig Tool
   - Scope: camera mode presets (follow/orbit/shoulder), offsets, clamps.
   - Hooks: CameraRig3D.apply_camera_data(id), FSM camera intent emission.
   - Outputs: CameraRigData resources.

3) Model/Animation Binder
   - Scope: assign ModelData (mesh/material/anim set) to actors.
   - Hooks: ActorCharacter3D.apply_model_data(id), AnimDriver3D parameter map.
   - Outputs: ModelData resources + animation intent mappings.

4) Prefab Browser / Stamper
   - Scope: browse PrefabData, spawn into scene, apply default_data_id.
   - Hooks: SceneManager.apply_*; PrefabData.default_data_id.
   - Outputs: PrefabData entries; optional grouping tags.

5) Stats/Combat Balancer
   - Scope: edit StatsData + per‑element power/defense/redirect flags.
   - Hooks: StatsComponent.apply_stats_resource, HurtboxReceiver/HitPayload.
   - Outputs: StatsData presets, attack payload templates.

6) AI Profile Authoring Tool
   - Scope: define AIProfileData + BT graph mapping.
   - Hooks: AI controller reads AIProfileData; BT runtime (if used).
   - Outputs: AIProfileData presets; behavior tree assets.

7) Terrain/Level Tool (3D)
   - Scope: place collision volumes, ramps, water volumes, teleports.
   - Hooks: PrefabData + SceneManager apply; collision layers presets.
   - Outputs: Scene prefabs, CollisionData presets.

## Strategy Notes
- Each tool is a separate scene/UI with a small set of dependencies.
- Shared utilities: DataRegistry browser widget, resource save/load, undo stack.
- When unified, combine tools behind a toolbar/launcher; keep tools standalone.
