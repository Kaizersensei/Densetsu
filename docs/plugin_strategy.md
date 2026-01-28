# Plugin Strategy (Godot 4.4)

Goal: offload lower-level implementation to stable plugins where it reduces workload, while keeping data-driven ownership (Resources) and Actor/FSM lifecycle intact.

Selection criteria
- Godot 4.4 compatible, GDScript-based, export-safe (no editor-only dependency).
- Acts as a component provider (child node/behavior), not an owner of actors/data.
- Can read/write our Resource data (via bridging scripts) and emit signals we can forward through `ActorInterface`/FSM.
- Small surface area; no duplicate databases; no tilemaps.

Shortlist & decisions
- Combat: Hitbox/Hurtbox plugin (e.g., “godot-hitbox-system” style, GDScript).
  - Use: provide hitbox areas, filtering, and contact events. We wrap it with an `AttackData` payload -> `StatsComponent`/FSM Hurt/Death.
  - Fit: replaces custom overlap code, keeps damage math in our data layer. Low risk; drop-in nodes per actor.
  - Action: use Combat Collider hitboxes with adapter (`engine/combat/HitPayloadAdapter.gd`) and existing bridge (`engine/combat/HurtboxReceiver.gd`, `HitPayload.gd`) to normalize payloads and route to `ActorInterface.apply_hit` + FSM Hurt; projectiles expose `get_hit_payload`.
- AI: Behavior Tree plugin (e.g., “godot-behavior-tree” GDScript runtime).
  - Use: optional AI backend for `AIProfileData` entries; BT nodes drive FSM requests and movement inputs.
  - Fit: satisfies “Behavior Trees allowed only if exportable/runtime-usable”. Keeps profiles as Resources; BT graphs live under AI node.
  - Action: author BT loader that maps `AIProfileData` -> BT graph; guard so actors without BT use the lightweight AI controller.
- Debugging: DebugDraw2D-style overlay plugin.
  - Use: visualize collision, hitboxes, AI sensing in-editor and at runtime toggle via EditorOverlay.
  - Fit: dev-only aid; must be runtime-safe and disabled in release builds.
  - Action: gate behind debug flag; no dependency from core logic.
- Navigation/Pathing: use Godot built-ins (`NavigationServer2D`, nav regions); no external plugin needed.
- Animation: keep built-in `AnimationTree`/`AnimationPlayer`; no plugin.
- Movement/physics: keep `BaselinePlatformController`; no external plugin (third-party character controllers risk conflicting with our data contracts).
- Data/editor: keep custom `DataEditor`; generic inspector plugins would collide with our schema-driven design.

Integration notes
- All plugin nodes live under actors as children; `ActorInterface` remains the lifecycle broker.
- Plugin events/signals are translated into our data contracts (hit payload -> `AttackData`; BT blackboard -> `AIProfileData` params).
- Editor usage must avoid editor-only APIs; in-game editor should operate with plugins loaded as normal nodes.

Feasibility
- Combat plugin + bridges: High benefit, low integration cost (only touch actors/combat).
- Behavior Tree plugin: Medium benefit, medium cost (needs loader + fallback AI).
- Debug overlay plugin: Medium benefit, low cost (dev-only).
- Others: defer unless a specific need arises to avoid surface area creep.
