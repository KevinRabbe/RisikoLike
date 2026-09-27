extends Node

const MAIN_MENU := "res://scenes/menu/MainMenu.tscn"
const SETTINGS := "res://scenes/menu/Settings.tscn"
const LOCAL_SETUP := "res://scenes/menu/LocalSetup.tscn"
const GAME := "res://scenes/game/Game.tscn"

func go_to_main_menu() -> void:
	change_scene(MAIN_MENU)

func go_to_settings() -> void:
	change_scene(SETTINGS)

func go_to_local_setup() -> void:
	change_scene(LOCAL_SETUP)

func go_to_game() -> void:
	change_scene(GAME)

func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_error("[APP] Refusing empty scene path")
		return
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("[APP] Failed to change scene to %s (error %d)" % [scene_path, error])
