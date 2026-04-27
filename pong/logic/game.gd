extends Node2D

const WIN_SCORE := 5
const LEADERBOARD_SCENE_PATH := "res://leaderboard.tscn"
const RETURN_DELAY := 2.0
const BASE_BALL_NAME := "Ball"
const SINGLE_BALL_SPEED_CAP := 1200.0
const TWO_BALL_SPEED_CAP := 900.0
const LEFT_PADDLE_SPRITE_PATH := "Left/Sprite2D"
const RIGHT_PADDLE_SPRITE_PATH := "Right/Sprite2D"
const SCORE_TEXTURES: Array[Texture2D] = [
	preload("res://assests/1.png"),
	preload("res://assests/2.png"),
	preload("res://assests/3.png"),
	preload("res://assests/4.png"),
	preload("res://assests/5.png"),
]

var score_left := 0
var score_right := 0
var game_over := false
var returning_to_leaderboard := false
var balls: Array[Area2D] = []
var ball_spawn_position := Vector2.ZERO
var ball_two_spawn_position := Vector2.ZERO
var practice_mode := false
var target_win_score := WIN_SCORE
var _last_score_ms_by_ball: Dictionary = {}

@onready var ball: Area2D = $Ball
@onready var ball_two: Area2D = get_node_or_null("BallTwo") as Area2D
@onready var left_score_label: Label = $UI/LeftScoreLabel
@onready var right_score_label: Label = $UI/RightScoreLabel
@onready var left_score_sprite: Sprite2D = get_node_or_null("UI/p1 score") as Sprite2D
@onready var right_score_sprite: Sprite2D = get_node_or_null("UI/p2 score") as Sprite2D
@onready var winner_label: Label = $UI/WinnerLabel
@onready var left_paddle: Area2D = $Left
@onready var right_paddle: Area2D = $Right


func _ready() -> void:
	ball_spawn_position = ball.position
	if ball_two != null:
		ball_two_spawn_position = ball_two.position
	balls = [ball]
	practice_mode = GlobalData.is_practice_round()
	target_win_score = 1 if practice_mode else WIN_SCORE
	_apply_paddle_visuals()
	_apply_round_state()
	_update_score_display()
	winner_label.visible = false
	if left_score_label:
		left_score_label.visible = false
	if right_score_label:
		right_score_label.visible = false


func _input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		_return_to_leaderboard()
	if game_over and event is InputEventJoypadButton and event.pressed:
		if GlobalData.is_player_confirm_event(event, 1) or GlobalData.is_player_confirm_event(event, 2):
			_return_to_leaderboard()


func goal_scored(side: StringName, scoring_ball: Area2D = null) -> void:
	if game_over:
		return
	if scoring_ball != null:
		var ball_id := scoring_ball.get_instance_id()
		var now_ms := Time.get_ticks_msec()
		var last_ms := int(_last_score_ms_by_ball.get(ball_id, -1000))
		if now_ms - last_ms < 120:
			return
		_last_score_ms_by_ball[ball_id] = now_ms
	if side == "left":
		score_left += 1
	else:
		score_right += 1
	_update_score_display()
	if balls.size() >= 2 and scoring_ball != null:
		_reset_single_ball(scoring_ball)
	else:
		_reset_all_balls()
	if score_left >= target_win_score or score_right >= target_win_score:
		game_over = true
		for current_ball in balls:
			current_ball.set_process(false)
		if practice_mode:
			await get_tree().create_timer(0.25).timeout
			_start_actual_minigame()
		else:
			if score_left >= target_win_score:
				GlobalData.award_win(1)
				winner_label.text = "Left wins!"
			else:
				GlobalData.award_win(2)
				winner_label.text = "Right wins!"
			winner_label.visible = true
			_queue_leaderboard_return()
	else:
		_apply_round_state()


func _update_score_display() -> void:
	if left_score_label:
		left_score_label.text = str(score_left)
	if right_score_label:
		right_score_label.text = str(score_right)
	_update_score_sprite(left_score_sprite, score_left)
	_update_score_sprite(right_score_sprite, score_right)


func _queue_leaderboard_return() -> void:
	await get_tree().create_timer(RETURN_DELAY).timeout
	_return_to_leaderboard()

func _return_to_leaderboard() -> void:
	if returning_to_leaderboard:
		return
	returning_to_leaderboard = true
	get_tree().change_scene_to_file(LEADERBOARD_SCENE_PATH)

func get_max_ball_speed() -> float:
	var max_speed := 360.0
	for current_ball in balls:
		if current_ball != null and current_ball.has_method("get_current_speed"):
			max_speed = maxf(max_speed, float(current_ball.call("get_current_speed")))
	return max_speed

