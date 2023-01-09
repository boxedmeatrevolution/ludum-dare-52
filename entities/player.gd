extends Node2D

const Block := preload("res://entities/block.gd")
const BubbleEffectScene := preload("res://entities/bubble_effect.tscn")
const FruitDashEffectScene := preload("res://entities/fruit_dash_effect.tscn")
const LaunchEffectScene := preload("res://entities/launch_effect.tscn")

enum State {
	STAND,
	DASH,
	SLIDE,
}
const BLOCK_BIT := 1
const BLOCK_MASK :=  0b0000000000000010
const FRUIT_BIT := 2
const FRUIT_MASK :=  0b0000000000000100
const HAZARD_BIT := 3
const HAZARD_MASK := 0b0000000000001000
const DOOR_BIT := 4
const DOOR_MASK :=   0b0000000000010000

const FRUIT_DASH_TIME := 0.2
const DASH_STEER_STRENGTH := 0.3#0.6
const DASH_STEER_SENSITIVITY := 1.0 / 200.0
const DASH_SPEED := 350.0#600.0
const DASH_CHAIN_SPEED := 350.0#400.0
const DASH_ACCEL := 100.0
const SLIDE_SPEED_ICE := 300.0
const SLIDE_SMOOTH_CROSS := 0.9
const SLIDE_FRICTION := 8#800.0
const SLIDE_FRICTION_ICE := 5#800.0
const DASH_MIN_UPWARDNESS := -0.8
const ROTATION_OFFSET := 30.0
const HEAD_COLLISION_OFFSET := 30.0
const PERFECT_DASH_TIME := 0.3

onready var sprite := $Sprite
onready var animation_player := $AnimationPlayer
onready var dash_particles := $DashEffect/Particles2D
onready var dash_effect := $DashEffect
onready var dash_effect_sprite := $DashEffect/Sprite
onready var fruit_particles := $Sprite/FruitEffect/Particles2D
onready var skate_particles := $Sprite/SkateEffect/Particles2D

var state: int = State.STAND

var fruit_position := Vector2.ZERO
var stand_block : Block = null
var stand_segment_idx := 0
var stand_position := 0.0
var slide_velocity := 0.0
var dash_velocity := Vector2.ZERO
var dash_chain := 0
var perfect_dash_timer := 0.0
var fruit_dash_timer := 0.0

const DASH_INPUT_TIME := 0.1
var dash_input_timer := 0.0

func _ready() -> void:
	state = State.DASH
	dash_velocity = DASH_SPEED * Vector2.RIGHT
	$"/root/GameController".player = self

