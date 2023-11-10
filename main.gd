extends Node2D

const GridFiller = preload("res://grid_filler.tscn")
const DestructionLine = preload("res://horizontal_destruction_line.tscn")
@onready var tileset = preload("res://block/block_tileset.tres")

var drag_assist: float:
	set(value):
		Global.settings["drag_assist"] = value
	get:
		return Global.settings["drag_assist"]

var game_ongoing: bool:
	set(value):
		Global.settings["game_ongoing"] = value
	get:
		return Global.settings["game_ongoing"]

var high_score: int:
	set(value):
		Global.settings["high_score"] = value
	get:
		return Global.settings["high_score"]

var score: int:
	set(value):
		Global.settings["score"] = value
		if value >= high_score:
			high_score = value
	get:
		return Global.settings["score"]

var visible_score: float:
	set(value):
		%ScoreLabel.text = str(round(value))
		visible_score = value

var visible_high_score: float:
	set(value):
		%HighScoreLabel.text = str(round(value))
		visible_high_score = value

var placing: bool = false
var placing_slot: int
var placing_position: Vector2
var click_position: Vector2
var pattern_rect: Rect2i

var pattern_slots = []

var input_enabled: bool:
	set(value):
		input_enabled = value
		if value == false:
			placing = false

func _ready():
	Global.load_game()
	input_enabled = true
	
	%DragAssist.value = drag_assist
	
	pattern_slots.push_back(%PatternSlot0)
	pattern_slots.push_back(%PatternSlot1)
	pattern_slots.push_back(%PatternSlot2)
	
	for slot_number in range(pattern_slots.size()):
		reset_slot(slot_number, game_ongoing)
		
	%Grid.clear()
	placing = false
	score = score if game_ongoing else 0
	visible_score = score
	visible_high_score = high_score
	
	%GameOverPanel.visible = false
	%NextPatternTilemap.clear()
	
	# Load previously saved tiles
	if game_ongoing:
		var used_cells = Global.settings["used_cells"]
		var atlas_coords = Global.settings["used_atlas_coords"]
		for used_cell_num in range(used_cells.size()):
			%Grid.set_cell(0, used_cells[used_cell_num], 1, atlas_coords[used_cell_num])
		
	show_all_slots()

func _process(delta):
	drag_assist = %DragAssist.value
	%DragAssistLabel.text = "Assisted dragging: " + str(int(drag_assist * 100.0)) + "%"
	update_placing_position(get_global_mouse_position())
	update_placing_grid()
	# Update score labels
	visible_score = lerp(visible_score, float(score), 0.1)
	visible_high_score = lerp(visible_high_score, float(high_score), 0.1)
	clip_grid()

# Remove tiles outside of grid boundaries
func clip_grid():
	for layer in range(%Grid.get_layers_count()):
		for tile in %Grid.get_used_cells(layer):
			if tile.x < 0 or tile.y < 0 or tile.x > 7 or tile.y > 7:
				%Grid.erase_cell(layer, tile)

func update_placing_grid():
	%Grid.clear_layer(1)
	if placing:
		%NextPatternContainer.global_position = lerp(%NextPatternContainer.global_position, placing_position, 0.5)
		%NextPatternContainer.scale = lerp(%NextPatternContainer.scale, Vector2(1, 1), 0.5)
		%Grid.set_pattern(1, get_placing_position_on_grid_map(), get_next_pattern())
	else:
		%NextPatternContainer.global_position = lerp(%NextPatternContainer.global_position, get_pattern_default_position(), 0.5)
		%NextPatternContainer.scale = lerp(%NextPatternContainer.scale, Vector2(0.4, 0.4), 0.5)

func _unhandled_input(event):
	if input_enabled == false:
		return
		
	var global_mouse_position = get_global_mouse_position()
	# We have to update the grid's layer 1 here to avoid accidentally placing blocks on top
	# of each other in the next frame when the grid is updated
	update_placing_grid()
	
	if event is InputEventMouseMotion:
		if global_mouse_position.y > click_position.y:
			click_position.y = global_mouse_position.y
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				click_position = global_mouse_position
			else:
				if placing:
					place_pattern()
				placing = false

func update_placing_position(position: Vector2):
	placing_position = position - Vector2(0, 200)
	placing_position -= Vector2(pattern_rect.size.x * Global.BLOCK_SIZE.x / 2, pattern_rect.size.y * Global.BLOCK_SIZE.y)
	if drag_assist > 0.0:
		placing_position += (position - click_position) * drag_assist

func reset_slot(slot_number, from_save_data = false):
	var slot_tilemap = pattern_slots[slot_number].get_tilemap()
	
	if from_save_data:
		var slot_cells = Global.settings["slot_cells"][slot_number]
		var slot_atlas_coords = Global.settings["slot_atlas_coords"][slot_number]
		for cell_num in range(slot_cells.size()):
			pattern_slots[slot_number].get_tilemap().set_cell(0, slot_cells[cell_num], 1, slot_atlas_coords[cell_num])
	else:
		var pattern = tileset.get_pattern(randi_range(0, tileset.get_patterns_count() - 1))
		var atlas_coordinate = Vector2i(randi_range(0, 3), randi_range(0, 3))
		
		for cell in pattern.get_used_cells():
			pattern.set_cell(cell, 1, atlas_coordinate, 0)
		
		slot_tilemap.clear()
		slot_tilemap.set_pattern(0, Vector2i(0, 0), pattern)
		
		Global.settings["slot_cells"][slot_number].clear()
		Global.settings["slot_atlas_coords"][slot_number].clear()
		
		Global.settings["slot_cells"][slot_number] = slot_tilemap.get_used_cells(0)
		for cell in slot_tilemap.get_used_cells(0):
			Global.settings["slot_atlas_coords"][slot_number].push_back(slot_tilemap.get_cell_atlas_coords(0, cell))
	
	var pattern_size = Vector2(slot_tilemap.get_used_rect().size) * Global.BLOCK_SIZE
	pattern_slots[slot_number].offset = -pattern_size / 2

