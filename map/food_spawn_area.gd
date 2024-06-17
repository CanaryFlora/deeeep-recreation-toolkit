@tool
extends Polygon2D
class_name FoodSpawnArea


@export_enum("Nutrient Pellet") var food_type : String
@export var food_spawn_cooldown : float
@export var max_food_count : int
@export var food_to_prespawn : int


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		offset = Vector2(0, 0)
		antialiased = false
		skeleton = NodePath()
		vertex_colors = []
		polygons = []
		internal_vertex_count = 0
		texture_offset = Vector2(0, 0)
		texture_scale = Vector2(1, 1)
		texture_rotation = 0
		rotation = 0
		scale = Vector2(1, 1)
		if food_type == "":
			color = Color.WHITE
		else:
			match food_type:
				"Nutrient Pellet":
					color = Color(Color.MEDIUM_AQUAMARINE)
			color = Color(color, 0.5)


func _ready() -> void:
	if not Engine.is_editor_hint():
		var food_spawn_properties : FoodSpawnAreaProperties = FoodSpawnAreaProperties.new(food_type, food_spawn_cooldown, 
		polygon, global_position, max_food_count, food_to_prespawn)
		get_parent().food_spawn_areas.append(food_spawn_properties)
		queue_free()
