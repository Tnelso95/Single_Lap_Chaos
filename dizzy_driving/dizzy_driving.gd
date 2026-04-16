extends Node2D

const LEADERBOARD_SCENE_PATH := "res://leaderboard.tscn"
const RETURN_DELAY := 2.0

@onready var player_one_car: CharacterBody2D = $PlayerOneCar
@onready var player_two_car: CharacterBody2D = $PlayerTwoCar
@onready var status_label: Label = get_node_or_null("UI/StatusLabel") as Label
@onready var winner_label: Label = get_node_or_null("UI/WinnerLabel") as Label

var game_over := false
var transitioning := false

func _ready() -> void:
	player_one_car.rotation = 0.0
	player_two_car.rotation = 0.0
	player_one_car.set_car_visual(GlobalData.p1Car)
	player_two_car.set_car_visual(GlobalData.p2Car)
	if winner_label:
		winner_label.visible = false
	if status_label:
		status_label.text = "Dizzy Driving: reach the finish line first!"

func _on_finish_line_body_entered(body: Node) -> void:
	if game_over:
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
