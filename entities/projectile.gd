extends Entity
class_name Projectile


@export var base_movement_speed : float


@onready var movement_speed : float = base_movement_speed * 30


func _ready():
	super()
	collision_layer = pow(2, 4-1)
	collision_mask = pow(2, 1 - 1) + pow(2, 2-1) + pow(2, 3-1)
	self.linear_damp = 5
	self.lock_rotation = true
	self.contact_monitor = true
	self.max_contacts_reported = 100
	self.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

