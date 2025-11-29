# Editor Implementation Status & Next Steps

## Current State
- **Panels**: Ribbon buttons toggle panes for Data, Save, Load, and Templates. Panels anchor below the ribbon, cover sidebar, use opaque dark styling. Only one pane visible at a time; Data pane keeps the modal blocker off.
- **Data Editor**: Three-column flow (Categories → Types → Inspector). Category selection forces a rescan, repopulates Types, and loads the first entry. List clicks fire immediately (no delay). Inspector clears before load. Debug logging available.
- **Registry**: Category-scoped maps for lookups; supports Actor, Spawner, Faction, AIProfile, Item, Projectile, Trap, Platform, LootTable, Stats. Base templates exist for each.
- **ActorData**: Unified schema with input_source (Player/AI), player_number (1–4 shown only for Player), aggressiveness (-1/0/1), and universal fields (behavior/dialogue/loot/inventory/patrol/schedule, spawn flags/radius, level/xp, etc.).
- **SpawnerData**: Uses `spawn_scene` and spawner fields; save guards prevent invalid assignments.
- **Templates Pane**: UI scaffold with tabs for future template editors (actors, stats, factions, AI profiles, items, projectiles, traps, platforms, loot tables); currently placeholder text.
- **Save/Load Pane**: Custom panels with path, filename, list, and buttons; modal blocker used; ribbon buttons hide while panes open.

## Known Gaps / Risks
- **Inspector per category**: Non-Actor categories show only ID/path; no dedicated fields yet.
- **Template editing**: Locate/Create buttons in Data Editor are stubs; Template pane tabs are placeholders.
- **Runtime wiring**: Actor/spawner instances are not yet auto-loading data ids at runtime; stats/templates not applied to scene entities.
- **Logging**: Debug prints remain in Data Editor (useful now; remove/toggle later).
- **Validation**: Minimal validation on numeric fields; no user feedback on bad input.

## Recommendations (Deterministic/Modular)
1) **Per-category inspectors**: Add lightweight inspectors for Faction, AIProfile, Item, Projectile, Trap, Platform, LootTable, Stats (start with ID + key fields) to avoid blank panels.
2) **Template actions**: Implement Locate/Create to open the Templates pane to the relevant tab and seed a new entry; store last-selected template ids.
3) **Runtime integration**: Add data id fields to test-scene entities and spawners; on ready, load data from registry and apply (scene, stats, behavior profile, aggressiveness/player_number).
4) **Validation & UX**: Clamp numeric inputs; add minimal status toast/log on save/load; optionally remove debug prints once stable.
5) **Docs**: Keep this file updated as features land; add a short “How to use Data Editor” section once inspectors per category exist.

## Potential Removals
- Any leftover window/popup logic not used by the pane system.
- Debug prints in production mode once stability is confirmed.

## Next Step: In-Scene Popup Inspector (No Panels Active)
- **Behavior**: When a scene entity is selected (no modal panel open), show a small popup near the entity with tabs: Transform, Data, Collision, AI/Behavior. Popup clamps within viewport and never overlaps ribbon/sidebar; scales down if needed.
- **Safe drawing**: Reuse panel styling (opaque dark, mouse_filter=STOP) with a blocker disabled. Position via screen coords of selection clamped to viewport minus ribbon/sidebar padding.
- **Data tab**: Shows instantiated dataset fields (e.g., actor data id, aggressiveness/player #, behavior profile, stats template id). Read-only for now; later add edits.
- **Lifecycle**: Popup appears on selection change; hides on deselect or when a modal panel opens; only one popup at a time.
- **Integration steps**:
  1) Add a lightweight `EntityInspectorPopup` scene (Panel + TabContainer) with clamped positioning helper.
  2) In `EditorManager`, on selection change and no panels open, instantiate/show the popup near selection using `Node2D.get_global_transform_with_canvas()` → viewport coords; clamp to available area.
  3) Feed selected node’s data (data id, transforms, collision layers/masks if present) into the tabs; hide tabs that don’t apply.
  4) Hide/destroy the popup when panels open or selection clears.
