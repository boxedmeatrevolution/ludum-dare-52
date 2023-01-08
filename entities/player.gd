extends Node2D

const Block := preload("res://entities/block.gd")

enum State {
	STAND,
	DASH,
	SLIDE,
}

const BLOCK_MASK := 0b0000000000000010

const DASH_SPEED := 600.0
const SLIDE_SPEED_MIN := 200.0
const SLIDE_FRICTION := 400.0

onready var sprite := $Sprite
onready var animation_player := $AnimationPlayer

var state : int = State.STAND

var stand_block : Block = null
var stand_segment_idx := 0
var stand_position := 0.0
var slide_velocity := 0.0
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
	elif state == State.SLIDE:
		sprite.rotation = get_normal().angle() + 0.5 * PI
		if slide_velocity == 0.0:
			state = State.STAND
		else:
			var max_distance := abs(slide_velocity * delta)
			while max_distance > 0.0:
				var segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
				var segment_length := (segment.b - segment.a).length()
				var edge_distance : float
				if slide_velocity > 0.0:
					edge_distance = segment_length - stand_position
				else:
					edge_distance = stand_position
				var next_stand_position := stand_position + slide_velocity * delta
				if edge_distance < max_distance:
					if slide_velocity > 0.0:
						next_stand_position = segment_length
					else:
						next_stand_position = 0.0
				var next_position := convert_pos_seg_to_global(stand_block, stand_segment_idx, next_stand_position)
				var space_state := get_world_2d().direct_space_state
				var raycast := space_state.intersect_ray(position, next_position, [stand_block], BLOCK_MASK)
				if raycast:
					var old_tangent := get_tangent()
					stand_block = raycast.collider
					stand_segment_idx = raycast.shape
					stand_position = convert_pos_global_to_seg(stand_block, stand_segment_idx, raycast.position)
					slide_velocity *= get_tangent().dot(old_tangent)
					next_position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
					max_distance -= (next_position - position).length()
					position = next_position
				elif edge_distance < max_distance:
					var old_tangent := get_tangent()
					if slide_velocity > 0.0:
						stand_segment_idx = (stand_segment_idx + 1) % stand_block.segments.size()
						stand_position = 0.0
					else:
						stand_segment_idx = (stand_segment_idx + stand_block.segments.size() - 1) % stand_block.segments.size()
						var prev_segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
						var prev_segment_length := (prev_segment.b - prev_segment.a).length()
						stand_position = prev_segment_length
					slide_velocity *= get_tangent().dot(old_tangent)
					max_distance -= edge_distance
					position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
				else:
					stand_position = next_stand_position
					position = next_position
					max_distance = 0.0
	elif state == State.DASH:
		if dash_velocity.angle() + 0.5 * PI != sprite.rotation:
			rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
		var space_state := get_world_2d().direct_space_state
		var delta_position := dash_velocity * delta
		var next_position := position + delta_position
		var raycast := space_state.intersect_ray(position, next_position + target_direction * head_collision_offset, [], BLOCK_MASK)
		if raycast:
			state = State.SLIDE
			animation_player.play("slide")
			stand_block = raycast.collider
			stand_segment_idx = raycast.shape
			stand_position = convert_pos_global_to_seg(stand_block, stand_segment_idx, raycast.position)
			position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
			sprite.rotation = get_normal().angle() + 0.5 * PI
			slide_velocity = get_tangent().dot(dash_velocity)
		else:
			position = next_position

func get_tangent() -> Vector2:
	if state == State.STAND || state == State.SLIDE:
		var segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
		var tangent := (segment.b - segment.a).normalized()
		return tangent
	else:
		return Vector2(NAN, NAN)

func get_normal() -> Vector2:
	return get_tangent().rotated(-0.5 * PI)

func convert_pos_seg_to_global(block: Block, segment_idx: int, segment_position: float) -> Vector2:
	var segment : SegmentShape2D = block.segments[segment_idx]
	var position := segment.a + block.position + segment_position * (segment.b - segment.a).normalized()
	return position
	
func convert_pos_global_to_seg(block: Block, segment_idx: int, position: Vector2) -> float:
	var segment : SegmentShape2D = block.segments[segment_idx]
	var segment_position = clamp(
		(position - segment.a - block.position).dot((segment.b - segment.a).normalized()),
		0.0,
		(segment.b - segment.a).length())
	return segment_position

func rotation_offset_vector() -> Vector2:
	return Vector2(0, -rotation_offset).rotated(sprite.rotation)

func rotate_around_rotation_offset(rot: float) -> void:
	var angle = rot - sprite.rotation
	var offset = rotation_offset_vector()
	var delta = offset - offset.rotated(angle)
	sprite.rotation = rot
	position += delta

