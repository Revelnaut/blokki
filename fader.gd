extends ColorRect

var fade_speed = 5
var fade_direction = -1

func _ready():
	visible = true
	color.a = 2.0

func _process(delta):
	color.a += delta * fade_speed * fade_direction
	if color.a <= 0.0:
		queue_free()

func fade_out():
	fade_direction = 1

func fade_in():
	fade_direction = -1