func _physics_process(delta: float) -> void:
	skate_particles.emitting = (state == State.SLIDE && abs(slide_velocity) == SLIDE_SPEED_ICE)
	if dash_input_timer > 0.0:
		dash_input_timer -= delta
	if Input.is_action_just_pressed("dash"):
		dash_input_timer = DASH_INPUT_TIME
	if state == State.STAND || state == State.SLIDE:
		if perfect_dash_timer > 0.0:
			perfect_dash_timer -= delta
		else:
			perfect_dash_timer = 0.0
			dash_chain = 0
	
	if fruit_dash_timer > 0.0:
		fruit_dash_timer -= delta
	if state == State.STAND:
		var normal := get_normal()
		var target_rotation := normal.angle() + 0.5 * PI
		var delta_rotation := angle_difference(target_rotation, sprite.rotation)
		sprite.rotation += delta_rotation * (1.0 - exp(-delta / 0.05))
		#sprite.rotation -= delta_rotation * delta / 0.1
		if input_dash_check():
			var target_direction = input_target_position()
			if target_direction.dot(normal) > DASH_MIN_UPWARDNESS:
				var launch_effect := LaunchEffectScene.instance()
				get_parent().add_child(launch_effect)
				launch_effect.rotation = get_rotation()
				launch_effect.position = position
				dash_particles.emitting = true
				dash_effect_sprite.visible = true
				animation_player.play("dash")
				dash_velocity = (DASH_SPEED + tanh(dash_chain / 4.0) * DASH_CHAIN_SPEED) * target_direction
				position += dash_velocity * delta + 1.0 * normal
				rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
				state = State.DASH
				dash_chain += 1
	elif state == State.SLIDE:
		var normal := get_normal()
		var target_rotation := normal.angle() + 0.5 * PI
		var delta_rotation := angle_difference(target_rotation, sprite.rotation)
		sprite.rotation += delta_rotation * (1.0 - exp(-delta / 0.05))
		#sprite.rotation -= delta_rotation * delta / 0.1
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
						stand_position += 1.0 * sign(slide_velocity)
						#slide_velocity *= get_tangent().dot(old_tangent)
						next_position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
						max_distance -= (next_position - position).length()
						position = next_position
					elif sign(slide_velocity) * tangent_cross < 0.0 || abs(slide_velocity) < SLIDE_SPEED_ICE:
						slide_velocity = 0.0
						max_distance = 0.0
					else:
						dash_particles.emitting = true
						dash_effect_sprite.visible = true
						animation_player.play("dash")
						dash_velocity = sign(slide_velocity) * DASH_SPEED * old_tangent
						position += dash_velocity * delta + 1.0 * old_normal
						rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
						state = State.DASH
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
						dash_particles.emitting = true
						dash_effect_sprite.visible = true
						animation_player.play("dash")
						dash_velocity = sign(slide_velocity) * DASH_SPEED * old_tangent
						position += dash_velocity * delta + 1.0 * old_normal
						rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
						state = State.DASH
				else:
					stand_position = next_stand_position
					position = next_position
					max_distance = 0.0
		if input_dash_check():
			var target_direction := input_target_position()
			if target_direction.dot(normal) > DASH_MIN_UPWARDNESS:
				var launch_effect := LaunchEffectScene.instance()
				get_parent().add_child(launch_effect)
				launch_effect.rotation = get_rotation()
				launch_effect.position = position
				dash_particles.emitting = true
				dash_effect_sprite.visible = true
				animation_player.play("dash")
				dash_velocity = (DASH_SPEED + tanh(dash_chain / 4.0) * DASH_CHAIN_SPEED) * target_direction
				position += dash_velocity * delta + 1.0 * normal
				rotate_around_rotation_offset(dash_velocity.angle() + 0.5 * PI)
				state = State.DASH
				dash_chain += 1
	elif state == State.DASH:
		dash_effect.modulate = lerp(Color.white, Color.red, tanh((dash_chain - 1) / 4.0))
		# Angle position based on relative mouse coordinate
		var target_delta := (get_global_mouse_position() - position - rotation_offset_vector())
		var steering := -DASH_STEER_STRENGTH * tanh(target_delta.cross(dash_velocity.normalized()) * DASH_STEER_SENSITIVITY)
		dash_velocity = dash_velocity.rotated(steering * delta)
		dash_velocity += DASH_ACCEL * dash_velocity.normalized() * delta
		sprite.rotation = get_rotation()
		dash_effect.rotation = sprite.rotation
		var space_state := get_world_2d().direct_space_state
		var delta_position := dash_velocity * delta
		var next_position := position + delta_position
		var raycast := space_state.intersect_ray(position + dash_velocity.normalized() * HEAD_COLLISION_OFFSET, next_position + dash_velocity.normalized() * HEAD_COLLISION_OFFSET, [], BLOCK_MASK)
		if raycast:
			dash_particles.emitting = false
			dash_effect_sprite.visible = false
			state = State.SLIDE
			perfect_dash_timer = PERFECT_DASH_TIME
			animation_player.play("slide")
			stand_block = raycast.collider
			stand_segment_idx = raycast.shape
			stand_position = convert_pos_global_to_seg(stand_block, stand_segment_idx, raycast.position)
			position = convert_pos_seg_to_global(stand_block, stand_segment_idx, stand_position)
			var slide_velocity_factor := get_tangent().dot(dash_velocity.normalized())
			if abs(slide_velocity_factor) > 0.25:
				slide_velocity_factor = sign(slide_velocity_factor) * 1.0
			slide_velocity = dash_velocity.length() * slide_velocity_factor
			var max_speed := SLIDE_SPEED_ICE
			if abs(slide_velocity) > max_speed:
				slide_velocity = sign(slide_velocity) * max_speed
			sprite.flip_h = (slide_velocity < 0.0)
			var bubble_effect := BubbleEffectScene.instance()
			bubble_effect.position = position
			bubble_effect.rotation = get_rotation()
			get_parent().add_child(bubble_effect)
		else:
			position = next_position
			if input_dash_check() && fruit_dash_timer > 0.0:
				fruit_dash_timer = 0.0
				var target_direction := input_target_position()
				dash_particles.emitting = true
				dash_effect_sprite.visible = true
				animation_player.play("dash")
				var offset := rotation_offset_vector()
				position = fruit_position - offset
				rotate_around_rotation_offset(target_direction.angle() + 0.5 * PI)
				dash_velocity = (DASH_SPEED + tanh(dash_chain / 4.0) * DASH_CHAIN_SPEED) * target_direction
				dash_chain += 1
				var launch_effect := LaunchEffectScene.instance()
				launch_effect.rotation = get_rotation()
				launch_effect.position = position
				get_parent().add_child(launch_effect)
				var fruit_dash_effect := FruitDashEffectScene.instance()
				fruit_dash_effect.position = position + rotation_offset_vector()
				fruit_dash_effect.rotation = get_rotation()
				get_parent().add_child(fruit_dash_effect)

