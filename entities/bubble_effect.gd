extends Node2D

const BubbleDropletEffectScene := preload("res://entities/bubble_droplet_effect.tscn")

func _ready():
	$AnimationPlayer.play("main")
	var num_droplets := 8
	for i in num_droplets:
		var lambda := float(i) / (num_droplets - 1)
		var bubble_droplet := BubbleDropletEffectScene.instance()
		bubble_droplet.angle = lerp(-0.5 * PI, 0.5 * PI, lambda)
		bubble_droplet.position = Vector2.ZERO
		if i % 2 == 1:
			bubble_droplet.distance_2 -= 20
		bubble_droplet.distance_1 -= 20
		bubble_droplet.distance_2 -= 20
		add_child(bubble_droplet)

func animation_finished(name: String) -> void:
	queue_free()
