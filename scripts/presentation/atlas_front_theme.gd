class_name AtlasFrontTheme
extends RefCounted

const INK := Color("#07111d")
const PANEL := Color("#0d1d2b")
const PANEL_RAISED := Color("#12283a")
const PANEL_MUTED := Color("#0a1724")
const CYAN := Color("#5be7e5")
const CYAN_SOFT := Color("#9ef5f1")
const TEXT := Color("#e6f7f8")
const TEXT_MUTED := Color("#91b1bb")
const WARNING := Color("#ffbe68")
const DANGER := Color("#ff7185")
const SUCCESS := Color("#75e0a1")

static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	for type_name in ["Label", "Button", "LineEdit", "SpinBox", "OptionButton", "CheckButton", "HSlider"]:
		theme.set_color("font_color", type_name, TEXT)
		theme.set_color("font_hover_color", type_name, Color.WHITE)
		theme.set_color("font_pressed_color", type_name, Color.WHITE)
		theme.set_color("font_disabled_color", type_name, Color(TEXT_MUTED, 0.52))
	theme.set_color("font_placeholder_color", "LineEdit", Color(TEXT_MUTED, 0.72))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "Button", 15)
	theme.set_font_size("font_size", "LineEdit", 16)
	theme.set_font_size("font_size", "SpinBox", 15)
	theme.set_font_size("font_size", "OptionButton", 15)
	var panel := _box(PANEL, Color(CYAN, 0.18), 1, 10, 12)
	panel.shadow_color = Color(0, 0, 0, 0.28)
	panel.shadow_size = 12
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	var button := _box(PANEL_RAISED, Color(CYAN, 0.32), 1, 6, 12)
	var button_hover := _box(Color("#1b4050"), CYAN, 1, 6, 12)
	button_hover.shadow_color = Color(CYAN, 0.20)
	button_hover.shadow_size = 8
	var button_pressed := _box(Color("#245968"), CYAN_SOFT, 2, 6, 12)
	var button_disabled := _box(Color("#0b1823"), Color(TEXT_MUTED, 0.14), 1, 6, 12)
	theme.set_stylebox("normal", "Button", button)
	theme.set_stylebox("hover", "Button", button_hover)
	theme.set_stylebox("pressed", "Button", button_pressed)
	theme.set_stylebox("focus", "Button", button_hover)
	theme.set_stylebox("disabled", "Button", button_disabled)
	var input := _box(Color("#081522"), Color(CYAN, 0.25), 1, 6, 10)
	var input_focus := _box(Color("#0b1e2c"), CYAN, 2, 6, 10)
	theme.set_stylebox("normal", "LineEdit", input)
	theme.set_stylebox("focus", "LineEdit", input_focus)
	theme.set_stylebox("read_only", "LineEdit", input)
	theme.set_stylebox("normal", "SpinBox", input)
	theme.set_stylebox("focus", "SpinBox", input_focus)
	theme.set_stylebox("normal", "OptionButton", input)
	theme.set_stylebox("focus", "OptionButton", input_focus)
	theme.set_stylebox("normal", "CheckButton", input)
	theme.set_stylebox("hover", "CheckButton", input_focus)
	theme.set_stylebox("focus", "CheckButton", input_focus)
	theme.set_color("grabber_color", "HSlider", CYAN)
	theme.set_color("grabber_highlight_color", "HSlider", CYAN_SOFT)
	theme.set_color("slider_color", "HSlider", Color(CYAN, 0.35))
	theme.set_color("slider_focus_color", "HSlider", CYAN)
	theme.set_stylebox("tooltip", "TooltipPanel", _box(PANEL_RAISED, CYAN, 1, 5, 8))
	return theme

static func install(root: Control) -> void:
	root.theme = create_theme()
	root.add_theme_color_override("font_color", TEXT)

static func add_backdrop(root: Control) -> AtlasFrontBackdrop:
	var backdrop := AtlasFrontBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = -100
	root.add_child(backdrop)
	root.move_child(backdrop, 0)
	return backdrop

static func section_label(value: String) -> Label:
	var label := Label.new()
	label.text = value.to_upper()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", CYAN_SOFT)
	return label

static func title_label(value: String, size := 30) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT)
	return label

static func _box(background: Color, border: Color, width: int, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
