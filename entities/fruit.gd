extends Node2D


func _ready() -> void:
	$"/root/GameController".num_fruits_remaining += 1


func _process(_delta: float) -> void:
	pass

func harvest() -> void:
	$"/root/GameController".num_fruits_remaining -= 1
	queue_free()
