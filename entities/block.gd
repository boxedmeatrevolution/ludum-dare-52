extends StaticBody2D

export var invert := false

onready var path := $Path2D

var polygon: PoolVector2Array
var segments: Array
var dir := 1

func _ready() -> void:
	var curve : Curve2D = path.curve
	var count := curve.get_point_count()
	var first := curve.get_point_position(0)
	var last := curve.get_point_position(count - 1)
	var first_out := curve.get_point_out(0)
	var last_in := curve.get_point_in(count - 1)
	var point := (first + last) / 2
	var curve_param := (first_out - last_in) / 2
	curve.set_point_position(0, point)
	curve.set_point_position(count - 1, point)
	curve.set_point_out(0, curve_param)
	curve.set_point_in(count - 1, -curve_param)
	polygon = curve.tessellate(5, 4)
	
	var angle := 0.0
	for i in polygon.size():
		var prev := polygon[i]
		var current := polygon[(i + 1) % polygon.size()]
		var next := polygon[(i + 2) % polygon.size()]
		var tangent_1 : Vector2 = (current - prev).normalized()
		var tangent_2 : Vector2 = (next - current).normalized()
		angle += tangent_1.angle_to(tangent_2)
	if angle > PI && angle < 3 * PI:
		dir = 1
	elif angle > -3 * PI && angle < -PI:
		dir = -1
	else:
		print("Bad Bezier!")
	if invert:
		dir = -dir
	
	for i in polygon.size() - 1:
		var prev := polygon[i]
		var next := polygon[i + 1]
		var segment := SegmentShape2D.new()
		segment.a = prev
		segment.b = next
		var collision_shape := CollisionShape2D.new()
		collision_shape.set_shape(segment)
		add_child(collision_shape)
		segments.push_back(segment)
	
	var shape := Polygon2D.new()
	shape.polygon = polygon
	shape.color = Color.aquamarine
	shape.invert_enable = invert
	add_child(shape)

func _process(delta: float) -> void:
	pass
