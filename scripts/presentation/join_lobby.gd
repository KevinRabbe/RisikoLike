extends Control

var player_name_input: LineEdit
var address_input: LineEdit
var port_spin: SpinBox
var status_label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "Lokaler Lobby beitreten"
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)
	content.add_child(_label("Development Local Join — kein Internet-Backend"))
	content.add_child(_label("Spielername"))
	player_name_input = LineEdit.new()
	player_name_input.text = SettingsManager.player_name
	player_name_input.max_length = 20
	content.add_child(player_name_input)
	content.add_child(_label("Host-Adresse"))
	address_input = LineEdit.new()
	address_input.text = "127.0.0.1"
	content.add_child(address_input)
	content.add_child(_label("Development-Port"))
	port_spin = SpinBox.new()
	port_spin.min_value = 1
	port_spin.max_value = 65535
	port_spin.value = NetworkManager.DEFAULT_LOCAL_PORT
	content.add_child(port_spin)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(actions)
	var back := Button.new()
	back.text = "Zurück"
	back.pressed.connect(_on_back_pressed)
	actions.add_child(back)
	var join := Button.new()
	join.text = "Beitreten"
	join.pressed.connect(_on_join_pressed)
	actions.add_child(join)

func _on_join_pressed() -> void:
	var cleaned_name := player_name_input.text.strip_edges()
	if cleaned_name.length() < 2 or cleaned_name.length() > 20:
		status_label.text = "Spielername muss 2 bis 20 Zeichen lang sein."
		return
	SettingsManager.player_name = cleaned_name
	SettingsManager.save_settings()
	var result := NetworkManager.join_local_lobby(cleaned_name, address_input.text.strip_edges(), int(port_spin.value))
	if not bool(result.get("ok", false)):
		status_label.text = "Beitreten fehlgeschlagen: %s" % result.get("code", "NETWORK_ERROR")
		return
	SceneRouter.go_to_lobby()

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()

func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	return label
