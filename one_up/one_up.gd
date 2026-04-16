extends Control

const LEADERBOARD_SCENE_PATH := "res://leaderboard.tscn"
const RETURN_DELAY := 2.0
const TURN_SWAP_DELAY := 1.0

enum Direction { UP, RIGHT, DOWN, LEFT }

const PLAYER_ONE_KEYS := {
	KEY_W: Direction.UP,
	KEY_D: Direction.RIGHT,
	KEY_S: Direction.DOWN,
	KEY_A: Direction.LEFT,
}

const PLAYER_TWO_KEYS := {
	KEY_UP: Direction.UP,
	KEY_RIGHT: Direction.RIGHT,
	KEY_DOWN: Direction.DOWN,
	KEY_LEFT: Direction.LEFT,
}

const DIRECTION_TEXT := {
	Direction.UP: "Up",
	Direction.RIGHT: "Right",
	Direction.DOWN: "Down",
	Direction.LEFT: "Left",
}

@onready var p1_score_label: Label = $UI/PlayerOneScoreLabel
@onready var p2_score_label: Label = $UI/PlayerTwoScoreLabel
@onready var result_label: Label = $UI/ResultLabel
@onready var prompt_label: Label = $UI/PromptLabel
@onready var icon: TextureRect = $Icon

var game_over := false
var transitioning := false
var active_player := 1
var chain: Array[int] = []
var replay_index := 0
var waiting_for_new_step := true
var input_locked := false

func _ready() -> void:
	result_label.visible = false
	icon.pivot_offset = icon.size / 2.0
	_start_new_round()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if game_over or input_locked:
		return
	var input_direction := _direction_for_active_player(event.keycode)
	if input_direction == -1:
		return
	_show_direction(input_direction)
	if waiting_for_new_step:
		_add_step_and_pass_turn(input_direction)
		return
	var expected_direction := chain[replay_index]
	if input_direction != expected_direction:
		var winner := 2 if active_player == 1 else 1
		_end_game(winner, "Player %d broke the chain." % active_player)
		return
	replay_index += 1
	if replay_index >= chain.size():
		waiting_for_new_step = true
		prompt_label.text = "Correct. Player %d add one new direction." % active_player
	else:
		prompt_label.text = "Player %d: keep replaying (%d/%d)." % [active_player, replay_index, chain.size()]

func _end_game(winner: int, text: String) -> void:
	game_over = true
	GlobalData.award_win(winner)
	result_label.text = "Player %d wins One Up!\n%s" % [winner, text]
	result_label.visible = true
	prompt_label.text = "Returning to leaderboard..."
	_queue_return()

func _queue_return() -> void:
	await get_tree().create_timer(RETURN_DELAY).timeout
	_return_to_leaderboard()

func _return_to_leaderboard() -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().change_scene_to_file(LEADERBOARD_SCENE_PATH)

func _start_new_round() -> void:
	chain.clear()
	active_player = 1
	replay_index = 0
	waiting_for_new_step = true
	input_locked = false
	_prepare_active_player_turn("Player 1 starts: add the first direction.")

func _add_step_and_pass_turn(input_direction: int) -> void:
	chain.append(input_direction)
	input_locked = true
	prompt_label.text = "Chain extended. Switching turns..."
	await get_tree().create_timer(TURN_SWAP_DELAY).timeout
	if game_over:
		return
	active_player = 2 if active_player == 1 else 1
	replay_index = 0
	waiting_for_new_step = false
	input_locked = false
	_prepare_active_player_turn("Player %d replay the chain (%d step%s), then add one." % [
		active_player,
		chain.size(),
		"" if chain.size() == 1 else "s"
	])

func _update_turn_labels() -> void:
	p1_score_label.text = "Player 1%s" % (" <- Turn" if active_player == 1 else "")
	p2_score_label.text = "Player 2%s" % (" <- Turn" if active_player == 2 else "")

func _direction_for_active_player(keycode: int) -> int:
	var key_map := PLAYER_ONE_KEYS if active_player == 1 else PLAYER_TWO_KEYS
	if key_map.has(keycode):
		return key_map[keycode]
	return -1

func _show_direction(direction: int) -> void:
	prompt_label.text = "Player %d input: %s" % [active_player, DIRECTION_TEXT[direction]]
	match direction:
		Direction.UP:
			icon.rotation_degrees = 0.0
		Direction.RIGHT:
			icon.rotation_degrees = 90.0
		Direction.DOWN:
			icon.rotation_degrees = 180.0
		Direction.LEFT:
			icon.rotation_degrees = -90.0

func _prepare_active_player_turn(prompt_text: String) -> void:
	_update_turn_labels()
	_set_active_player_car()
	icon.rotation_degrees = 0.0
	prompt_label.text = prompt_text

func _set_active_player_car() -> void:
	var car_id = GlobalData.p1Car if active_player == 1 else GlobalData.p2Car
	var texture_path := GlobalData.get_car_texture_path(car_id)
	if texture_path.is_empty():
		return
	icon.texture = load(texture_path)
