extends CharacterBody3D

func interact() -> void:
	GameManager.collect_egg()
	queue_free()
