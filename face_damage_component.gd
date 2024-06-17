extends Node
class_name FaceDamageComponent


signal damaged_entity(entity : Entity)
signal collision_detected(entity : Entity)
signal collision_ended(entity : Entity)
signal collision_ticked(entity : Entity)


@export var base_damage : float
@export var knockback_strength : float = 1000
@export var can_hit : bool = true
@export var face_shapes : Array[CollisionShape2D]
@export var damage_cooldown : float = 0.1


@onready var damage : float = base_damage
@onready var self_knockback_strength : float = knockback_strength
@onready var enemy_knockback_strength : float = knockback_strength


var colliding_entities : Array[Entity]
var colliding_entities_timers : Array[EntityTimerUnion]
# IMPORTANT: collision masks/layers DO NOT AFFECT detections from RigidBody2D.body_shape_entered/exited
# to make something not detectable by FaceDamageComponents, use this property (excluded_entities)
var excluded_entities : Array[Entity]


func _ready():
	get_parent().body_shape_entered.connect(process_starting_collision)
	get_parent().body_shape_exited.connect(process_collision_end)


func process_starting_collision(body_rid : RID, body : Node, body_shape_index : int, local_shape_index : int) -> void:
	if body is Entity:
		if (face_shapes.has(get_parent().shape_owner_get_owner(get_parent().shape_find_owner(local_shape_index)))
		and not excluded_entities.has(body)):
			#print("%s collided with %s" % [get_parent(), body])
			emit_signal("collision_detected", body)
			colliding_entities.append(body)
			if can_hit and body.health_component != null:
				var hit_timer : Timer = Timer.new()
				self.add_child(hit_timer)
				hit_timer.wait_time = damage_cooldown
				hit_timer.one_shot = true
				colliding_entities_timers.append(EntityTimerUnion.new(body, hit_timer))


func process_collision_end(body_rid : RID, body : Node, body_shape_index : int, local_shape_index : int) -> void:
	if body is Entity:
		if (face_shapes.has(get_parent().shape_owner_get_owner(get_parent().shape_find_owner(local_shape_index)))
		and not excluded_entities.has(body)):
			#print("%s stopped colliding with %s" % [get_parent(), body])
			emit_signal("collision_ended", body)
			for entity : Entity in colliding_entities:
				# the copy is needed because erasing while iterating on the array gives weird results
				var copy : Array[Entity]
				if entity != body:
					copy.append(entity)
				colliding_entities = copy
			for entity_timer_union : EntityTimerUnion in colliding_entities_timers:
				var copy : Array[EntityTimerUnion]
				if entity_timer_union.entity == body:
					entity_timer_union.hit_timer.queue_free()
				else:
					copy.append(entity_timer_union)
				colliding_entities_timers = copy


func damage_entity(entity_timer_union : EntityTimerUnion) -> void:
	entity_timer_union.entity.health_component.deal_damage(damage)
	entity_timer_union.entity.apply_central_impulse(Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * enemy_knockback_strength * -1)
	get_parent().apply_central_impulse(Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * self_knockback_strength)
	emit_signal("damaged_entity", entity_timer_union.entity)
	entity_timer_union.hit_timer.start()


func _physics_process(delta):
	for entity_timer_union in colliding_entities_timers:
		if entity_timer_union.hit_timer.is_stopped():
			emit_signal("collision_ticked", entity_timer_union.entity)
			damage_entity(entity_timer_union)


class EntityTimerUnion:
	var entity : Entity
	var hit_timer : Timer
	
	
	func _init(e : Entity, ht : Timer):
		entity = e
		hit_timer = ht
