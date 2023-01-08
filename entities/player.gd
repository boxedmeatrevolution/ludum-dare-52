extends Node2D

const Block := preload("res://entities/block.gd")

enum State {
	STAND,
	DASH,
	SLIDE,
}

const BLOCK_MASK := 0b0000000000000010

const DASH_SPEED := 600.0
const SLIDE_SPEED_ICE := 400.0
const SLIDE_SMOOTH_CROSS := 0.5
const SLIDE_FRICTION := 8#800.0
const SLIDE_FRICTION_ICE := 5#800.0
const DASH_MIN_UPWARDNESS := -0.8
const ROTATION_OFFSET := 30.0
const HEAD_COLLISION_OFFSET := 30.0

onready var sprite := $Sprite
onready var animation_player := $AnimationPlayer

var state: int = State.STAND

var stand_block : Block = null
var stand_segment_idx := 0
var stand_position := 0.0
var slide_velocity := 0.0
var dash_velocity := Vector2.ZERO

func _ready() -> void:
	state = State.DASH
	dash_velocity = DASH_SPEED * Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if state == State.STAND:
		var normal := get_normal()
		sprite.rotation = normal.angle() + 0.5 * PI
		if Input.is_action_just_released("dash"):
			var target_direction = (get_global_mouse_position() - position - rotation_offset_vector()).normalized()
			if target_direction.dot(normal) > DASH_MIN_UPWARDNESS:
				state = State.DASH
				animation_player.play("dash")
				dash_velocity = DASH_SPEED * target_direction
				position += dash_velocity * delta + 1.0 * normal
				rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
	elif state == State.SLIDE:
		var normal := get_normal()
		sprite.rotation = normal.angle() + 0.5 * PI
		var friction := SLIDE_FRICTION
		if stand_block.ice:
			if abs(slide_velocity) >= SLIDE_SPEED_ICE:
				friction = 0.0
			else:
				friction = SLIDE_FRICTION_ICE
		var delta_slide_velocity := -slide_velocity * friction * delta
		if abs(delta_slide_velocity) >= abs(slide_velocity):
			slide_velocity = 0.0
		else:
			slide_velocity += delta_slide_velocity
		if slide_velocity == 0.0:
			state = State.STAND
		else:
			var max_distance := abs(slide_velocity * delta)
			while max_distance > 0.0 && state == State.SLIDE:
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
					var old_normal := get_normal()
					var new_stand_block : Block = raycast.collider
					var new_stand_segment_idx : int = raycast.shape
					var new_stand_segment : SegmentShape2D = new_stand_block.segments[new_stand_segment_idx]
					var new_tangent := (new_stand_segment.b - new_stand_segment.a).normalized()
					var tangent_cross := old_tangent.cross(new_tangent)
					if abs(tangent_cross) < SLIDE_SMOOTH_CROSS:
						stand_block = new_stand_block
						stand_segment_idx = new_stand_segment_idx
						stand_position = convert_pos_global_to_seg(stand_block, stand_segment_idx, raycast.position)
						#slide_velocity *= get_tangent().dot(old_tangent)
						next_position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
						max_distance -= (next_position - position).length()
						position = next_position
					elif sign(slide_velocity) * tangent_cross < 0.0 || abs(slide_velocity) < SLIDE_SPEED_ICE:
						slide_velocity = 0.0
						max_distance = 0.0
					else:
						state = State.DASH
						animation_player.play("dash")
						dash_velocity = slide_velocity * old_tangent
						position += dash_velocity * delta + 1.0 * old_normal
						rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
				elif edge_distance < max_distance:
					var old_tangent := get_tangent()
					var old_normal := get_normal()
					var new_stand_segment_idx : int
					var new_stand_segment : SegmentShape2D
					var new_stand_position : float
					if slide_velocity > 0.0:
						new_stand_segment_idx = (stand_segment_idx + 1) % stand_block.segments.size()
						new_stand_segment = stand_block.segments[new_stand_segment_idx]
						new_stand_position = 0.0
					else:
						new_stand_segment_idx = (stand_segment_idx + stand_block.segments.size() - 1) % stand_block.segments.size()
						new_stand_segment = stand_block.segments[new_stand_segment_idx]
						var new_segment_length := (new_stand_segment.b - new_stand_segment.a).length()
						new_stand_position = new_segment_length
					var new_tangent := (new_stand_segment.b - new_stand_segment.a).normalized()
					var tangent_cross := old_tangent.cross(new_tangent)
					if abs(tangent_cross) < SLIDE_SMOOTH_CROSS:
						stand_segment_idx = new_stand_segment_idx
						stand_position = new_stand_position
						#slide_velocity *= get_tangent().dot(old_tangent)
						max_distance -= edge_distance
						position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
					elif sign(slide_velocity) * tangent_cross < 0.0 || abs(slide_velocity) < SLIDE_SPEED_ICE:
						if slide_velocity < 0.0:
							stand_position = 0.0
						else:
							stand_position = segment_length
						position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
						slide_velocity = 0.0
						max_distance = 0.0
					else:
						state = State.DASH
						animation_player.play("dash")
						dash_velocity = slide_velocity * old_tangent
						position += dash_velocity * delta + 1.0 * old_normal
						rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
				else:
					stand_position = next_stand_position
					position = next_position
					max_distance = 0.0
		if Input.is_action_just_released("dash"):
			var target_direction = (get_global_mouse_position() - position - rotation_offset_vector()).normalized()
			if target_direction.dot(normal) > DASH_MIN_UPWARDNESS:
				state = State.DASH
				animation_player.play("dash")
				dash_velocity = DASH_SPEED * target_direction
				position += dash_velocity * delta + 1.0 * normal
				rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
	elif state == State.DASH:
		#if dash_velocity.angle() + 0.5 * PI != sprite.rotation:
		#	rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
		var space_state := get_world_2d().direct_space_state
		var delta_position := dash_velocity * delta
		var next_position := position + delta_position
		var raycast := space_state.intersect_ray(position, next_position + dash_velocity.normalized() * HEAD_COLLISION_OFFSET, [], BLOCK_MASK)
		if raycast:
			state = State.SLIDE
			animation_player.play("slide")
			stand_block = raycast.collider
			stand_segment_idx = raycast.shape
			stand_position = convert_pos_global_to_seg(stand_block, stand_segment_idx, raycast.position)
			position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
			sprite.rotation = get_normal().angle() + 0.5 * PI
			var slide_velocity_factor := get_tangent().dot(dash_velocity.normalized())
			slide_velocity = dash_velocity.length() * slide_velocity_factor
			var max_speed := SLIDE_SPEED_ICE
			if abs(slide_velocity) > max_speed:
				slide_velocity = sign(slide_velocity) * max_speed
			sprite.flip_h = (slide_velocity < 0.0)
		else:
			position = next_position
			
	handle_fruit_collisions()
	handle_hazard_collisions()

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
	return Vector2(0, -ROTATION_OFFSET).rotated(sprite.rotation)
	
func HEAD_COLLISION_OFFSET_vector() -> Vector2:
	return Vector2(0, -HEAD_COLLISION_OFFSET).rotated(sprite.rotation)

func rotate_around_rotation_offset(rot: float) -> void:
	var angle = rot - sprite.rotation
	var offset = rotation_offset_vector()
	var delta = offset - offset.rotated(angle)
	sprite.rotation = rot
	position += delta

func handle_fruit_collisions() -> void:
	var space_state := get_world_2d().direct_space_state
	var mask := 0b0000000000000100 #Fruit
	var collisions := space_state.intersect_point(position + HEAD_COLLISION_OFFSET_vector(), 32, [], mask, false, true)
	for collision in collisions:
		var fruit = collision.collider.get_parent()
		fruit.harvest()

func handle_hazard_collisions() -> void:
	var space_state := get_world_2d().direct_space_state
	var mask := 0b0000000000001000 #hazard
	var collisions := space_state.intersect_point(position + HEAD_COLLISION_OFFSET_vector(), 32, [], mask, false, true)
	for collision in collisions:
		print("Oh I have been slain!")
		var hazard = collision.collider.get_parent()
