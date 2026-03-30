extends Node

@export var camera: Camera3D
@export var interact_distance: float = 2.5

var _current_target: Node3D = null

func _ready() -> void:
	if camera == null:
		push_error("Interactions: camera is not assigned on " + str(get_path()))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_instance_valid(_current_target):
		_current_target.interact()
		_current_target = null

func _physics_process(_delta: float) -> void:
	_current_target = _find_nearest_interactable()

func _find_nearest_interactable() -> Node3D:
	if camera == null:
		return null

	var origin := camera.global_position
	var best: Node3D = null
	var best_dist := interact_distance

	for node in get_tree().get_nodes_in_group("interactable"):
		if not node is Node3D:
			continue
		if not node.has_method("interact"):
			continue
		var dist := origin.distance_to((node as Node3D).global_position)
		if dist < best_dist:
			best = node
			best_dist = dist

	return best
