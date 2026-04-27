extends Area2D


const DEFAULT_SPEED := 450.0
const SPEED_GAIN_PER_SECOND := 50.0
const MAX_SPEED := 1200.0
const TOP_LIMIT := -22.0
const BOTTOM_LIMIT := 622.0
const LEFT_GOAL_X := 8.0
const RIGHT_GOAL_X := 1162.0
const MIN_VERTICAL_MAGNITUDE := 0.12
const PADDLE_BOUNCE_COOLDOWN_MS := 55

var _speed: float = DEFAULT_SPEED
var direction := Vector2.LEFT
var _last_paddle_bounce_ms := -1000
var _goal_reported := false
var _speed_cap := MAX_SPEED

@onready var _initial_pos: Vector2 = position

func _ready() -> void:
	add_to_group("pong_ball")
	reset()

func _physics_process(delta: float) -> void:
	var previous_position := position
	_speed = minf(_speed_cap, _speed + delta * SPEED_GAIN_PER_SECOND)
	position += direction * _speed * delta
	_keep_inside_vertical_bounds()
	_report_goal_cross_if_needed(previous_position)
	_resolve_paddle_tunneling(previous_position)


func reset() -> void:
	direction = Vector2.LEFT
	position = _initial_pos
	_speed = DEFAULT_SPEED
	_goal_reported = false

func get_current_speed() -> float:
	return _speed

func set_speed_cap(new_cap: float) -> void:
	_speed_cap = clampf(new_cap, DEFAULT_SPEED, MAX_SPEED)
	_speed = minf(_speed, _speed_cap)

func add_speed(amount: float) -> void:
	_speed = clampf(_speed + amount, DEFAULT_SPEED, _speed_cap)

func _keep_inside_vertical_bounds() -> void:
	# Prevent tunneling through ceiling/floor at high speeds.
	if position.y < TOP_LIMIT:
		position.y = TOP_LIMIT
		direction.y = absf(direction.y)
	elif position.y > BOTTOM_LIMIT:
		position.y = BOTTOM_LIMIT
		direction.y = -absf(direction.y)
	if absf(direction.y) < MIN_VERTICAL_MAGNITUDE:
		direction.y = MIN_VERTICAL_MAGNITUDE if direction.y >= 0.0 else -MIN_VERTICAL_MAGNITUDE
	direction = direction.normalized()

func _resolve_paddle_tunneling(previous_position: Vector2) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var left_paddle := parent_node.get_node_or_null("Left") as Area2D
	var right_paddle := parent_node.get_node_or_null("Right") as Area2D
	if left_paddle != null:
		_try_crossing_paddle(previous_position, left_paddle, true)
	if right_paddle != null:
		_try_crossing_paddle(previous_position, right_paddle, false)

func _try_crossing_paddle(previous_position: Vector2, paddle: Area2D, is_left_paddle: bool) -> void:
	var paddle_shape_node := paddle.get_node_or_null("Collision") as CollisionShape2D
	if paddle_shape_node == null:
		return
	var rect_shape := paddle_shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return
	var ball_shape_node := get_node_or_null("Collision") as CollisionShape2D
	var ball_shape := ball_shape_node.shape as CircleShape2D if ball_shape_node else null
	var ball_radius := ball_shape.radius * ball_shape_node.scale.x if ball_shape else 14.0
	var paddle_half_width := rect_shape.size.x * 0.5
	var paddle_half_height := rect_shape.size.y * 0.5
	var paddle_center := paddle.global_position + paddle_shape_node.position
	var hit_vertical_range := absf(position.y - paddle_center.y) <= (paddle_half_height + ball_radius)
	if not hit_vertical_range:
		return
	var crossed := false
	if is_left_paddle and direction.x < 0.0:
		crossed = previous_position.x >= paddle_center.x and position.x <= paddle_center.x
	elif not is_left_paddle and direction.x > 0.0:
		crossed = previous_position.x <= paddle_center.x and position.x >= paddle_center.x
	if not crossed:
		return
	# Bounce back out of the paddle face when a fast step skipped the area_entered signal.
	var bounce_x := 1.0 if is_left_paddle else -1.0
	if not bounce_from_paddle(bounce_x):
		return
	if is_left_paddle:
		position.x = paddle_center.x + paddle_half_width + ball_radius + 1.0
	else:
		position.x = paddle_center.x - paddle_half_width - ball_radius - 1.0

func bounce_from_paddle(bounce_x: float) -> bool:
	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_paddle_bounce_ms < PADDLE_BOUNCE_COOLDOWN_MS:
		return false
	_last_paddle_bounce_ms = now_ms
	direction = Vector2(bounce_x, direction.y).normalized()
	return true

func _report_goal_cross_if_needed(previous_position: Vector2) -> void:
	if _goal_reported:
		return
	var parent_node := get_parent()
	if parent_node == null or not parent_node.has_method("goal_scored"):
		return
	# Keep fallback scoring only for two-ball rounds (round 3+).
	if parent_node.has_method("is_two_ball_round") and not bool(parent_node.call("is_two_ball_round")):
		return
	var crossed_left := previous_position.x >= LEFT_GOAL_X and position.x < LEFT_GOAL_X
	var crossed_right := previous_position.x <= RIGHT_GOAL_X and position.x > RIGHT_GOAL_X
	if crossed_left:
		_goal_reported = true
		parent_node.call("goal_scored", &"right", self)
	elif crossed_right:
		_goal_reported = true
		parent_node.call("goal_scored", &"left", self)
