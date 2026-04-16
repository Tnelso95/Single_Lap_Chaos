extends Node2D


enum Direction {UP, RIGHT, DOWN, LEFT}

const DIRECTION_TEXT := {
	Direction.UP: "Up",
	Direction.RIGHT: "Right",
	Direction.DOWN: "Down",
	Direction.LEFT: "Left",
}

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

@export var step_display_time: float = 0.7
@export var step_pause_time: float = 0.2
@export var next_round_delay: float = 0.9
@export var hide_after_sequence_delay: float = 1.00

var p1_sequence: Array[int] = []
var p2_sequence: Array[int] = []
var showing_sequence := false
var round_active := false
var game_over := false

var p1_index := 0
var p2_index := 0
var p1_failed := false
var p2_failed := false
var p1_done := false
var p2_done := false

@onready var p1_car_sprite: Sprite2D = $PlayerOneCar
@onready var p2_car_sprite: Sprite2D = $PlayerTwoCar
@onready var round_label: Label = $UI/RoundLabel
@onready var p1_sequence_label: Label = get_node_or_null("UI/PlayerOneSequenceLabel") as Label
@onready var p2_sequence_label: Label = get_node_or_null("UI/PlayerTwoSequenceLabel") as Label
@onready var prompt_label: Label = $UI/PromptLabel
@onready var p1_status_label: Label = $UI/PlayerOneStatusLabel
@onready var p2_status_label: Label = $UI/PlayerTwoStatusLabel
@onready var result_label: Label = $UI/ResultLabel


func _ready() -> void:
	randomize()
	prompt_label.visible = false
	_start_new_game()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if game_over and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			_start_new_game()


func _unhandled_input(event: InputEvent) -> void:
	if not round_active or showing_sequence or game_over:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if PLAYER_ONE_KEYS.has(event.keycode) and not p1_failed and not p1_done:
			_handle_player_input(1, PLAYER_ONE_KEYS[event.keycode])
		elif PLAYER_TWO_KEYS.has(event.keycode) and not p2_failed and not p2_done:
			_handle_player_input(2, PLAYER_TWO_KEYS[event.keycode])


func _start_new_game() -> void:
	p1_sequence.clear()
	p2_sequence.clear()
	result_label.visible = false
	game_over = false
	p1_car_sprite.visible = true
	p2_car_sprite.visible = true
	_start_next_round()


func _start_next_round() -> void:
	p1_sequence.append(_next_direction(p1_sequence))
	p2_sequence.append(_next_direction(p2_sequence))
	p1_car_sprite.visible = true
	p2_car_sprite.visible = true
	round_label.text = "Round %d" % p1_sequence.size()
	_set_label_text(p1_sequence_label, "Watch...")
	_set_label_text(p2_sequence_label, "Watch...")
	prompt_label.text = "Memorize the sequence"

	p1_index = 0
	p2_index = 0
	p1_failed = false
	p2_failed = false
	p1_done = false
	p2_done = false
	_update_status_labels()

	showing_sequence = true
	round_active = false
	_play_sequence()


func _play_sequence() -> void:
	for i in range(p1_sequence.size()):
		var p1_step: int = p1_sequence[i]
		var p2_step: int = p2_sequence[i]
		_show_car_direction(p1_car_sprite, p1_step)
		_show_car_direction(p2_car_sprite, p2_step)
		_set_label_text(p1_sequence_label, DIRECTION_TEXT[p1_step])
		_set_label_text(p2_sequence_label, DIRECTION_TEXT[p2_step])
		await get_tree().create_timer(step_display_time).timeout
		_set_label_text(p1_sequence_label, "")
		_set_label_text(p2_sequence_label, "")
		await get_tree().create_timer(step_pause_time).timeout

	await get_tree().create_timer(hide_after_sequence_delay).timeout
	p1_car_sprite.visible = false
	p2_car_sprite.visible = false
	_set_label_text(p1_sequence_label, "Your turn")
	_set_label_text(p2_sequence_label, "Your turn")
	prompt_label.text = "P1 inputs P1 chain (WASD), P2 inputs P2 chain (Arrows)"
	showing_sequence = false
	round_active = true


func _show_car_direction(car_sprite: Sprite2D, direction: int) -> void:
	match direction:
		Direction.UP:
			car_sprite.rotation_degrees = 0.0
		Direction.RIGHT:
			car_sprite.rotation_degrees = 90.0
		Direction.DOWN:
			car_sprite.rotation_degrees = 180.0
		Direction.LEFT:
			car_sprite.rotation_degrees = -90.0


func _set_label_text(label: Label, text: String) -> void:
	if label:
		label.text = text


func _next_direction(existing_sequence: Array[int]) -> int:
	var next_direction := randi() % 4
	if existing_sequence.is_empty():
		return next_direction

	var previous_direction: int = existing_sequence[existing_sequence.size() - 1]
	while next_direction == previous_direction:
		next_direction = randi() % 4
	return next_direction


func _handle_player_input(player: int, input_direction: int) -> void:
	var expected_index := p1_index if player == 1 else p2_index
	var expected_direction: int = p1_sequence[expected_index] if player == 1 else p2_sequence[expected_index]

	if input_direction != expected_direction:
		if player == 1:
			p1_failed = true
		else:
			p2_failed = true
	else:
		if player == 1:
			p1_index += 1
			p1_done = p1_index >= p1_sequence.size()
		else:
			p2_index += 1
			p2_done = p2_index >= p2_sequence.size()

	_update_status_labels()
	_resolve_round_state()


func _update_status_labels() -> void:
	if p1_failed:
		p1_status_label.text = "Player 1: Missed"
	elif p1_done:
		p1_status_label.text = "Player 1: Correct"
	else:
		p1_status_label.text = "Player 1: %d / %d" % [p1_index, p1_sequence.size()]

	if p2_failed:
		p2_status_label.text = "Player 2: Missed"
	elif p2_done:
		p2_status_label.text = "Player 2: Correct"
	else:
		p2_status_label.text = "Player 2: %d / %d" % [p2_index, p2_sequence.size()]


func _resolve_round_state() -> void:
	if not round_active:
		return

	if p1_failed and p2_failed:
		_end_game("Tie! Both players missed the chain.")
		return

	if p1_failed and p2_done:
		_end_game("Player 2 wins! Player 1 missed.")
		return

	if p2_failed and p1_done:
		_end_game("Player 1 wins! Player 2 missed.")
		return

	if p1_done and p2_done:
		round_active = false
		prompt_label.text = "Both players got it. Next round..."
		_begin_next_round_after_delay()
		return

	if p1_failed or p2_failed:
		prompt_label.text = "One player missed. Waiting on the other..."
	else:
		prompt_label.text = "Keep entering the chain"


func _begin_next_round_after_delay() -> void:
	await get_tree().create_timer(next_round_delay).timeout
	if not game_over:
		_start_next_round()


func _end_game(result_text: String) -> void:
	round_active = false
	showing_sequence = false
	game_over = true
	result_label.visible = true
	result_label.text = result_text
	prompt_label.text = "Press Enter to play again"
