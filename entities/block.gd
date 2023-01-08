extends StaticBody2D

const ICE_TEXTURE := preload("res://sprites/ice.png")
const GRASS_TEXTURE := preload("res://sprites/grass.png")

export var invert := false
export var texture : Texture = null
export var texture_scale := 1.0
export var ice := false

onready var path := $Path2D
onready var mesh_interior := $PolygonInterior
onready var mesh_border := $MeshInstanceBorder

var polygon: PoolVector2Array
var polygon_inner: PoolVector2Array
var polygon_outer: PoolVector2Array
var segments: Array

func _ready() -> void:
	# Overwrite texture.
	if !texture:
		if ice:
			texture = ICE_TEXTURE
			texture_scale = 0.5
		else:
			texture = GRASS_TEXTURE
			texture_scale = 0.5
	
	position += path.position
	path.position = Vector2.ZERO
	
	# Close the curve by averaging first and last points.
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
	
	# Tesselate to make the collision polygon.
	polygon = curve.tessellate(5, 4)
	polygon.remove(polygon.size() - 1)
	
	# Remove any duplicate neighbouring points.
	var idx = 0
	while idx < polygon.size():
		var prev : Vector2 = polygon[idx]
		var next : Vector2 = polygon[(idx + 1) % polygon.size()]
		if prev == next:
			polygon.remove(idx)
		else:
			idx += 1
	
	# Check the orientation.
	var angle := 0.0
	var perimeter := 0.0
	for i in polygon.size():
		var prev : Vector2 = polygon[i]
		var current : Vector2 = polygon[(i + 1) % polygon.size()]
		var next : Vector2 = polygon[(i + 2) % polygon.size()]
		var tangent_1 := (current - prev).normalized()
		var tangent_2 := (next - current).normalized()
		perimeter += (next - current).length()
		angle += tangent_1.angle_to(tangent_2)
	var flip := false
	if angle > PI && angle < 3 * PI:
		flip = invert
	elif angle > -3 * PI && angle < -PI:
		flip = !invert
	else:
		print("Bad Bezier!")
	if flip:
		polygon.invert()
	
	# Make the padded polygons.
	for i in polygon.size():
		var prev := polygon[(i + polygon.size() - 1) % polygon.size()]
		var current := polygon[i]
		var next := polygon[(i + 1) % polygon.size()]
		var tangent_1 : Vector2 = (current - prev).normalized()
		var tangent_2 : Vector2 = (next - current).normalized()
		var normal_1 := Vector2(tangent_1.y, -tangent_1.x)
		var normal_2 := Vector2(tangent_2.y, -tangent_2.x)
		var offset := (normal_1 + normal_2) / (1.0 + normal_1.dot(normal_2))
		polygon_inner.append(current + 0.5 * texture_scale * texture.get_height() * offset)
		polygon_outer.append(current - 0.5 * texture_scale * texture.get_height() * offset)
	
	# Fill the interior mesh.
	mesh_interior.polygon = polygon
	mesh_interior.invert_enable = invert
	mesh_interior.color = Color.black
	
	# Fill the border mesh.
	var vertices := PoolVector2Array()
	var indices := PoolIntArray()
	var uvs := PoolVector2Array()
	uvs.resize(2 * (polygon.size() + 1))
	vertices.append_array(polygon_inner)
	vertices.push_back(polygon_inner[0])
	vertices.append_array(polygon_outer)
	vertices.push_back(polygon_outer[0])
	var uv_max := round(perimeter / (texture_scale * texture.get_width()))
	if uv_max <= 0.0:
		uv_max = 1.0
	var distance := 0.0
	for i in polygon.size() + 1:
		var uv_x := (distance / perimeter) * uv_max
		indices.append(i)
		indices.append(i + polygon.size() + 1)
		uvs[i] = Vector2(uv_x, 0.0)
		uvs[i + polygon.size() + 1] = Vector2(uv_x, 1.0)
		var prev : Vector2 = polygon[i % polygon.size()]
		var next : Vector2 = polygon[(i + 1) % polygon.size()]
		distance += (next - prev).length()
	var array_mesh_border := ArrayMesh.new()
	var arrays_border := []
	arrays_border.resize(ArrayMesh.ARRAY_MAX)
	arrays_border[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays_border[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays_border[ArrayMesh.ARRAY_INDEX] = indices
	array_mesh_border.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays_border)
	mesh_border.mesh = array_mesh_border
	mesh_border.texture = texture
	
	# Make the collision objects.
	for i in polygon.size():
		var prev := polygon[i]
		var next := polygon[(i + 1) % polygon.size()]
		var segment := SegmentShape2D.new()
		segment.a = prev
		segment.b = next
		var collision_shape := CollisionShape2D.new()
		collision_shape.set_shape(segment)
		add_child(collision_shape)
		segments.push_back(segment)

func _process(delta: float) -> void:
	pass
