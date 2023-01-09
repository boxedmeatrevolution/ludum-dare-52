extends Node2D

var time_left := 10.00
var time := 0.0
var player = null
onready var label := $Node2D/Label
var finished_bit := false
var started := false

func _ready():
	time = time_left

func _process(delta : float) -> void:
	if finished_bit:
		return
	if started:
		time -= delta
	if time < 0.0:
		label.text = "DE:AD"
		scale.x = 1.5
		scale.y = 1.5
		if is_instance_valid(player):
			player._on_HurtBox_area_entered(null)
		return
	var seconds := int(floor(time))
	var fraction := int(floor(100 * (time - seconds)))
	if fraction >= 100:
		fraction = 99
	if fraction < 0:
		fraction = 0
	var seconds_str := str(seconds)
	var fraction_str := str(fraction)
	var pulse := 1.0 / (1 + 100.0 * sin(PI * time) * sin(PI * time))
	var sc := 1.0 + clamp(lerp(1.5, 0.0, time / 5.0), 0.4, 1.5) * pulse
	scale.x = sc
	scale.y = sc
	if time < 1.0:
		label.add_color_override("font_color", Color.red)
	elif time < 2.0:
		label.add_color_override("font_color", Color.orangered)
	elif time < 3.0:
		label.add_color_override("font_color", Color.orange)
	elif time < 5.0:
		label.add_color_override("font_color", Color.yellow)
	label.text = seconds_str + ":" + fraction_str.pad_zeros(2)

func finished() -> void:
	label.add_color_override("font_color", Color.white)
	scale.x = 1.0
	scale.y = 1.0
	finished_bit = true
	
func start() -> void:
	started = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
