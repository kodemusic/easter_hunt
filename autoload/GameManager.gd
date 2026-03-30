extends Node

signal egg_collected(total: int)

var egg_count: int = 0

func collect_egg() -> void:
	egg_count += 1
	emit_signal("egg_collected", egg_count)
