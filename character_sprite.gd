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
@onready var blink_overlay_left: ColorRect = $BlinkOverlayLeft
@onready var blink_overlay_right: ColorRect = $BlinkOverlayRight

var _base_y: float
var _time: float = 0.0

func _ready() -> void:
	_base_y = sprite.position.y
	blink_overlay_left.visible = false
	blink_overlay_right.visible = false
	_schedule_next_blink()

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
