extends Node

# ── Streams ──────────────────────────────────────────────────────────────────
const _MUSIC     := preload("res://audio/music/837910__universfield__tense-horror-atmosphere.mp3")
const _AMBIENCE  := preload("res://audio/ambience/SewerSounds/626096__resaural__backrooms-ambience.wav")
const _RABBIT    := preload("res://audio/sfx/397312__quetzalcontla__rabbit-3.wav")
const _GATE      := preload("res://audio/sfx/doors/386531__glennm__gate_closing_interact_edit.wav")
const _STEPS: Array = [
	preload("res://audio/sfx/footsteps/204035__duckduckpony__footsteps_water_light_008.wav"),
	preload("res://audio/sfx/footsteps/464610__d001447733__water_footsteps.wav"),
	preload("res://audio/sfx/footsteps/611278__xkeril__footsteps-on-slush.wav"),
]

# ── Players ───────────────────────────────────────────────────────────────────
var _music:     AudioStreamPlayer
var _ambience:  AudioStreamPlayer
var _rabbit:    AudioStreamPlayer
var _gate:      AudioStreamPlayer
var _footstep:  AudioStreamPlayer

# ── Rabbit state ──────────────────────────────────────────────────────────────
var _rabbit_active: bool = false   # true when near OR chasing
var _rabbit_timer: float = 0.0

func _ready() -> void:
	_music    = _make_player(_MUSIC,    -12.0, true)
	_ambience = _make_player(_AMBIENCE, -8.0,  true)
	_rabbit   = _make_player(_RABBIT,   0.0,   false)
	_gate     = _make_player(_GATE,    -2.0,   false)
	_footstep = _make_player(null,     -14.0,  false)

	_music.play()
	_ambience.play()
	_rabbit_timer = randf_range(4.0, 8.0)

func _make_player(stream, volume_db: float, loop: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	if stream and loop:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	add_child(p)
	return p

func _process(delta: float) -> void:
	if not _rabbit_active:
		return
	_rabbit_timer -= delta
	if _rabbit_timer <= 0.0:
		_play_rabbit_periodic()
		_rabbit_timer = randf_range(4.0, 8.0)

# ── Public API ────────────────────────────────────────────────────────────────

## Call from bunny_ai when bunny spawns in (loud one-shot scare hit)
func play_rabbit_appear() -> void:
	_rabbit.volume_db = 0.0
	_rabbit.play()
	_rabbit_timer = randf_range(5.0, 9.0)  # brief pause before periodic starts

## Call from bunny_ai each frame with current near/chasing state
func set_rabbit_active(is_active: bool) -> void:
	_rabbit_active = is_active

## Call from gate.gd when gate opens
func play_gate_open() -> void:
	_gate.play()

## Call from player_controler.gd on each footstep
func play_footstep() -> void:
	_footstep.stream = _STEPS[randi() % _STEPS.size()]
	_footstep.pitch_scale = randf_range(0.9, 1.1)
	_footstep.play()

# ── Internal ──────────────────────────────────────────────────────────────────
func _play_rabbit_periodic() -> void:
	_rabbit.volume_db = -5.0
	_rabbit.play()
