extends Control

var player_name_input: LineEdit
var max_players_spin: SpinBox
var port_spin: SpinBox
var debug_check: CheckButton
var cards_check: CheckButton
var continents_check: CheckButton
var port_label: Label
var status_label: Label
var waiting_for_backend := false

func _ready() -> void:
	AtlasFrontTheme.install(self)
	AtlasFrontTheme.add_backdrop(self, AtlasFrontTheme.LOBBY_BACKGROUND)
	_build_ui()
	AudioManager.attach_feedback(self)
	AudioManager.start_music()
	NetworkManager.lobby_changed.connect(_on_lobby_changed)
	NetworkManager.network_error.connect(_on_network_error)

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
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
	title.text = "ATLAS // FRONT"
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)
	var subtitle := _label("LOBBY ERSTELLEN  //  PRIVATE MATCH")
	subtitle.add_theme_color_override("font_color", AtlasFrontTheme.CYAN_SOFT)
	content.add_child(subtitle)
	content.add_child(_label("Online-Lobby per Invite-Code; TCP bleibt als Debug-Modus verfügbar."))
	content.add_child(_label("Spielername"))
	player_name_input = LineEdit.new()
	player_name_input.text = SettingsManager.player_name
	player_name_input.max_length = 20
	content.add_child(player_name_input)
	content.add_child(_label("Maximale Spielerzahl (2–5)"))
	max_players_spin = SpinBox.new()
	max_players_spin.min_value = 2
	max_players_spin.max_value = 5
	max_players_spin.value = 2
	content.add_child(max_players_spin)
	debug_check = CheckButton.new()
	debug_check.text = "Lokalen TCP-Debugmodus verwenden"
	debug_check.toggled.connect(_on_debug_toggled)
	content.add_child(debug_check)
	port_label = _label("Development-Port")
	port_label.visible = false
	content.add_child(port_label)
	port_spin = SpinBox.new()
	port_spin.min_value = 1024
	port_spin.max_value = 65535
	port_spin.value = NetworkManager.DEFAULT_LOCAL_PORT
	port_spin.visible = false
	content.add_child(port_spin)
	cards_check = CheckButton.new()
	cards_check.text = "Gebietskarten aktiv"
	cards_check.button_pressed = true
	content.add_child(cards_check)
	continents_check = CheckButton.new()
	continents_check.text = "Kontinentboni aktiv"
	continents_check.button_pressed = true
	content.add_child(continents_check)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(actions)
	var back := Button.new()
	back.text = "Zurück"
	AtlasFrontTheme.apply_icon(back, "quit", 24)
	back.pressed.connect(_on_back_pressed)
	actions.add_child(back)
	var create := Button.new()
	create.text = "Lobby erstellen"
	AtlasFrontTheme.apply_icon(create, "create_lobby", 24)
	create.pressed.connect(_on_create_pressed)
	actions.add_child(create)

func _on_create_pressed() -> void:
	var cleaned_name := player_name_input.text.strip_edges()
	if cleaned_name.length() < 2 or cleaned_name.length() > 20:
		status_label.text = "Spielername muss 2 bis 20 Zeichen lang sein."
		return
	SettingsManager.player_name = cleaned_name
	SettingsManager.save_settings()
	var ruleset := Ruleset.new()
	ruleset.territory_cards_enabled = cards_check.button_pressed
	ruleset.continent_bonus_enabled = continents_check.button_pressed
	var result: Dictionary
	if debug_check.button_pressed:
		result = NetworkManager.host_local_lobby(cleaned_name, int(max_players_spin.value), ruleset, int(port_spin.value))
	else:
		waiting_for_backend = true
		status_label.text = "Backend: Lobby wird erstellt …"
		result = NetworkManager.host_online_lobby(cleaned_name, int(max_players_spin.value), ruleset)
	if not bool(result.get("ok", false)):
		waiting_for_backend = false
		status_label.text = "Erstellen fehlgeschlagen: %s" % result.get("code", "NETWORK_ERROR")
		return
	if debug_check.button_pressed:
		SceneRouter.go_to_lobby()

func _on_debug_toggled(enabled: bool) -> void:
	port_label.visible = enabled
	port_spin.visible = enabled

func _on_lobby_changed(_snapshot: LobbySnapshot) -> void:
	if waiting_for_backend and NetworkManager.lobby_state != null:
		waiting_for_backend = false
		SceneRouter.go_to_lobby()

func _on_network_error(code: String) -> void:
	if waiting_for_backend:
		waiting_for_backend = false
		status_label.text = "Backend/Netzwerk: %s" % code

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()

func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
