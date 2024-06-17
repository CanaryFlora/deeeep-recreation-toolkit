extends Node
class_name AnimalControlComponent


signal click_boosted(animal_control_component : AnimalControlComponent)
signal charge_boosted(animal_control_component : AnimalControlComponent)


const CHARGE_BOOST_BAR_SCENE : PackedScene = preload("res://components/player_control_component/charge_boost_bar/charge_boost_bar.tscn")
const CHARGE_BOOST_BAR_THEME : Theme = preload("res://components/player_control_component/charge_boost_bar/charge_boost_bar_theme.tres")
const CHARGE_BOOST_FULL_THEME : Theme = preload("res://components/player_control_component/charge_boost_bar/charge_boost_full_theme.tres")
const CHARGE_BOOST_YELLOW_THEME : Theme  = preload("res://components/player_control_component/charge_boost_bar/charge_boost_yellow_theme.tres")
const CHARGE_BOOST_RED_THEME : Theme  = preload("res://components/player_control_component/charge_boost_bar/charge_boost_red_theme.tres")

const BOOST_BAR_BOX = preload("res://components/player_control_component/boost_bar/boost_bar_box.tscn")
const BOOST_BAR_MIDDLE = preload("res://components/player_control_component/boost_bar/boost_bar_middle.tscn")
const BOOST_BAR_EDGE_FULL_LEFT_THEME = preload("res://components/player_control_component/boost_bar/boost_bar_edge_full_left.tres")
const BOOST_BAR_EDGE_FULL_RIGHT_THEME = preload("res://components/player_control_component/boost_bar/boost_bar_edge_full_right.tres")
const BOOST_BAR_EDGE_RIGHT_THEME = preload("res://components/player_control_component/boost_bar/boost_bar_edge_right.tres")
const BOOST_BAR_EDGE_LEFT_THEME = preload("res://components/player_control_component/boost_bar/boost_bar_edge_left.tres")
const BOOST_BAR_MIDDLE_THEME = preload("res://components/player_control_component/boost_bar/boost_bar_middle.tres")
const BOOST_BAR_MIDDLE_FULL_THEME = preload("res://components/player_control_component/boost_bar/boost_bar_middle_full.tres")


var camera : Camera2D = Camera2D.new()
var hold_timer : Timer = Timer.new()

## An array of tweens that are being used for precise rotation.
var rotation_tween_array : Array[Tween]
var delay_modifier : int = 0
var min_turn_time : float = 0

var can_click_boost : bool = true
var can_charge_boost : bool = true
var boost_fully_charged : bool
var current_ability : Ability
var ability_timer : SceneTreeTimer
var ability_objects : Array[Object]

var charge_boost_colorrect : ColorRect = CHARGE_BOOST_BAR_SCENE.instantiate()
var charge_boost_bar : ProgressBar = charge_boost_colorrect.get_child(0)

var boost_bar_box : HBoxContainer = BOOST_BAR_BOX.instantiate()
var boost_bar_edge_left : ProgressBar = boost_bar_box.get_node("BoostBarEdgeLeft")
var boost_bar_edge_right : ProgressBar = boost_bar_box.get_node("BoostBarEdgeRight")
var middle_boost_bars : Array[ProgressBar]
var boost_points : float = 99
var dash_boost_cooldown_timer : Timer = Timer.new()



enum Ability {
	NO_ABILITY,
	GWS_CHARGE,
	TORPEDO_SELF_SHOCK,
	TORPEDO_BOOST_SHOCK,
	MORAY_BLEED_DASH,
	GOBLIN_DASH_JAW,
	LEATHERBACK_SHIELD,
	FIN_WHALE_SUCTION,
	MARLIN_BLEED_DASH,
}


