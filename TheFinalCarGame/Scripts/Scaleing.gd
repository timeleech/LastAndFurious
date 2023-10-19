extends MeshInstance3D



func _process(_delta):
	
	if Input.is_action_pressed("SQUASH"):
		scale.x = 0.3
		
	else:
		scale = Vector3(1, 1, 1)
		
