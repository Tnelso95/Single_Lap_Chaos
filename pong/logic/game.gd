extends Node2D

const WIN_SCORE := 5

var score_left := 0
var score_right := 0
var game_over := false

@onready var ball: Area2D = $Ball
@onready var left_score_label: Label = $UI/LeftScoreLabel
@onready var right_score_label: Label = $UI/RightScoreLabel
@onready var winner_label: Label = $UI/WinnerLabel


func _ready() -> void:
	_update_score_display()
	winner_label.visible = false


func _input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		_restart_game()


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
			winner_label.text = "Left wins!"
		else:
			winner_label.text = "Right wins!"
		winner_label.visible = true


func _update_score_display() -> void:
	left_score_label.text = str(score_left)
	right_score_label.text = str(score_right)


func _restart_game() -> void:
	score_left = 0
	score_right = 0
	game_over = false
	_update_score_display()
	winner_label.visible = false
	ball.set_process(true)
	ball.reset()