func _ready():
	dash_boost_cooldown_timer.wait_time = 0.5
	dash_boost_cooldown_timer.one_shot = true
	self.add_child(dash_boost_cooldown_timer)
	Global.current_animal_control_component = self
	hold_timer.wait_time = get_parent().charge_max_seconds
	self.add_child(hold_timer)
	
	get_parent().player_controlled = true
	get_parent().add_child.call_deferred(camera)
	camera.zoom = Vector2(0.7, 0.7)
	
	if get_parent().charge_max_seconds > 0:
		get_parent().add_child.call_deferred(charge_boost_colorrect)
	
	if get_parent().boosts > 0:
		Global.ui_canvaslayer.add_child(boost_bar_box)
		for boosts in range(get_parent().boosts - 2):
			var middle_boost_bar : ProgressBar = BOOST_BAR_MIDDLE.instantiate()
			middle_boost_bars.append(middle_boost_bar)
			boost_bar_edge_left.add_sibling(middle_boost_bar)
	
	# children get readied before parents
	get_parent().ready.connect(setup_animal)


func _physics_process(delta):
	if get_parent().global_position.distance_to(get_parent().get_global_mouse_position()) > 150:
		if get_parent().can_move:
			basic_movement()
	if get_parent().can_rotate:
		mouse_rotation()
	if Global.current_player_animal.animal_name == "Goblin Shark":
		if boost_fully_charged:
			if not get_parent().gob_overcharging and not get_parent().gob_overcharge_maxed and not get_parent().gob_pre_overcharging:
				get_parent().gob_pre_overcharging = true
				get_parent().gob_pre_slowdown_timer = get_tree().create_timer(0.5)
				get_parent().gob_pre_slowdown_timer.timeout.connect(func():
					get_parent().gob_pre_overcharging = false
					if boost_fully_charged:
						get_parent().gob_overcharging = true
						get_parent().gob_slowdown_tween = get_tree().create_tween()
						get_parent().gob_slowdown_tween.tween_property(get_parent(), "movement_speed", get_parent().movement_speed - 50, 2.5)
						get_parent().gob_slowdown_tween.finished.connect(func():
							get_parent().gob_slowdown_tween = null)
							
						get_parent().gob_slowdown_timer = get_tree().create_timer(2.5)
						get_parent().gob_slowdown_timer.timeout.connect(reset_overcharge)
							
						get_parent().gob_pre_slowdown_timer = null
					)
			if get_parent().gob_slowdown_timer != null:
				get_parent().gob_overcharge_duration = snappedf(2.5 - get_parent().gob_slowdown_timer.time_left, 0.1)


