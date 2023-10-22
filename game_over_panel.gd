extends Panel

func _input(event):
	if visible:
		if event is InputEventMouseButton:
			print("yee")