func _round_number() -> int:
	return score_left + score_right + 1

func _apply_round_state() -> void:
	var round := _round_number()
	var desired_ball_count := 1
	var free_movement := false
	if round >= 3:
		desired_ball_count = 2

	_ensure_ball_count(desired_ball_count)
	_apply_ball_speed_caps(desired_ball_count)
	_configure_paddle_movement(free_movement)
	_reset_all_balls()

func _ensure_ball_count(desired_count: int) -> void:
	balls = [ball]
	if desired_count >= 2 and ball_two != null:
		balls.append(ball_two)
		ball_two.visible = true
		ball_two.monitoring = true
		ball_two.monitorable = true
	else:
		if ball_two != null:
			ball_two.visible = false
			ball_two.set_process(false)
			ball_two.monitoring = false
			ball_two.monitorable = false

func _reset_all_balls() -> void:
	var first_ball_direction := Vector2.LEFT
	var second_ball_direction := Vector2.RIGHT
	for i in range(balls.size()):
		var current_ball := balls[i]
		if current_ball == null:
			continue
		current_ball.call("reset")
		current_ball.set_process(true)
		if current_ball == ball:
			current_ball.position = ball_spawn_position
		elif current_ball == ball_two:
			current_ball.position = ball_two_spawn_position
		else:
			current_ball.position = ball_spawn_position
		if i == 0:
			current_ball.direction = first_ball_direction
		elif i == 1:
			# Second ball is always opposite horizontal direction.
			current_ball.direction = second_ball_direction
		else:
			current_ball.direction = Vector2.RIGHT.rotated(randf_range(-0.75, 0.75))

func _reset_single_ball(scoring_ball: Area2D) -> void:
	if scoring_ball == null:
		return
	scoring_ball.call("reset")
	scoring_ball.set_process(true)
	if scoring_ball == ball:
		scoring_ball.position = ball_spawn_position
		scoring_ball.direction = Vector2.LEFT
	elif scoring_ball == ball_two:
		scoring_ball.position = ball_two_spawn_position
		scoring_ball.direction = Vector2.RIGHT
	else:
		scoring_ball.position = ball_spawn_position
		scoring_ball.direction = Vector2.LEFT

func _configure_paddle_movement(free_movement: bool) -> void:
	var left_limit := 60.0
	var right_limit := 1110.0
	var top_limit := 50.0
	var bottom_limit := 598.0
	var bounds := Rect2(Vector2(left_limit, top_limit), Vector2(right_limit - left_limit, bottom_limit - top_limit))
	var midline := 585.0
	left_paddle.call("set_free_movement", free_movement, bounds, midline)
	right_paddle.call("set_free_movement", free_movement, bounds, midline)

func _apply_paddle_visuals() -> void:
	var left_sprite := get_node_or_null(LEFT_PADDLE_SPRITE_PATH) as Sprite2D
	var right_sprite := get_node_or_null(RIGHT_PADDLE_SPRITE_PATH) as Sprite2D
	if left_sprite != null:
		var p1_path := GlobalData.get_car_texture_path(GlobalData.p1Car)
		if not p1_path.is_empty():
			left_sprite.texture = load(p1_path) as Texture2D
	if right_sprite != null:
		var p2_path := GlobalData.get_car_texture_path(GlobalData.p2Car)
		if not p2_path.is_empty():
			right_sprite.texture = load(p2_path) as Texture2D

func _update_score_sprite(score_sprite: Sprite2D, score: int) -> void:
	if score_sprite == null:
		return
	if score <= 0:
		score_sprite.visible = false
		return
	var clamped_score := mini(score, SCORE_TEXTURES.size())
	score_sprite.texture = SCORE_TEXTURES[clamped_score - 1]
	score_sprite.visible = true

func _start_actual_minigame() -> void:
	if returning_to_leaderboard:
		return
	returning_to_leaderboard = true
	GlobalData.complete_practice_round()
	get_tree().change_scene_to_file(GlobalData.get_actual_minigame_scene_path())

func is_two_ball_round() -> bool:
	return balls.size() >= 2

func _apply_ball_speed_caps(ball_count: int) -> void:
	var cap := TWO_BALL_SPEED_CAP if ball_count >= 2 else SINGLE_BALL_SPEED_CAP
	for current_ball in [ball, ball_two]:
		if current_ball != null and current_ball.has_method("set_speed_cap"):
			current_ball.call("set_speed_cap", cap)
