extends Entity


var initial_velocity : Vector2


func _ready():
	super()
	collision_priority = 100000
	face_damage_component.excluded_entities.append(get_parent())


func _physics_process(delta):
	global_position = get_parent().global_position
