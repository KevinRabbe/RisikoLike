extends Node

const MAIN_MENU := "res://scenes/menu/MainMenu.tscn"
const SETTINGS := "res://scenes/menu/Settings.tscn"

func go_to_main_menu() -> void:
	change_scene(MAIN_MENU)

func go_to_settings() -> void:
	change_scene(SETTINGS)

func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_error("[APP] Refusing empty scene path")
		return
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("[APP] Failed to change scene to %s (error %d)" % [scene_path, error])
