# Editor & Engine Work Principles (Week 1 Summary)

These guidelines capture the practices we used so far so tasks stay predictable and consistent.

## Design Philosophy
- Modular and deterministic: prefer explicit data flow, avoid hidden magic; each feature declares inputs/outputs.
- Category → Type → Instance: categories publish allowed data fields, types pick from those sets, instances bind a single type id and inherit its data.
- Scene-driven visuals: sprites, tint, colliders come from data assets or scene overrides; always reapply tints after transforms/overrides.
- Entity-agnostic systems: FSM, data editor, inspector, selection/highlights must work for any entity category unless explicitly excluded.

## Editor UX Patterns
- Panels (Save/Load/Data/Templates/Polygon) live under the ribbon; ribbon stays visible, active panel button highlights yellow; only one panel visible at a time.
- Hover tips under cursor, never on the ribbon; selection name in the ribbon; inspector/sidebar shows current selection; deselection clears handles/highlight/cursor.
- Prefab palette uses explicit buttons; stamp/delete modes use custom cursors; polygon mode uses its own toolbar (Use/Cancel).
- Transform handles stay off when nothing is selected; handle positions are offset for polygons; rotation/scale follow selection rotation.

## Data & Templates
- DataRegistry categories (Actor, Scenery, Item, Trap, Spawner, Stats, AIProfile, Faction, LootTable, PolygonTemplate, etc.) are sorted and typed.
- Types map to scene entities via `data_id`; selection/inspector/type dropdowns are filtered by category.
- Placeables in scenes must use current type ids (e.g., ACTOR_Player/NPC/Enemy, SCENERY_*), no legacy ids.
- Saving/loading routes through DataEditor and uses the system FileDialog for scenes; type edits overwrite, not duplicate.

## Camera & Interaction
- Game camera centers on the primary player (first ACTOR_Player or node named “Player”) on editor exit/startup; shows footer warning if no player exists.
- Editor camera is isolated; grid/handles/highlights are editor-only. Delete key removes selected entity with undo support.
- Polygon mode: seeded triangle at editor camera center, points numbered, red warning on invalid polygons; right-click delete with confirmation at 3 pts; Use/Cancel toolbar.

## Debug & Feedback
- Footer/ribbon messages for critical states (missing player, camera recenter).
- Logs only on actions (panel toggles, data load/apply, polygon edits) to keep noise low.
- Always keep hover/select highlights in sync with actual transforms; reapply tints after any transform change.

Use this as baseline context for Week 2 tasks. Update as practices evolve.***
