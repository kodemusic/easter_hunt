extends SpotLight3D

@export var base_energy: float = 2.4

# Layer 2: macro flicker state
var _flicker_timer: float = 0.0
var _flicker_active: bool = false
var _bunny_near: bool = false

# Called by bunny_ai.gd when the bunny enters/exits detection range.
func set_bunny_near(is_near: bool) -> void:
	_bunny_near = is_near
	if is_near:
		_flicker_timer = randf_range(1.0, 2.0)

func _process(delta: float) -> void:
	# Layer 2: macro flicker event timer
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(1.0, 2.0) if _bunny_near else randf_range(3.0, 8.0)
		_flicker_active = true

	# Layer 1: constant micro noise
	var energy := base_energy + randf_range(-0.05, 0.05)

	# Layer 2: dramatic dip during active flicker event
	if _flicker_active:
		energy += randf_range(-0.5, 0.2)
		if randf() < 0.1:
			_flicker_active = false

	light_energy = energy
