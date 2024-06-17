extends Node


var console_open : bool
var remove_zoom_limits : bool
var hide_console_hint : bool = true
var current_player_animal : Animal
var current_animal_control_component : AnimalControlComponent
var ui_canvaslayer : CanvasLayer = CanvasLayer.new()
var choose_animal_menu : ColorRect


const CONSOLE : PackedScene = preload("res://ui/console/console.tscn")


var console_instance : Node = CONSOLE.instantiate()


func _ready():
	self.add_child(ui_canvaslayer)
	self.add_child(console_instance)
	console_instance.visible = false


func _unhandled_input(event):
	if event.is_action_pressed("toggle_test_console") and console_open ==false:
		console_open = true
		console_instance.visible = true
	elif event.is_action_pressed("toggle_test_console") and console_open == true:
		console_open = false
		console_instance.visible = false
