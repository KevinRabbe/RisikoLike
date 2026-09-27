extends Control

var title_label: Label
var invite_label: Label
var status_label: Label
var players_list: VBoxContainer
var rules_label: Label
var ready_button: Button
var start_button: Button
var cards_check: CheckButton
var continents_check: CheckButton
var copy_button: Button

func _ready() -> void:
	_build_ui()
	NetworkManager.lobby_changed.connect(_on_lobby_changed)
	NetworkManager.network_error.connect(_on_network_error)
	NetworkManager.match_started.connect(_on_match_started)
	_refresh(NetworkManager.lobby_state)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 30)
	root.add_child(title_label)
	invite_label = Label.new()
	root.add_child(invite_label)
	copy_button = Button.new()
	copy_button.text = "Invite-Code kopieren"
	copy_button.pressed.connect(_on_copy_invite_pressed)
	root.add_child(copy_button)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	var players_panel := PanelContainer.new()
	players_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(players_panel)
	var players_box := VBoxContainer.new()
	players_box.add_theme_constant_override("separation", 8)
	players_panel.add_child(players_box)
	var players_title := Label.new()
	players_title.text = "Spieler"
	players_title.add_theme_font_size_override("font_size", 22)
	players_box.add_child(players_title)
	players_list = VBoxContainer.new()
	players_box.add_child(players_list)
	var rules_panel := PanelContainer.new()
	rules_panel.custom_minimum_size = Vector2(360, 0)
	content.add_child(rules_panel)
	var rules_box := VBoxContainer.new()
	rules_box.add_theme_constant_override("separation", 8)
	rules_panel.add_child(rules_box)
	var rules_title := Label.new()
	rules_title.text = "Ruleset"
	rules_title.add_theme_font_size_override("font_size", 22)
	rules_box.add_child(rules_title)
	rules_label = Label.new()
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_box.add_child(rules_label)
	cards_check = CheckButton.new()
	cards_check.text = "Gebietskarten aktiv"
	cards_check.toggled.connect(_on_ruleset_changed)
	rules_box.add_child(cards_check)
	continents_check = CheckButton.new()
	continents_check.text = "Kontinentboni aktiv"
	continents_check.toggled.connect(_on_ruleset_changed)
	rules_box.add_child(continents_check)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(actions)
	ready_button = Button.new()
	ready_button.text = "Bereit"
	ready_button.pressed.connect(_on_ready_pressed)
	actions.add_child(ready_button)
	start_button = Button.new()
	start_button.text = "Match starten"
	start_button.pressed.connect(_on_start_pressed)
	actions.add_child(start_button)
	var leave := Button.new()
	leave.text = "Lobby verlassen"
	leave.pressed.connect(_on_leave_pressed)
	actions.add_child(leave)

func _refresh(lobby: LobbyState) -> void:
	if lobby == null:
		status_label.text = "Keine Lobby aktiv."
		return
	title_label.text = "Lobby %s" % lobby.lobby_id
	if NetworkManager.backend_mode:
		invite_label.text = "Invite-Code: %s | Online-Signaling | Status: %s" % [lobby.invite_code, lobby.status_name()]
	else:
		invite_label.text = "Development-Code: %s | localhost:%d | Status: %s" % [lobby.invite_code, NetworkManager.local_port, lobby.status_name()]
	copy_button.visible = NetworkManager.backend_mode and not lobby.invite_code.is_empty()
	for child in players_list.get_children():
		child.queue_free()
	for player_id: String in _sorted_player_ids(lobby.players):
		var player := lobby.get_player(player_id)
		var row := Label.new()
		row.text = "%s  [%s]%s%s" % [player.name, player.player_id, "  HOST" if player.is_host else "", "  BEREIT" if player.is_ready else "  wartet"]
		players_list.add_child(row)
	rules_label.text = "Karten: %s\nKontinentboni: %s\nProtokoll: %d\nSpielversion: %s" % ["AN" if lobby.ruleset.territory_cards_enabled else "AUS", "AN" if lobby.ruleset.continent_bonus_enabled else "AUS", lobby.protocol_version, lobby.game_version]
	cards_check.button_pressed = lobby.ruleset.territory_cards_enabled
	continents_check.button_pressed = lobby.ruleset.continent_bonus_enabled
	var is_host := NetworkManager.role == NetworkManager.Role.HOST
	start_button.visible = is_host
	start_button.disabled = not is_host
	cards_check.disabled = not is_host or lobby.ruleset_locked
	continents_check.disabled = not is_host or lobby.ruleset_locked
	ready_button.visible = NetworkManager.role == NetworkManager.Role.CLIENT
	if NetworkManager.role == NetworkManager.Role.CLIENT:
		var local := lobby.get_player(NetworkManager.local_player_id)
		ready_button.text = "Nicht bereit" if local != null and local.is_ready else "Bereit"

func _on_ready_pressed() -> void:
	var lobby := NetworkManager.lobby_state
	var local := lobby.get_player(NetworkManager.local_player_id) if lobby != null else null
	if local != null:
		NetworkManager.set_ready_state(not local.is_ready)

func _on_ruleset_changed(_value: bool) -> void:
	if NetworkManager.role != NetworkManager.Role.HOST or NetworkManager.lobby_state == null or NetworkManager.lobby_state.ruleset_locked:
		return
	var ruleset := NetworkManager.lobby_state.ruleset.duplicate_ruleset()
	ruleset.territory_cards_enabled = cards_check.button_pressed
	ruleset.continent_bonus_enabled = continents_check.button_pressed
	var result := NetworkManager.configure_ruleset(ruleset)
	if not bool(result.get("ok", false)):
		status_label.text = "Ruleset abgelehnt: %s" % result.get("code", "INVALID_RULESET")

func _on_start_pressed() -> void:
	var result := NetworkManager.start_match()
	if not bool(result.get("ok", false)):
		status_label.text = "Start nicht möglich: %s" % result.get("code", "INVALID_REQUEST")

func _on_leave_pressed() -> void:
	NetworkManager.leave_lobby()
	SceneRouter.go_to_main_menu()

func _on_copy_invite_pressed() -> void:
	if NetworkManager.lobby_state != null:
		DisplayServer.clipboard_set(NetworkManager.lobby_state.invite_code)
		status_label.text = "Invite-Code kopiert."

func _on_lobby_changed(snapshot: LobbySnapshot) -> void:
	_refresh(snapshot)

func _on_network_error(code: String) -> void:
	status_label.text = "Netzwerk: %s" % code
	if code == "LOBBY_CLOSED":
		NetworkManager.shutdown()
		SceneRouter.go_to_main_menu()

func _on_match_started(_state: GameState) -> void:
	SceneRouter.go_to_game()

static func _sorted_player_ids(values: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for player_id in values:
		result.append(str(player_id))
	result.sort()
	return result
