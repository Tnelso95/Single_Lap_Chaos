extends Node2D

const WIN_SCORE := 5
const LEADERBOARD_SCENE_PATH := "res://leaderboard.tscn"
const RETURN_DELAY := 2.0

var score_left := 0
var score_right := 0
var game_over := false
var returning_to_leaderboard := false

@onready var ball: Area2D = $Ball
@onready var left_score_label: Label = $UI/LeftScoreLabel
@onready var right_score_label: Label = $UI/RightScoreLabel
@onready var winner_label: Label = $UI/WinnerLabel


func _ready() -> void:
	_update_score_display()
	winner_label.visible = false


func _input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		_return_to_leaderboard()


func goal_scored(side: StringName) -> void:
	if game_over:
		return
	if side == "left":
		score_left += 1
	else:
		score_right += 1
	_update_score_display()
	ball.reset()
	if score_left >= WIN_SCORE or score_right >= WIN_SCORE:
		game_over = true
		ball.set_process(false)
		if score_left >= WIN_SCORE:
			GlobalData.award_win(1)
			winner_label.text = "Left wins!"
		else:
			GlobalData.award_win(2)
			winner_label.text = "Right wins!"
		winner_label.visible = true
		_queue_leaderboard_return()


func _update_score_display() -> void:
	left_score_label.text = str(score_left)
	right_score_label.text = str(score_right)


func _queue_leaderboard_return() -> void:
	await get_tree().create_timer(RETURN_DELAY).timeout
	_return_to_leaderboard()

func _return_to_leaderboard() -> void:
	if returning_to_leaderboard:
		return
	returning_to_leaderboard = true
	get_tree().change_scene_to_file(LEADERBOARD_SCENE_PATH)