func get_pattern_default_position():
	return pattern_slots[placing_slot].global_position

func get_placing_position_on_grid_map():
	return %Grid.local_to_map(%Grid.to_local(placing_position) + Vector2(32, 32) + %NextPatternTilemap.position)

func get_next_pattern():
	return %NextPatternTilemap.get_pattern(0, %NextPatternTilemap.get_used_cells(0))

func remove_complete_lines():
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
			var dl = DestructionLine.instantiate()
			dl.position = %GridContainer.position
			dl.position.y -= Global.BLOCK_SIZE.y * 4
			dl.position.y += Global.BLOCK_SIZE.y / 2.0
			dl.position.y += Global.BLOCK_SIZE.y * row
			%Game.add_child(dl)
	
	for col in range(Global.GRID_SIZE.x):
		if deleted_columns[col]:
			# TODO: This whole section is just... bullshit. Works though.
			var dl = DestructionLine.instantiate()
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
	
	%Grid.set_pattern(0, get_placing_position_on_grid_map(), get_next_pattern())
	
	game_ongoing = true
	
	score += new_used_cells.size()
	
	remove_complete_lines()
	reset_slot(placing_slot)
	#set_next_pattern_from_slot(placing_slot)
	show_all_slots()
	%NextPatternTilemap.clear()
	
	%AnimationPlayer.play("boing")
	
	Global.settings["used_cells"].clear()
	Global.settings["used_atlas_coords"].clear()
	
	if is_game_over():
		game_ongoing = false
		input_enabled = false
		%GameOverTimer.start()
	else:
		Global.settings["used_cells"] = %Grid.get_used_cells(0)
		for cell in %Grid.get_used_cells(0):
			Global.settings["used_atlas_coords"].push_back(%Grid.get_cell_atlas_coords(0, cell))
		
	Global.save_game()

func toggle_settings():
	%SettingsPanel.visible = !%SettingsPanel.visible

func restart_game():
	game_ongoing = false
	Global.save_game()
	reload_scene()

func reload_scene():
	get_tree().reload_current_scene()

func open_game_over_panel():
	if score == high_score:
		%GameOverScore.label_settings.font_color = Color("#ffcd75")
		%GameOverScoreDescription.text = "New high score!!!"
		%Confetti.emitting = true
	else:
		%GameOverScore.label_settings.font_color = Color("#f4f4f4")
		%GameOverScoreDescription.text = "Your final score was:"
	%GameOverScore.text = str(score)
	%GameOverPanel.visible = true
	input_enabled = true

func pattern_fits_on_grid(slot_number):
	var pattern = pattern_slots[slot_number].get_pattern()
	var pattern_size = pattern.get_size()
	for y in range(9 - pattern_size.y):
		for x in range(9 - pattern_size.x):
			%Grid.clear_layer(2)
			%Grid.set_pattern(2, Vector2i(x, y), pattern)
			var new_used_cells = %Grid.get_used_cells(2)
			var current_used_cells = %Grid.get_used_cells(0)
			var free_space = true
			# Check if there's a free spot on the grid
			for new_cell in new_used_cells:
				if new_cell in current_used_cells:
					free_space = false # This place was in use
			# If a free spot was found, we can return false, as the game is not over
			if free_space:
				return true
	return false

func is_game_over():
	var invalid_slot_count = 0
	for slot_number in range(pattern_slots.size()):
		if pattern_fits_on_grid(slot_number) == false:
			invalid_slot_count += 1
	return invalid_slot_count == pattern_slots.size()

func _on_animation_player_animation_finished(anim_name):
	pass

func _on_game_over_timer_timeout():
	input_enabled = false
	var gf = GridFiller.instantiate()
	gf.done_filling.connect(func():
		%Grid.clear()
		gf.begin_clearing()
	)
	gf.done_clearing.connect(func():
		open_game_over_panel()
		gf.queue_free()
	)
	%Grid.add_child(gf)
	gf.begin_filling()

func _on_pattern_slot_pressed(slot_number):
	if input_enabled == false:
		return
	if pattern_fits_on_grid(slot_number):
		placing_slot = slot_number
		placing = true
		set_next_pattern_from_slot(placing_slot)

func show_all_slots():
	for slot in pattern_slots:
		slot.get_tilemap().visible = true
	for slot in range(pattern_slots.size()):
		pattern_slots[slot].enabled = pattern_fits_on_grid(slot)

func hide_slot(slot_number):
	show_all_slots()
	pattern_slots[slot_number].get_tilemap().visible = false

func set_next_pattern_from_slot(slot_number):
	%NextPatternTilemap.clear()
	%NextPatternTilemap.set_pattern(0, Vector2i(0, 0), pattern_slots[placing_slot].get_pattern())
	%NextPatternTilemap.position = pattern_slots[slot_number].offset
	%NextPatternContainer.scale = Vector2(0.4, 0.4)
	%NextPatternContainer.global_position = get_pattern_default_position()
	hide_slot(placing_slot)


func _on_drag_assist_drag_ended(value_changed):
	Global.save_game()
