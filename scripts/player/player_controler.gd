extends CharacterBody3D

@export var walk_speed: float = 4.2
@export var sprint_speed: float = 5.8
@export var acceleration: float = 10.0
@export var gravity: float = 18.0
@export var mouse_sensitivity: float = 0.14

# --- Head Bob ---
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.05

@onready var camera: Camera3D = $Camera3D

var pitch: float = 0.0
var _bob_timer: float = 0.0
var _camera_base_y: float = 0.0
var _step_timer: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_camera_base_y = camera.position.y

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -80.0, 80.0)
		camera.rotation_degrees.x = pitch

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	var input_vec := Vector2.ZERO

	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_vec = input_vec.normalized()

	var move_dir := Vector3.ZERO
	move_dir += transform.basis.x * input_vec.x
	move_dir += transform.basis.z * input_vec.y
	move_dir = move_dir.normalized()

	var current_speed := walk_speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	var target_velocity := move_dir * current_speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_apply_headbob(delta)

func _apply_headbob(delta: float) -> void:
	var flat_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and flat_speed > 0.5:
		_bob_timer += delta * bob_frequency * (flat_speed / walk_speed)
		camera.position.y = _camera_base_y + sin(_bob_timer * TAU) * bob_amplitude
		_step_timer -= delta
		if _step_timer <= 0.0:
			AudioManager.play_footstep()
			_step_timer = 0.5 / (bob_frequency * (flat_speed / walk_speed))
	else:
		_bob_timer = lerp(_bob_timer, 0.0, delta * 6.0)
		camera.position.y = lerp(camera.position.y, _camera_base_y, delta * 6.0)
