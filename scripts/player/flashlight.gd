extends SpotLight3D

@export_group("Brightness")
@export_range(0.1, 8.0, 0.05) var base_energy: float = 2.4
@export_range(0.0, 0.5, 0.01) var micro_noise: float = 0.05   # Layer 1: constant micro jitter ±

@export_group("Flicker — Normal")
@export_range(0.5, 20.0, 0.5) var idle_interval_min: float = 3.0
@export_range(0.5, 20.0, 0.5) var idle_interval_max: float = 8.0
@export_range(0.0, 2.0, 0.05) var idle_dip: float = 0.5        # how far energy drops during event

@export_group("Flicker — Bunny Near")
@export_range(0.1, 5.0, 0.1) var chase_interval_min: float = 1.0
@export_range(0.1, 5.0, 0.1) var chase_interval_max: float = 2.0
@export_range(0.0, 2.0, 0.05) var chase_dip: float = 0.5

# Layer 2: macro flicker state
var _flicker_timer: float = 0.0
var _flicker_active: bool = false
var _bunny_near: bool = false

# Called by bunny_ai.gd when the bunny enters/exits detection range.
func set_bunny_near(is_near: bool) -> void:
	_bunny_near = is_near
	if is_near:
		_flicker_timer = randf_range(chase_interval_min, chase_interval_max)

func _process(delta: float) -> void:
	# Layer 2: macro flicker event timer
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		if _bunny_near:
			_flicker_timer = randf_range(chase_interval_min, chase_interval_max)
		else:
			_flicker_timer = randf_range(idle_interval_min, idle_interval_max)
		_flicker_active = true

	# Layer 1: constant micro noise
	var energy := base_energy + randf_range(-micro_noise, micro_noise)

	# Layer 2: dramatic dip during active flicker event
	if _flicker_active:
		var dip := chase_dip if _bunny_near else idle_dip
		energy += randf_range(-dip, dip * 0.4)
		if randf() < 0.1:
			_flicker_active = false

	light_energy = energy
