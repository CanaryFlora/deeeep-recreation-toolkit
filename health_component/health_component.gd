extends Node
class_name HealthComponent


signal health_reached_0(entity : Entity)
signal damage_dealt(danage : float)
signal health_healed(health : float)


@export var max_health : float
@export var regeneration_seconds : float = 1
@export var regeneration_percentage : float = 0.02
@export var healthbar_extra_y : float
@export var show_hp_text : bool = true
@export var show_health_bar : bool = true


@onready var health : float = max_health


var regen_timer : Timer = Timer.new()
var health_bar : ProgressBar = HEALTH_BAR_SCENE.instantiate()


const HEALTH_BAR_SCENE : PackedScene = preload("res://components/health_component/health_bar.tscn")
const DAMAGE_TEXT := preload("res://components/health_component/damage_text.tscn")
const HEAL_TEXT = preload("res://components/health_component/heal_text.tscn")
const DAMAGE_TEXT_THEME = preload("res://components/health_component/damage_text_theme.tres")
const HEAL_TEXT_THEME = preload("res://components/health_component/heal_text_theme.tres")


func _ready():
	regen_timer.wait_time = regeneration_seconds
	regen_timer.timeout.connect(regen_hp)
	self.add_child(regen_timer)
	regen_timer.start()
	#health_bar.top_level = truer
	get_parent().add_child.call_deferred(health_bar)
	health_bar.max_value = max_health
	update_health_bar()


func _process(delta):
	regen_timer.wait_time = regeneration_seconds
	if show_health_bar:
		if health == max_health:
			health_bar.visible = false
		else:
			health_bar.visible = true
	else:
		health_bar.visible = false
	## HACK
	health_bar.rotation_degrees = -1 * get_parent().rotation_degrees
	health_bar.global_position = Vector2(get_parent().global_position.x - 90, get_parent().global_position.y - 180 + healthbar_extra_y)



func deal_damage(damage : float) -> void:
	var new_health : float = health - damage
	if new_health <= 0:
		emit_signal("health_reached_0", get_parent())
	var old_health : float = health
	health = new_health
	print("health at %s" % health)
	emit_signal("damage_dealt", damage)
	update_health_bar()
	# create dmg text
	if show_hp_text:
		var dmg_text : Label = DAMAGE_TEXT.instantiate()
		var dmg_text_theme_inst : Theme = DAMAGE_TEXT_THEME.duplicate(true)
		var font_size = abs(old_health - new_health) / 3
		if font_size > 128:
			font_size = 128
		elif font_size < 32:
			font_size = 32
		dmg_text_theme_inst.set_font_size("font_size", "Label", font_size)
		dmg_text.theme = dmg_text_theme_inst
		dmg_text.text = "-" + str(damage)
		var dmg_tween : Tween = get_tree().create_tween()
		var move_vector : Vector2 = Vector2(randi_range(-100, 200), -200)
		get_parent().add_child(dmg_text)
		dmg_tween.tween_property(dmg_text, "global_position", dmg_text.global_position + move_vector, 0.5)
		if new_health > 0:
			dmg_tween.finished.connect(func():
				if dmg_text != null and new_health > 0:
					dmg_text.queue_free(), Object.CONNECT_ONE_SHOT)


func regen_hp() -> void:
	if regeneration_percentage != 0:
		heal(max_health * regeneration_percentage)


func heal(hp : float) -> void:
	if health < max_health:
		var old_health : float = health
		health += hp
		update_health_bar()
		emit_signal("health_healed", hp)
		if show_hp_text:
			var heal_text : Label = HEAL_TEXT.instantiate()
			var heal_text_theme_inst : Theme = HEAL_TEXT_THEME.duplicate(true)
			var font_size = abs(old_health - health)
			if font_size > 128:
				font_size = 128
			elif font_size < 32:
				font_size = 32
			heal_text_theme_inst.set_font_size("font_size", "Label", font_size)
			heal_text.theme = heal_text_theme_inst
			heal_text.text = str(abs(old_health - health))
			var heal_tween : Tween = get_tree().create_tween()
			var move_vector : Vector2 = Vector2(randi_range(-100, 200), -200)
			get_parent().add_child(heal_text)
			heal_tween.tween_property(heal_text, "global_position", heal_text.global_position + move_vector, 0.5)
			heal_tween.finished.connect(func():
				if heal_text != null:
					heal_text.queue_free(), Object.CONNECT_ONE_SHOT)

func update_health_bar() -> void:
	health_bar.value = health
