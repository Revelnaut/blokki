extends Node2D

@onready var ap = %AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	ap.play("disappear")
	ap.speed_scale = 1.5
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not ap.is_playing():
		queue_free()
	pass
