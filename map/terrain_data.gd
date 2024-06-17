extends Resource
class_name TerrainData

var polygon : PackedVector2Array
var position : Vector2
var terrain_type : String
var diggable : bool



func _init(poly : PackedVector2Array, pos : Vector2, tt : String, d : bool):
	polygon = poly
	position = pos
	terrain_type = tt
	diggable = d
