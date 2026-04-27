extends Area2D


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("pong_ball"):
		# Only bounce when the ball is moving into this boundary.
		if name == "Ceiling":
			if area.direction.y < 0.0:
				area.direction = Vector2(area.direction.x, absf(area.direction.y)).normalized()
		else:
			if area.direction.y > 0.0:
				area.direction = Vector2(area.direction.x, -absf(area.direction.y)).normalized()
