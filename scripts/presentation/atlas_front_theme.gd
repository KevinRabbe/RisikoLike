class_name AtlasFrontTheme
extends RefCounted

const ASSET_ROOT := "res://assets/ui/atlas_front"
const MAIN_MENU_BACKGROUND := ASSET_ROOT + "/backgrounds/main_menu_command_room.png"
const LOBBY_BACKGROUND := ASSET_ROOT + "/backgrounds/lobby_command_room.png"
const MENU_OVERLAY := ASSET_ROOT + "/backgrounds/menu_dark_overlay.png"
const RECONNECT_BACKDROP := ASSET_ROOT + "/states/reconnect_backdrop.png"
const VICTORY_BACKDROP := ASSET_ROOT + "/states/victory_backdrop.png"
const WORDMARK := ASSET_ROOT + "/branding/atlas_front_wordmark.png"
const MARK := ASSET_ROOT + "/branding/atlas_front_mark.png"

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
	theme.default_font_size = 17
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

static func add_backdrop(root: Control, background_path: String = MAIN_MENU_BACKGROUND) -> AtlasFrontBackdrop:
	var backdrop := AtlasFrontBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = -100
	backdrop.configure(background_path, MENU_OVERLAY)
	root.add_child(backdrop)
	root.move_child(backdrop, 0)
	return backdrop

static func add_state_backdrop(root: Control, texture_path: String, top_offset: float = 104.0, bottom_offset: float = 184.0) -> TextureRect:
	var backdrop := TextureRect.new()
	backdrop.texture = load(texture_path) as Texture2D
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	backdrop.set_anchors_preset(Control.PRESET_CENTER_TOP)
	backdrop.offset_left = -250
	backdrop.offset_top = top_offset
	backdrop.offset_right = 250
	backdrop.offset_bottom = bottom_offset
	backdrop.modulate = Color(1.0, 1.0, 1.0, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.visible = false
	backdrop.z_index = 1
	root.add_child(backdrop)
	return backdrop

static func branding_texture(mark: bool = false, width: float = 320.0) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(MARK if mark else WORDMARK) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture_size := image.texture.get_size() if image.texture != null else Vector2(width, width)
	image.custom_minimum_size = Vector2(width, width * texture_size.y / texture_size.x)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

static func state_overlay_style() -> StyleBoxFlat:
	var style := _box(Color(0.03, 0.10, 0.16, 0.18), Color(CYAN, 0.70), 1, 10, 14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 12
	return style

static func apply_icon(button: Button, icon_name: String, max_width: int = 26) -> void:
	var icon_path := ASSET_ROOT + "/icons/" + icon_name + ".png"
	var texture := load(icon_path) as Texture2D
	if texture == null:
		return
	button.icon = texture
	button.add_theme_constant_override("icon_max_width", max_width)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

static func add_decor_texture(root: Control, texture_path: String, rect: Rect2, opacity: float = 0.35) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(texture_path) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.position = rect.position
	image.size = rect.size
	image.modulate = Color(1.0, 1.0, 1.0, opacity)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.z_index = -1
	root.add_child(image)
	return image

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
