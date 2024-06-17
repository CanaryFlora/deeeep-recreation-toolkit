extends Animal


var burst_timer : Timer = Timer.new()


func _ready():
	super()
	burst_timer.wait_time = 1
	burst_timer.timeout.connect(burst_forward)
	self.add_child(burst_timer)
	burst_timer.start()


func burst_forward() -> void:
	apply_central_impulse(Vector2.from_angle(deg_to_rad(rotation_degrees + 90)) * -500)
