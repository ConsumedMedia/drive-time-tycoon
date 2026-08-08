extends Button

## Icon + hover tint + click dim + a custom tooltip positioned above this
## specific button. Uses its OWN hint_text field rather than the built-in
## Tooltip Text property - Godot's native tooltip system only activates
## when Tooltip Text is non-empty, so keeping that blank and storing our
## text separately means there's no native tooltip left to suppress or
## fight with (a stray border/frame from the empty suppressed tooltip
## was the cause of the small line artifact near the cursor).

@export_multiline var hint_text: String = ""
@export var hover_tint: Color = Color(1.25, 1.15, 0.9, 1.0)
@export var click_opacity: float = 0.75
@export var tween_duration: float = 0.1
@export var tooltip_gap_above: float = 10.0
@export var tooltip_font_size: int = 16
@export var tooltip_background_color: Color = Color(0.1, 0.1, 0.1, 0.85)
@export var tooltip_padding: float = 12.0

var _tooltip: PanelContainer = null

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", hover_tint, tween_duration)
	_show_tooltip()

func _on_mouse_exited() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, tween_duration)
	_hide_tooltip()

func _on_button_down() -> void:
	var tween := create_tween()
	tween.tween_property(self, "self_modulate:a", click_opacity, tween_duration)

func _on_button_up() -> void:
	var tween := create_tween()
	tween.tween_property(self, "self_modulate:a", 1.0, tween_duration)

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

	# Longer hint text (3-4 sentences) needs to wrap into multiple lines
	# within a fixed width, rather than rendering as one giant unwrapped
	# line that runs off both edges of the screen.
	label.custom_minimum_size = Vector2(320, 0)
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
	var x: float = global_position.x + (size.x / 2.0) - (tooltip_size.x / 2.0)
	var y: float = global_position.y - tooltip_size.y - tooltip_gap_above
	_tooltip.global_position = Vector2(x, y)

func _hide_tooltip() -> void:
	if _tooltip != null:
		_tooltip.queue_free()
		_tooltip = null
