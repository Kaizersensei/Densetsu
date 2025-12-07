extends RefCounted
class_name BaselinePlatformController

# Lightweight baseline platform controller with hook points for future modules.

var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var drop_timer: float = 0.0
var dropping_through: bool = false
var jump_cut_applied: bool = false
var original_mask: int = 0
var was_on_floor: bool = false
var wall_normal: Vector2 = Vector2.ZERO
var jump_lock_until_release: bool = false
var glide_active: bool = false
var flight_active: bool = false
var swim_active: bool = false
var flap_uses: int = 0

const ONE_WAY_LAYER_BIT := 0
const PLAYER_FALLBACK_LAYER_BIT := 2

func step(actor: CharacterBody2D, input: Dictionary, delta: float) -> void:
	if actor == null:
		return
	var dir: float = input.get("dir", 0.0)
	var jump_pressed: bool = input.get("jump_pressed", false)
	var jump_released: bool = input.get("jump_released", false)
	var jump_held: bool = input.get("jump_held", false)
	var down_pressed: bool = input.get("down_pressed", false)
	var in_water: bool = input.get("in_water", false)

	# Clear jump lock as soon as the button is not held, so a release between jumps is honored.
	if not jump_held:
		jump_lock_until_release = false

	_update_wall_normal(actor)
	_update_coyote_and_buffer(actor, delta, jump_pressed)
	_update_drop_through(actor, delta, down_pressed, jump_pressed)
	_update_swim_state(actor, in_water)
	var water_slow := in_water and not swim_active
	if swim_active:
		_apply_swim(actor, delta, dir, input)
	else:
		_apply_gravity(actor, delta, jump_held, jump_released, water_slow)
		_apply_horizontal(actor, delta, dir, water_slow)
	_apply_jump_buffer(actor, jump_pressed)
	_apply_glide(actor, delta, input)
	_apply_flight(actor, delta, input)
	_apply_fall_cap(actor)

	actor.move_and_slide()

	if actor.is_on_floor() and not was_on_floor:
		if actor.has_signal("landed"):
			actor.emit_signal("landed")
	if actor.is_on_floor():
		if "jump_count" in actor:
			actor.jump_count = 0
		if "jump_released_flag" in actor:
			actor.jump_released_flag = true
		if "jump_min_reached" in actor:
			actor.jump_min_reached = true
		if "flap_count" in actor:
			actor.flap_count = 0
		flap_uses = 0
		glide_active = false
		flight_active = false
		swim_active = false
	was_on_floor = actor.is_on_floor()
	if was_on_floor:
		jump_cut_applied = false


func _update_coyote_and_buffer(actor: CharacterBody2D, delta: float, jump_pressed: bool) -> void:
	if actor.is_on_floor():
		coyote_timer = actor.coyote_time if "coyote_time" in actor else 0.0
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if jump_pressed:
		jump_buffer = actor.jump_buffer_time if "jump_buffer_time" in actor else 0.0
	elif jump_buffer > 0.0:
		jump_buffer = max(jump_buffer - delta, 0.0)


func _apply_gravity(actor: CharacterBody2D, delta: float, jump_held: bool, jump_released: bool, water_slow: bool) -> void:
	if actor.is_on_floor():
		return
	if "min_jump_height" in actor and "jump_min_reached" in actor and "jump_start_y" in actor:
		var min_h: float = actor.min_jump_height
		if min_h > 0.0 and not actor.jump_min_reached:
			var traveled: float = actor.jump_start_y - actor.global_position.y
			if traveled >= min_h:
				actor.jump_min_reached = true
	if flight_active:
		# Flight neutralizes gravity; handled in _apply_flight.
		return
	if swim_active:
		return
	var g: float = actor.gravity if "gravity" in actor else ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	if water_slow:
		g *= 0.5
	# Wall slide reduces gravity
	if wall_normal != Vector2.ZERO and actor.velocity.y > 0.0 and not actor.is_on_floor():
		var slide_scale: float = actor.wall_slide_gravity_scale if "wall_slide_gravity_scale" in actor else 1.0
		g *= slide_scale
	if actor.velocity.y < 0.0 and not jump_held:
		if "jump_release_gravity_scale" in actor:
			g *= actor.jump_release_gravity_scale
		if jump_released and not jump_cut_applied and (not ("jump_min_reached" in actor) or actor.jump_min_reached):
			var cut := 0.35
			if "jump_release_cut" in actor:
				cut = actor.jump_release_cut
			actor.velocity.y *= cut
			jump_cut_applied = true
	actor.velocity.y += g * delta


