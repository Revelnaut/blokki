extends Node2D

var timer: float = 0.0
var delay: float = 0.01
var clear_position: Vector2i
var filling: bool = false

signal done

func _process(delta):
	if filling:
		timer += delta
		if timer >= delay:
			timer = 0.0
			
			var atlas_coordinate = Vector2i(randi_range(0, 3), randi_range(0, 3))
			%TileMap.set_cell(0, clear_position, 1, atlas_coordinate)
			
			clear_position.x += 1
			if clear_position.x == 8:
				clear_position.y += 1
				clear_position.x = 0
			
			if clear_position.y == 8:
				done.emit()
				filling = false

func begin_filling():
	%TileMap.clear()
	clear_position = Vector2i(0, 0)
	timer = 0.0
	filling = true
