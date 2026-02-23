@tool
extends Area3D
class_name CameraModeTrigger3D

enum PriorityMode {
	LAST,
	CLOSEST,
}

@export_category("Trigger")
## Enable enabled.
@export var enabled: bool = true
## Enable apply only once.
@export var apply_only_once: bool = false
## Enable ignore if active.
@export var ignore_if_active: bool = true
## Controls priority mode.
@export var priority_mode: PriorityMode = PriorityMode.LAST

@export_category("Camera")
## Enable force camera context.
@export var force_camera_context: bool = true
## Controls camera context.
@export var camera_context: ActorCharacter3D.CameraContext = ActorCharacter3D.CameraContext.SIDE_SCROLLER
## Enable apply allowed modes.
@export var apply_allowed_modes: bool = true
## Allow third person.
@export var allow_third_person: bool = true
## Allow first person.
@export var allow_first_person: bool = true
## Allow side scroller.
@export var allow_side_scroller: bool = true

@export_category("Side Scroller")
## Enable apply side scroller settings.
@export var apply_side_scroller_settings: bool = true
## Controls side scroller axes.
@export var side_scroller_axes: ActorCharacter3D.SideScrollerAxes = ActorCharacter3D.SideScrollerAxes.XY
## Enable side scroller allow depth.
@export var side_scroller_allow_depth: bool = true
## Enable side scroller crouch uses side down.
@export var side_scroller_crouch_uses_side_down: bool = true
## Enable side scroller use camera space.
@export var side_scroller_use_camera_space: bool = true
## Enable side scroller plane lock.
@export var side_scroller_plane_lock: bool = true
## Controls side scroller depth deadzone.
@export var side_scroller_depth_deadzone: float = 0.1
## Enable side scroller face invert.
@export var side_scroller_face_invert: bool = false
## Enable side scroller invert depth.
@export var side_scroller_invert_depth: bool = false
## Enable side scroller disable turn.
@export var side_scroller_disable_turn: bool = false

@export_category("Orbit")
## Enable orbit mode override.
@export var orbit_mode_override: bool = false
## Controls orbit mode.
@export var orbit_mode: OrbitCamera3D.CameraMode = OrbitCamera3D.CameraMode.FOLLOW

var _applied := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not enabled:
		return
	if apply_only_once and _applied:
		return
	if body is ActorCharacter3D:
		if body.has_method("apply_camera_trigger"):
			body.call("apply_camera_trigger", self)
			if apply_only_once:
				_applied = true
