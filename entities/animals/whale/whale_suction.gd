extends Node2D
class_name WhaleSuction


@onready var area_2d = $Area2D


var overlapping_bodies : Array[Entity]


func _on_area_2d_body_entered(body):
	if body is Entity:
		if body.affected_by_suction and body != get_parent():
			overlapping_bodies.append(body)


func _physics_process(delta):
	for body : Entity in overlapping_bodies:
		var direction : Vector2 = body.global_position.direction_to(get_node("Marker2D").global_position)
		body.apply_central_force(direction * 4000)


func _on_area_2d_body_exited(body):
	if overlapping_bodies.has(body):
		overlapping_bodies.erase(body)
