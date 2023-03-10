extends Node

const TIME_TO_RESET_AFTER_DEATH := 1.0
const TIME_TO_LOAD_NEXT_LEVEL := 3.0

var spawn_player_next_tick := true
var current_level_idx := -1
var levels := [
	"res://levels/level_1.tscn", 
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn",
	"res://levels/level_4.tscn",
	"res://levels/level_5.tscn",
	"res://levels/level_6.tscn",
	"res://levels/level_1.tscn", 
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn",
	"res://levels/level_4.tscn",
	"res://levels/level_5.tscn",
	"res://levels/level_6.tscn",
	"res://levels/game_finished.tscn"
]
var level_time := [
	20,
	20,
	14,
	19,
	19,
	18,
	
	14,
	14,
	10,
	13,
	14,
	14,
	
	100000,
]

var num_fruits_remaining := 0
var spaceship = null
var player = null
var timer = null
var fruit_type := 1

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
	if spawn_player_next_tick:
		spawn_player_next_tick = false
		if spaceship and player and is_instance_valid(spaceship) and is_instance_valid(player):
			player.position = spaceship.position
			player.dash_velocity = Vector2(0.0, -1000.0).rotated(spaceship.rotation + PI)
			
	if is_level_complete and current_level_idx < levels.size() - 1:
		level_complete_timer += delta
		if level_complete_timer > TIME_TO_LOAD_NEXT_LEVEL:
			current_level_idx += 1
			load_level(current_level_idx)
	elif is_player_dead:
		player_death_timer += delta
		if player_death_timer > TIME_TO_RESET_AFTER_DEATH:
			load_level(current_level_idx)
	
func try_enter_door() -> bool:
	if num_fruits_remaining <= 0:
		is_level_complete = true
		if player and is_instance_valid(player):
			player.queue_free()
		if spaceship and is_instance_valid(spaceship):
			var p : Node = spaceship.get_parent()
			p.move_child(spaceship, p.get_child_count() - 1)
			spaceship.launch()
		return true
	return false

func trigger_player_death() -> void:
	is_player_dead = true
	player_death_timer = 0

func load_level(level_idx: int) -> void:
	spawn_player_next_tick = true
	is_player_dead = false
	is_level_complete = false
	num_fruits_remaining = 0
	player_death_timer = 0
	level_complete_timer = 0
	get_tree().change_scene(levels[level_idx])
	$"/root/GameController".fruit_type = randi() % 6

