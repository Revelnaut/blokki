extends Node2D

var timer: float = 0.0
var delay: float = 0.02
var grid_position: Vector2i
var filling: bool = false
var clearing: bool = false

signal done_filling
signal done_clearing

func _process(delta):
	if filling or clearing:
		timer += delta
		if timer >= delay:
			timer = 0.0
			
			if filling:
				var atlas_coordinate = Vector2i(randi_range(0, 3), randi_range(0, 3))
				%TileMap.set_cell(0, grid_position, 1, atlas_coordinate)
			elif clearing:
				%TileMap.set_cell(0, grid_position)
			
			grid_position.x += 1
			if grid_position.x == 8:
				grid_position.y += 1
				grid_position.x = 0
			
			if grid_position.y == 8:
				if filling:
					done_filling.emit()
					filling = false
				elif clearing:
					done_clearing.emit()
					clearing = false

func begin_filling():
	%TileMap.clear()
	grid_position = Vector2i(0, 0)
	timer = 0.0
	filling = true

func begin_clearing():
	grid_position = Vector2i(0, 0)
	timer = 0.0
	clearing = true
