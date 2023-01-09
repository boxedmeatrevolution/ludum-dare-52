extends Sprite

const BubbleDropletEffectScene := preload("res://entities/bubble_droplet_effect.tscn")

func _ready():
	$AnimationPlayer.play("main")

func animation_finished(name: String) -> void:
	queue_free()
