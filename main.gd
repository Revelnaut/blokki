extends Node2D

@onready var destruction_line = preload("res://horizontal_destruction_line.tscn")
@onready var tileset = preload("res://tileset.tres")
@onready var ap = %AnimationPlayer
@onready var next_pattern = %NextPattern
@onready var next_pattern_2 = %NextPattern2

var high_score: int:
	set(value):
		%HighScoreLabel.text = str(value)
		Global.settings["high_score"] = value
	get:
		return Global.settings["high_score"]

var score: int:
	set(value):
		%ScoreLabel.text = str(value)
		score = value
		if score >= high_score:
			high_score = score
			Global.save_game()

var placing_pattern = false
var placing_position: Vector2
var click_position: Vector2
var pattern_rect: Rect2i

func _ready():
	Global.load_game()
	new_game()

func _process(delta):
	%Grid.clear_layer(1)
	if placing_pattern:
		%NextPattern.global_position = lerp(%NextPattern.global_position, placing_position, 0.5)
		%NextPattern.scale = lerp(%NextPattern.scale, Vector2(1, 1), 0.5)
		%Grid.set_pattern(1, get_placing_position_on_grid_map(), get_pattern_of_next())
	else:
		%NextPattern.position = lerp(%NextPattern.position, get_pattern_default_position(), 0.5)
		%NextPattern.scale = lerp(%NextPattern.scale, Vector2(0.5, 0.5), 0.5)

func _unhandled_input(event):
	var global_mouse_position = get_global_mouse_position()
	if event is InputEventMouseMotion:
		if global_mouse_position.y > click_position.y:
			click_position.y = global_mouse_position.y
		update_placing_position(global_mouse_position)
	
	if event is InputEventMouseButton:
		if event.pressed:
			click_position = global_mouse_position
		else:
			if placing_pattern:
				place_pattern()
		placing_pattern = event.pressed
		update_placing_position(global_mouse_position)
	
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_DOWN:
				next_random_pattern()
			if event.keycode == KEY_UP:
				new_game()

func update_placing_position(position: Vector2):
	placing_position = position - Vector2(0, 200)
	placing_position -= Vector2(pattern_rect.size.x * Global.BLOCK_SIZE.x / 2, pattern_rect.size.y * Global.BLOCK_SIZE.y)
	if Global.settings["gameplay_place_assist"]:
		placing_position += (position - click_position) * Global.settings["gameplay_place_assist_intensity"]

func new_game():
	%Grid.clear()
	next_random_pattern()
	next_random_pattern()
	placing_pattern = false
	score = 0
	high_score = high_score

func next_random_pattern():
	var pattern = tileset.get_pattern(randi_range(0, tileset.get_patterns_count() - 1))
	var tile_alternative_count = tileset.get_source(1).get_alternative_tiles_count(Vector2i(0, 0))
	var alternative = randi_range(1, tile_alternative_count - 1)
	
	for cell in pattern.get_used_cells():
		pattern.set_cell(cell, 1, Vector2i(0, 0), alternative)
	
	%NextPattern.clear()
	%NextPattern.set_pattern(0,Vector2i(0, 0),%NextPattern2.get_pattern(0, %NextPattern2.get_used_cells(0)))
	%NextPattern2.clear()
	%NextPattern2.set_pattern(0, Vector2i(0, 0), pattern)
	pattern_rect = %NextPattern.get_used_rect()
	
	var next_pattern_position = %NextPatternDefaultPosition.position + Vector2(-150, 150) - Vector2(%NextPattern2.get_used_rect().size.x * Global.BLOCK_SIZE.x * 0.5 / 2, 0)
	
	%NextPattern.position = get_pattern_default_position()
	%NextPattern.position.y = next_pattern_position.y
	%NextPattern.scale = Vector2(0.5, 0.5)
	
	%NextPattern2.position = next_pattern_position
	%NextPattern2.scale = Vector2(0.5, 0.5)

func get_pattern_default_position():
	return %NextPatternDefaultPosition.position - Vector2(pattern_rect.size.x * Global.BLOCK_SIZE.x * 0.5 / 2, 0)

func get_placing_position_on_grid_map():
	return %Grid.local_to_map(%Grid.to_local(placing_position) + Vector2(32, 32))

func get_pattern_of_next():
	return %NextPattern.get_pattern(0, %NextPattern.get_used_cells(0))

func check_full_lines():
	var marked_for_deletion = []
	var deleted_rows = []
	var deleted_columns = []
	var score_multiplier = 0
	
	deleted_rows.resize(Global.GRID_SIZE.y)
	deleted_rows.fill(false)
	deleted_columns.resize(Global.GRID_SIZE.x)
	deleted_columns.fill(false)
	
	for y in range(Global.GRID_SIZE.y):
		var delete_row = true
		for x in range(Global.GRID_SIZE.x):
			if %Grid.get_cell_atlas_coords(0, Vector2i(x, y)) == Vector2i(-1, -1):
				delete_row = false
		
		if delete_row:
			score_multiplier += 1
			deleted_rows[y] = true
			for x in range(Global.GRID_SIZE.x):
				marked_for_deletion.append(Vector2i(x, y))
	
	for x in range(Global.GRID_SIZE.x):
		var delete_column = true
		for y in range(Global.GRID_SIZE.y):
			if %Grid.get_cell_atlas_coords(0, Vector2i(x, y)) == Vector2i(-1, -1):
				delete_column = false
		
		if delete_column:
			score_multiplier += 1
			deleted_columns[x] = true
			for y in range(Global.GRID_SIZE.y):
				marked_for_deletion.append(Vector2i(x, y))
	
	for cell in marked_for_deletion:
		%Grid.erase_cell(0, cell)
		score += 1 * score_multiplier
	
	for row in range(Global.GRID_SIZE.y):
		if deleted_rows[row]:
			# TODO: This whole section is just... bullshit. Works though.
			var dl = destruction_line.instantiate()
			dl.position = %GridContainer.position
			dl.position.y -= Global.BLOCK_SIZE.y * 4
			dl.position.y += Global.BLOCK_SIZE.y / 2.0
			dl.position.y += Global.BLOCK_SIZE.y * row
			%Game.add_child(dl)
	
	for col in range(Global.GRID_SIZE.x):
		if deleted_columns[col]:
			# TODO: This whole section is just... bullshit. Works though.
			var dl = destruction_line.instantiate()
			dl.rotation_degrees = 90
			dl.position = %GridContainer.position
			dl.position.x -= Global.BLOCK_SIZE.x * 4
			dl.position.x += Global.BLOCK_SIZE.x / 2.0
			dl.position.x += Global.BLOCK_SIZE.x * col
			%Game.add_child(dl)

func place_pattern():
	var new_used_cells = %Grid.get_used_cells(1)
	var current_used_cells = %Grid.get_used_cells(0)
	
	for new_cell in new_used_cells:
		if new_cell in current_used_cells:
			print("New pattern doesn't fit")
			return
		if new_cell.x < 0 || new_cell.y < 0 || new_cell.x >= Global.GRID_SIZE.x || new_cell.y >= Global.GRID_SIZE.y:
			print("New pattern out of bounds")
			return
	
	%Grid.set_pattern(0, get_placing_position_on_grid_map(), get_pattern_of_next())
	
	ap.speed_scale = 0.5
	ap.play("boing")
	
	score += new_used_cells.size()
	
	check_full_lines()
	
	next_random_pattern()

func _on_newgame_button_pressed():
	new_game()

func _on_settings_button_pressed():
	pass # Replace with function body.
