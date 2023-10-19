extends Skeleton3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("SQUASH"):
		position.x = 0.3
	else:
		position.x = -1.6
