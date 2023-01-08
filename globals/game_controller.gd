extends Node

const TIME_TO_RESET_AFTER_DEATH := 0.6
const TIME_TO_LOAD_NEXT_LEVEL := 3.0

var current_level_idx := -1
var levels := ["res://levels/level_1.tscn", "res://levels/level_2.tscn"]

var num_fruits_remaining := 0
var spaceship = null

var is_player_dead := false
var is_level_complete := false
var player_death_timer := 0.0
var level_complete_timer := 0.0

func _ready() -> void:
	var loaded_level_path = get_tree().current_scene.filename
	var loaded_level_idx = levels.find(loaded_level_path)
	if loaded_level_idx != -1:
		current_level_idx = loaded_level_idx
	
	
func _process(delta: float) -> void:
	if is_level_complete and current_level_idx < levels.size() - 1:
		level_complete_timer += delta
		if level_complete_timer > TIME_TO_LOAD_NEXT_LEVEL:
			load_level(current_level_idx + 1)
	elif is_player_dead:
		player_death_timer += delta
		if player_death_timer > TIME_TO_RESET_AFTER_DEATH:
			load_level(current_level_idx)
	
func try_enter_door() -> void:
	if num_fruits_remaining <= 0:
		is_level_complete = true
		if spaceship:
			spaceship.launch()
	else:
		print("Not enough fruit")

func trigger_player_death() -> void:
	is_player_dead = true
	player_death_timer = 0

func load_level(level_idx: int) -> void:
	is_player_dead = false
	is_level_complete = false
	num_fruits_remaining = 0
	player_death_timer = 0
	level_complete_timer = 0
	get_tree().change_scene(levels[level_idx])
