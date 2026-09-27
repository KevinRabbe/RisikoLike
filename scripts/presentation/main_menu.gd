extends Control

@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	version_label.text = "v%s" % App.GAME_VERSION

func _on_create_lobby_pressed() -> void:
	SceneRouter.go_to_create_lobby()

func _on_join_lobby_pressed() -> void:
	SceneRouter.go_to_join_lobby()

func _on_settings_pressed() -> void:
	SceneRouter.go_to_settings()

func _on_exit_pressed() -> void:
	get_tree().quit()
