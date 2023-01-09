extends PathFollow2D

export var period := 5.0
export var motion_loop := false
export var time_offset := 0.0

var timer := 0.0

func _ready():
	timer = time_offset
	pass

func _physics_process(delta: float) -> void:
	timer += delta
	if timer > period:
		timer -= period
	if motion_loop:
		unit_offset = timer / period
	else:
		if timer < 0.5 * period:
			unit_offset = 2.0 * timer / period
		else:
			unit_offset = 1.0 - 2.0 * (timer - 0.5 * period) / period