func _process(delta):
	# boosts
	if get_parent().boosts > 0:
		if boost_points > get_parent().boosts * 7.5:
			boost_points = get_parent().boosts * 7.5
		# if player has less than 1 boost
		if boost_points <= 7.5:
			boost_bar_edge_left.value = boost_points
			boost_bar_edge_left.theme = BOOST_BAR_EDGE_LEFT_THEME
			for bar in middle_boost_bars:
				bar.theme = BOOST_BAR_MIDDLE_THEME
				bar.value = 0
			boost_bar_edge_right.theme = BOOST_BAR_EDGE_RIGHT_THEME
			boost_bar_edge_right.value = 0
		# if player has more than 1 boost
		elif boost_points > 7.5:
			boost_bar_edge_right.theme = BOOST_BAR_EDGE_RIGHT_THEME
			boost_bar_edge_right.value = 0
			boost_bar_edge_left.theme = BOOST_BAR_EDGE_FULL_LEFT_THEME
			boost_bar_edge_left.value = 7.5
			if get_parent().boosts == 2:
				if boost_points < 15:
					boost_bar_edge_right.value = boost_points
					boost_bar_edge_right.theme = BOOST_BAR_EDGE_RIGHT_THEME
				elif boost_points == 15:
					boost_bar_edge_right.theme = BOOST_BAR_EDGE_FULL_RIGHT_THEME
			# if player's boost cap is above 2
			else:
				# if player has more than 1 boost until max
				if boost_points < (get_parent().boosts - 1) * 7.5:
					var current_bar_index : int = ceil(boost_points / 7.5)
					var current_bar : ProgressBar = middle_boost_bars[middle_boost_bars.size() - 1 - (current_bar_index - 2)] # 2 - 1 - (2 - 2) = 1 cor
					for bar in middle_boost_bars:
						if (middle_boost_bars.size() - middle_boost_bars.find(bar)) + 2 > current_bar_index: # 
							bar.theme = BOOST_BAR_MIDDLE_THEME
							if bar != current_bar:
								bar.value = 0
						else:
							bar.theme = BOOST_BAR_MIDDLE_FULL_THEME
					current_bar.value = boost_points - ((current_bar_index - 1) * 7.5)
				# if player has less than 1 boost until max
				else:
					for bar in middle_boost_bars:
						bar.theme = BOOST_BAR_MIDDLE_FULL_THEME
						bar.value = 7.5
					boost_bar_edge_right.value = boost_points - (get_parent().boosts - 1) * 7.5
					if boost_points == get_parent().boosts * 7.5:
						boost_bar_edge_right.theme = BOOST_BAR_EDGE_FULL_RIGHT_THEME
					else:
						boost_bar_edge_right.theme = BOOST_BAR_EDGE_RIGHT_THEME

	if get_parent().charge_max_seconds > 0 and can_charge_boost:
		charge_boost_colorrect.visible = true
		charge_boost_colorrect.rotation_degrees = -1 * get_parent().rotation_degrees
		charge_boost_colorrect.global_position = Vector2(get_parent().global_position.x + 150, get_parent().global_position.y - 30) + get_parent().charge_boost_bar_offset
		if not hold_timer.is_stopped():
			charge_boost_colorrect.visible = true
			charge_boost_bar.max_value = hold_timer.wait_time
			if not boost_fully_charged:
				if get_parent().two_step_charge_boost and hold_timer.wait_time - hold_timer.time_left > get_parent().yellow_boost_start:
					charge_boost_bar.theme = CHARGE_BOOST_YELLOW_THEME
				else:
					charge_boost_bar.theme = CHARGE_BOOST_BAR_THEME
				charge_boost_bar.value = (hold_timer.wait_time - hold_timer.time_left)
			else:
				charge_boost_bar.value = charge_boost_bar.max_value
				if get_parent().two_step_charge_boost:
					charge_boost_bar.theme = CHARGE_BOOST_RED_THEME
				else:
					charge_boost_bar.theme = CHARGE_BOOST_FULL_THEME
		else:
			charge_boost_colorrect.visible = false
	else:
		charge_boost_colorrect.visible = false


## Moves the entity in the direction it's facing. Must be called every frame for smooth movement.
func basic_movement():
	#print("velocity: ", get_parent().linear_velocity, " current movement speed: ", get_parent().linear_velocity / 4, " damp ", snapped(get_parent().linear_damp, 0.01))
	get_parent().apply_central_force(Vector2(movement_vector()) * get_parent().movement_force)


## Rotates the entity to the cursor.
func mouse_rotation():
	var rotation_tween : Tween = get_tree().create_tween()
	var final_angle_to_cursor : float = rad_to_deg(get_parent().get_angle_to(get_parent().get_global_mouse_position())) + 90
	var delay : float 
	if delay_modifier == 0:
		delay = 0
	else:
		delay = abs(final_angle_to_cursor / delay_modifier)
	var final_delay : float = delay
	if delay < min_turn_time:
		final_delay = min_turn_time
	elif delay >= min_turn_time:
		final_delay = delay
	rotation_tween_array.append(rotation_tween)
	# we have to use this hacky approach instead of modfying the rotation directlly because
	# if we modify rotation directly it will freeze the rigidbody
	rotation_tween.tween_property(get_parent(), "to_rotate", final_angle_to_cursor, final_delay).as_relative()
	await get_tree().create_timer(delay + 0.5).timeout
	rotation_tween_array.erase(rotation_tween)
	rotation_tween.kill()


