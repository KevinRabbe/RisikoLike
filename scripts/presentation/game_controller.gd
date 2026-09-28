extends Control

var game_state: GameState
var processor: CommandProcessor
var map_controller: MapController
var phase_label: Label
var player_label: Label
var timer_label: Label
var status_label: Label
var reinforcement_label: Label
var selection_label: Label
var result_label: Label
var amount_spin: SpinBox
var attacker_dice_spin: SpinBox
var defender_dice_spin: SpinBox
var primary_action: Button
var end_phase_button: Button
var end_turn_button: Button
var reset_button: Button
var trade_button: Button
var player_panel: VBoxContainer
var source_id := ""
var target_id := ""
var network_mode := false
var local_player_id := ""
var pending_network_action := false
var surrender_dialog: ConfirmationDialog
var spectator_button: Button
var result_overlay: PanelContainer
var result_overlay_label: Label
var connection_overlay: PanelContainer
var connection_overlay_label: Label
var card_summary_label: Label

func _process(_delta: float) -> void:
	if game_state != null and timer_label != null:
		_refresh_timer()
		if not network_mode and processor != null and game_state.status == GameState.MatchStatus.PLAYING:
			var lifecycle := processor.advance_time(game_state.clock.now_msec())
			if bool(lifecycle.get("changed", false)):
				_refresh_ui()

func _ready() -> void:
	if NetworkManager.has_active_match():
		network_mode = true
		local_player_id = NetworkManager.local_player_id
		game_state = NetworkManager.game_state
		NetworkManager.command_result_received.connect(_on_network_command_result)
		NetworkManager.state_snapshot_changed.connect(_on_network_snapshot_changed)
		NetworkManager.connection_changed.connect(_on_network_connection_changed)
	else:
		var player_count := int(get_tree().get_meta("local_player_count", 2))
		game_state = GameState.create_local(clampi(player_count, 2, 5), 424242)
		processor = CommandProcessor.new(game_state, RandomSource.new(424242))
	_build_ui()
	_refresh_ui()

