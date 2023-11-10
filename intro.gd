extends Node

func _ready():
	%AnimationPlayer.play("icon_bounce")

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
