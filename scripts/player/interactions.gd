extends Node

@export var camera: Camera3D
@export var interact_distance: float = 2.5

var _current_target: Node3D = null

func _ready() -> void:
	if camera == null:
		push_error("Interactions: camera is not assigned on " + str(get_path()))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_target != null:
		_current_target.interact()

func _physics_process(_delta: float) -> void:
	_current_target = _cast_interact_ray()

func _cast_interact_ray() -> Node3D:
	if camera == null:
		return null

	var space := get_viewport().get_world_3d().direct_space_state
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var end := origin + forward * interact_distance

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	# Exclude the player body so we don't hit ourselves
	var player := get_parent()
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]

	var result := space.intersect_ray(query)
	if result.is_empty():
		return null

	# Walk up to scene root of the hit object looking for "interactable" group
	var node: Node = result.collider
	while node != null:
		if node.is_in_group("interactable"):
			return node as Node3D
		node = node.get_parent()

	return null
