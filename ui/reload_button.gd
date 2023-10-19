extends TextureButton

var down = false

func _process(delta):
	if down and is_hovered():
		scale = lerp(scale, Vector2(1.5, 1.5), 0.5)
	else:
		scale = lerp(scale, Vector2.ONE, 0.5)

func _on_button_down():
	down = true

func _on_button_up():
	down = false
