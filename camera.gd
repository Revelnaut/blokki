extends Camera2D

@onready var timer: Timer = %ShakeTimer
var previous_position: Vector2
var previous_rotation: float
var shake_intensity: float = 3

func _ready():
	pass

func _physics_process(delta):
	if not timer.is_stopped():
		position = lerp(position, previous_position + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity)), 0.4)
		#rotation_degrees = lerp(rotation_degrees, previous_rotation + randf_range(-shake_intensity, shake_intensity), 0.1)
		#position = previous_position + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		#rotation_degrees = previous_rotation + randf_range(-shake_intensity, shake_intensity) * 0.1
		
func _on_shake_timer_timeout():
	position = previous_position
	rotation_degrees = previous_rotation

func shake():
	previous_position = position
	previous_rotation = rotation_degrees
	timer.start()
