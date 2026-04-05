extends Camera3D

var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _shake_duration: float = 0.0

## Call this from anywhere: get_viewport().get_camera_3d().shake(0.05, 0.6)
func shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration  = duration
	_shake_timer     = duration

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var progress := _shake_timer / _shake_duration          # 1 → 0
		var mag := _shake_intensity * progress                  # fades out
		h_offset = randf_range(-mag, mag)
		v_offset = randf_range(-mag, mag)
	else:
		h_offset = 0.0
		v_offset = 0.0