func _build_ui() -> void:
	AtlasFrontTheme.install(self)
	AtlasFrontTheme.add_backdrop(self)
	var top_bar_panel := PanelContainer.new()
	top_bar_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar_panel.offset_left = 20
	top_bar_panel.offset_top = 16
	top_bar_panel.offset_right = -20
	top_bar_panel.offset_bottom = 86
	add_child(top_bar_panel)
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 18)
	top_bar_panel.add_child(top_bar)
	var brand := AtlasFrontTheme.title_label("ATLAS // FRONT", 22)
	brand.add_theme_color_override("font_color", AtlasFrontTheme.CYAN_SOFT)
	top_bar.add_child(brand)
	phase_label = Label.new()
	phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(phase_label)
	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_color_override("font_color", AtlasFrontTheme.WARNING)
	top_bar.add_child(timer_label)
	player_label = Label.new()
	player_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(player_label)
	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 20
	content.offset_top = 100
	content.offset_right = -20
	content.offset_bottom = -212
	add_child(content)
	map_controller = MapController.new()
	map_controller.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_controller.territory_selected.connect(_on_territory_selected)
	content.add_child(map_controller)
	var side_panel := PanelContainer.new()
	side_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	side_panel.offset_left = -326
	side_panel.offset_right = -6
	side_panel.offset_top = 12
	side_panel.offset_bottom = -212
	add_child(side_panel)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 9)
	side_panel.add_child(side)
	var title := Label.new()
	title.text = "TACTICAL OVERVIEW"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", AtlasFrontTheme.CYAN_SOFT)
	side.add_child(title)
	var players_title := Label.new()
	players_title.text = "PLAYERS // STATUS"
	players_title.add_theme_font_size_override("font_size", 18)
	side.add_child(players_title)
	player_panel = VBoxContainer.new()
	side.add_child(player_panel)
	reinforcement_label = Label.new()
	side.add_child(reinforcement_label)
	selection_label = Label.new()
	selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(selection_label)
	card_summary_label = Label.new()
	card_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_summary_label.add_theme_color_override("font_color", AtlasFrontTheme.TEXT_MUTED)
	side.add_child(card_summary_label)
	side.add_child(HSeparator.new())
	var combat_title := AtlasFrontTheme.section_label("COMBAT // PARAMETERS")
	side.add_child(combat_title)
	amount_spin = SpinBox.new()
	amount_spin.min_value = 1
	amount_spin.max_value = 100
	amount_spin.step = 1
	side.add_child(amount_spin)
	attacker_dice_spin = SpinBox.new()
	attacker_dice_spin.min_value = 1
	attacker_dice_spin.max_value = 3
	attacker_dice_spin.value = 3
	attacker_dice_spin.prefix = "Angriffswürfel: "
	side.add_child(attacker_dice_spin)
	defender_dice_spin = SpinBox.new()
	defender_dice_spin.min_value = 1
	defender_dice_spin.max_value = 2
	defender_dice_spin.value = 2
	defender_dice_spin.prefix = "Verteidigungswürfel: "
	side.add_child(defender_dice_spin)
	var action_bar_panel := PanelContainer.new()
	action_bar_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_bar_panel.offset_left = 20
	action_bar_panel.offset_top = -202
	action_bar_panel.offset_right = -20
	action_bar_panel.offset_bottom = -18
	add_child(action_bar_panel)
	var action_bar := VBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 7)
	action_bar_panel.add_child(action_bar)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	action_bar.add_child(actions)
	primary_action = Button.new()
	primary_action.text = "Aktion bestätigen"
	primary_action.custom_minimum_size = Vector2(190, 42)
	primary_action.pressed.connect(_on_primary_action_pressed)
	actions.add_child(primary_action)
	trade_button = Button.new()
	trade_button.text = "Kartenset tauschen"
	trade_button.pressed.connect(_on_trade_pressed)
	actions.add_child(trade_button)
	reset_button = Button.new()
	reset_button.text = "Verstärkungen zurücksetzen"
	reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(reset_button)
	end_phase_button = Button.new()
	end_phase_button.text = "Phase beenden"
	end_phase_button.pressed.connect(_on_end_phase_pressed)
	actions.add_child(end_phase_button)
	end_turn_button = Button.new()
	end_turn_button.text = "Zug beenden"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	actions.add_child(end_turn_button)
	var surrender_button := Button.new()
	surrender_button.text = "Aufgeben"
	surrender_button.pressed.connect(_on_surrender_pressed)
	actions.add_child(surrender_button)
	surrender_dialog = ConfirmationDialog.new()
	surrender_dialog.title = "Partie aufgeben"
	surrender_dialog.dialog_text = "Möchtest du die Partie wirklich aufgeben?"
	surrender_dialog.ok_button_text = "Aufgeben"
	surrender_dialog.cancel_button_text = "Abbrechen"
	surrender_dialog.confirmed.connect(_confirm_surrender)
	add_child(surrender_dialog)
	spectator_button = Button.new()
	spectator_button.text = "Zuschauen"
	spectator_button.pressed.connect(_on_spectator_pressed)
	actions.add_child(spectator_button)
	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_bar.add_child(result_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", AtlasFrontTheme.CYAN_SOFT)
	action_bar.add_child(status_label)
	var zoom_row := HBoxContainer.new()
	var zoom_out_button := Button.new()
	zoom_out_button.text = "Karte −"
	zoom_out_button.pressed.connect(_on_zoom_out_pressed)
	zoom_row.add_child(zoom_out_button)
	var zoom_reset_button := Button.new()
	zoom_reset_button.text = "Ansicht zurücksetzen"
	zoom_reset_button.pressed.connect(_on_zoom_reset_pressed)
	zoom_row.add_child(zoom_reset_button)
	var zoom_in_button := Button.new()
	zoom_in_button.text = "Karte +"
	zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	zoom_row.add_child(zoom_in_button)
	action_bar.add_child(zoom_row)
	var hint := Label.new()
	hint.text = "Gebiet anklicken: Verstärken = Gebiet, Angriff/Fortification = Quelle dann Ziel."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", AtlasFrontTheme.TEXT_MUTED)
	action_bar.add_child(hint)
	_build_lifecycle_overlays()

func _build_lifecycle_overlays() -> void:
	connection_overlay = PanelContainer.new()
	connection_overlay.set_anchors_preset(Control.PRESET_CENTER_TOP)
	connection_overlay.offset_left = -250
	connection_overlay.offset_top = 104
	connection_overlay.offset_right = 250
	connection_overlay.offset_bottom = 184
	connection_overlay.visible = false
	add_child(connection_overlay)
	connection_overlay_label = Label.new()
	connection_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connection_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	connection_overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	connection_overlay.add_child(connection_overlay_label)
	result_overlay = PanelContainer.new()
	result_overlay.set_anchors_preset(Control.PRESET_CENTER)
	result_overlay.offset_left = -250
	result_overlay.offset_top = -110
	result_overlay.offset_right = 250
	result_overlay.offset_bottom = 110
	result_overlay.visible = false
	add_child(result_overlay)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 12)
	result_overlay.add_child(result_box)
	result_overlay_label = Label.new()
	result_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_box.add_child(result_overlay_label)
	var return_button := Button.new()
	return_button.text = "Zum Hauptmenü"
	return_button.pressed.connect(_on_return_to_menu_pressed)
	result_box.add_child(return_button)

