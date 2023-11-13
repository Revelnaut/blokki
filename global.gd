extends Node

const GRID_SIZE = Vector2i(8, 8)
const BLOCK_SIZE = Vector2(64, 64)
const DATA_FILE = "user://save.data"

var settings = {
	"game_ongoing": false,
	"drag_assist": 0.3,
	"score": 0,
	"high_score": 0,
	"used_cells": [],
	"used_atlas_coords": [],
	"slot_count": 3,
	"slot_cells": [[], [], []],
	"slot_atlas_coords": [[], [], []]
}

func save_game():
	var save_file = FileAccess.open(DATA_FILE, FileAccess.WRITE)
	save_file.store_var(settings)

func load_game():
	if not FileAccess.file_exists(DATA_FILE):
		return
	var save_file = FileAccess.open(DATA_FILE, FileAccess.READ)
	settings.merge(save_file.get_var(), true)