func input_dash_check() -> bool:
	return dash_input_timer > 0.0

func input_target_position() -> Vector2:
	return (get_global_mouse_position() - position - rotation_offset_vector()).normalized()

func get_tangent() -> Vector2:
	if state == State.STAND || state == State.SLIDE:
		var segment : SegmentShape2D = stand_block.segments[stand_segment_idx]
		var tangent := (segment.b - segment.a).normalized()
		return tangent
	else:
		return Vector2(NAN, NAN)

func get_normal() -> Vector2:
	return get_tangent().rotated(-0.5 * PI)

func get_rotation() -> float:
	if state == State.STAND || state == State.SLIDE:
		return get_normal().angle() + 0.5 * PI
	elif state == State.DASH:
		return dash_velocity.angle() + 0.5 * PI
	return NAN

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
	return Vector2(0, -ROTATION_OFFSET).rotated(get_rotation())
	
func head_collision_offset_vector() -> Vector2:
	return Vector2(0, -HEAD_COLLISION_OFFSET).rotated(get_rotation())

func rotate_around_rotation_offset(rot: float) -> void:
	var angle = rot - get_rotation()
	var offset = rotation_offset_vector()
	var delta = offset - offset.rotated(angle)
	sprite.rotation = rot
	position += delta

func _on_HitBox_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_bit(FRUIT_BIT):
		var fruit = area.get_parent()
		fruit.harvest()
		fruit_dash_timer = FRUIT_DASH_TIME
		fruit_particles.restart()
		fruit_particles.emitting = true
		fruit_position = fruit.position
	elif area.get_collision_layer_bit(DOOR_BIT):
		$"/root/GameController".try_enter_door()

func angle_difference(angle_1: float, angle_2: float) -> float:
	if angle_1 > angle_2:
		return fmod(angle_1 - angle_2 + PI, 2 * PI) - PI
	else:
		return -(fmod(angle_2 - angle_1 + PI, 2 * PI) - PI)

func _on_HurtBox_area_entered(area: Area2D) -> void:
	queue_free()
	$"/root/GameController".trigger_player_death()
