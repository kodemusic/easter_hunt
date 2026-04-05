extends Node3D

enum Phase { STABLE, FLICKER, STABLE2, BLACKOUT }

@export_group("Base")
@export_range(0.0, 8.0, 0.05) var base_energy: float = 1.0
@export_range(0.0, 0.3, 0.01) var micro_noise: float = 0.04
@export_range(0.0, 10.0, 0.1) var start_offset: float = 0.0

@export_group("Stable Phase")
@export_range(0.5, 30.0, 0.5) var stable_min: float = 4.0
@export_range(0.5, 30.0, 0.5) var stable_max: float = 10.0

@export_group("Flicker Phase")
@export_range(0.2, 5.0, 0.1) var flicker_duration_min: float = 0.4
@export_range(0.2, 5.0, 0.1) var flicker_duration_max: float = 1.2
@export_range(0.0, 2.0, 0.05) var flicker_depth: float = 0.9
@export_range(0.0, 0.5, 0.01) var flicker_spike_chance: float = 0.08

@export_group("Blackout Phase")
@export_range(0.05, 3.0, 0.05) var blackout_min: float = 0.15
@export_range(0.05, 3.0, 0.05) var blackout_max: float = 0.5

var _light: OmniLight3D
var _phase: Phase = Phase.STABLE
var _phase_timer: float = 0.0

func _ready() -> void:
	_light = find_child("OmniLight3D", true, false)
	if _light == null:
		push_error("hall_light: no OmniLight3D child found in " + name)
		return
	# Use scene's existing energy as base if export is at default
	if base_energy == 1.0:
		base_energy = _light.light_energy
	_phase = Phase.STABLE
	_phase_timer = randf_range(stable_min, stable_max) + start_offset

func _process(delta: float) -> void:
	if _light == null:
		return

	_phase_timer -= delta

	match _phase:
		Phase.STABLE, Phase.STABLE2:
			_light.light_energy = base_energy + randf_range(-micro_noise, micro_noise)
			if _phase_timer <= 0.0:
				if _phase == Phase.STABLE:
					_enter_phase(Phase.FLICKER)
				else:
					_enter_phase(Phase.BLACKOUT)

		Phase.FLICKER:
			if randf() < flicker_spike_chance:
				_light.light_energy = randf_range(0.0, 0.1)
			else:
				_light.light_energy = base_energy + randf_range(-flicker_depth, flicker_depth * 0.3)
			_light.light_energy = maxf(_light.light_energy, 0.0)
			if _phase_timer <= 0.0:
				_enter_phase(Phase.STABLE2)

		Phase.BLACKOUT:
			_light.light_energy = 0.0
			if _phase_timer <= 0.0:
				_enter_phase(Phase.STABLE)

func _enter_phase(p: Phase) -> void:
	_phase = p
	match p:
		Phase.STABLE, Phase.STABLE2:
			_phase_timer = randf_range(stable_min, stable_max)
		Phase.FLICKER:
			_phase_timer = randf_range(flicker_duration_min, flicker_duration_max)
		Phase.BLACKOUT:
			_phase_timer = randf_range(blackout_min, blackout_max)
