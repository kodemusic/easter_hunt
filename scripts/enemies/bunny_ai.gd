extends CharacterBody3D

signal player_caught

enum State { HIDDEN, VISIBLE, CHASE, CATCH }

@export var move_speed: float = 3.0
@export var chase_duration: float = 6.0
@export var stare_duration: float = 2.5
@export var catch_distance: float = 1.0
@export var near_distance: float = 6.0
@export var flashlight: SpotLight3D

var state = State.HIDDEN
var player: Node3D
var chase_timer := 0.0
var _stare_timer := 0.0
var _anim: AnimationPlayer
var _caught := false

func _ready() -> void:
	_anim = $AnimationPlayer
	set_hidden()

func set_hidden() -> void:
	state = State.HIDDEN
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if flashlight:
		flashlight.set_bunny_near(false)

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
	_anim.play("idle")

func begin_chase(duration: float = -1.0) -> void:
	state = State.CHASE
	chase_timer = duration if duration > 0.0 else chase_duration
	_anim.play("walk")

func _physics_process(delta: float) -> void:
	if state == State.HIDDEN or player == null or _caught:
		return

	_update_flashlight_proximity()

	match state:
		State.VISIBLE:
			_tick_visible(delta)
		State.CHASE:
			_tick_chase(delta)

func _tick_visible(delta: float) -> void:
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
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
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	move_and_slide()

func _trigger_catch() -> void:
	_caught = true
	state = State.CATCH
	velocity = Vector3.ZERO
	_anim.play("stab")
	emit_signal("player_caught")

func _update_flashlight_proximity() -> void:
	if not flashlight or player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	flashlight.set_bunny_near(dist < near_distance)
