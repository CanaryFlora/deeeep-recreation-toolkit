extends Entity
class_name Animal
 

## The base movement speed of the entity.
@export var animal_name : StringName
@export var base_movement_speed : float
@export_category("Boosting")
@export var boosts : int
@export var charge_max_seconds : float
@export var charge_boost_bar_offset : Vector2
@export var two_step_charge_boost : bool
## When the boost bar will start being displayed yellow.
@export var yellow_boost_start : float


@onready var movement_speed : float = base_movement_speed
@onready var movement_force : float = movement_speed * 30


# this is meant to be used by a PlayerMovementComponent
var to_rotate : float
var player_controlled : bool

var can_rotate : bool = true
var can_move : bool = true


func _ready():
	super()
	collision_mask = pow(2, 1 - 1) + pow(2, 2-1) + pow(2, 3-1) + pow(2, 4-1)
	collision_layer = pow(2, 1 - 1) + pow(2, 6 - 1)
	self.linear_damp = 5
	if health_component != null:
		health_component.health_reached_0.connect(func(entity : Node2D):
			self.queue_free()
			#get_parent().entities.erase(self)
			)
		pass


func _integrate_forces(state):
	if player_controlled:
		rotation_degrees = to_rotate


func _physics_process(delta):
	movement_force = movement_speed * 30
