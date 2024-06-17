extends Resource
class_name FoodSpawnAreaProperties


var food_type : String
var food_spawn_cooldown : float
var unweighted_triangulated_polygon : Array[UnweightedTriangle]
var weights : PackedFloat32Array
var food_spawn_polygon_position : Vector2
var max_food_count : int
var food_to_prespawn : int

var food_spawn_timer : Timer
var current_food : Array
var food_count : int


func _init(ft : String, fsc : float, food_spawn_polygon : PackedVector2Array, fspp : Vector2, mfc : int, ftps : int) -> void:
	food_type = ft
	food_spawn_cooldown = fsc
	food_spawn_polygon_position = fspp
	max_food_count = mfc
	food_to_prespawn = ftps
	
	var triangulated_polygon : PackedInt32Array = Geometry2D.triangulate_polygon(food_spawn_polygon)
	var unweighted_polygon : Array[UnweightedTriangle]
	var triangle_areas : Array[float]
	if triangulated_polygon.size() < 3:
		OS.crash("Food polygon triangulation failed")
	var total_area : float
	for i in range(0, triangulated_polygon.size() / 3):
		var a : Vector2 = food_spawn_polygon[triangulated_polygon[i * 3 - 1]]
		var b : Vector2 = food_spawn_polygon[triangulated_polygon[i * 3 - 2]]
		var c : Vector2 = food_spawn_polygon[triangulated_polygon[i * 3 - 3]]
		var ab_len : float = a.distance_to(b)
		var bc_len : float = b.distance_to(c)
		var ac_len: float = a.distance_to(c)
		var half_perimeter = (ab_len + bc_len + ac_len) * 0.5
		var area : float = sqrt(half_perimeter * (half_perimeter - ab_len) * (half_perimeter - ac_len) * (half_perimeter - bc_len))
		total_area += area
		unweighted_polygon.append(UnweightedTriangle.new(a, b, c, area))
	for unweighted_triangle : UnweightedTriangle in unweighted_polygon:
		var new_triangle : UnweightedTriangle = unweighted_triangle
		weights.append(unweighted_triangle.area / total_area)
		unweighted_triangulated_polygon.append(new_triangle)


func get_random_triangle() -> UnweightedTriangle:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	return unweighted_triangulated_polygon[rng.rand_weighted(weights)]


class UnweightedTriangle:
	var a : Vector2
	var b : Vector2
	var c : Vector2
	var area : float
	
	
	func _init(a1 : Vector2, b1 : Vector2, c1 : Vector2, ar : float):
		a = a1
		b = b1
		c = c1
		area = ar
