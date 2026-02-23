# Densetsu Flowing Water (DFW) - Phase 1

`DFW` is a lightweight, deterministic Godot 4 spatial shader for water surfaces.

Phase 1 uses UV advection + normal/roughness modulation only (no vertex displacement).
It is intended to be drop-in on a `ShaderMaterial` and works best on:

- subdivided planes (lakes, ponds, wide surfaces)
- curved strips/polystrips with consistent UVs (rivers)

## Files

- Shader: `res://shaders/dfw/dfw_flowing_water.gdshader`
- Demo: `res://engine3d/tests/water/WaterDemo.tscn`

## Mesh / UV Requirements

### Primary case (grid planes)
- UV0 should be continuous and cover `0..1` across the surface.
- If the mesh has `N` quads across the UV span, set:
  - `quad_uv_size = 1.0 / N`

Example:
- 16 quads across -> `quad_uv_size = 0.0625`
- 64 quads across -> `quad_uv_size = 0.015625`

### River strips / polystrips
- DFW works in UV space (not tied to mesh type).
- Recommended UV layout:
  - one UV axis along river length (flow axis)
  - one UV axis across river width
- `base_dir` should point in the UV direction that matches your river flow.

## Determinism

DFW is deterministic for the same:
- mesh UVs
- parameters
- `seed`
- time input

Cosmetic randomness is per-quad only and seeded by `seed`.

## Material Map Support (Phase 1)

DFW is a custom shader, so it does **not** auto-read `StandardMaterial3D` maps.
If you want map support, assign them to DFW shader uniforms directly.

Supported (phase 1):
- `albedo_tex`
- `normal_tex` (optional; procedural fallback exists)
- `roughness_tex`
- `metallic_tex`
- `ao_tex`
- `emission_tex`
- `border_mask` (optional, manual for now)

## Core Parameters (most important)

- `base_dir`
  - Base UV flow direction.
  - Example river down V: `Vector2(0, 1)`.
- `quad_uv_size`
  - Quad grouping size in UV space. Controls per-quad flow quantization.
- `speed`
  - Main flow speed.
- `speed_variation`
  - Per-quad speed variation amount (cosmetic only).
- `jitter_angle_deg`
  - Per-quad directional jitter around `base_dir`.
- `seed`
  - Cosmetic random seed (deterministic).

## UV / Motion Tuning

- `uv_scale`
  - Global texture UV scale (visual texel density).
- `continuous_warp_amp`
  - Smooth UV warping (keeps result visually fluid).
- `per_quad_warp_amp`
  - Tiny deterministic per-quad offset (breaks repetition).

Recommended:
- keep `continuous_warp_amp` small (`0.001` to `0.008`)
- keep `per_quad_warp_amp` smaller than continuous warp

## Border Steering (Phase 1 = manual mask)

Enable with:
- `use_border = true`
- assign `border_mask`

Border mask convention:
- `0` at edges/banks
- `1` in interior water

Controls:
- `border_strength`
- `border_smooth`
- `border_gradient_step_mul`
- `border_influence_gain`

If no mask is assigned or you are not using it:
- set `use_border = false`

## Debug Modes (required workflow)

Enable debug using either:
- `debug_flow = true` (quick flow-direction view), or
- `debug_mode` (specific mode)

`debug_mode` values:
- `0` Off
- `1` Flow direction
- `2` Cell hash / per-quad randomization
- `3` Border influence factor
- `4` Border gradient direction
- `5` Flow noise
- `6` Roughness output
- `7` Tangent normal view
- `8` Advected UV view

Also available:
- `debug_freeze_animation`
- `debug_time`

## Tuning Presets

### Calm lake
- `speed = 0.03 - 0.08`
- `jitter_angle_deg = 4 - 10`
- `roughness_base = 0.35 - 0.6`
- `roughness_flow_amp = 0.03 - 0.08`
- `continuous_warp_amp = 0.001 - 0.004`

### River
- `speed = 0.12 - 0.35`
- `jitter_angle_deg = 8 - 20`
- `speed_variation = 0.05 - 0.2`
- `continuous_warp_amp = 0.002 - 0.01`
- `use_border = true` + painted/baked mask
- `border_strength = 0.6 - 2.0`

## Common Pitfalls

- Wrong `quad_uv_size`
  - Causes debug flow to look unstable or too coarse/fine.
- River UVs not aligned to flow axis
  - Flow moves in unexpected direction because DFW is UV-driven.
- Expecting `StandardMaterial3D` maps to transfer automatically
  - Reassign maps in DFW shader uniforms.
- Large warp values
  - Produces smearing instead of water-like motion.
- Border mask reversed
  - If edges behave like interior, toggle `border_mask_invert`.

## Next Phases (planned)

- Static-collision border mask bake/cache helper
- Dynamic actor interaction displacement/ripples
- Better river/shore presets
- Weather/sky integration hooks
