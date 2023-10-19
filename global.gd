extends Node

const GRID_SIZE = Vector2i(8, 8)
const BLOCK_SIZE = Vector2(64, 64)
const DATA_FILE = "user://save.data"

var settings = {
	"gameplay_place_assist": true,
	"gameplay_place_assist_intensity": 0.5,
	"high_score": 0,
}

func save_game():
	var save_file = FileAccess.open(DATA_FILE, FileAccess.WRITE)
	save_file.store_var(settings)

func load_game():
	if not FileAccess.file_exists(DATA_FILE):
		return
	var save_file = FileAccess.open(DATA_FILE, FileAccess.READ)
	settings = save_file.get_var()
