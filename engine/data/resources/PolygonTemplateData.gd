extends Resource
class_name PolygonTemplateData

@export var id: String = ""
@export var tags: PackedStringArray = PackedStringArray()
@export var description: String = ""

# Textures for distance-based zoning
@export var texture_border: Texture2D
@export var texture_transition: Texture2D
@export var texture_core: Texture2D

@export var border_width: float = 8.0
@export var transition_width: float = 12.0

# Angle filter (degrees). If both 0, applies to all.
@export var angle_min: float = 0.0
@export var angle_max: float = 0.0

# Smoothing defaults
@export var smoothing_threshold_deg: float = 30.0
@export var smoothing_steps: int = 0

@export var material_override: Material
