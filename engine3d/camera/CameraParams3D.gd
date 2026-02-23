extends Resource
class_name CameraParams3D

@export_category("Modes")
## Allow third person.
@export var allow_third_person: bool = true
## Allow first person.
@export var allow_first_person: bool = true
## Allow side scroller.
@export var allow_side_scroller: bool = true
## Enable apply default context.
@export var apply_default_context: bool = false
## Controls default context.
@export var default_context: ActorCharacter3D.CameraContext = ActorCharacter3D.CameraContext.SIMPLE_THIRD_PERSON

@export_category("Side Scroller")
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
## Enable apply orbit mode.
@export var apply_orbit_mode: bool = false
## Controls orbit mode.
@export var orbit_mode: OrbitCamera3D.CameraMode = OrbitCamera3D.CameraMode.FOLLOW
## Controls camera rig.
@export var camera_rig: CameraRigData3D
