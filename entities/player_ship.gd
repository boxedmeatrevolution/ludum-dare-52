extends Node2D

const LAUNCH_ACCEL = 10.0

var is_launch := false
var launch_vel := 0.0

onready var launch_stream := $LaunchStream

func _ready() -> void:
	$"/root/GameController".spaceship = self

func _process(delta: float) -> void:
	if is_launch:
		launch_vel += delta * LAUNCH_ACCEL
		position += Vector2(0.0, -1.0).rotated(rotation) * launch_vel

func launch() -> void:
	is_launch = true
	launch_stream.play()
