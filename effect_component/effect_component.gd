extends Node
class_name EffectComponent


signal effect_applied(effect : Effect)
signal effect_ended(effect : Effect)
signal effect_extended(effect : Effect)



## The maximum amount of effects this entity can be affected by at once.
@export var max_effects : int = 100
## The effects which cannot be applied to this entity.
@export var effect_blacklist : Array[Effect]


## The current effects applied to this entity.
var current_effects : Array[Effect]
var effect_objects : Array[Object]

## A dictionary containing all the effects and their resources.
const effect_database : Dictionary = {
	#"health_boost": preload("res://health_boost.tres")
	"electrified": preload("res://entities/effects/electrified/electrified.tres"),
	"electrified_spread": preload("res://entities/effects/electrified/electrified_spread.tres"),
	"bleeding": preload("res://entities/effects/bleeding/bleeding.tres"),
	"speed_change": preload("res://entities/effects/speed_change/speed_change.tres"),
}

## Searches the effect database for an effect with name corresponding to effect_name and applies it for duration.
func apply_effect(effect_name : StringName, duration : float, metadata : Variant = null):
	var effect : Effect = effect_database[effect_name.to_snake_case()].duplicate(true)
	if not is_effect_blacklisted(effect_name):
		if not is_effect_applied(effect_name) or effect.stacking_mode == "Stack":
			if len(current_effects) < max_effects:
				## setup timer
				var effect_timer : Timer = Timer.new()
				effect.timer = effect_timer
				effect_timer.wait_time = duration
				self.add_child(effect_timer)
				effect_timer.one_shot = true
				## append effect to current effects array
				current_effects.append(effect)
				## what to do when effect is applied
				match effect.name:
					"Electrified":
						if get_parent().health_component != null:
							const HEALTH_BAR_THEME : Theme = preload("res://components/health_component/health_bar_theme.tres")
							const ELECTRIFIED_BAR_THEME : Theme = preload("res://entities/effects/electrified/electrified_bar_theme.tres")
							var elec_dmg_timer : Timer = Timer.new()
							elec_dmg_timer.wait_time = 0.25
							elec_dmg_timer.timeout.connect(
								func():
									get_parent().health_component.deal_damage(get_parent().health_component.max_health * 0.01)
							)
							
							self.add_child(elec_dmg_timer)
							elec_dmg_timer.start()
							get_parent().health_component.health_bar.theme = ELECTRIFIED_BAR_THEME
							get_parent().can_move = false
							get_parent().can_rotate = false
							get_parent().health_component.deal_damage(140)
							
							var elec_spread_lambda : Callable = func(body : Node):
								if body.get("effect_component") != null:
									body.effect_component.apply_effect("ElectrifiedSpread", 1, get_parent())
									pass
								
							get_parent().body_entered.connect(elec_spread_lambda)
							
							for body in get_parent().get_colliding_bodies():
								if body.get("effect_component") != null:
									body.effect_component.apply_effect("ElectrifiedSpread", 1, get_parent())
									pass
								
							effect_timer.timeout.connect(func():
								elec_dmg_timer.queue_free()
								get_parent().body_entered.disconnect(elec_spread_lambda)
								get_parent().health_component.health_bar.theme = HEALTH_BAR_THEME
								get_parent().can_move = true
								get_parent().can_rotate = true, Object.CONNECT_ONE_SHOT)
					"ElectrifiedSpread":
						if get_parent().health_component != null:
							const HEALTH_BAR_THEME : Theme = preload("res://components/health_component/health_bar_theme.tres")
							const ELECTRIFIED_BAR_THEME : Theme = preload("res://entities/effects/electrified/electrified_bar_theme.tres")
							var elec_dmg_timer : Timer = Timer.new()
							elec_dmg_timer.wait_time = 0.25
							elec_dmg_timer.timeout.connect(
								func():
									get_parent().health_component.deal_damage(get_parent().health_component.max_health * 0.01)
							)
							
							self.add_child(elec_dmg_timer)
							elec_dmg_timer.start()
							get_parent().health_component.health_bar.theme = ELECTRIFIED_BAR_THEME
							get_parent().can_move = false
							get_parent().can_rotate = false
							get_parent().apply_central_impulse(metadata.linear_velocity.normalized() * 2000)
							get_parent().health_component.deal_damage(140)
							
							
							effect_timer.timeout.connect(func():
								elec_dmg_timer.queue_free()
								get_parent().health_component.health_bar.theme = HEALTH_BAR_THEME
								get_parent().can_move = true
								get_parent().can_rotate = true, Object.CONNECT_ONE_SHOT)
					"Bleeding":
							const HEALTH_BAR_THEME : Theme = preload("res://components/health_component/health_bar_theme.tres")
							const BLEEDING_BAR_THEME = preload("res://entities/effects/bleeding/bleeding_bar_theme.tres")
							var old_regen_percent = get_parent().health_component.regeneration_percentage
							get_parent().health_component.regeneration_percentage = 0
							var bleed_dmg_timer : Timer = Timer.new()
							bleed_dmg_timer.wait_time = 1
							bleed_dmg_timer.timeout.connect(
								func():
									get_parent().health_component.deal_damage(get_parent().health_component.max_health * 0.03)
							)
							self.add_child(bleed_dmg_timer)
							get_parent().health_component.health_bar.theme = BLEEDING_BAR_THEME
							bleed_dmg_timer.start()
							
							effect_timer.timeout.connect(func():
								bleed_dmg_timer.queue_free()
								get_parent().health_component.regeneration_percentage = old_regen_percent
								get_parent().health_component.health_bar.theme = HEALTH_BAR_THEME
								)
					"Speed Change":
						const SLOWED_BAR_THEME = preload("res://entities/effects/speed_change/slowed_bar_theme.tres")
						const HEALTH_BAR_THEME : Theme = preload("res://components/health_component/health_bar_theme.tres")
						var trails : Array[Sprite2D]
						if metadata > 0:
							for child in get_parent().get_children():
								if child is Sprite2D:
									var trail_sprite : Sprite2D = Sprite2D.new()
									trail_sprite.texture = child.texture
									trail_sprite.scale = child.scale
									trail_sprite.self_modulate = Color(trail_sprite.self_modulate, 0.2)
									trail_sprite.show_behind_parent = true
									trail_sprite.position.y = sqrt(metadata) * 4 
									get_parent().add_child(trail_sprite)
									trails.append(trail_sprite)
						get_parent().movement_speed += metadata
						if metadata <= -30 and get_parent().health_component.health_bar.theme == HEALTH_BAR_THEME:
							get_parent().health_component.health_bar.theme = SLOWED_BAR_THEME
						
						effect_timer.timeout.connect(func():
							if metadata > 0:
								for trail : Sprite2D in trails:
									trail.queue_free()
							if metadata <= -30 and get_parent().health_component.health_bar.theme == SLOWED_BAR_THEME:
								get_parent().health_component.health_bar.theme = HEALTH_BAR_THEME
							get_parent().movement_speed -= metadata
							)
				# beginning of overall effect stuff
				effect_timer.timeout.connect(func():
					current_effects.erase(effect)
					emit_signal("effect_ended", effect)
					print("Effect %s has expired, removing effect from %s" % [effect.name, get_parent().name]))
				effect_timer.start()
				emit_signal("effect_applied", effect)
				print("Applied new effect %s to %s" % [effect.name, get_parent().name])
			elif len(current_effects) >= max_effects:
				if effect.overflow_mode == "Replace":
					var old_effect : Effect = current_effects.back()
					shorten_effect(current_effects.back().name.to_snake_case())
					if metadata != null:
						apply_effect(effect_name, duration, metadata)
					else:
						apply_effect(effect_name, duration)
					print("Replaced oldest effect %s with new effect %s" % [old_effect.name, effect.name])
				elif effect.overflow_mode == "Discard":
					print("All effect slots filled and effect overflow mode set to Discard, effect %s will not be applied" % effect.name)
		elif is_effect_applied(effect_name):
			effect = get_applied_effect(effect_name)
			match effect.stacking_mode:
				"Override":
					shorten_effect(effect_name)
					if metadata != null:
						apply_effect(effect_name, duration, metadata)
					else:
						apply_effect(effect_name, duration)
					print("Replaced effect %s with a new instance of %s" % [effect.name, effect.name])
				"Duration":
					var current_duration : float = effect.timer.time_left
					effect.timer.stop()
					effect.timer.wait_time = current_duration + duration
					effect.timer.start()
					emit_signal("effect_extended", effect)
					print("Duration of effect %s increased by %s from %s to %s" % [effect.name, duration, current_duration, effect.timer.time_left])
	elif is_effect_blacklisted(effect_name):
		print("Effect %s is blacklisted for this EffectComponent, discarding effect" % effect.name)


