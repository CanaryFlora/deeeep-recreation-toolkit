## A terrain in the game.
##
## Game terrains are constructed at launch with the setup_terrain method from a TerrainData resource. They can be reconstructed at runtime
## if needed.
extends StaticBody2D
class_name GameTerrain


var terrain_data : TerrainData


func setup_terrain(new_terrain_data : TerrainData) -> void:
	for child in get_children():
		child.queue_free()
	
	terrain_data = new_terrain_data
	var collision_polygon : CollisionPolygon2D = CollisionPolygon2D.new()
	collision_polygon.polygon = terrain_data.polygon
	var texture_polygon : Polygon2D = Polygon2D.new()
	texture_polygon.polygon = terrain_data.polygon
	var image : Texture2D
	match terrain_data.terrain_type:
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
	texture_polygon.texture = atlas
	texture_polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	self.global_position = terrain_data.position
	collision_priority = 100
	if terrain_data.diggable:
		collision_layer = pow(2, 2-1)
		collision_mask = pow(2, 2-1)
	elif not terrain_data.diggable:
		collision_layer = pow(2, 2-1) + pow(2, 3-1)
		collision_mask = pow(2, 2-1) + pow(2, 3-1)
	self.queue_redraw()
	self.add_child(collision_polygon)
	self.add_child(texture_polygon)
	#await get_tree().create_timer(0.5).timeout
	#if not get_parent().game_terrains.has(self):
		#get_parent().game_terrains.append(self)
 