func _on_return_to_menu_pressed() -> void:
	NetworkManager.shutdown()
	SceneRouter.go_to_main_menu()

func _on_territory_selected(territory_id: String) -> void:
	if not _can_local_player_act():
		return
	if network_mode and game_state.turn_state.active_player_id != local_player_id:
		result_label.text = "Du bist nicht am Zug."
		return
	var phase := game_state.turn_state.phase
	if phase == TurnState.Phase.REINFORCEMENT or (phase == TurnState.Phase.ATTACK and game_state.get_player(game_state.turn_state.active_player_id).pending_trade_reinforcements > 0):
		source_id = territory_id
		target_id = ""
		var available := game_state.get_player(game_state.turn_state.active_player_id).reinforcements_remaining if phase == TurnState.Phase.REINFORCEMENT else game_state.get_player(game_state.turn_state.active_player_id).pending_trade_reinforcements
		amount_spin.max_value = maxi(1, available)
		amount_spin.value = 1
	elif phase == TurnState.Phase.ATTACK or phase == TurnState.Phase.FORTIFICATION:
		if source_id.is_empty() or (not target_id.is_empty()):
			source_id = territory_id
			target_id = ""
		else:
			target_id = territory_id
	selection_label.text = "Auswahl: %s -> %s" % [source_id if not source_id.is_empty() else "—", target_id if not target_id.is_empty() else "—"]

func _on_primary_action_pressed() -> void:
	var player_id := _command_player_id()
	if player_id.is_empty():
		return
	var command: CommandEnvelope
	match game_state.turn_state.phase:
		TurnState.Phase.REINFORCEMENT:
			command = PlaceReinforcementCommand.create(player_id, game_state.state_revision, source_id, int(amount_spin.value))
		TurnState.Phase.ATTACK:
			if game_state.get_player(player_id).pending_trade_reinforcements > 0:
				command = PlaceReinforcementCommand.create(player_id, game_state.state_revision, source_id, int(amount_spin.value))
			elif not game_state.pending_conquest.is_empty():
				command = CommandEnvelope.create(player_id, game_state.state_revision, "conquest_move", {"amount": int(amount_spin.value)})
			else:
				command = CommandEnvelope.create(player_id, game_state.state_revision, "attack", {"source_id": source_id, "target_id": target_id, "attacker_dice": int(attacker_dice_spin.value), "defender_dice": int(defender_dice_spin.value)})
		TurnState.Phase.FORTIFICATION:
			command = CommandEnvelope.create(player_id, game_state.state_revision, "fortify", {"source_id": source_id, "target_id": target_id, "amount": int(amount_spin.value)})
		_:
			result_label.text = "In dieser Phase gibt es keine primäre Aktion."
			return
	_execute(command)

func _on_reset_pressed() -> void:
	_execute(CommandEnvelope.create(_command_player_id(), game_state.state_revision, "reset_reinforcements"))

func _on_trade_pressed() -> void:
	var player := game_state.get_player(_command_player_id())
	if player == null:
		return
	var card_ids := _find_valid_card_set(player.territory_card_ids)
	if card_ids.is_empty():
		result_label.text = "Kein gültiges Kartenset gefunden."
		return
	_execute(CommandEnvelope.create(player.player_id, game_state.state_revision, "trade_cards", {"card_ids": card_ids}))

