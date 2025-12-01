# Data Inspector (Deterministic Template Builder)

## What we built
- A Godot 4.4 data inspector that renders UI rows dynamically from per-category templates.
- Templates live in `CATEGORY_CONTROLS` inside `engine/editor/DataEditor.gd` and define `key`, `label`, and `type` (`string`, `int`, `float`, `bool`, `color`, `dict`, `array`).
- Core fields `path/id/tags` are always added, then the category template rows.
- The inspector container is cleared and regenerated on each selection via `_build_inspector`.
- Controls are tracked in `_inspector_rows` for load/save.

## Loading data
- `_build_inspector(cat, res, res_path)`:
  - Clears the container.
  - Generates rows for core + template keys.
  - For each key present in the resource (`_res_has` uses `get_property_list`), fills:
    - `tags`: CSV join from `PackedStringArray`.
    - `scene/sprite/texture`: use `resource_path` when present.
    - `color`: stored as hex string.
    - `dict`: serialized as `key=value;key2=value2`.
    - `array`: CSV.
    - Numbers/bools as strings/checked.
  - If `path` is supplied separately, sets it on the `path` row.

## Saving data
- `_apply_fields_to_resource` reads `_inspector_rows` only:
  - `id` via `_set_res_id`.
  - `tags` CSV -> `PackedStringArray`.
  - `scene/sprite/texture` paths -> `load` and set if found.
  - `dict` -> `_parse_dict` (semicolon-separated `key=value`).
  - `array` -> CSV parts.
  - `color` -> `Color(txt)`.
  - `int/float/bool/string` set directly.
  - Skips keys the resource doesn’t expose (`_res_has`).

## Key helpers
- `_res_has(res, key)`: checks `get_property_list` for `key`.
- `_serialize_dict` / `_parse_dict`: round-trip dicts via semicolon-separated pairs.
- Browse helpers write into the generated controls and call `_update_preview_from_inputs`.

## Resource/schema alignment
- Resource scripts in `engine/data/resources` must export the keys used in templates.
- We added missing fields to Weather/Particles/Sound/Strings/Faction/Spawner; platform `.tres` files got collision defaults, etc.
- Sound category key is `Sound` (not `Sounds`).

## Extending
1) Add the category script/exports.
2) Add a template entry in `CATEGORY_CONTROLS` with keys/types.
3) Ensure any default `.tres` in `data/<category>` include the keys (with safe defaults).
4) The inspector will render rows automatically and save/load via `_apply_fields_to_resource`.

## Rationale
- Deterministic, schema-first rendering avoids visibility glitches and missing fields.
- No reliance on pre-placed controls; everything is generated per selection.
- Safer saves: only sets properties that exist on the resource.