func _apply_horizontal(actor: CharacterBody2D, delta: float, dir: float, water_slow: bool) -> void:
	if dir != 0.0:
		var slope_scale := _slope_accel_scale(actor, dir)
		var accel: float = actor.acceleration if "acceleration" in actor else 900.0
		var move_speed: float = actor.move_speed if "move_speed" in actor else 140.0
		if water_slow:
			accel *= 0.5
			move_speed *= 0.5
		actor.velocity.x = move_toward(actor.velocity.x, dir * move_speed, accel * slope_scale * delta)
	else:
		var f: float = actor.friction_ground if actor.is_on_floor() and "friction_ground" in actor else 0.0
		if not actor.is_on_floor() and "friction_air" in actor:
			f = actor.friction_air
		if water_slow:
			f *= 2.0
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, f * delta)


func _apply_jump_buffer(actor: CharacterBody2D, jump_pressed: bool) -> void:
	if jump_buffer <= 0.0:
		return
	var max_jumps: int = actor.max_jumps if "max_jumps" in actor else 1
	var current_jumps: int = actor.jump_count if "jump_count" in actor else 0

	# Wall jump takes precedence while airborne (and not in coyote window).
	if wall_normal != Vector2.ZERO and not actor.is_on_floor() and coyote_timer <= 0.0:
		jump_buffer = 0.0
		var push_x: float = actor.wall_jump_speed_x if "wall_jump_speed_x" in actor else 200.0
		var push_y: float = actor.wall_jump_speed_y if "wall_jump_speed_y" in actor else -320.0
		var dir: float = -sign(wall_normal.x)
		actor.velocity.x = dir * abs(push_x)
		actor.velocity.y = push_y
		if "jump_count" in actor:
			actor.jump_count = max(current_jumps, 1)
		jump_lock_until_release = true
		if actor.has_signal("jumped"):
			actor.emit_signal("jumped")
		if "debug_state" in actor:
			actor.debug_state = "WallJump"
		return

	var airborne := not actor.is_on_floor() and coyote_timer <= 0.0
	if current_jumps >= max_jumps:
		return
	# Ground/coyote jumps require a release between jumps.
	if not airborne and jump_lock_until_release:
		return
	# Flap handling (air-only, ignores max_jumps as a bonus thrust)
	if _try_flap(actor, jump_pressed, airborne):
		return

	jump_buffer = 0.0
	coyote_timer = 0.0
	current_jumps += 1
	if "jump_count" in actor:
		actor.jump_count = current_jumps
	if "jump_start_y" in actor:
		actor.jump_start_y = actor.global_position.y
	if "jump_min_reached" in actor:
		var min_h: float = actor.min_jump_height if "min_jump_height" in actor else 0.0
		actor.jump_min_reached = min_h <= 0.0
	# Lock only ground/coyote jumps; air jumps can chain after a press without extra release lock.
	jump_lock_until_release = not airborne

	var js: float = actor.jump_speed if "jump_speed" in actor else -720.0
	if airborne and current_jumps > 1 and "air_jump_speed" in actor:
		js = actor.air_jump_speed
	actor.velocity.y = js
	if "jump_released_flag" in actor:
		actor.jump_released_flag = false

	if actor.has_signal("jumped"):
		actor.emit_signal("jumped")
	if "debug_state" in actor:
		actor.debug_state = "Jump" if not airborne else "AirJump"


func _apply_glide(actor: CharacterBody2D, delta: float, input: Dictionary) -> void:
	if not ("enable_glide" in actor and actor.enable_glide):
		glide_active = false
		return
	if actor.is_on_floor():
		glide_active = false
		return
	# Simple glide: hold jump while falling to reduce gravity and fall speed.
	var jump_held: bool = input.get("jump_held", false)
	if jump_held and actor.velocity.y > 0.0:
		glide_active = true
		var g_scale: float = actor.glide_gravity_scale if "glide_gravity_scale" in actor else 0.3
		var g: float = actor.gravity if "gravity" in actor else ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
		actor.velocity.y += g * g_scale * delta
		var max_fall: float = actor.glide_max_fall_speed if "glide_max_fall_speed" in actor else 300.0
		if actor.velocity.y > max_fall:
			actor.velocity.y = max_fall
	else:
		glide_active = false


func _apply_flight(actor: CharacterBody2D, delta: float, input: Dictionary) -> void:
	if not ("enable_flight" in actor and actor.enable_flight):
		flight_active = false
		return
	var dir_x: float = input.get("dir", 0.0)
	var dir_y: float = -input.get("dir_y", 0.0) # up is negative in Godot
	var wants_move: bool = dir_x != 0.0 or dir_y != 0.0 or input.get("jump_held", false)
	if actor.is_on_floor() and not wants_move:
		flight_active = false
		return
	flight_active = true
	var accel: float = actor.flight_acceleration if "flight_acceleration" in actor else 600.0
	var max_spd: float = actor.flight_max_speed if "flight_max_speed" in actor else 400.0
	var drag: float = actor.flight_drag if "flight_drag" in actor else 8.0
	var vel := actor.velocity
	# Apply thrust
	var thrust: Vector2 = Vector2(dir_x, dir_y).normalized() * accel * delta
	vel += thrust
	# Apply drag
	vel = vel.move_toward(Vector2.ZERO, drag * delta)
	# Clamp speed
	if vel.length() > max_spd:
		vel = vel.normalized() * max_spd
	actor.velocity = vel


