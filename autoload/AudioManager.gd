extends Node

# ─────────────────────────────────────────────────────────────────────────────
# AudioManager — all audio routing goes through here.
#
# ADDING NEW SOUND BANKS:
#   1. Add a const Array for the files
#   2. Add a var AudioStreamPlayer for the channel
#   3. Create it in _ready() with _make_player()
#   4. Add a public play_*() method
#
# ADDING NEW RANDOM-PICK BANKS (like footsteps/ambience stings):
#   1. Add a const Array with the clips
#   2. Call _play_random(array, player) in your method
# ─────────────────────────────────────────────────────────────────────────────

# ── Single streams ────────────────────────────────────────────────────────────
const _MUSIC  := preload("res://audio/music/837910__universfield__tense-horror-atmosphere.mp3")
const _RABBIT := preload("res://audio/sfx/397312__quetzalcontla__rabbit-3.wav")
const _GATE   := preload("res://audio/sfx/doors/gate_close.mp3")
const _WHISPERS := preload("res://audio/ambience/atmosphere/whispers.mp3")

# ── Random-pick banks ─────────────────────────────────────────────────────────
const _AMBIENCE_BANK: Array = [
	preload("res://audio/ambience/SewerSounds/626096__resaural__backrooms-ambience.wav"),
	preload("res://audio/ambience/SewerSounds/408532__170084__factory-with-machines-ambience.wav"),
	preload("res://audio/ambience/SewerSounds/343763__inspectorj__dripping-medium-a.wav"),
]

const _STEPS_BANK: Array = [
	preload("res://audio/sfx/footsteps/464610__d001447733__water_footsteps.wav"),
	preload("res://audio/sfx/footsteps/611278__xkeril__footsteps-on-slush.wav"),
	preload("res://audio/sfx/footsteps/204035__duckduckpony__footsteps_water_light_008.wav")
]

const _ENEMY_STING_BANK: Array = [
	preload("res://audio/sfx/enemy/732772__avstudent__clangs-distant-creepy.wav"),
]

# ── Volume exports ────────────────────────────────────────────────────────────
@export_group("Volume (dB)")
@export_range(-40.0, 6.0, 0.5) var music_db: float       = -12.0
@export_range(-40.0, 6.0, 0.5) var ambience_db: float    = -10.0
@export_range(-40.0, 6.0, 0.5) var rabbit_db: float      = 0.0
@export_range(-40.0, 6.0, 0.5) var gate_db: float        = -2.0
@export_range(-40.0, 6.0, 0.5) var footstep_db: float    = -14.0
@export_range(-40.0, 6.0, 0.5) var enemy_sting_db: float = -6.0
@export_range(-40.0, 6.0, 0.5) var whispers_db: float    = -8.0

# ── Fade exports ──────────────────────────────────────────────────────────────
@export_group("Fades (seconds)")
@export_range(0.0, 5.0, 0.1) var music_fade_in: float    = 2.0
@export_range(0.0, 5.0, 0.1) var music_fade_out: float   = 1.5
@export_range(0.0, 5.0, 0.1) var ambience_fade_in: float = 3.0
@export_range(0.0, 5.0, 0.1) var ambience_crossfade: float = 4.0

# ── Players ───────────────────────────────────────────────────────────────────
var _players: Dictionary = {}

# ── Rabbit / ambience state ───────────────────────────────────────────────────
var _rabbit_active: bool  = false
var _rabbit_timer: float  = 0.0
var _ambience_timer: float = 0.0
var _ambience_idx: int    = 0   # which bank clip is currently playing

func _ready() -> void:
	_ensure_buses()
	_players["music"]       = _make_player(_MUSIC,   music_db,       true,  "Music")
	_players["ambience"]    = _make_player(null,      ambience_db,    false, "Music")
	_players["ambience_b"]  = _make_player(null,      -40.0,          false, "Music")  # crossfade second slot
	_players["rabbit"]      = _make_player(_RABBIT,   rabbit_db,      false, "SFX")
	_players["gate"]        = _make_player(_GATE,     gate_db,        false, "SFX")
	_players["footstep"]    = _make_player(null,      footstep_db,    false, "SFX")
	_players["enemy_sting"] = _make_player(null,      enemy_sting_db, false, "SFX")
	_players["whispers"]    = _make_player(_WHISPERS, whispers_db,    false, "SFX")
	# Start music with fade-in
	_players["music"].volume_db = -40.0
	_players["music"].play()
	_fade_to(_players["music"], music_db, music_fade_in)

	# Start first ambience clip
	_start_ambience_clip(0, ambience_fade_in)

	_rabbit_timer  = randf_range(4.0, 8.0)
	_ambience_timer = _get_ambience_clip_length(0)

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")

