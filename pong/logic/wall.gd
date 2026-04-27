extends Area2D


func _on_wall_area_entered(area: Area2D) -> void:
	if area.is_in_group("pong_ball"):
		# Ball passed this paddle: the other side scores
		if name == "LeftWall":
			get_parent().goal_scored(&"right", area)
		else:
			get_parent().goal_scored(&"left", area)
