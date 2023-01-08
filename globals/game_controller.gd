extends Node

var current_level_idx := -1
var num_fruits_remaining := 0
var levels := ["res://levels/level_1.tscn", "res://levels/level_2.tscn"]

func _ready() -> void:
	var loaded_level_path = get_tree().current_scene.filename
	var loaded_level_idx = levels.find(loaded_level_path)
	if loaded_level_idx != -1:
		current_level_idx = loaded_level_idx
	
	
func _process(delta: float) -> void:
	pass
	
func try_enter_door() -> void:
	if num_fruits_remaining <= 0:
		print("Next level")
		go_to_next_level()
	else:
		print("Not enough fruit")

func go_to_next_level() -> void:
	if current_level_idx < levels.size() - 1:
		current_level_idx += 1
		get_tree().change_scene(levels[current_level_idx])
