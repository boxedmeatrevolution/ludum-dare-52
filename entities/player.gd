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
var target_direction := Vector2.ZERO
var rotation_offset := 30.0
var head_collision_offset := 60.0

func _ready() -> void:
	state = State.DASH
	dash_velocity = DASH_SPEED * Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if state == State.STAND:
		var normal := get_normal()
		sprite.rotation = normal.angle() + 0.5 * PI
		if Input.is_action_just_released("dash"):
			target_direction = (get_global_mouse_position() - position - rotation_offset_vector()).normalized()
			if target_direction.dot(normal) > -0.8:
				state = State.DASH
				animation_player.play("dash")
				dash_velocity = DASH_SPEED * target_direction
				position += dash_velocity * delta + 1.0 * normal
				rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
	elif state == State.DASH:
		if dash_velocity.angle() + 0.5 * PI != sprite.rotation:
			rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
		var space_state := get_world_2d().direct_space_state
		var delta_position := dash_velocity * delta
		var next_position := position + delta_position
		var mask := 0b0000000000000010
		var raycast := space_state.intersect_ray(position, next_position + target_direction * head_collision_offset, [], mask)
		if raycast:
			position = raycast.position
			state = State.STAND
			animation_player.play("stand")
			stand_block = raycast.collider
			stand_segment_idx = raycast.shape
			var segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
			stand_position = (position - segment.a - stand_block.position).dot((segment.b - segment.a).normalized())
			position = segment.a + stand_block.position + stand_position * (segment.b - segment.a).normalized()
			var normal := get_normal()
			sprite.rotation = normal.angle() + 0.5 * PI
		else:
			position = next_position
			
	handle_fruit_collisions()
	handle_hazard_collisions()

func get_normal() -> Vector2:
	var segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
	var normal := (segment.b - segment.a).normalized().rotated(-0.5 * PI)
	return normal

func rotation_offset_vector() -> Vector2:
	return Vector2(0, -rotation_offset).rotated(sprite.rotation)
	
func head_collision_offset_vector() -> Vector2:
	return Vector2(0, -head_collision_offset).rotated(sprite.rotation)

func rotate_around_rotation_offset(rot: float) -> void:
	var angle = rot - sprite.rotation
	var offset = rotation_offset_vector()
	var delta = offset - offset.rotated(angle)
	sprite.rotation = rot
	position += delta

func handle_fruit_collisions() -> void:
	var space_state := get_world_2d().direct_space_state
	var mask := 0b0000000000000100 #Fruit
	var collisions := space_state.intersect_point(position + head_collision_offset_vector(), 32, [], mask, false, true)
	for collision in collisions:
		var fruit = collision.collider.get_parent()
		fruit.harvest()

func handle_hazard_collisions() -> void:
	var space_state := get_world_2d().direct_space_state
	var mask := 0b0000000000001000 #hazard
	var collisions := space_state.intersect_point(position + head_collision_offset_vector(), 32, [], mask, false, true)
	for collision in collisions:
		print("Oh I have been slain!")
		var hazard = collision.collider.get_parent()
