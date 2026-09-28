extends Control

var player_name_input: LineEdit
var invite_code_input: LineEdit
var address_input: LineEdit
var port_spin: SpinBox
var debug_check: CheckButton
var status_label: Label
var waiting_for_backend := false

func _ready() -> void:
	AtlasFrontTheme.install(self)
	AtlasFrontTheme.add_backdrop(self)
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
	title.text = "ATLAS // FRONT"
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)
	var subtitle := _label("LOBBY BEITRETEN  //  INVITE LINK")
	subtitle.add_theme_color_override("font_color", AtlasFrontTheme.CYAN_SOFT)
	content.add_child(subtitle)
	content.add_child(_label("Invite-Code eingeben; der Host muss keine IP oder Portfreigabe teilen."))
	content.add_child(_label("Spielername"))
	player_name_input = LineEdit.new()
	player_name_input.text = SettingsManager.player_name
	player_name_input.max_length = 20
	content.add_child(player_name_input)
	content.add_child(_label("Invite-Code (ABC-123)"))
	invite_code_input = LineEdit.new()
	invite_code_input.placeholder_text = "ABC-123"
	invite_code_input.max_length = 7
	content.add_child(invite_code_input)
	debug_check = CheckButton.new()
	debug_check.text = "Lokalen TCP-Debugmodus verwenden"
	debug_check.toggled.connect(_on_debug_toggled)
	content.add_child(debug_check)
	content.add_child(_label("Host-Adresse"))
	address_input = LineEdit.new()
	address_input.text = "127.0.0.1"
	address_input.visible = false
	content.add_child(address_input)
	var port_label := _label("Development-Port")
	port_label.visible = false
	content.add_child(port_label)
	port_spin = SpinBox.new()
	port_spin.min_value = 1
	port_spin.max_value = 65535
	port_spin.value = NetworkManager.DEFAULT_LOCAL_PORT
	port_spin.visible = false
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
	var result: Dictionary
	if debug_check.button_pressed:
		result = NetworkManager.join_local_lobby(cleaned_name, address_input.text.strip_edges(), int(port_spin.value))
	else:
		var code := _normalize_invite_code(invite_code_input.text)
		if code.is_empty():
			status_label.text = "Invite-Code muss das Format ABC-123 haben."
			return
		waiting_for_backend = true
		status_label.text = "Backend: Invite-Code wird aufgelöst …"
		result = NetworkManager.join_online_lobby(cleaned_name, code)
	if not bool(result.get("ok", false)):
		waiting_for_backend = false
		status_label.text = "Beitreten fehlgeschlagen: %s" % result.get("code", "NETWORK_ERROR")
		return
	if debug_check.button_pressed:
		SceneRouter.go_to_lobby()

func _on_back_pressed() -> void:
	SceneRouter.go_to_main_menu()

func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _on_debug_toggled(enabled: bool) -> void:
	address_input.visible = enabled
	port_spin.visible = enabled
	invite_code_input.visible = not enabled
	for child in address_input.get_parent().get_children():
		if child is Label and child.text == "Development-Port":
			child.visible = enabled

func _on_lobby_changed(_snapshot: LobbySnapshot) -> void:
	if waiting_for_backend and NetworkManager.lobby_state != null:
		waiting_for_backend = false
		SceneRouter.go_to_lobby()

func _on_network_error(code: String) -> void:
	if waiting_for_backend:
		waiting_for_backend = false
		status_label.text = "Backend/Netzwerk: %s" % code

func _normalize_invite_code(value: String) -> String:
	var compact := value.strip_edges().replace("-", "").replace(" ", "").to_upper()
	if compact.length() != 6:
		return ""
	for character in compact:
		if not "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains(character):
			return ""
	return "%s-%s" % [compact.substr(0, 3), compact.substr(3, 3)]
