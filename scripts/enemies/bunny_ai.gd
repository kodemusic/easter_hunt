extends CharacterBody3D

signal player_caught

enum State { HIDDEN, VISIBLE, CHASE, CATCH }

@export var move_speed: float = 3.0
@export var acceleration: float = 8.0
@export var turn_speed: float = 6.0
@export var chase_duration: float = 6.0
@export var stare_duration: float = 2.5
@export var catch_distance: float = 1.0
@export var near_distance: float = 6.0
@export var flashlight: SpotLight3D
@export var idle_speed: float = 1.0
@export var walk_speed: float = 1.0
@export var stab_speed: float = 1.0

const GRAVITY := 18.0

var state = State.HIDDEN
var player: Node3D
var chase_timer := 0.0
var _stare_timer := 0.0
var _anim: AnimationPlayer
var _caught := false
var _debug_tick := 0.0

func _ready() -> void:
	_anim = $AnimationPlayer
	print("[Bunny] animations available: ", _anim.get_animation_list())
	set_hidden()

func set_hidden() -> void:
	state = State.HIDDEN
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if flashlight:
		flashlight.set_bunny_near(false)
	print("[Bunny] → HIDDEN")

func appear_at(pos: Vector3, target: Node3D) -> void:
	global_position = pos
	player = target
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	state = State.VISIBLE
	_stare_timer = stare_duration
	chase_timer = 0.0
	_caught = false
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	_anim.speed_scale = idle_speed
	_anim.play("idle")
	print("[Bunny] → VISIBLE at ", pos, " | stare_timer=", stare_duration)

func begin_chase(duration: float = -1.0) -> void:
	state = State.CHASE
	chase_timer = duration if duration > 0.0 else chase_duration
	_anim.speed_scale = walk_speed
	_anim.play("walk")
	print("[Bunny] → CHASE | chase_timer=", chase_timer)

func _physics_process(delta: float) -> void:
	if state == State.HIDDEN or player == null or _caught:
		return

	_debug_tick -= delta
	if _debug_tick <= 0.0:
		_debug_tick = 1.0
		var dist := global_position.distance_to(player.global_position)
		print("[Bunny] state=", State.keys()[state], " dist=", snappedf(dist, 0.1),
			" stare=", snappedf(_stare_timer, 0.1), " chase=", snappedf(chase_timer, 0.1))

	_update_flashlight_proximity()

	match state:
		State.VISIBLE:
			_tick_visible(delta)
		State.CHASE:
			_tick_chase(delta)

func _tick_visible(delta: float) -> void:
	_smooth_look_at(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_stare_timer -= delta
	if _stare_timer <= 0.0:
		begin_chase()

func _tick_chase(delta: float) -> void:
	chase_timer -= delta

	var dist := global_position.distance_to(player.global_position)
	if dist < catch_distance:
		_trigger_catch()
		return

	if chase_timer <= 0.0:
		set_hidden()
		return

	var dir := (player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()

	var target_vx := dir.x * move_speed
	var target_vz := dir.z * move_speed
	velocity.x = lerp(velocity.x, target_vx, acceleration * delta)
	velocity.z = lerp(velocity.z, target_vz, acceleration * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	_smooth_look_at(delta)
	move_and_slide()

func _smooth_look_at(delta: float) -> void:
	var target := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	if target.is_equal_approx(global_position):
		return
	var target_basis := Basis.looking_at(target - global_position, Vector3.UP)
	basis = basis.orthonormalized().slerp(target_basis, turn_speed * delta)

func _trigger_catch() -> void:
	_caught = true
	state = State.CATCH
	velocity = Vector3.ZERO
	_anim.speed_scale = stab_speed
	_anim.play("stab")
	print("[Bunny] → CATCH — emitting player_caught")
	emit_signal("player_caught")

func _update_flashlight_proximity() -> void:
	if not flashlight or player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	flashlight.set_bunny_near(dist < near_distance)
