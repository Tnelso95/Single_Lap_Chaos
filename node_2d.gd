extends Node2D

const INTRO_SCENE_PATH := "res://minigame_intro.tscn"
const GAME_PONG := 0
const GAME_ONE_UP := 1
const GAME_PHOTO_MEMORY := 2
const GAME_DIZZY_DRIVING := 3

func _ready():
	randomize()
	spin_the_wheel()


@export var revolutions: int = 10
@export var spin_time: float = 12.0 # seconds the wheel spins
@export var game_count: int = 4 # number of available mini games

var chosen_game: int = 1
var _spin_start_rotation: float = 0.0


func spin_the_wheel():
	# Spin to a random final angle; game is derived from landing sector.
	_spin_start_rotation = rotation
	var random_degrees := randf_range(0.0, 360.0)
	var final_rotation = _spin_start_rotation + (revolutions * TAU) + deg_to_rad(random_degrees)
	var tween = create_tween()
	tween.tween_property(
		self,
		"rotation",
		final_rotation,
		spin_time
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.finished.connect(spin_finished)


func spin_finished():
	chosen_game = _game_from_landing_angle()
	print("Game chosen: ", chosen_game)
	if chosen_game == GAME_PONG:
		GlobalData.pendingMinigame = GlobalData.MINIGAME_PONG
	elif chosen_game == GAME_ONE_UP:
		GlobalData.pendingMinigame = GlobalData.MINIGAME_ONE_UP
	elif chosen_game == GAME_PHOTO_MEMORY:
		GlobalData.pendingMinigame = GlobalData.MINIGAME_PHOTO_MEMORY
	else:
		GlobalData.pendingMinigame = GlobalData.MINIGAME_DIZZY_DRIVING
	get_tree().change_scene_to_file(INTRO_SCENE_PATH)

func _game_from_landing_angle() -> int:
	# 0 deg means wheel is where it started (middle of Pong).
	# Convert to [0,360) for sector checks against the north pointer.
	var relative_degrees := fposmod(rad_to_deg(rotation - _spin_start_rotation), 360.0)
	if relative_degrees >= 315.0 or relative_degrees < 45.0:
		return GAME_PONG
	if relative_degrees < 135.0:
		return GAME_ONE_UP
	if relative_degrees < 215.0:
		return GAME_PHOTO_MEMORY
	return GAME_DIZZY_DRIVING
