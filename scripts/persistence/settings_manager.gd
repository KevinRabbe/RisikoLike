extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_PLAYER_NAME := "Spieler"

var player_name: String = DEFAULT_PLAYER_NAME
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var language: String = "de"

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	player_name = str(config.get_value("general", "player_name", DEFAULT_PLAYER_NAME))
	language = str(config.get_value("general", "language", "de"))
	master_volume = float(config.get_value("audio", "master", 1.0))
	music_volume = float(config.get_value("audio", "music", 0.8))
	sfx_volume = float(config.get_value("audio", "sfx", 1.0))

func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("general", "player_name", player_name)
	config.set_value("general", "language", language)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	return config.save(SETTINGS_PATH)