func movement_vector() -> Vector2:
	return Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * -1
	


func stop_mouse_rotation():
	for rotation_tween in rotation_tween_array:
		rotation_tween.kill()


func dash_boost() -> void:
	get_parent().apply_central_impulse(movement_vector() * 4000)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				hold_timer.start()
				hold_timer.timeout.connect(
					func():
					boost_fully_charged = true
				)
				# the timer has to be paused to store the wait time
			elif not event.pressed:
				if !hold_timer.is_stopped():
					if boost_fully_charged:
						hold_timer.stop()
						boost_fully_charged = false
						animal_charge_boost(true)
					else:
						hold_timer.paused = true
						var hold_time : float = hold_timer.wait_time - hold_timer.time_left
						hold_timer.stop()
						hold_timer.paused = false
						#print("hold time: %s" % hold_time)
						if get_parent().two_step_charge_boost:
							if hold_time > get_parent().yellow_boost_start and hold_time < get_parent().charge_max_seconds and can_charge_boost:
								animal_charge_boost(false, hold_time)
							else:
								animal_click_boost()
						else:
							animal_click_boost()
		if event.is_action_pressed("scroll_up") and camera.zoom < Vector2(2, 2):
			if camera.zoom < Vector2(2, 2) or Global.remove_zoom_limits:
				camera.zoom += Vector2(0.1, 0.1)
		elif event.is_action_pressed("scroll_down"):
			if camera.zoom > Vector2(0.3, 0.3) or Global.remove_zoom_limits:
				camera.zoom -= Vector2(0.1, 0.1)


func reset_overcharge() -> void:
	get_parent().gob_overcharge_maxed = true
	get_parent().gob_slowdown_timer = null
	get_parent().gob_overcharging = false


func setup_animal() -> void:
	Global.current_player_animal = get_parent()
	match Global.current_player_animal.animal_name:
		"Great Whtie Shark":
			get_parent().face_damage_component.damaged_entity.connect(func(entity : Entity):
				if current_ability == Ability.GWS_CHARGE:
					ability_timer.emit_signal("timeout"))


func animal_click_boost() -> void:
	if can_click_boost:
		match Global.current_player_animal.animal_name:
			"Great White Shark":
				if current_ability == Ability.GWS_CHARGE:
					ability_timer.emit_signal("timeout")
					ability_timer = null
					
			"Goblin Shark":
				if current_ability == Ability.NO_ABILITY and boost_points >= 7.5:
					boost_points -= 7.5
					const GOBLIN_DASH_JAW = preload("res://entities/animals/goblin/goblin_dash_jaw.tscn")
					var dash_jaw : Node2D = GOBLIN_DASH_JAW.instantiate()
					get_parent().goblin_dash_jaw = dash_jaw
					dash_jaw.position = Vector2(0, -230)
					
					var dash_jaw_lambda : Callable = func(body : Node2D):
						if current_ability == Ability.GOBLIN_DASH_JAW:
							if body is Entity and body != get_parent():
								if body.effect_component != null:
									body.effect_component.apply_effect("Speed Change", 2, -30)
								if body.health_component != null:
									body.health_component.deal_damage(150)
									ability_timer.emit_signal("timeout")
									ability_timer = null

					
					dash_jaw.get_node("Area2D").body_entered.connect(dash_jaw_lambda, CONNECT_ONE_SHOT)
					get_parent().add_child(dash_jaw)
					ability_objects.append(dash_jaw)
					get_parent().effect_component.apply_effect("Speed Change", 3, 50)
					current_ability = Ability.GOBLIN_DASH_JAW
					
					ability_timer = get_tree().create_timer(3)
					ability_timer.timeout.connect(func():
						var new_array : Array[Object]
						for object in ability_objects:
							if object is GoblinDashJaw:
								object.queue_free()
							else:
								new_array.append(object)
						ability_objects = new_array
						get_parent().effect_component.shorten_effect("Speed Change")
						current_ability = Ability.NO_ABILITY, CONNECT_ONE_SHOT)
			"Fin Whale":
				if current_ability == Ability.FIN_WHALE_SUCTION:
					ability_timer.emit_signal("timeout")
			"Marlin":
				if boost_points >= 7.5 and dash_boost_cooldown_timer.is_stopped():
					boost_points -= 7.5
					dash_boost_cooldown_timer.start()
					var marlin_bleed_boost : Callable = func(entity : Node2D):
							if entity is Animal:
								entity.effect_component.apply_effect("Bleeding", 2)
					get_parent().face_damage_component.damaged_entity.connect(marlin_bleed_boost)
					dash_boost()
					get_parent().effect_component.apply_effect("Speed Change", 3, 30)
					current_ability = Ability.MARLIN_BLEED_DASH
					
					ability_timer = get_tree().create_timer(1)
					ability_timer.timeout.connect(
						func():
							get_parent().face_damage_component.damaged_entity.disconnect(marlin_bleed_boost)
							current_ability = Ability.NO_ABILITY
					, CONNECT_ONE_SHOT)
			_:
				if dash_boost_cooldown_timer.is_stopped():
					dash_boost_cooldown_timer.start()
					dash_boost()