func _on_end_phase_pressed() -> void:
	var player_id := _command_player_id()
	if player_id.is_empty():
		return
	var command_type := "confirm_reinforcements" if game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT else "end_phase"
	_execute(CommandEnvelope.create(player_id, game_state.state_revision, command_type))

func _on_zoom_in_pressed() -> void:
	map_controller.zoom_in()

func _on_zoom_out_pressed() -> void:
	map_controller.zoom_out()

func _on_zoom_reset_pressed() -> void:
	map_controller.reset_view()

func _on_end_turn_pressed() -> void:
	_execute(CommandEnvelope.create(_command_player_id(), game_state.state_revision, "end_turn"))

func _on_surrender_pressed() -> void:
	if _can_local_player_act() and surrender_dialog != null:
		surrender_dialog.popup_centered()

func _confirm_surrender() -> void:
	_execute(CommandEnvelope.create(_command_player_id(), game_state.state_revision, "surrender"))

func _on_spectator_pressed() -> void:
	if game_state == null:
		return
	var player_id := NetworkManager.local_player_id if network_mode else game_state.turn_state.active_player_id
	var result: Dictionary
	if network_mode:
		result = NetworkManager.enter_spectator()
	else:
		result = processor.enter_spectator(player_id)
	result_label.text = "Zuschauermodus angefordert." if bool(result.get("ok", false)) else "Abgelehnt: %s" % result.get("code", "SPECTATOR_REJECTED")
	_refresh_ui()

func _execute(command: CommandEnvelope) -> void:
	if command == null or command.player_id.is_empty():
		return
	if network_mode:
		if pending_network_action:
			result_label.text = "Aktion wird noch verarbeitet."
			return
		var queued := NetworkManager.submit_command(command)
		if not bool(queued.get("ok", false)):
			result_label.text = "Abgelehnt: %s" % queued.get("code", "NETWORK_ERROR")
		else:
			pending_network_action = true
		_refresh_ui()
		return
	var result := processor.execute(command)
	if result.accepted:
		result_label.text = "OK: %s" % result.data.get("code", "OK")
		source_id = ""
		target_id = ""
	else:
		result_label.text = "Abgelehnt: %s" % result.code
	_refresh_ui()

func _on_network_command_result(result: CommandResult) -> void:
	pending_network_action = false
	if result.accepted:
		result_label.text = "Host bestätigt: %s" % _format_command_result(result)
		source_id = ""
		target_id = ""
	else:
		result_label.text = "Host lehnt ab: %s" % result.code
	_refresh_ui()

func _on_network_snapshot_changed(_snapshot: GameStateSnapshot) -> void:
	game_state = NetworkManager.game_state
	_refresh_ui()

func _on_network_connection_changed(state: String) -> void:
	match state:
		"disconnected":
			result_label.text = "Verbindung unterbrochen. Wiederverbinden wird versucht …"
		"reconnecting":
			result_label.text = "Wiederverbinden …"
		"failed":
			result_label.text = "Wiederverbinden fehlgeschlagen: Partie verlassen oder Fenster abgelaufen."
		"in_game":
			result_label.text = "Wieder verbunden. Autoritativer Spielstand synchronisiert."
	if connection_overlay != null:
		connection_overlay.visible = state in ["disconnected", "reconnecting", "failed"]
		if connection_overlay.visible:
			connection_overlay_label.text = "VERBINDUNG UNTERBROCHEN\n" + ("Wiederverbinden läuft …" if state != "failed" else "Reconnect-Fenster abgelaufen")
	_refresh_ui()

