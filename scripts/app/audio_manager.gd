extends Node

func apply_settings() -> void:
	_set_bus_volume("Master", SettingsManager.master_volume)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(linear_value, 0.0, 1.0)))
