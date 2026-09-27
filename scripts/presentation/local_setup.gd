extends Control

@onready var player_count: SpinBox = %PlayerCount
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	player_count.value = 2
	status_label.text = "Lokaler Hotseat-Debugmodus bis M4"

func _on_start_pressed() -> void:
	var count := int(player_count.value)
	if count < Ruleset.MIN_PLAYERS or count > Ruleset.MAX_PLAYERS:
		status_label.text = "Spielerzahl muss zwischen 2 und 5 liegen."
		return
	get_tree().set_meta("local_player_count", count)
	SceneRouter.go_to_game()

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()
