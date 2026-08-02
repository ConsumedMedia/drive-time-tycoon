extends Node2D

## Reusable animation controller for any character sprite: a gentle idle
## bob (pure code, no extra art) and a blink (a flat-colored rectangle
## briefly covering the eyes - zero risk of a mismatched second GPT image,
## since it's just a shape toggling on/off).

@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 2.0
@export var blink_interval_min: float = 2.0
@export var blink_interval_max: float = 5.0
@export var blink_duration: float = 0.15

@onready var sprite: Sprite2D = $Sprite2D
@onready var blink_overlay_left: Control = $BlinkOverlayLeft
@onready var blink_overlay_right: Control = $BlinkOverlayRight

var _base_y: float
var _time: float = 0.0

func _ready() -> void:
	_base_y = sprite.position.y
	blink_overlay_left.visible = false
	blink_overlay_right.visible = false
	_schedule_next_blink()

## Called by whatever instances this scene (e.g. station_view.gd) right
## after add_child(), to set which character this is and where their eyes
## sit - so one shared scene works for every Talent instead of needing a
## duplicate scene per person.
func configure(texture_path: String, left_eye_offset: Vector2, right_eye_offset: Vector2, eye_color: Color) -> void:
	sprite.texture = load(texture_path)

	var overlay_size := Vector2(40, 47)
	blink_overlay_left.position = left_eye_offset
	blink_overlay_left.size = overlay_size
	blink_overlay_right.position = right_eye_offset
	blink_overlay_right.size = overlay_size

	_set_overlay_color(blink_overlay_left, eye_color)
	_set_overlay_color(blink_overlay_right, eye_color)

## Handles either node type for the overlays - a plain ColorRect (set
## .color directly) or a Panel with a rounded StyleBoxFlat (duplicate its
## existing style so we don't overwrite the corner radius you set by hand,
## just the color).
func _set_overlay_color(overlay: Control, eye_color: Color) -> void:
	if overlay is ColorRect:
		overlay.color = eye_color
	elif overlay is Panel:
		var base_style: StyleBox = overlay.get_theme_stylebox("panel")
		var style: StyleBoxFlat = base_style.duplicate() as StyleBoxFlat
		style.bg_color = eye_color
		overlay.add_theme_stylebox_override("panel", style)

func _process(delta: float) -> void:
	_time += delta
	sprite.position.y = _base_y + sin(_time * bob_speed) * bob_amplitude

func _schedule_next_blink() -> void:
	var wait_time: float = randf_range(blink_interval_min, blink_interval_max)
	await get_tree().create_timer(wait_time).timeout
	_do_blink()

func _do_blink() -> void:
	blink_overlay_left.visible = true
	blink_overlay_right.visible = true
	await get_tree().create_timer(blink_duration).timeout
	blink_overlay_left.visible = false
	blink_overlay_right.visible = false
	_schedule_next_blink()
