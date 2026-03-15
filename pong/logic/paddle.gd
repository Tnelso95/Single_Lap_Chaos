extends Area2D


const MOVE_SPEED = 300

var _ball_dir: int
var _up: String
var _down: String

@onready var _screen_size_y: float = get_viewport_rect().size.y


func _ready() -> void:
	var n := String(name).to_lower()
	_up = n + "_move_up"
	_down = n + "_move_down"
	_ball_dir = 1 if n == "left" else -1


func _process(delta: float) -> void:
	var input := Input.get_action_strength(_down) - Input.get_action_strength(_up)
	position.y = clamp(position.y + input * MOVE_SPEED * delta, 50.0, _screen_size_y - 50.0)


func _on_area_entered(area: Area2D) -> void:
	if area.name == "Ball":
		area.direction = Vector2(_ball_dir, randf() * 2.0 - 1.0).normalized()
