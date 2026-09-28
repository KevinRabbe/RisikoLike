extends Node

## M14 audio boundary. UI and gameplay call named events; generated fallback
## tones keep the build functional until licensed production assets are added.
const SAMPLE_RATE := 44100.0
const EFFECTS := {
	"ui_hover": [720.0, 0.025, 0.035],
	"ui_click": [520.0, 0.055, 0.065],
	"error": [170.0, 0.14, 0.08],
	"notification": [620.0, 0.11, 0.055],
	"turn_start": [390.0, 0.16, 0.055],
	"own_turn": [760.0, 0.18, 0.07],
	"territory_select": [680.0, 0.045, 0.045],
	"reinforcement": [480.0, 0.09, 0.055],
	"dice_roll": [250.0, 0.18, 0.045],
	"conquest": [440.0, 0.24, 0.06],
	"card_draw": [600.0, 0.12, 0.05],
	"card_trade": [840.0, 0.14, 0.06],
	"elimination": [210.0, 0.22, 0.06],
	"victory": [520.0, 0.32, 0.065]
}

var music_player: AudioStreamPlayer
var music_active := false

func _ready() -> void:
	call_deferred("apply_settings")

func apply_settings() -> void:
	_set_bus_volume("Master", SettingsManager.master_volume)
	_set_bus_volume("Music", SettingsManager.music_volume)
	_set_bus_volume("SFX", SettingsManager.sfx_volume)
	if SettingsManager.music_volume <= 0.001:
		stop_music()

func attach_feedback(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			var button := child as Button
			if not button.has_meta("atlas_audio_bound"):
				button.set_meta("atlas_audio_bound", true)
				button.pressed.connect(play_ui_click)
				button.mouse_entered.connect(play_ui_hover)
		attach_feedback(child)

func play_ui_hover() -> void:
	play_event("ui_hover")

func play_ui_click() -> void:
	play_event("ui_click")

func play_event(event_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not EFFECTS.has(event_name) or SettingsManager.sfx_volume <= 0.001:
		return
	var values: Array = EFFECTS[event_name]
	_play_tone(float(values[0]), float(values[1]), float(values[2]))

func start_music() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if music_active or SettingsManager.music_volume <= 0.001:
		return
	music_active = true
	_play_music_buffer()

func stop_music() -> void:
	music_active = false
	if music_player != null:
		music_player.stop()

func _play_tone(frequency: float, duration: float, amplitude: float) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = duration + 0.04
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := int(SAMPLE_RATE * duration)
	for index in range(frames):
		var progress := float(index) / maxf(1.0, float(frames))
		var envelope := 1.0 - progress
		var sample := sin(TAU * frequency * float(index) / SAMPLE_RATE) * amplitude * envelope
		playback.push_frame(Vector2(sample, sample))

func _play_music_buffer() -> void:
	if not music_active:
		return
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.bus = "Music"
		add_child(music_player)
	var duration := 6.0
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = duration + 0.1
	music_player.stream = stream
	music_player.play()
	var playback := music_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback != null:
		var frames := int(SAMPLE_RATE * duration)
		for index in range(frames):
			var time := float(index) / SAMPLE_RATE
			var sample := (sin(TAU * 82.4 * time) * 0.018 + sin(TAU * 123.5 * time) * 0.012) * 0.45
			playback.push_frame(Vector2(sample, sample))
	if not music_player.finished.is_connected(_on_music_finished):
		music_player.finished.connect(_on_music_finished)

func _on_music_finished() -> void:
	if music_active:
		_play_music_buffer()

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var value := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(value))
