## A terrain in the editor. 
##
## Editor terrains are heavily stripped down Polygon2Ds designed to be used with the built-n polygon editor
## for making map terrains. Editor terrains are not visible at runtime and are instead replaced with StaticBody2Ds which have a 
## CollisionPolygon2D matching the editor polygon as its hitbox and a texture matching the terrain type.
##
## Editor terrains don't support the following Polygon2D features: texture/texture offset/texture scale/texture rotation, skeleton, 
## UV, vertex colors, polygons, internal vertex count. Any changes to these features will immediately revert to default.

@tool
extends Polygon2D
class_name Terrain


@export var diggable : bool = true
@export_enum("F.E.D.E Phase 1", "Volcanic Sand", "Beach", "Cenote", "F.E.D.E Phase 1 Dark") var terrain_type : String


func _process(delta):
	if Engine.is_editor_hint():
		color = Color.WHITE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		offset = Vector2(0, 0)
		antialiased = false
		skeleton = NodePath()
		if terrain_type == "":
			texture = null
		else:
			set_terrain_preview_texture(terrain_type)
		uv = []
		vertex_colors = []
		polygons = []
		internal_vertex_count = 0
		texture_offset = Vector2(0, 0)
		texture_scale = Vector2(1, 1)
		texture_rotation = 0


func set_terrain_preview_texture(terrain_type : String) -> void:
	var image : Texture2D
	match terrain_type:
		"F.E.D.E Phase 1":
			image = preload("res://assets/map/terrains/fede terrain.png")
		"Volcanic Sand":
			image = preload("res://assets/map/terrains/volcanicsand.png")
		"Beach":
			image = preload("res://assets/map/terrains/beach.png")
		"Cenote":
			image = preload("res://assets/map/terrains/cenote1.png")
		"F.E.D.E Phase 1 Dark":
			image = preload("res://assets/map/terrains/fede_terrain_dark.png")
	var atlas : AtlasTexture = AtlasTexture.new()
	atlas.region = Rect2(0, 0, image.get_width(), image.get_height())
	atlas.atlas = image
	texture = atlas
	self.queue_redraw()


func _ready():
	if not Engine.is_editor_hint():
		var terrain_data : TerrainData = TerrainData.new(polygon, global_position, terrain_type, diggable)
		var game_terrain : GameTerrain = GameTerrain.new()
		self.add_sibling.call_deferred(game_terrain)
		game_terrain.setup_terrain(terrain_data)
		self.queue_free()