## Shortens the currently applied effect with the name corresponding to effect_name by duration.
func shorten_effect(effect_name : StringName, duration : float = INF):
	var effect : Effect = get_applied_effect(effect_name)
	if effect != null:
		var current_duration : float = effect.timer.time_left
		if current_duration - duration <= 0:
			effect.timer.stop()
			effect.timer.emit_signal("timeout")
			effect.timer.queue_free()
			print("%s duration reached 0, removing effect" % effect.name)
		else:
			effect.timer.stop()
			effect.timer.wait_time = current_duration - duration
			effect.timer.start()
			print("%s duration shortened by %s" % [effect.name, duration])
	else:
		print("Could not find effect %s in currently applied effects array" % effect_name)


func _process(delta):
	if is_effect_applied("Speed Change"):
		pass


func is_effect_applied(effect_name : StringName) -> bool:
	for effect : Effect in current_effects:
		if effect.name.to_snake_case() == effect_name.to_snake_case():
			return true
	return false


func is_effect_blacklisted(effect_name : StringName) -> bool:
	for effect : Effect in effect_blacklist:
		if effect.name.to_snake_case() == effect_name.to_snake_case():
			return true
	return false


func get_applied_effect(effect_name : StringName) -> Effect:
	for effect : Effect in current_effects:
		if effect.name.to_snake_case() == effect_name.to_snake_case():
			return effect
	return null
