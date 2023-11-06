@tool
extends Area2D

@export var slot_number: int
var enabled: bool = true

var offset: Vector2:
	set(value):
		offset = value
		%TileMap.position = offset * %TileMap.scale

signal pressed(slot_number)

func _process(delta):
	modulate.v = lerp(modulate.v, 1.0 if enabled else 0.5, 0.2)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed.emit(slot_number)

func get_tilemap():
	return %TileMap

func get_pattern():
	return %TileMap.get_pattern(0, %TileMap.get_used_cells(0))