func _refresh_ui() -> void:
	if game_state == null:
		return
	if game_state.last_action_id.begins_with("lifecycle-"):
		source_id = ""
		target_id = ""
		pending_network_action = false
	if map_controller != null:
		if map_controller.grid == null:
			map_controller.configure(game_state.map_data, game_state)
		else:
			map_controller.refresh()
		map_controller.set_interaction_context(source_id, target_id, game_state.turn_state.phase, _command_player_id())
	var active_player := game_state.get_player(game_state.turn_state.active_player_id)
	var visible_player := game_state.get_player(_command_player_id()) if not _command_player_id().is_empty() else active_player
	phase_label.text = "Phase: %s | Runde %d | Revision %d" % [game_state.turn_state.phase_name(), game_state.turn_state.round_number, game_state.state_revision]
	player_label.text = "Am Zug: %s%s" % [active_player.name, " | Du: %s" % visible_player.name if network_mode and visible_player != null else ""]
	reinforcement_label.text = "Eigene Verstärkungen: %d | Eigene Karten: %d" % [visible_player.reinforcements_remaining if visible_player != null else 0, visible_player.territory_card_ids.size() if visible_player != null else 0]
	card_summary_label.text = _card_summary(visible_player)
	for child in player_panel.get_children():
		child.queue_free()
	for player_id: String in game_state.players:
		var listed_player := game_state.get_player(player_id)
		var player_row := Label.new()
		var card_count := listed_player.territory_card_ids.size() if not network_mode or player_id == local_player_id else listed_player.visible_card_count
		player_row.text = "%s  ·  %s\nGebiete %d  ·  Karten %d%s" % [listed_player.name, _player_status_text(listed_player), listed_player.territory_count(game_state), card_count, "  ·  AM ZUG" if player_id == game_state.turn_state.active_player_id else ""]
		player_row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		player_panel.add_child(player_row)
	selection_label.text = "Auswahl: %s -> %s" % [source_id if not source_id.is_empty() else "—", target_id if not target_id.is_empty() else "—"]
	var reinforcement_phase := game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT
	var can_act := _can_local_player_act()
	reset_button.visible = reinforcement_phase
	trade_button.visible = can_act and (game_state.turn_state.phase == TurnState.Phase.CARD_TRADE or game_state.forced_trade_player_id == game_state.turn_state.active_player_id)
	if network_mode:
		primary_action.disabled = pending_network_action
		trade_button.disabled = pending_network_action
		reset_button.disabled = pending_network_action
		end_phase_button.disabled = pending_network_action
		end_turn_button.disabled = pending_network_action
	primary_action.visible = can_act and (game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT or game_state.turn_state.phase == TurnState.Phase.ATTACK or game_state.turn_state.phase == TurnState.Phase.FORTIFICATION)
	if game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT:
		primary_action.text = "Verstärkung platzieren"
	elif game_state.turn_state.phase == TurnState.Phase.ATTACK:
		primary_action.text = "Eroberung fortsetzen" if not game_state.pending_conquest.is_empty() else "Angriff ausführen"
	elif game_state.turn_state.phase == TurnState.Phase.FORTIFICATION:
		primary_action.text = "Truppen bewegen"
	end_phase_button.visible = can_act and game_state.turn_state.phase != TurnState.Phase.TURN_END and game_state.status == GameState.MatchStatus.PLAYING
	end_phase_button.text = "Verstärkungen bestätigen" if reinforcement_phase else "Phase beenden"
	end_turn_button.visible = can_act and game_state.turn_state.phase == TurnState.Phase.TURN_END
	var local_player := game_state.get_player(_command_player_id() if not _command_player_id().is_empty() else local_player_id)
	spectator_button.visible = local_player != null and not local_player.is_spectating() and local_player.status in [PlayerState.Status.SURRENDERED, PlayerState.Status.ELIMINATED, PlayerState.Status.LEFT] and game_state.ruleset.spectating_allowed
	if game_state.status == GameState.MatchStatus.FINISHED:
		var winner := game_state.get_player(game_state.winner_player_id)
		status_label.text = "Partie beendet — Sieg: %s" % (winner.name if winner != null else game_state.winner_player_id)
		if connection_overlay != null:
			connection_overlay.visible = false
		_show_result_overlay("MATCH COMPLETE\nSieg: %s" % (winner.name if winner != null else game_state.winner_player_id))
	elif game_state.status == GameState.MatchStatus.TERMINATED:
		status_label.text = "Partie beendet: Host nicht verfügbar."
		if connection_overlay != null:
			connection_overlay.visible = false
		_show_result_overlay("MATCH TERMINATED\nHost nicht verfügbar")
	elif network_mode and NetworkManager.connection_state in ["disconnected", "reconnecting", "failed"]:
		status_label.text = "Verbindung unterbrochen — Timer läuft weiter; Wiederverbinden wird versucht."
		if connection_overlay != null:
			connection_overlay.visible = true
	elif visible_player != null and visible_player.is_spectating():
		status_label.text = "Zuschauermodus — öffentliche Partieansicht, keine Spielaktionen."
	else:
		status_label.text = ""
	_refresh_timer()

