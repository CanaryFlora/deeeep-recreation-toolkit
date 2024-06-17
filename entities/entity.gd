extends RigidBody2D
class_name Entity


@export var affected_by_suction : bool = true
@export var whale_swallow_effect : WhaleSwallowEffect


var health_component : HealthComponent
var face_damage_component : FaceDamageComponent
var effect_component : EffectComponent


func _ready():
	#get_parent().entities.append(self)
	self.lock_rotation = true
	self.contact_monitor = true
	self.max_contacts_reported = 100
	self.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	find_components()


func find_components():
	var children : Array = self.get_children()
	for child in children:
		if child is HealthComponent:
			health_component = child
		elif child is FaceDamageComponent:
			face_damage_component = child
		elif child is EffectComponent:
			effect_component = child
