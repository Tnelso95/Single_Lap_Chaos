extends Node2D

const INTRO_SCENE_PATH := "res://minigame_intro.tscn"
const GAME_PONG := 0
const GAME_DIZZY_DRIVING := 1
const GAME_PHOTO_MEMORY := 2
const GAME_ONE_UP := 3

func _ready():
	randomize()
	spin_the_wheel()


@export var revolutions: int = 10
@export var spin_time: float = 12.0 # seconds the wheel spins
@export var game_count: int = 4 # number of available mini games

var chosen_game: int = 1
var _spin_start_rotation: float = 0.0


func spin_the_wheel():
	# Spin to the preset demo game so visual landing matches selected game.
	GlobalData.rumble_player(1, 0.55, 0.95, 1.0)
	GlobalData.rumble_player(2, 0.55, 0.95, 1.0)
	_spin_start_rotation = rotation
	var scheduled_minigame: String = GlobalData.get_next_demo_minigame()
	chosen_game = _game_from_minigame_key(scheduled_minigame)
	var target_degrees: float = _center_angle_for_game(chosen_game)
	var final_rotation = _spin_start_rotation + (revolutions * TAU) + deg_to_rad(target_degrees)
	var tween = create_tween()
	tween.tween_property(
		self,
		"rotation",
		final_rotation,
		spin_time
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.finished.connect(spin_finished)


func spin_finished():
	print("Game chosen: ", chosen_game)
	if chosen_game == GAME_PONG:
		GlobalData.set_pending_minigame(GlobalData.MINIGAME_PONG)
	elif chosen_game == GAME_ONE_UP:
		GlobalData.set_pending_minigame(GlobalData.MINIGAME_ONE_UP)
	elif chosen_game == GAME_PHOTO_MEMORY:
		GlobalData.set_pending_minigame(GlobalData.MINIGAME_PHOTO_MEMORY)
	else:
		GlobalData.set_pending_minigame(GlobalData.MINIGAME_DIZZY_DRIVING)
	get_tree().change_scene_to_file(INTRO_SCENE_PATH)

func _game_from_landing_angle() -> int:
	# 0 deg means wheel is where it started (middle of Pong).
	# Convert to [0,360) for sector checks against the north pointer.
	var relative_degrees := fposmod(rad_to_deg(rotation - _spin_start_rotation), 360.0)
	if relative_degrees >= 315.0 or relative_degrees < 45.0:
		return GAME_PONG
	if relative_degrees < 135.0:
		return GAME_DIZZY_DRIVING
	if relative_degrees < 215.0:
		return GAME_PHOTO_MEMORY
	return GAME_ONE_UP

func _game_from_minigame_key(minigame: String) -> int:
	if minigame == GlobalData.MINIGAME_PONG:
		return GAME_PONG
	if minigame == GlobalData.MINIGAME_DIZZY_DRIVING:
		return GAME_DIZZY_DRIVING
	if minigame == GlobalData.MINIGAME_PHOTO_MEMORY:
		return GAME_PHOTO_MEMORY
	return GAME_ONE_UP

func _center_angle_for_game(game_id: int) -> float:
	match game_id:
		GAME_PONG:
			return 0.0
		GAME_DIZZY_DRIVING:
			return 90.0
		GAME_PHOTO_MEMORY:
			return 175.0
		GAME_ONE_UP:
			return 265.0
		_:
			return 0.0
