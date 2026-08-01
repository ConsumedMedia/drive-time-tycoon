extends Node2D

## Scrolls two copies of a horizontally-tileable sky texture side by side,
## wrapping each one back around once it scrolls off-screen. Classic
## "conveyor belt" seamless scroll - no shader needed.

@export var scroll_speed: float = 15.0

@onready var sky_a: Sprite2D = $SkyA
@onready var sky_b: Sprite2D = $SkyB

var _sky_width: float

func _ready() -> void:
	_sky_width = sky_a.texture.get_width() * sky_a.scale.x
	sky_b.position.x = sky_a.position.x + _sky_width

func _process(delta: float) -> void:
	sky_a.position.x -= scroll_speed * delta
	sky_b.position.x -= scroll_speed * delta

	if sky_a.position.x <= -_sky_width:
		sky_a.position.x = sky_b.position.x + _sky_width
	if sky_b.position.x <= -_sky_width:
		sky_b.position.x = sky_a.position.x + _sky_width
