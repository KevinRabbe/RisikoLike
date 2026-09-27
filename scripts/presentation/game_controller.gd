extends Control

var game_state: GameState
var processor: CommandProcessor
var map_controller: MapController
var phase_label: Label
var player_label: Label
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

func _ready() -> void:
	var player_count := int(get_tree().get_meta("local_player_count", 2))
	game_state = GameState.create_local(clampi(player_count, 2, 5), 424242)
	processor = CommandProcessor.new(game_state, RandomSource.new(424242))
	_build_ui()
	_refresh_ui()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var top_bar := HBoxContainer.new()
	root.add_child(top_bar)
	phase_label = Label.new()
	phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(phase_label)
	player_label = Label.new()
	top_bar.add_child(player_label)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	map_controller = MapController.new()
	map_controller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_controller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_controller.territory_selected.connect(_on_territory_selected)
	content.add_child(map_controller)
	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(340, 0)
	content.add_child(side_panel)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	side_panel.add_child(side)
	var title := Label.new()
	title.text = "Lokale Partie"
	title.add_theme_font_size_override("font_size", 24)
	side.add_child(title)
	var players_title := Label.new()
	players_title.text = "Spielerübersicht"
	players_title.add_theme_font_size_override("font_size", 18)
	side.add_child(players_title)
	player_panel = VBoxContainer.new()
	side.add_child(player_panel)
	reinforcement_label = Label.new()
	side.add_child(reinforcement_label)
	selection_label = Label.new()
	selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(selection_label)
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
	primary_action = Button.new()
	primary_action.text = "Aktion bestätigen"
	primary_action.pressed.connect(_on_primary_action_pressed)
	side.add_child(primary_action)
	trade_button = Button.new()
	trade_button.text = "Erstes gültiges Kartenset tauschen"
	trade_button.pressed.connect(_on_trade_pressed)
	side.add_child(trade_button)
	reset_button = Button.new()
	reset_button.text = "Verstärkungen zurücksetzen"
	reset_button.pressed.connect(_on_reset_pressed)
	side.add_child(reset_button)
	end_phase_button = Button.new()
	end_phase_button.text = "Phase beenden"
	end_phase_button.pressed.connect(_on_end_phase_pressed)
	side.add_child(end_phase_button)
	end_turn_button = Button.new()
	end_turn_button.text = "Zug beenden"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	side.add_child(end_turn_button)
	var surrender_button := Button.new()
	surrender_button.text = "Aufgeben"
	surrender_button.pressed.connect(_on_surrender_pressed)
	side.add_child(surrender_button)
	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(result_label)
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
	side.add_child(zoom_row)
	var hint := Label.new()
	hint.text = "Gebiet anklicken: Verstärken = Gebiet, Angriff/Fortification = Quelle dann Ziel."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(hint)

func _on_territory_selected(territory_id: String) -> void:
	if game_state.status == GameState.MatchStatus.FINISHED:
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
	var player_id := game_state.turn_state.active_player_id
	var command: CommandEnvelope
	switch game_state.turn_state.phase:
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
	_execute(CommandEnvelope.create(game_state.turn_state.active_player_id, game_state.state_revision, "reset_reinforcements"))

func _on_trade_pressed() -> void:
	var player := game_state.get_player(game_state.turn_state.active_player_id)
	var card_ids := _find_valid_card_set(player.territory_card_ids)
	if card_ids.is_empty():
		result_label.text = "Kein gültiges Kartenset gefunden."
		return
	_execute(CommandEnvelope.create(player.player_id, game_state.state_revision, "trade_cards", {"card_ids": card_ids}))

func _on_end_phase_pressed() -> void:
	var command_type := "confirm_reinforcements" if game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT else "end_phase"
	_execute(CommandEnvelope.create(game_state.turn_state.active_player_id, game_state.state_revision, command_type))

func _on_zoom_in_pressed() -> void:
	map_controller.zoom_in()

func _on_zoom_out_pressed() -> void:
	map_controller.zoom_out()

func _on_zoom_reset_pressed() -> void:
	map_controller.reset_view()

func _on_end_turn_pressed() -> void:
	_execute(CommandEnvelope.create(game_state.turn_state.active_player_id, game_state.state_revision, "end_turn"))

func _on_surrender_pressed() -> void:
	_execute(CommandEnvelope.create(game_state.turn_state.active_player_id, game_state.state_revision, "surrender"))

func _execute(command: CommandEnvelope) -> void:
	var result := processor.execute(command)
	if result.accepted:
		result_label.text = "OK: %s" % result.data.get("code", "OK")
		source_id = ""
		target_id = ""
	else:
		result_label.text = "Abgelehnt: %s" % result.code
	_refresh_ui()

func _refresh_ui() -> void:
	if map_controller != null:
		if map_controller.grid == null:
			map_controller.configure(game_state.map_data, game_state)
		else:
			map_controller.refresh()
	var player := game_state.get_player(game_state.turn_state.active_player_id)
	phase_label.text = "Phase: %s | Runde %d | Revision %d" % [game_state.turn_state.phase_name(), game_state.turn_state.round_number, game_state.state_revision]
	player_label.text = "Am Zug: %s" % player.name
	reinforcement_label.text = "Verstärkungen: %d | Karten: %d" % [player.reinforcements_remaining, player.territory_card_ids.size()]
	for child in player_panel.get_children():
		child.queue_free()
	for player_id: String in game_state.players:
		var listed_player := game_state.get_player(player_id)
		var player_row := Label.new()
		player_row.text = "%s  | Gebiete: %d  | Karten: %d%s" % [listed_player.name, listed_player.territory_count(game_state), listed_player.territory_card_ids.size(), "  ← am Zug" if player_id == game_state.turn_state.active_player_id else ""]
		player_panel.add_child(player_row)
	selection_label.text = "Auswahl: %s -> %s" % [source_id if not source_id.is_empty() else "—", target_id if not target_id.is_empty() else "—"]
	var reinforcement_phase := game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT
	reset_button.visible = reinforcement_phase
	trade_button.visible = game_state.turn_state.phase == TurnState.Phase.CARD_TRADE or game_state.forced_trade_player_id == game_state.turn_state.active_player_id
	primary_action.visible = game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT or game_state.turn_state.phase == TurnState.Phase.ATTACK or game_state.turn_state.phase == TurnState.Phase.FORTIFICATION
	end_phase_button.visible = game_state.turn_state.phase != TurnState.Phase.TURN_END and game_state.status == GameState.MatchStatus.PLAYING
	end_phase_button.text = "Verstärkungen bestätigen" if reinforcement_phase else "Phase beenden"
	end_turn_button.visible = game_state.turn_state.phase == TurnState.Phase.TURN_END
	if game_state.status == GameState.MatchStatus.FINISHED:
		result_label.text = "Sieg: %s" % game_state.get_player(game_state.winner_player_id).name

func _find_valid_card_set(card_ids: Array[String]) -> Array[String]:
	for first in range(card_ids.size()):
		for second in range(first + 1, card_ids.size()):
			for third in range(second + 1, card_ids.size()):
				var candidate: Array[String] = [card_ids[first], card_ids[second], card_ids[third]]
				if processor.card_manager.is_valid_set(candidate):
					return candidate
	return []
