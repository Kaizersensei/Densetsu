extends Node
class_name DensetsuBootLoader

@export_group("Load Target")
## Default scene path to load through the loading screen.
@export_file("*.tscn", "*.scn") var target_scene_path: String = "res://Maps/Hirogawa.scn"
## Allows overriding target scene from command line arguments.
@export var use_cmdline_scene_override: bool = true
## Command-line prefix for direct scene path override (example: --scene=res://Maps/Hirogawa.scn).
@export var cmdline_scene_key: String = "--scene="
## Command-line token form also supported: --scene res://Maps/Hirogawa.scn
@export var cmdline_scene_token: String = "--scene"

@export_group("Loading Screen")
## Scene used as the runtime loading screen host.
@export var loading_screen_scene: PackedScene = preload("res://engine3d/loading/DensetsuLoadingScreen.tscn")
## Optional content scene to show while loading.
@export var loading_content_scene: PackedScene
## Applies loading_content_scene to the loading screen before it starts.
@export var apply_loading_content_scene: bool = false
## Forces loading screen overlay visibility.
@export var force_overlay_visible: bool = true
## Let loading screen auto-switch to loaded scene.
@export var auto_switch_to_loaded_scene: bool = true
## Minimum time the loading screen stays visible.
@export_range(0.0, 30.0, 0.01) var minimum_visible_seconds: float = 0.0
## Shows built-in loading status/detail labels.
@export var show_default_status_text: bool = true
## Prints boot/loading milestones to the console for debugging startup stalls.
@export var verbose_boot_log: bool = true

@export_group("Startup Splashes")
## Enables startup splash playback before the loading screen appears.
@export var play_startup_splashes: bool = true
## Ordered splash scene list, played from index 0 to end.
@export var startup_splash_scenes: Array[PackedScene] = [
	preload("res://engine3d/loading/splashes/DensetsuCompanyLogoSplash.tscn"),
	preload("res://engine3d/loading/splashes/DensetsuStartupInfoSplash.tscn")
]
## Allows skipping splash playback with input.
@export var startup_splash_allow_skip: bool = true
## Delay between splash scenes.
@export_range(0.0, 5.0, 0.01) var startup_splash_gap_seconds: float = 0.0

var _last_progress_bucket_logged: int = -1


func _ready() -> void:
	call_deferred("_run_boot_sequence")


func _run_boot_sequence() -> void:
	var resolved_target: String = _resolve_target_scene_path()
	if resolved_target.is_empty():
		push_error("DensetsuBootLoader: Target scene path is empty.")
		return
	_log("Boot start. Target: %s" % resolved_target)

	if play_startup_splashes:
		_log("Playing startup splashes...")
		await _play_startup_splashes()
		_log("Startup splashes finished.")

	if loading_screen_scene == null:
		push_error("DensetsuBootLoader: loading_screen_scene is not assigned.")
		return

	var loading_node: Node = loading_screen_scene.instantiate()
	var loading_screen: DensetsuLoadingScreen = loading_node as DensetsuLoadingScreen
	if loading_screen == null:
		push_error("DensetsuBootLoader: loading_screen_scene root is not DensetsuLoadingScreen.")
		return

	loading_screen.auto_start_scene_load = false
	loading_screen.auto_switch_to_loaded_scene = auto_switch_to_loaded_scene
	loading_screen.minimum_visible_seconds = minimum_visible_seconds
	loading_screen.show_default_status_text = show_default_status_text
	if force_overlay_visible:
		loading_screen.overlay_visible = true
	if apply_loading_content_scene and loading_content_scene != null:
		loading_screen.content_scene = loading_content_scene
		loading_screen.auto_instance_content_scene = true

	loading_screen.loading_started.connect(_on_loading_started)
	loading_screen.loading_progress.connect(_on_loading_progress)
	loading_screen.loading_completed.connect(_on_loading_completed)
	loading_screen.loading_failed.connect(_on_loading_failed)
	add_child(loading_screen)
	_log("Loading screen instantiated. Requesting threaded load...")
	loading_screen.begin_load_scene(resolved_target)


func _play_startup_splashes() -> void:
	for splash_scene_ref in startup_splash_scenes:
		var splash_scene: PackedScene = splash_scene_ref
		if splash_scene == null:
			continue

		var splash_node: Node = splash_scene.instantiate()
		if splash_node == null:
			continue
		if not splash_node.has_method("play") or not splash_node.has_signal("finished"):
			push_warning("DensetsuBootLoader: Splash scene root is not DensetsuSplashScreen: %s" % splash_scene.resource_path)
			continue

		add_child(splash_node)
		splash_node.set("allow_skip", startup_splash_allow_skip)
		splash_node.call("play")
		await splash_node.finished
		if is_instance_valid(splash_node):
			splash_node.queue_free()

		if startup_splash_gap_seconds > 0.0:
			await get_tree().create_timer(startup_splash_gap_seconds).timeout


func _resolve_target_scene_path() -> String:
	var resolved: String = target_scene_path.strip_edges()
	if use_cmdline_scene_override:
		var cmdline_path: String = _extract_cmdline_scene_path()
		if not cmdline_path.is_empty():
			resolved = cmdline_path
	return resolved


func _extract_cmdline_scene_path() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index < args.size():
		var arg_text: String = args[index]
		if not cmdline_scene_key.is_empty() and arg_text.begins_with(cmdline_scene_key):
			var key_length: int = cmdline_scene_key.length()
			return arg_text.substr(key_length, arg_text.length() - key_length).strip_edges()
		if arg_text == cmdline_scene_token and index + 1 < args.size():
			return args[index + 1].strip_edges()
		index += 1
	return ""


func _on_loading_started(scene_path: String) -> void:
	_last_progress_bucket_logged = -1
	_log("Threaded load started: %s" % scene_path)


func _on_loading_progress(scene_path: String, progress: float) -> void:
	var percent: int = int(floor(clampf(progress, 0.0, 1.0) * 100.0))
	var bucket: int = percent / 10
	if bucket == _last_progress_bucket_logged:
		return
	_last_progress_bucket_logged = bucket
	_log("Loading %s: %d%%" % [scene_path, percent])


func _on_loading_completed(scene_path: String, _packed_scene: PackedScene) -> void:
	_log("Threaded load completed: %s" % scene_path)


func _on_loading_failed(scene_path: String, reason: String) -> void:
	push_error("DensetsuBootLoader: Loading failed for %s (%s)" % [scene_path, reason])


func _log(message: String) -> void:
	if not verbose_boot_log:
		return
	print("[DensetsuBootLoader] ", message)