func animal_charge_boost(fully_charged : bool, hold_time : float = INF) -> void:
	match Global.current_player_animal.animal_name:
		"Great White Shark":
			if current_ability == Ability.NO_ABILITY and fully_charged and boost_points >= 7.5:
				get_parent().collision_layer = pow(2, 1 - 1)
				current_ability = Ability.GWS_CHARGE
				boost_points -= 7.5
				get_parent().effect_component.apply_effect("Speed Change", 4, 200)
				delay_modifier = 20
				get_parent().face_damage_component.damage += 90
				
				ability_timer = get_tree().create_timer(4)
				var gws_lambda : Callable = func():
					get_parent().collision_layer = pow(2, 1 - 1) + pow(2, 6 - 1)
					current_ability = Ability.NO_ABILITY
					delay_modifier = 0
					get_parent().effect_component.shorten_effect("Speed Change")
					get_parent().face_damage_component.damage -= 90 
					stop_mouse_rotation()
				ability_timer.timeout.connect(gws_lambda, CONNECT_ONE_SHOT)
				get_parent().face_damage_component.damaged_entity.connect(func(entity : Entity):
					if current_ability == Ability.GWS_CHARGE:
						ability_timer.emit_signal("timeout"))
				
		"Atlantic Torpedo":
			if current_ability == Ability.NO_ABILITY and boost_points >= 7.5:
				boost_points -= 7.5
				const ELECTRIFIED = preload("res://entities/effects/electrified/electrified.tres")
				const ELECTRIFIED_SPREAD = preload("res://entities/effects/electrified/electrified_spread.tres")
				if hold_time > 0.5 and hold_time < get_parent().charge_max_seconds:
					current_ability = Ability.TORPEDO_SELF_SHOCK
					get_parent().face_damage_component.can_hit = false
					get_parent().effect_component.effect_blacklist.append(ELECTRIFIED)
					get_parent().effect_component.effect_blacklist.append(ELECTRIFIED_SPREAD)
					get_parent().get_node("ShockAnimation").visible = true
					
					var torp_small_shock_start : Callable = func(body : Node):
						if body is Entity:
							body.apply_central_impulse(Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * 2000 * -1)
							if body.effect_component != null:
								body.effect_component.apply_effect("Electrified", 1)
					get_parent().body_entered.connect(torp_small_shock_start)
					
					ability_timer = get_tree().create_timer(1)
					var torp_small_shock_stop : Callable = func():
						current_ability = Ability.NO_ABILITY
						get_parent().body_entered.disconnect(torp_small_shock_start)
						get_parent().face_damage_component.can_hit = true
						get_parent().effect_component.effect_blacklist.erase(ELECTRIFIED)
						get_parent().effect_component.effect_blacklist.erase(ELECTRIFIED_SPREAD)
						get_parent().get_node("ShockAnimation").visible = false
						
					ability_timer.timeout.connect(torp_small_shock_stop, CONNECT_ONE_SHOT)
				
				elif fully_charged:
					current_ability = Ability.TORPEDO_BOOST_SHOCK
					get_parent().face_damage_component.can_hit = false
					get_parent().effect_component.effect_blacklist.append(ELECTRIFIED)
					get_parent().effect_component.effect_blacklist.append(ELECTRIFIED_SPREAD)
					get_parent().get_node("ShockAnimation").visible = true
					#get_tree().create_timer(0.9).timeout.connect(func():
						#get_parent().get_node("ShockAnimation").visible = false
						#)
					
					var torp_small_shock_start : Callable = func(body : Node):
						if body is Entity:
							get_parent().apply_central_impulse(Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * 500)
							body.apply_central_impulse(Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * 2000 * -1)
							if body.effect_component != null:
								body.effect_component.apply_effect("Electrified", 1)
					get_parent().body_entered.connect(torp_small_shock_start)
					
					ability_timer = get_tree().create_timer(1)
					var torp_small_shock_stop : Callable = func():
						current_ability = Ability.NO_ABILITY
						get_parent().body_entered.disconnect(torp_small_shock_start)
						get_parent().face_damage_component.can_hit = true
						get_parent().effect_component.effect_blacklist.erase(ELECTRIFIED)
						get_parent().effect_component.effect_blacklist.erase(ELECTRIFIED_SPREAD)
						get_parent().get_node("ShockAnimation").visible = false
					ability_timer.timeout.connect(torp_small_shock_stop, CONNECT_ONE_SHOT)
					dash_boost()
					
		"Moray Eel":
			if boost_points >= 7.5:
				boost_points -= 7.5
				var moray_bleed_boost : Callable = func(entity : Node2D):
						if entity is Animal:
							entity.effect_component.apply_effect("Bleeding", 2)
				get_parent().face_damage_component.damaged_entity.connect(moray_bleed_boost)
				get_parent().get_node("Hook").show()
				dash_boost()
				current_ability = Ability.MORAY_BLEED_DASH
				
				ability_timer = get_tree().create_timer(1)
				ability_timer.timeout.connect(
					func():
						get_parent().face_damage_component.damaged_entity.disconnect(moray_bleed_boost)
						get_parent().get_node("Hook").hide()
						current_ability = Ability.NO_ABILITY
				, CONNECT_ONE_SHOT)
			
		"Goblin Shark":
			if boost_points >= 7.5:
				boost_points -= 7.5
				var new_array : Array[Object]
				for object in ability_objects:
					if object is GoblinDashJaw:
						object.queue_free()
					else:
						new_array.append(object)
				ability_objects = new_array
				const GOBLIN_JAW = preload("res://entities/animals/goblin/goblin_jaw.tscn")
				var jaw : Projectile = GOBLIN_JAW.instantiate()
				jaw.global_position = get_parent().global_position + Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * -180
				jaw.rotation_degrees = get_parent().rotation_degrees
				jaw.direction = Vector2.from_angle(deg_to_rad(get_parent().rotation_degrees + 90)) * -1
				get_parent().get_parent().add_child(jaw)
				ability_objects.append(jaw)
					
				var overcharge_duration_copy : float = get_parent().gob_overcharge_duration
				var jaw_hit : Callable = func(body : Node2D):
					if body is Animal and not body == get_parent():
						if overcharge_duration_copy == 0:
							body.health_component.deal_damage(160)
						else:
							body.health_component.deal_damage(160 + 20 * overcharge_duration_copy)
						body.effect_component.apply_effect("Speed Change", 2, -30)
						ability_objects.erase(jaw)
						jaw.queue_free()
					elif body is GameTerrain:
						jaw.queue_free()
						ability_objects.erase(jaw)
				jaw.body_entered.connect(jaw_hit)
				
				if get_parent().gob_overcharging:
					get_parent().gob_slowdown_timer.timeout.disconnect(reset_overcharge)
					get_parent().gob_slowdown_tween.kill()
					get_parent().movement_speed = get_parent().base_movement_speed
					get_parent().gob_overcharge_duration = 0
					get_parent().gob_overcharging = false
					get_parent().gob_slowdown_timer = null
				elif get_parent().gob_overcharge_maxed:
					get_parent().movement_speed = get_parent().base_movement_speed
					get_parent().gob_overcharge_duration = 0
					get_parent().gob_overcharge_maxed = false
			
		"Leatherback Turtle":
			if current_ability == Ability.NO_ABILITY and boost_points >= 7.5:
				boost_points -= 7.5
				get_parent().collision_layer = pow(2, 1 - 1)
				current_ability = Ability.LEATHERBACK_SHIELD
				const LEATHERBACK_SHIELD = preload("res://entities/animals/leatherback/leatherback_shield.tscn")
				var shield : Entity = LEATHERBACK_SHIELD.instantiate()
				get_parent().add_collision_exception_with(shield)
				get_parent().add_child(shield)
				get_parent().face_damage_component.excluded_entities.append(shield)
				
				ability_timer = get_tree().create_timer(2)
				ability_timer.timeout.connect(func():
					get_parent().collision_layer = pow(2, 1 - 1) + pow(2, 6 - 1)
					shield.queue_free()
					get_parent().remove_collision_exception_with(shield)
					get_parent().face_damage_component.excluded_entities.erase(shield)
					current_ability = Ability.NO_ABILITY
					, CONNECT_ONE_SHOT)
				
				shield.face_damage_component.collision_ticked.connect(func(entity : Entity):
					for body in entity.get_colliding_bodies():
						if body is GameTerrain:
							var direction : Vector2 = entity.global_position.direction_to(get_parent().global_position)
							entity.apply_central_impulse(get_parent().linear_velocity.normalized() * 1000)
							get_parent().apply_central_impulse(direction * 2000)
							return
					entity.apply_central_impulse(get_parent().linear_velocity.normalized() * 2000)
					)
		"Fin Whale":
			if current_ability == Ability.NO_ABILITY and boost_points >= 7.5:
				boost_points -= 7.5
				current_ability = Ability.FIN_WHALE_SUCTION
				const WHALE_SUCTION = preload("res://entities/animals/whale/whale_suction.tscn")
				var suction : Node2D = WHALE_SUCTION.instantiate()
				suction.position = Vector2(0, -450)
				var old_kb : int = get_parent().face_damage_component.knockback_strength
				get_parent().face_damage_component.enemy_knockback_strength = 3000
				get_parent().face_damage_component.self_knockback_strength = 0
				get_parent().freeze = true
				get_parent().suction = suction
				## HACK
				get_parent().get_node("SuctionMarker").add_sibling(suction)
				
				ability_timer = get_tree().create_timer(5)
				ability_timer.timeout.connect(func():
					get_parent().suction = null
					get_parent().freeze = false
					get_parent().face_damage_component.enemy_knockback_strength = old_kb
					get_parent().face_damage_component.self_knockback_strength = old_kb
					current_ability = Ability.NO_ABILITY
					suction.queue_free()
					get_parent().face_damage_component.knockback_strength = old_kb
					,CONNECT_ONE_SHOT)
		_:
			pass


func ability_process() -> void:
	match current_ability:
		Ability.GWS_CHARGE:
			pass
		_:
			pass
