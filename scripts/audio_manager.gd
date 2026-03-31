extends Node
## Audio manager autoload — call SFX.play_sfx("hit") from anywhere.
## Drop .wav files into res://audio/sfx/ and .ogg into res://audio/music/.
## Files are loaded by filename (without extension) as the key.

# ── SFX pool (polyphonic, non-positional) ──────────────────────────────────
const SFX_POOL_SIZE := 12
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0

# ── Music player ───────────────────────────────────────────────────────────
var _music_player: AudioStreamPlayer

# ── Loaded streams keyed by name ───────────────────────────────────────────
var sfx_streams: Dictionary = {}
var music_streams: Dictionary = {}

# ── Volume (linear, 0.0–1.0) ──────────────────────────────────────────────
var sfx_volume: float = 1.0
var music_volume: float = 0.7


func _ready() -> void:
	# Create SFX player pool
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	# Ensure audio buses exist
	_ensure_buses()
	# Scan directories for audio files
	_scan_dir("res://audio/sfx", sfx_streams)
	_scan_dir("res://audio/music", music_streams)


func _ensure_buses() -> void:
	# Add SFX and Music buses if they don't exist
	for bus_name in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _scan_dir(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir():
			# Skip .import files
			if file.ends_with(".import"):
				file = dir.get_next()
				continue
			var full_path := path + "/" + file
			var stream = load(full_path)
			if stream is AudioStream:
				# Key = filename without extension
				var key := file.get_basename()
				target[key] = stream
		file = dir.get_next()


# ── Public API ─────────────────────────────────────────────────────────────

## Play a sound effect by name. Optionally set pitch and volume scale.
func play_sfx(sfx_name: String, pitch: float = 1.0, volume_scale: float = 1.0) -> void:
	if not sfx_streams.has(sfx_name):
		return
	var player := _sfx_players[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % SFX_POOL_SIZE
	player.stream = sfx_streams[sfx_name]
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.play()


## Play a sound effect with random pitch variation (good for hits, bounces).
func play_sfx_varied(sfx_name: String, pitch_min: float = 0.9, pitch_max: float = 1.1, volume_scale: float = 1.0) -> void:
	play_sfx(sfx_name, randf_range(pitch_min, pitch_max), volume_scale)


## Play music by name. Loops by default.
func play_music(music_name: String) -> void:
	if not music_streams.has(music_name):
		return
	_music_player.stream = music_streams[music_name]
	_music_player.volume_db = linear_to_db(music_volume)
	_music_player.play()


## Stop music.
func stop_music() -> void:
	_music_player.stop()


## Check if a sound effect exists (for optional sounds).
func has_sfx(sfx_name: String) -> bool:
	return sfx_streams.has(sfx_name)
