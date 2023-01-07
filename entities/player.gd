extends Node2D

const Block := preload("res://entities/block.gd")

enum State {
	STAND,
	DASH,
}

const DASH_SPEED := 400

onready var animation_player := $AnimationPlayer

var state : int = State.STAND

var stand_block : Block = null
var stand_segment := 0
var stand_fraction := 0.0
var dash_velocity := Vector2.ZERO

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if state == State.STAND:
		if Input.is_action_just_released("dash"):
			var target_direction := (get_global_mouse_position() - position).normalized()
			state = State.DASH
			dash_velocity = DASH_SPEED * target_direction
	elif state == State.DASH:
		var space_state := get_world_2d().direct_space_state
		var delta_position := dash_velocity * delta
		var next_position := position + delta_position
		var mask := 0b0000000000000010
		var raycast := space_state.intersect_ray(position, next_position, [], mask)
		if raycast:
			position = raycast.position
			state = State.STAND
			stand_block = raycast.collider
			# stand_segment
			# stand_fraction
		else:
			position = next_position
