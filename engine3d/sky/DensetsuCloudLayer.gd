@tool
extends Resource
class_name DensetsuCloudLayer

## Enables this cloud layer in the compositor stack.
@export var enabled: bool = true
## Material applied to this layer. Use a CanvasItem-compatible shader/material.
@export var material: Material
## Layer tint multiplied after material output.
@export var tint: Color = Color(1.0, 1.0, 1.0, 1.0)
## Global alpha multiplier for this layer.
@export_range(0.0, 1.0, 0.01) var opacity: float = 1.0
## Optional UV scale passed to shader uniforms when available.
@export var uv_scale: Vector2 = Vector2.ONE
## Optional UV offset passed to shader uniforms when available.
@export var uv_offset: Vector2 = Vector2.ZERO
## Optional UV scroll speed (units/second) passed to shader uniforms when available.
@export var uv_scroll: Vector2 = Vector2.ZERO
