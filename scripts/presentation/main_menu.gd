extends Control

var version_label: Label

func _ready() -> void:
	AtlasFrontTheme.install(self)
	AtlasFrontTheme.add_backdrop(self)
	_build_ui()

func _build_ui() -> void:
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 72)
	frame.add_theme_constant_override("margin_top", 58)
	frame.add_theme_constant_override("margin_right", 72)
	frame.add_theme_constant_override("margin_bottom", 58)
	add_child(frame)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 42)
	frame.add_child(columns)
	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(455, 0)
	columns.add_child(menu_panel)
	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 34)
	menu_margin.add_theme_constant_override("margin_top", 30)
	menu_margin.add_theme_constant_override("margin_right", 34)
	menu_margin.add_theme_constant_override("margin_bottom", 30)
	menu_panel.add_child(menu_margin)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu)
	menu.add_child(AtlasFrontTheme.section_label("COMMAND ROOM // PRIVATE MATCH"))
	var title := AtlasFrontTheme.title_label("ATLAS // FRONT", 42)
	title.add_theme_color_override("font_color", AtlasFrontTheme.CYAN_SOFT)
	menu.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Eine eigene Welt. Ein autoritativer Host."
	subtitle.add_theme_color_override("font_color", AtlasFrontTheme.TEXT_MUTED)
	menu.add_child(subtitle)
	menu.add_child(HSeparator.new())
	var hint := Label.new()
	hint.text = "Starte eine private Partie oder tritt per Invite-Code bei."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", AtlasFrontTheme.TEXT_MUTED)
	menu.add_child(hint)
	menu.add_child(_button("Lobby erstellen", _on_create_lobby_pressed))
	menu.add_child(_button("Lobby beitreten", _on_join_lobby_pressed))
	menu.add_child(_button("Einstellungen", _on_settings_pressed))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.add_child(spacer)
	var exit := _button("Beenden", _on_exit_pressed)
	exit.modulate = Color(1, 1, 1, 0.82)
	menu.add_child(exit)
	version_label = Label.new()
	version_label.text = "ATLAS FRONT // v%s" % App.GAME_VERSION
	version_label.add_theme_color_override("font_color", AtlasFrontTheme.TEXT_MUTED)
	menu.add_child(version_label)
	var command_panel := PanelContainer.new()
	command_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(command_panel)
	var command_margin := MarginContainer.new()
	command_margin.add_theme_constant_override("margin_left", 38)
	command_margin.add_theme_constant_override("margin_top", 38)
	command_margin.add_theme_constant_override("margin_right", 38)
	command_margin.add_theme_constant_override("margin_bottom", 38)
	command_panel.add_child(command_margin)
	var command := VBoxContainer.new()
	command.add_theme_constant_override("separation", 16)
	command_margin.add_child(command)
	command.add_child(AtlasFrontTheme.section_label("TACTICAL OVERVIEW"))
	command.add_child(AtlasFrontTheme.title_label("THE FRONT IS YOURS", 28))
	var copy := Label.new()
	copy.text = "Klar lesbare Befehlsflächen für Karte, Lobby und Match.\n\nDie Weltkarte bleibt im Match der Mittelpunkt. Cyan markiert nur Interaktion, Auswahl und Verbindung — nie bloß Dekoration."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_color_override("font_color", AtlasFrontTheme.TEXT_MUTED)
	command.add_child(copy)
	var table := PanelContainer.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	command.add_child(table)
	var table_margin := MarginContainer.new()
	table_margin.add_theme_constant_override("margin_left", 24)
	table_margin.add_theme_constant_override("margin_top", 24)
	table_margin.add_theme_constant_override("margin_right", 24)
	table_margin.add_theme_constant_override("margin_bottom", 24)
	table.add_child(table_margin)
	var table_content := VBoxContainer.new()
	table_content.add_theme_constant_override("separation", 10)
	table_margin.add_child(table_content)
	table_content.add_child(AtlasFrontTheme.section_label("SESSION READINESS"))
	table_content.add_child(_readout("01", "PRIVATE INVITE LOBBIES", "Host-authoritative match flow"))
	table_content.add_child(_readout("02", "WEBRTC GAME SESSION", "Reconnect and spectator states visible"))
	table_content.add_child(_readout("03", "ATLAS WORLD MAP", "42 territories // readable first"))

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 50)
	button.pressed.connect(callback)
	return button

func _readout(index: String, heading: String, detail: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = "%s  //  %s" % [index, heading]
	label.add_theme_color_override("font_color", AtlasFrontTheme.CYAN_SOFT)
	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.add_theme_color_override("font_color", AtlasFrontTheme.TEXT_MUTED)
	box.add_child(label)
	box.add_child(detail_label)
	return box

func _on_create_lobby_pressed() -> void:
	SceneRouter.go_to_create_lobby()

func _on_join_lobby_pressed() -> void:
	SceneRouter.go_to_join_lobby()

func _on_settings_pressed() -> void:
	SceneRouter.go_to_settings()

func _on_exit_pressed() -> void:
	get_tree().quit()
