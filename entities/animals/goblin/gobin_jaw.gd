extends Projectile
class_name GoblinJaw


var direction : Vector2


func _physics_process(delta):
	apply_central_force(direction * movement_speed)
