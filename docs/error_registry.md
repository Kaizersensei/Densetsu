# Error Registry (Godot 4.x)  

A running log of common errors encountered and how we fixed them. Update this whenever a recurring issue is resolved.

## API / Syntax
- `xform` / `clear_current` removed in Godot 4: use `Transform2D * vector`, `make_current()`, `is_current()`.
- Ternary: `value if condition else value` (no `? :`).
- `rad2deg` → `rad_to_deg`; `round()` takes a single argument.

## Scene Text Format
- Sub-resources must be resource types (e.g., `ConvexPolygonShape2D`, `RectangleShape2D`), not node types.
- `load_steps` must match sub_resource count; assign shapes via `SubResource("id")`.
- Polygon2D visuals should be node properties, not sub-resources of type Polygon2D.

## Input / Editor Toggling
- Autoloads don’t receive unhandled input by default: enable `_input` / `_unhandled_input` / `_unhandled_key_input`.
- Ensure actions exist in `InputMap` (inject F12 into `toggle_editor` if missing).
- Add a toggle cooldown to prevent double toggles on key hold.

## Selection / Picking
- Use `PhysicsPointQueryParameters2D` with `intersect_point`.
- For non-colliding visuals, add editor-only `Area2D` or fallback checks on `Sprite2D`/`Polygon2D`.
- Skip UI hits via `gui_get_hovered_control()` before scene picking.

## Snap Grid Performance
- Avoid per-dot draws; use tiled textures generated in code.
- Throttle redraw based on camera movement/zoom/snap changes and a short cooldown.

## Inspector / Transforms
- Connect fields via `text_submitted`/`focus_exited` and Apply buttons; write directly to the node transform.
- Highlights should use collider geometry transformed to world space (rect or convex points) for accurate outlines.

## Prefab Stamping
- Clear stamp after placement; right-click exits stamp mode so selection works.
- Attach per-entity spawners if multiple instances need independent firing.
- Item bobbing: store base position so float_idle doesn’t drift.

## Typing / Preloads
- Explicitly type locals when inference warnings trigger (e.g., slope flags, distances).
- `preload` paths must be constant strings; avoid dynamic preload paths.

