extends Node3D

# Called by interactions.gd when the player looks at this and presses E.
# Full implementation (signal to GameManager, queue_free, etc.) comes next task.
func interact() -> void:
	print("egg picked up: ", name)
	queue_free()
