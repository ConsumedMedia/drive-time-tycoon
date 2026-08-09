extends Node2D

## Scrolls THREE copies of a horizontally-tileable sky texture side by
## side, wrapping seamlessly. Upgraded from 2 tiles to 3 for redundancy -
## with only 2, SkyB (the later sibling, drawn on top wherever they
## overlap) was masking SkyA's leading edge whenever the two got close,
## making it look like a gap even though the underlying positions were
## always mathematically correct. A third tile means there's always
## backup coverage even if two tiles briefly overlap or draw-order masks
## each other at their shared edge.

@export var scroll_speed: float = 15.0

## Leave at 0 to auto-calculate from the texture's pixel width * scale.
@export var sky_width_override: float = 0.0

@onready var sky_a: Sprite2D = $SkyA
@onready var sky_b: Sprite2D = $SkyB
@onready var sky_c: Sprite2D = $SkyC

var _sky_width: float
var _base_x: float
var _distance_scrolled: float = 0.0

func _ready() -> void:
	if sky_width_override > 0.0:
		_sky_width = sky_width_override
	else:
		_sky_width = sky_a.texture.get_width() * sky_a.scale.x
	_base_x = sky_a.position.x

func _process(delta: float) -> void:
	_distance_scrolled += scroll_speed * delta
	var wrapped_offset: float = fmod(_distance_scrolled, _sky_width)

	sky_a.position.x = _base_x - wrapped_offset
	sky_b.position.x = _base_x - wrapped_offset + _sky_width
	sky_c.position.x = _base_x - wrapped_offset + (_sky_width * 2.0)
