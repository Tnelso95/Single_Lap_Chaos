extends Node2D

const LEADERBOARD_SCENE_PATH := "res://leaderboard.tscn"
const RETURN_DELAY := 2.0
const USE_TRACK_SNAP_FALLBACK := false
const SHUFFLE_MIN_SECONDS := 3.0
const SHUFFLE_MAX_SECONDS := 5.0
const SHUFFLE_COUNTDOWN_TEXTURES: Array[Texture2D] = [
	preload("res://assests/1.png"),
	preload("res://assests/2.png"),
	preload("res://assests/3.png"),
	preload("res://assests/4.png"),
	preload("res://assests/5.png"),
]

@onready var player_one_car: CharacterBody2D = $PlayerOneCar
@onready var player_two_car: CharacterBody2D = $PlayerTwoCar
@onready var outer_polygon: CollisionPolygon2D = $Borders/Outer
@onready var inner_polygon: CollisionPolygon2D = $Borders/Inner
@onready var status_label: Label = get_node_or_null("UI/StatusLabel") as Label
@onready var winner_label: Label = get_node_or_null("UI/WinnerLabel") as Label
@onready var shuffle_countdown_sprite: Sprite2D = get_node_or_null("ShuffleCountdown") as Sprite2D

var game_over := false
var transitioning := false
var _start_gate_area: Area2D = null
var _finish_area: Area2D = null
var _start_gate_shape: CollisionShape2D = null
var _finish_shape: CollisionShape2D = null
var _require_start_gate := false
var _p1_cleared_start_gate := false
var _p2_cleared_start_gate := false
var _p1_inside_start_gate := false
var _p2_inside_start_gate := false
var _p1_inside_finish_gate := false
var _p2_inside_finish_gate := false
var _last_valid_p1_pos := Vector2.ZERO
var _last_valid_p2_pos := Vector2.ZERO
var _last_valid_p1_rot := 0.0
var _last_valid_p2_rot := 0.0
var _p1_has_valid_track_pos := false
var _p2_has_valid_track_pos := false
var _shuffle_rng := RandomNumberGenerator.new()
var _seconds_until_shuffle := 0.0

func _ready() -> void:
	player_one_car.set_car_visual(GlobalData.p1Car)
	player_two_car.set_car_visual(GlobalData.p2Car)
	player_one_car.randomize_inputs = false
	player_two_car.randomize_inputs = false
	_last_valid_p1_pos = player_one_car.global_position
	_last_valid_p2_pos = player_two_car.global_position
	_last_valid_p1_rot = player_one_car.global_rotation
	_last_valid_p2_rot = player_two_car.global_rotation
	_p1_has_valid_track_pos = _is_on_track(player_one_car.global_position)
	_p2_has_valid_track_pos = _is_on_track(player_two_car.global_position)
	_bind_track_gate_objects()
	if winner_label:
		winner_label.visible = false
	if status_label:
		status_label.text = "Dizzy Driving: reach the finish line first!"
	_shuffle_rng.randomize()
	_schedule_next_shuffle()

func _physics_process(_delta: float) -> void:
	if game_over:
		return
	_seconds_until_shuffle -= _delta
	if _seconds_until_shuffle <= 0.0:
		player_one_car.force_shuffle_now()
		player_two_car.force_shuffle_now()
		_schedule_next_shuffle()
	# Border CollisionPolygon2D walls are the source of truth for staying on track.
	# Keep the old geometry snap logic as an opt-in fallback only.
	if USE_TRACK_SNAP_FALLBACK:
		_enforce_track_bounds(player_one_car, 1)
		_enforce_track_bounds(player_two_car, 2)
	_update_gate_shape_crossings()
	_update_shuffle_countdown()

func _on_finish_line_body_entered(body: Node) -> void:
	_handle_finish_cross(body)

func _handle_finish_cross(body: Node) -> void:
	if game_over:
		return
	if _require_start_gate:
		if body == player_one_car and not _p1_cleared_start_gate:
			return
		if body == player_two_car and not _p2_cleared_start_gate:
			return
	if body == player_one_car:
		_end_game(1)
	elif body == player_two_car:
		_end_game(2)

func _end_game(winner: int) -> void:
	game_over = true
	GlobalData.award_win(winner)
	if winner_label:
		if winner == 1:
			winner_label.text = "Player 1 wins Dizzy Driving!"
		else:
			winner_label.text = "Player 2 wins Dizzy Driving!"
		winner_label.visible = true
	if status_label:
		status_label.text = "Returning to leaderboard..."
	player_one_car.set_physics_process(false)
	player_two_car.set_physics_process(false)
	_queue_return()

func _queue_return() -> void:
	await get_tree().create_timer(RETURN_DELAY).timeout
	_return_to_leaderboard()

func _return_to_leaderboard() -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().change_scene_to_file(LEADERBOARD_SCENE_PATH)

func _enforce_track_bounds(car: CharacterBody2D, player: int) -> void:
	if _is_on_track(car.global_position):
		if player == 1:
			_last_valid_p1_pos = car.global_position
			_last_valid_p1_rot = car.global_rotation
			_p1_has_valid_track_pos = true
		else:
			_last_valid_p2_pos = car.global_position
			_last_valid_p2_rot = car.global_rotation
			_p2_has_valid_track_pos = true
		return

	# If a car starts outside track after manual spawn edits, let it drive onto track first.
	if player == 1 and not _p1_has_valid_track_pos:
		return
	if player == 2 and not _p2_has_valid_track_pos:
		return

	if player == 1:
		car.global_position = _last_valid_p1_pos
		car.global_rotation = _last_valid_p1_rot
	else:
		car.global_position = _last_valid_p2_pos
		car.global_rotation = _last_valid_p2_rot
	car.velocity = Vector2.ZERO

