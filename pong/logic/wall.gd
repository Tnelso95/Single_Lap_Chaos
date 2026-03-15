extends Area2D


func _on_wall_area_entered(area: Area2D) -> void:
	if area.name == "Ball":
		# Ball passed this paddle: the other side scores
		if name == "LeftWall":
			get_parent().goal_scored(&"right")
		else:
			get_parent().goal_scored(&"left")
		area.reset()
