extends Node

func _ready() -> void:
	call_deferred("apply_settings")

func apply_settings() -> void:
	_set_bus_volume("Master", SettingsManager.master_volume)
	_set_bus_volume("Music", SettingsManager.music_volume)
	_set_bus_volume("SFX", SettingsManager.sfx_volume)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var value := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(value))