func _is_on_track(world_pos: Vector2) -> bool:
	var outer_local := outer_polygon.to_local(world_pos)
	var inner_local := inner_polygon.to_local(world_pos)
	var inside_outer := Geometry2D.is_point_in_polygon(outer_local, outer_polygon.polygon)
	var inside_inner := Geometry2D.is_point_in_polygon(inner_local, inner_polygon.polygon)
	return inside_outer and not inside_inner

func _bind_track_gate_objects() -> void:
	# Prefer Area2D triggers if present.
	var areas: Array[Node] = find_children("*", "Area2D", true, false)
	for node in areas:
		var area := node as Area2D
		if area == null:
			continue
		var lower_name := area.name.to_lower()
		if _start_gate_area == null and lower_name.contains("start"):
			_start_gate_area = area
		elif _finish_area == null and lower_name.contains("finish"):
			_finish_area = area

	if _start_gate_area:
		_require_start_gate = true
		if not _start_gate_area.body_entered.is_connected(_on_start_gate_body_entered):
			_start_gate_area.body_entered.connect(_on_start_gate_body_entered)

	if _finish_area:
		if not _finish_area.body_entered.is_connected(_on_finish_area_body_entered):
			_finish_area.body_entered.connect(_on_finish_area_body_entered)

	# Also support plain CollisionShape2D markers (common in quick level edits).
	var shapes: Array[Node] = find_children("*", "CollisionShape2D", true, false)
	for node in shapes:
		var shape_node := node as CollisionShape2D
		if shape_node == null:
			continue
		var shape_name := shape_node.name.to_lower()
		if _start_gate_shape == null and shape_name.contains("start"):
			_start_gate_shape = shape_node
		elif _finish_shape == null and shape_name.contains("finish"):
			_finish_shape = shape_node

	if _start_gate_shape and _start_gate_area == null:
		_require_start_gate = true

	# Initialize inside flags so first crossing is edge-triggered.
	_p1_inside_start_gate = _is_inside_start_marker(player_one_car)
	_p2_inside_start_gate = _is_inside_start_marker(player_two_car)
	_p1_inside_finish_gate = _is_inside_finish_marker(player_one_car)
	_p2_inside_finish_gate = _is_inside_finish_marker(player_two_car)

func _on_start_gate_body_entered(body: Node) -> void:
	if game_over:
		return
	if body == player_one_car:
		_p1_cleared_start_gate = true
	elif body == player_two_car:
		_p2_cleared_start_gate = true

func _on_finish_area_body_entered(body: Node) -> void:
	_handle_finish_cross(body)

func _update_gate_shape_crossings() -> void:
	if _start_gate_shape:
		var p1_start_now := _is_inside_start_marker(player_one_car)
		var p2_start_now := _is_inside_start_marker(player_two_car)
		if p1_start_now and not _p1_inside_start_gate:
			_p1_cleared_start_gate = true
		if p2_start_now and not _p2_inside_start_gate:
			_p2_cleared_start_gate = true
		_p1_inside_start_gate = p1_start_now
		_p2_inside_start_gate = p2_start_now

	if _finish_shape:
		var p1_finish_now := _is_inside_finish_marker(player_one_car)
		var p2_finish_now := _is_inside_finish_marker(player_two_car)
		if p1_finish_now and not _p1_inside_finish_gate:
			_handle_finish_cross(player_one_car)
		if p2_finish_now and not _p2_inside_finish_gate:
			_handle_finish_cross(player_two_car)
		_p1_inside_finish_gate = p1_finish_now
		_p2_inside_finish_gate = p2_finish_now

func _is_inside_start_marker(car: CharacterBody2D) -> bool:
	if _start_gate_shape == null:
		return false
	return _is_body_inside_gate_shape(car, _start_gate_shape)

func _is_inside_finish_marker(car: CharacterBody2D) -> bool:
	if _finish_shape == null:
		return false
	return _is_body_inside_gate_shape(car, _finish_shape)

func _is_body_inside_gate_shape(body: CharacterBody2D, gate_shape: CollisionShape2D) -> bool:
	if gate_shape.shape == null:
		return false
	var local_point := gate_shape.to_local(body.global_position)
	if gate_shape.shape is RectangleShape2D:
		var rect := gate_shape.shape as RectangleShape2D
		var half := rect.size * 0.5
		return absf(local_point.x) <= half.x and absf(local_point.y) <= half.y
	if gate_shape.shape is CircleShape2D:
		var circle := gate_shape.shape as CircleShape2D
		return local_point.length() <= circle.radius
	return false

func _update_shuffle_countdown() -> void:
	if shuffle_countdown_sprite == null:
		return
	if game_over:
		shuffle_countdown_sprite.visible = false
		return
	var seconds_to_show: int = clampi(int(ceili(_seconds_until_shuffle)), 1, 5)
	if seconds_to_show <= 0:
		shuffle_countdown_sprite.visible = false
		return
	var texture_index := clampi(seconds_to_show - 1, 0, SHUFFLE_COUNTDOWN_TEXTURES.size() - 1)
	shuffle_countdown_sprite.texture = SHUFFLE_COUNTDOWN_TEXTURES[texture_index]
	shuffle_countdown_sprite.visible = true

func _schedule_next_shuffle() -> void:
	var min_seconds := minf(SHUFFLE_MIN_SECONDS, SHUFFLE_MAX_SECONDS)
	var max_seconds := maxf(SHUFFLE_MIN_SECONDS, SHUFFLE_MAX_SECONDS)
	_seconds_until_shuffle = _shuffle_rng.randf_range(min_seconds, max_seconds)
