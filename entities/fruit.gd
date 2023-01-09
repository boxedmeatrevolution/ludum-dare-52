extends Node2D

onready var sprite := $Sprite
var time := 0.0

func _ready() -> void:
	$"/root/GameController".num_fruits_remaining += 1
	$Sprite.frame = $"/root/GameController".fruit_type


func _process(delta: float) -> void:
	time += delta
	sprite.position.y = 5.0 * sin(2 * PI * time / 1.5 + 2 * PI * position.x / 180.0)

func harvest() -> void:
	$"/root/GameController".num_fruits_remaining -= 1
	queue_free()