func _show_result_overlay(message: String) -> void:
	if result_overlay == null:
		return
	result_overlay.visible = true
	result_overlay_label.text = message

func _card_summary(player: PlayerState) -> String:
	if player == null:
		return "KARTENHAND\nKeine sichtbare Hand"
	if network_mode and player.player_id != local_player_id:
		return "KARTENHAND\nGegnerische Karten verborgen"
	if player.territory_card_ids.is_empty():
		return "KARTENHAND\nKeine Karten"
	var names: Array[String] = []
	for card_id in player.territory_card_ids:
		var territory := game_state.map_data.get_territory(card_id)
		names.append(territory.name_de if territory != null else str(card_id))
	return "KARTENHAND  //  %d\n%s" % [names.size(), ", ".join(names)]

func _find_valid_card_set(card_ids: Array[String]) -> Array[String]:
	if network_mode:
		return NetworkManager.find_valid_card_set(card_ids)
	for first in range(card_ids.size()):
		for second in range(first + 1, card_ids.size()):
			for third in range(second + 1, card_ids.size()):
				var candidate: Array[String] = [card_ids[first], card_ids[second], card_ids[third]]
				if processor.card_manager.is_valid_set(candidate):
					return candidate
	return []

func _format_command_result(result: CommandResult) -> String:
	if result == null or not result.accepted:
		return result.code if result != null else "NETWORK_ERROR"
	var data := result.data
	if data.has("attacker_dice"):
		return "Kampf: Angriff %s / Verteidigung %s | Verluste A:%d V:%d%s" % [str(data.get("attacker_dice", [])), str(data.get("defender_dice", [])), int(data.get("attacker_losses", 0)), int(data.get("defender_losses", 0)), " | Eroberung" if bool(data.get("conquered", false)) else ""]
	if data.has("trade"):
		var trade: Dictionary = data.get("trade", {})
		return "Kartentausch: +%d Verstärkungen" % int(trade.get("bonus", 0))
	if bool(data.get("victory", false)):
		return "Sieg: %s" % str(data.get("winner_player_id", game_state.winner_player_id))
	return str(data.get("code", result.code))

func _command_player_id() -> String:
	if network_mode:
		if game_state == null or game_state.turn_state.active_player_id != local_player_id:
			return ""
		return local_player_id
	return game_state.turn_state.active_player_id if game_state != null else ""

func _can_local_player_act() -> bool:
	if game_state == null or game_state.status != GameState.MatchStatus.PLAYING:
		return false
	var player_id := _command_player_id()
	var player := game_state.get_player(player_id) if not player_id.is_empty() else null
	if player == null or not player.can_take_turn():
		return false
	if network_mode and NetworkManager.connection_state != "in_game":
		return false
	return game_state.turn_state.active_player_id == player_id

func _refresh_timer() -> void:
	if timer_label == null or game_state == null:
		return
	var remaining := game_state.turn_time_remaining_msec()
	if remaining < 0:
		timer_label.text = "Zugzeit: deaktiviert"
		timer_label.modulate = Color.WHITE
		return
	var total_seconds := ceili(float(remaining) / 1000.0)
	timer_label.text = "Zugzeit: %02d:%02d" % [total_seconds / 60, total_seconds % 60]
	timer_label.modulate = Color("ffb347") if remaining <= 30000 else Color.WHITE

func _player_status_text(player: PlayerState) -> String:
	if player.is_spectating():
		return "Zuschauer"
	match player.status:
		PlayerState.Status.DISCONNECTED:
			return "Verbindung verloren"
		PlayerState.Status.SURRENDERED:
			return "Aufgegeben"
		PlayerState.Status.ELIMINATED:
			return "Eliminiert"
		PlayerState.Status.LEFT:
			return "Dauerhaft verlassen"
	return "Aktiv"
