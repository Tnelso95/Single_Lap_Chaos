extends Area2D


const DEFAULT_SPEED := 200.0

var _speed: float = DEFAULT_SPEED
var direction := Vector2.LEFT

@onready var _initial_pos: Vector2 = position


func _process(delta: float) -> void:
	_speed += delta * 20.0
	position += direction * _speed * delta


func reset() -> void:
	direction = Vector2.LEFT
	position = _initial_pos
	_speed = DEFAULT_SPEED
