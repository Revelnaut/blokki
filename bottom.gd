extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		visible = true
	else:
		visible = false
