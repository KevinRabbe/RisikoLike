class_name MapController
extends Control

signal territory_selected(territory_id: String)

var map_data: MapData
var game_state: GameState
var territory_buttons: Dictionary = {}
var grid: GridContainer

func configure(p_map_data: MapData, p_game_state: GameState) -> void:
	map_data = p_map_data
	game_state = p_game_state
	_build_placeholder_board()
	refresh()

func refresh() -> void:
	if game_state == null:
		return
	for territory_id: String in territory_buttons:
		var button: Button = territory_buttons[territory_id]
		var definition := map_data.get_territory(territory_id)
		var state := game_state.get_territory(territory_id)
		if definition == null or state == null:
			continue
		button.text = "%s\n%d" % [definition.name_de, state.army_count]
		button.tooltip_text = "%s | %s | %d Truppen" % [definition.name_de, state.owner_player_id, state.army_count]
		var player := game_state.get_player(state.owner_player_id)
		var color := player.color if player != null else Color.DIM_GRAY
		button.modulate = color

func _build_placeholder_board() -> void:
	for child in get_children():
		child.queue_free()
	territory_buttons.clear()
	grid = GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	var ids: Array[String] = []
	for territory_id: String in map_data.territories:
		ids.append(territory_id)
	ids.sort()
	for territory_id in ids:
		var button := Button.new()
		button.custom_minimum_size = Vector2(145, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_territory_pressed.bind(territory_id))
		grid.add_child(button)
		territory_buttons[territory_id] = button

func _on_territory_pressed(territory_id: String) -> void:
	territory_selected.emit(territory_id)
