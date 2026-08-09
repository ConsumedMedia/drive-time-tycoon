extends TextureRect

## Hover behavior for top-bar stat icons (Station Name, Listeners, Hype,
## Cash, Loyalty). Not a button - these aren't clickable, just displays -
## so no click-dim effect, just hover detection and a tooltip. The
## tooltip drops BELOW the icon instead of above, since these sit at the
## top of the screen and there's nowhere for it to go but down.
##
## The live-updating number itself is a separate child Label positioned
## in the blank space baked into each icon's art - this script doesn't
## touch that Label's text at all, station_view.gd keeps setting it
## directly via the same %Listeners / %Hype / %Cash / %Loyalty unique
## names it already used before this rebuild.

@export_multiline var hint_text: String = ""
@export var tooltip_gap_below: float = 10.0
@export var tooltip_font_size: int = 16
@export var tooltip_background_color: Color = Color(0.1, 0.1, 0.1, 0.85)
@export var tooltip_padding: float = 12.0

var _tooltip: PanelContainer = null

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_show_tooltip()

func _on_mouse_exited() -> void:
	_hide_tooltip()

func _show_tooltip() -> void:
	if hint_text == "":
		return

	_hide_tooltip()

	var panel := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = tooltip_background_color
	panel_style.content_margin_left = tooltip_padding
	panel_style.content_margin_right = tooltip_padding
	panel_style.content_margin_top = tooltip_padding
	panel_style.content_margin_bottom = tooltip_padding
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	label.text = hint_text
	label.add_theme_color_override("font_color", Color.WHITE)
	label.custom_minimum_size = Vector2(280, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", tooltip_font_size)

	panel.add_child(label)

	get_tree().current_scene.add_child(panel)
	_tooltip = panel

	call_deferred("_position_tooltip")

func _position_tooltip() -> void:
	if _tooltip == null:
		return
	var tooltip_size: Vector2 = _tooltip.size
	var viewport_width: float = get_viewport_rect().size.x

	var x: float = global_position.x + (size.x / 2.0) - (tooltip_size.x / 2.0)
	x = clamp(x, 0.0, viewport_width - tooltip_size.x)

	var y: float = global_position.y + size.y + tooltip_gap_below
	_tooltip.global_position = Vector2(x, y)

func _hide_tooltip() -> void:
	if _tooltip != null:
		_tooltip.queue_free()
		_tooltip = null
