extends Sprite2D


func _process(delta):
	rotation_degrees = get_parent().rotation_degrees * -1
