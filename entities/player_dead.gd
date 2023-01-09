extends Node2D

var timer := 0.0
const TIME := 0.8

onready var sprite := $Sprite
onready var rect := $Polygon2D

onready var death_stream := $DeathStream

func _ready():
	$Particles2D.restart()
	self.remove_child(rect)
	get_parent().add_child(rect)

func _physics_process(delta: float) -> void:
	if timer == 0:
		death_stream.play()
	timer += delta
	if timer >= TIME:
		queue_free()
	sprite.rotation += 2.0 * PI * delta / 0.5
	sprite.scale.x = lerp(1.0, 2.0, timer / TIME)
	sprite.scale.y = lerp(1.0, 2.0, timer / TIME)
	sprite.modulate = lerp(Color.white, Color.red, timer / TIME)
	sprite.modulate.a = lerp(1.0, 0.5, timer / TIME)
	rect.modulate.a = lerp(1.0, 0.0, timer / 0.3)
