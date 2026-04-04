extends Node3D

# Hide this gate node when the player collects enough eggs.
@export var eggs_required: int = 1

func _ready() -> void:
	GameManager.egg_collected.connect(_on_egg_collected)

func _on_egg_collected(total: int) -> void:
	if total >= eggs_required:
		AudioManager.play_gate_open()
		visible = false
		# Disable all collision shapes so the player can walk through
		for child in find_children("*", "CollisionShape3D", true, false):
			child.disabled = true
