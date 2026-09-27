extends Control

func _ready() -> void:
	AudioManager.apply_settings()
	call_deferred("_finish_boot")

func _finish_boot() -> void:
	SceneRouter.go_to_main_menu()