func _apply_fall_cap(actor: CharacterBody2D) -> void:
	if "max_fall_speed" in actor and actor.velocity.y > actor.max_fall_speed:
		actor.velocity.y = actor.max_fall_speed


func _try_flap(actor: CharacterBody2D, jump_pressed: bool, airborne: bool) -> bool:
	if not ("enable_flap" in actor and actor.enable_flap):
		return false
	if not airborne:
		return false
	var max_flaps: int = actor.max_flaps if "max_flaps" in actor else 0
	if max_flaps <= 0:
		return false
	if not jump_pressed:
		return false
	# Respect a small lock so we don't consume a flap before min height is met (optional)
	if not actor.jump_min_reached and "jump_min_reached" in actor:
		return false
	if "flap_count" in actor:
		if actor.flap_count >= max_flaps:
			return false
		actor.flap_count += 1
	flap_uses += 1
	var impulse: float = actor.flap_impulse if "flap_impulse" in actor else -500.0
	actor.velocity.y = impulse
	# allow a tiny upward nudge horizontally to maintain feel
	return true
func _update_swim_state(actor: CharacterBody2D, in_water: bool) -> void:
	swim_active = ("enable_swim" in actor and actor.enable_swim and in_water)
	if swim_active:
		# Reset jump state when entering water
		if "jump_count" in actor:
			actor.jump_count = 0
		if "jump_min_reached" in actor:
			actor.jump_min_reached = true
		jump_buffer = 0.0
		coyote_timer = 0.0


func _apply_swim(actor: CharacterBody2D, delta: float, dir: float, input: Dictionary) -> void:
	# Simplified swim: dampen gravity and use swim speeds/drag
	var swim_grav_scale: float = actor.swim_gravity_scale if "swim_gravity_scale" in actor else 0.3
	var g: float = actor.gravity if "gravity" in actor else ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	actor.velocity.y += g * swim_grav_scale * delta

	var target := Vector2.ZERO
	target.x = dir * (actor.swim_speed if "swim_speed" in actor else 120.0)
	target.y = (-input.get("dir_y", 0.0)) * (actor.swim_speed if "swim_speed" in actor else 120.0)
	var drag: float = actor.swim_drag if "swim_drag" in actor else 6.0
	actor.velocity = actor.velocity.move_toward(target, drag * delta)

	# Swim jump when pressing jump
	if input.get("jump_pressed", false):
		var sj: float = actor.swim_jump_speed if "swim_jump_speed" in actor else -360.0
		actor.velocity.y = sj


func _update_drop_through(actor: CharacterBody2D, delta: float, down_pressed: bool, jump_pressed: bool) -> void:
	if down_pressed and jump_pressed and actor.is_on_floor():
		if not dropping_through:
			original_mask = actor.collision_mask
			dropping_through = true
			drop_timer = actor.drop_through_time if "drop_through_time" in actor else 0.2
			var clear_bits := (1 << ONE_WAY_LAYER_BIT) | (1 << PLAYER_FALLBACK_LAYER_BIT)
			actor.collision_mask = original_mask & ~clear_bits
			if actor.velocity.y < 0.0:
				actor.velocity.y = 0.0
			actor.velocity.y += 50.0
	if dropping_through:
		drop_timer -= delta
		if drop_timer <= 0.0:
			dropping_through = false
			actor.collision_mask = original_mask


func _slope_accel_scale(actor: CharacterBody2D, dir: float) -> float:
	if not actor.is_on_floor():
		return 1.0
	var n := actor.get_floor_normal()
	var angle := Vector2.UP.angle_to(n)
	var slope_ratio: float = clamp(angle / 0.785398, 0.0, 1.0)
	var uphill: bool = sign(dir) != 0 and sign(dir) == -sign(n.x)
	var downhill: bool = sign(dir) != 0 and sign(dir) == sign(n.x)
	var penalty: float = actor.slope_penalty if "slope_penalty" in actor else 0.5
	if uphill:
		return max(0.1, 1.0 - slope_ratio * penalty)
	if downhill:
		return 1.0 + slope_ratio * 0.2
	return 1.0


func _update_wall_normal(actor: CharacterBody2D) -> void:
	wall_normal = Vector2.ZERO
	if actor.is_on_floor():
		return
	var count := actor.get_slide_collision_count()
	for i in range(count):
		var col := actor.get_slide_collision(i)
		if col == null:
			continue
		var n := col.get_normal()
		if abs(n.x) > 0.1 and n.dot(Vector2.UP) < 0.9:
			wall_normal = n
			return
