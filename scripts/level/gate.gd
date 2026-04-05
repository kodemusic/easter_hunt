extends Node3D

# Hide this gate node when the player collects enough eggs.
@export var eggs_required: int = 1

@export_group("Sound")
@export_range(0.0, 10.0, 0.5) var gate_sound_delay: float = 3.0

@export_group("Camera Shake")
@export_range(0.0, 0.5, 0.005) var shake_intensity: float = 0.04
@export_range(0.0, 3.0, 0.1)   var shake_duration: float  = 0.7

func _ready() -> void:
	GameManager.egg_collected.connect(_on_egg_collected)

func _on_egg_collected(total: int) -> void:
	if total >= eggs_required:
		visible = false
		for child in find_children("*", "CollisionShape3D", true, false):
			child.disabled = true
		await get_tree().create_timer(gate_sound_delay).timeout
		AudioManager.play_gate_open()
		get_viewport().get_camera_3d().call("shake", shake_intensity, shake_duration)
