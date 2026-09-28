extends Control

var version_label: Label

func _ready() -> void:
	AtlasFrontTheme.install(self)
	AtlasFrontTheme.add_backdrop(self)
	_build_ui()
	AudioManager.attach_feedback(self)
	AudioManager.start_music()

func _build_ui() -> void:
	var world_table := AtlasFrontWorldTable.new()
	world_table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_table.z_index = -10
	add_child(world_table)
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 64)
	frame.add_theme_constant_override("margin_top", 48)
	frame.add_theme_constant_override("margin_right", 64)
	frame.add_theme_constant_override("margin_bottom", 48)
	add_child(frame)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	frame.add_child(columns)
	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(380, 620)
	menu_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	columns.add_child(menu_panel)
	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 28)
	menu_margin.add_theme_constant_override("margin_top", 26)
	menu_margin.add_theme_constant_override("margin_right", 28)
	menu_margin.add_theme_constant_override("margin_bottom", 26)
	menu_panel.add_child(menu_margin)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 12)
	menu_margin.add_child(menu)
	menu.add_child(AtlasFrontTheme.section_label("COMMAND ROOM // PRIVATE MATCH"))
	var title := AtlasFrontTheme.title_label("ATLAS // FRONT", 38)
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
	var readout_panel := PanelContainer.new()
	readout_panel.custom_minimum_size = Vector2(288, 0)
	readout_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	readout_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	columns.add_child(readout_panel)
	var readout_margin := MarginContainer.new()
	readout_margin.add_theme_constant_override("margin_left", 20)
	readout_margin.add_theme_constant_override("margin_top", 18)
	readout_margin.add_theme_constant_override("margin_right", 20)
	readout_margin.add_theme_constant_override("margin_bottom", 18)
	readout_panel.add_child(readout_margin)
	var readout := VBoxContainer.new()
	readout.add_theme_constant_override("separation", 8)
	readout_margin.add_child(readout)
	readout.add_child(AtlasFrontTheme.section_label("COMMAND TABLE // READY"))
	readout.add_child(AtlasFrontTheme.title_label("THE FRONT IS YOURS", 22))
	readout.add_child(_readout("01", "PRIVATE MATCH", "Invite-only host flow"))
	readout.add_child(_readout("02", "42 TERRITORIES", "Readable first"))

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