func _make_player(stream, volume_db: float, loop: bool, bus: String = "Master") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.bus = bus
	if stream != null and loop:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	add_child(p)
	return p

func _process(delta: float) -> void:
	# Rabbit periodic sound
	if _rabbit_active:
		_rabbit_timer -= delta
		if _rabbit_timer <= 0.0:
			_play_rabbit_periodic()
			_rabbit_timer = randf_range(4.0, 8.0)

	# Ambience auto-advance (crossfade between bank clips)
	_ambience_timer -= delta
	if _ambience_timer <= 0.0:
		_advance_ambience()

# ── Ambience cycling ──────────────────────────────────────────────────────────

func _start_ambience_clip(idx: int, fade_in: float) -> void:
	var clip: AudioStream = _AMBIENCE_BANK[idx % _AMBIENCE_BANK.size()]
	var p: AudioStreamPlayer = _players["ambience"]
	p.stream = clip
	p.volume_db = -40.0
	p.play()
	_fade_to(p, ambience_db, fade_in)

func _advance_ambience() -> void:
	var next_idx := (_ambience_idx + 1) % _AMBIENCE_BANK.size()
	var clip: AudioStream = _AMBIENCE_BANK[next_idx]
	# Swap slots: fade out current into "ambience", fade in next into "ambience_b"
	var pa: AudioStreamPlayer = _players["ambience"]
	var pb: AudioStreamPlayer = _players["ambience_b"]
	pb.stream = clip
	pb.volume_db = -40.0
	pb.play()
	_fade_to(pa, -40.0, ambience_crossfade)
	_fade_to(pb, ambience_db, ambience_crossfade)
	# Swap references so "ambience" always points to the active slot
	_players["ambience"]   = pb
	_players["ambience_b"] = pa
	_ambience_idx = next_idx
	_ambience_timer = _get_ambience_clip_length(next_idx)

func _get_ambience_clip_length(idx: int) -> float:
	var clip: AudioStream = _AMBIENCE_BANK[idx % _AMBIENCE_BANK.size()]
	var clip_len := clip.get_length()
	# If clip has no length (looping wav reports 0), default to 30s
	return clip_len if clip_len > 1.0 else 30.0

# ── Fade helper ───────────────────────────────────────────────────────────────

func _fade_to(player: AudioStreamPlayer, target_db: float, duration: float) -> void:
	if duration <= 0.0:
		player.volume_db = target_db
		return
	var t := create_tween()
	t.tween_property(player, "volume_db", target_db, duration)

# ── Random-pick helper ────────────────────────────────────────────────────────

func _play_random(bank: Array, player: AudioStreamPlayer) -> void:
	player.stream = bank[randi() % bank.size()]
	player.play()

# ═══════════════════════════════════════════════════════════════════════════════
# Public API
# ═══════════════════════════════════════════════════════════════════════════════

## Bunny spawns — loud one-shot
func play_rabbit_appear() -> void:
	_players["rabbit"].volume_db = rabbit_db
	_players["rabbit"].play()
	_rabbit_timer = randf_range(5.0, 9.0)

## Call every frame from bunny_ai with proximity/chase state
func set_rabbit_active(is_active: bool) -> void:
	_rabbit_active = is_active

## Gate opens
func play_gate_open() -> void:
	_players["gate"].play()

## Footstep — random pick, pitch varied
func play_footstep() -> void:
	_players["footstep"].pitch_scale = randf_range(0.85, 0.9)
	_play_random(_STEPS_BANK, _players["footstep"])

## Distant enemy sting — random pick from enemy bank
func play_enemy_sting() -> void:
	_play_random(_ENEMY_STING_BANK, _players["enemy_sting"])

## Music fade out (e.g. on death screen)
func fade_out_music() -> void:
	_fade_to(_players["music"], -40.0, music_fade_out)

## Music fade in (e.g. on scene reload)
func fade_in_music() -> void:
	_fade_to(_players["music"], music_db, music_fade_in)

## Set whole bus volume (0.0–1.0 linear) — call from settings UI
func set_music_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(linear))

func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(linear))

## Set a single channel by key
func set_channel_db(key: String, db: float) -> void:
	if _players.has(key):
		_players[key].volume_db = db

# ── Internal ──────────────────────────────────────────────────────────────────

func _play_rabbit_periodic() -> void:
	_players["rabbit"].volume_db = rabbit_db - 5.0
	_players["rabbit"].play()