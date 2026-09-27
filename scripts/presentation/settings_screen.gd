extends Control

@onready var player_name_input: LineEdit = %PlayerNameInput
@onready var language_select: OptionButton = %LanguageSelect
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	player_name_input.text = SettingsManager.player_name
	language_select.select(0 if SettingsManager.language == "de" else 1)
	master_slider.value = SettingsManager.master_volume * 100.0
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	status_label.text = ""

func _on_save_pressed() -> void:
	var cleaned_name := player_name_input.text.strip_edges()
	if cleaned_name.length() < 2 or cleaned_name.length() > 20:
		status_label.text = "Spielername muss 2 bis 20 Zeichen lang sein."
		return

	SettingsManager.player_name = cleaned_name
	SettingsManager.language = "de" if language_select.selected == 0 else "en"
	SettingsManager.master_volume = master_slider.value / 100.0
	SettingsManager.music_volume = music_slider.value / 100.0
	SettingsManager.sfx_volume = sfx_slider.value / 100.0

	var error := SettingsManager.save_settings()
	if error != OK:
		status_label.text = "Einstellungen konnten nicht gespeichert werden."
		return

	AudioManager.apply_settings()
	status_label.text = "Gespeichert."

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()
