extends Node2D
class_name Map


var game_terrains : Array[GameTerrain]
var entities : Array[Entity]
var food_spawn_areas : Array[FoodSpawnAreaProperties]


func _ready() -> void:
	for area_properties : FoodSpawnAreaProperties in food_spawn_areas:
		var timer : Timer = Timer.new()
		timer.wait_time = area_properties.food_spawn_cooldown
		timer.timeout.connect(func():
			if area_properties.food_count < area_properties.max_food_count:
				spawn_food(area_properties)
				area_properties.food_count += 1
				)
		area_properties.food_spawn_timer = timer
		self.add_child(timer)
		timer.start()
		for food in range(area_properties.food_to_prespawn):
			spawn_food(area_properties)
		area_properties.food_count = area_properties.max_food_count


func spawn_food(food_spawn_area : FoodSpawnAreaProperties) -> void:
	while true:
		var food_scene : PackedScene
		match food_spawn_area.food_type:
			"Nutrient Pellet":
				food_scene = preload("res://map/food/nutrient_pellet.tscn")
		var food_pellet : FoodPellet = food_scene.instantiate()
		var test : float
		var random_triangle : FoodSpawnAreaProperties.UnweightedTriangle = food_spawn_area.get_random_triangle()
		var point1 : Vector2 = random_triangle.a
		var point2 : Vector2 = random_triangle.b
		var point3 : Vector2 = random_triangle.c
		#print(point1)
		#print(point2)
		#print(point3)
		# this is the point that is needed to construct a parallelogram
		var point4 : Vector2 = point3 - point2 + point1
		var r1 : float = randf()
		var r2 : float = randf()
		# random point in parallelogrma from https://stackoverflow.com/questions/9334970/create-a-function-to-generate-random-points-in-a-parallelogram
		var rand_point_parallelogram : Vector2 = Vector2(point1.x + r1 * (point2.x - point1.x) + r2 * (point4.x - point1.x),
		point1.y + r1 * (point2.y - point1.y) + r2 * (point4.y - point1.y))
		 #debug code that draws the parallelogram
		#var p1 = point1 + food_spawn_area.food_spawn_polygon_position
		#var p2 = point2 + food_spawn_area.food_spawn_polygon_position
		#var p3 = point3 + food_spawn_area.food_spawn_polygon_position
		#var p4 : Vector2 = point3 - point2 + point1 + food_spawn_area.food_spawn_polygon_position
		#var line1 = Line2D.new()
		#line1.add_point(p1)
		#line1.add_point(p2)
		#var line2 = Line2D.new()
		#line2.add_point(p1)
		#line2.add_point(p3)
		#line2.default_color = Color.BLUE
		#var line3 = Line2D.new()
		#line3.add_point(p2)
		#line3.add_point(p3)
		#line3.default_color = Color.YELLOW
		#var line4 = Line2D.new()
		#line4.add_point(p1)
		#line4.add_point(p4)
		#line4.default_color = Color.RED
		#var line5 = Line2D.new()
		#line5.add_point(p3)
		#line5.add_point(p4)
		#line5.default_color = Color.GREEN
		#add_child(line1)
		#add_child(line2)
		#add_child(line3)
		#add_child(line4)
		#add_child(line5)
		var is_in_triangle : bool = Geometry2D.point_is_inside_triangle(rand_point_parallelogram, point1, point2, point3)
		var final_pos : Vector2
		if is_in_triangle:
			final_pos = rand_point_parallelogram + food_spawn_area.food_spawn_polygon_position
		else:
			# if point is not in triangle, pick p', symmetrical point in the other triangle of the parallelogram
			# image here https://i.sstatic.net/zPeLg.png
			final_pos = point1 + point3 - rand_point_parallelogram + food_spawn_area.food_spawn_polygon_position
		food_pellet.global_position = final_pos
		food_pellet.body_entered.connect(func(body):
			if body is Animal:
				Global.current_animal_control_component.boost_points += food_pellet.boost_points
				body.health_component.heal(body.health_component.max_health * food_pellet.healing_percentage)
				food_pellet.queue_free()
				food_spawn_area.food_count -= 1
			)
		self.add_child(food_pellet)
		break
