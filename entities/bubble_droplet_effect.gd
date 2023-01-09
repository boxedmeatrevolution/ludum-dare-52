extends Sprite

const LIFETIME := 0.18
var timer := 0.0
onready var initial_position := position
var angle := 0.0
var distance_1 := 70.0
var distance_2 := 120.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	timer += delta
	var lambda := timer / LIFETIME
	if lambda > 1.0:
		queue_free()
	else:
		var lambda_2 := 0.5 * (1 - cos(PI * lambda))
		position = initial_position + lerp(distance_1, distance_2, lambda_2) * Vector2.UP.rotated(angle)
		scale.x = lerp(0.3, 1.2, lambda_2)
		scale.y = lerp(0.3, 1.2, lambda_2)
		rotation = angle
		modulate.a = 1.0 - lambda
