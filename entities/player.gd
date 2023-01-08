extends Node2D

const Block := preload("res://entities/block.gd")

enum State {
	STAND,
	DASH,
}

const DASH_SPEED := 600

onready var sprite := $Sprite
onready var animation_player := $AnimationPlayer

var state : int = State.STAND

var stand_block : Block = null
var stand_segment_idx := 0
var stand_position := 0.0
var dash_velocity := Vector2.ZERO

func _ready() -> void:
	state = State.DASH
	dash_velocity = DASH_SPEED * Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if state == State.STAND:
		var segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
		var normal := stand_block.dir * (segment.b - segment.a).normalized().rotated(-0.5 * PI)
		sprite.rotation = normal.angle() + 0.5 * PI
		if Input.is_action_just_released("dash"):
			var target_direction := (get_global_mouse_position() - position).normalized()
			if target_direction.dot(normal) > 0.0:
				state = State.DASH
				animation_player.play("dash")
				dash_velocity = DASH_SPEED * target_direction
				position += dash_velocity * delta + 1.0 * normal
	elif state == State.DASH:
		sprite.rotation = dash_velocity.angle() + 0.5 * PI
		var space_state := get_world_2d().direct_space_state
		var delta_position := dash_velocity * delta
		var next_position := position + delta_position
		var mask := 0b0000000000000010
		var raycast := space_state.intersect_ray(position, next_position, [], mask)
		if raycast:
			position = raycast.position
			state = State.STAND
			animation_player.play("stand")
			stand_block = raycast.collider
			stand_segment_idx = raycast.shape
			var segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
			stand_position = (position - segment.a - stand_block.position).dot((segment.b - segment.a).normalized())
			position = segment.a + stand_block.position + stand_position * (segment.b - segment.a).normalized()
		else:
			position = next_position
