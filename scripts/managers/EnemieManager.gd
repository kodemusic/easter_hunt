extends Node

@export var rabbit: Node3D
@export var player: Node3D
@export var spawn_points: Array[Marker3D]
@export var min_interval: float = 10.0
@export var max_interval: float = 40.0

var _spawn_timer: float = 0.0
var _egg_count: int = 0

func _ready() -> void:
	GameManager.egg_collected.connect(_on_egg_collected)
	if rabbit == null:
		push_error("EnemieManager: 'rabbit' export is not assigned in the editor.")
	else:
		rabbit.player_caught.connect(_on_player_caught)
	_reset_timer()

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		show_rabbit_at_random()
		_reset_timer()

func _reset_timer() -> void:
	var interval := maxf(min_interval, max_interval - _egg_count * 5.0)
	_spawn_timer = randf_range(interval * 0.6, interval)

func show_rabbit_at_random() -> void:
	if spawn_points.is_empty() or rabbit == null or player == null:
		return
	var point: Marker3D = spawn_points.pick_random()
	rabbit.appear_at(point.global_position, player)

func chase_from_random() -> void:
	if spawn_points.is_empty() or rabbit == null or player == null:
		return
	var point: Marker3D = spawn_points.pick_random()
	rabbit.appear_at(point.global_position, player)
	rabbit.begin_chase(2.0)

func _on_egg_collected(total: int) -> void:
	_egg_count = total

func _on_player_caught() -> void:
	await get_tree().create_timer(0.6).timeout
	get_tree().reload_current_scene()
