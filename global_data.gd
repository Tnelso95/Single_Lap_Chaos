extends Node

const POINTS_TO_WIN := 1000.0
const MINIGAME_WIN_POINTS := 250.0
const MINIGAME_PONG := "pong"
const MINIGAME_PHOTO_MEMORY := "photo_memory"
const MINIGAME_ONE_UP := "one_up"
const MINIGAME_DIZZY_DRIVING := "dizzy_driving"

var p1Car = null
var p2Car = null

var p1Points = 0.0
var p2Points = 0.0
var p1DisplayedPoints = 0.0
var p2DisplayedPoints = 0.0
var pendingMinigame = ""

func reset_race(reset_cars: bool = false) -> void:
	p1Points = 0.0
	p2Points = 0.0
	p1DisplayedPoints = 0.0
	p2DisplayedPoints = 0.0
	pendingMinigame = ""
	if reset_cars:
		p1Car = null
		p2Car = null

func award_win(player: int, points: float = MINIGAME_WIN_POINTS) -> void:
	if player == 1:
		p1Points += points
	elif player == 2:
		p2Points += points

func has_race_winner() -> bool:
	return p1Points >= POINTS_TO_WIN or p2Points >= POINTS_TO_WIN

func get_race_winner() -> int:
	if p1Points >= POINTS_TO_WIN and p1Points >= p2Points:
		return 1
	if p2Points >= POINTS_TO_WIN:
		return 2
	return 0

func sync_displayed_points() -> void:
	p1DisplayedPoints = p1Points
	p2DisplayedPoints = p2Points

func get_car_texture_path(car_id: Variant) -> String:
	match str(car_id):
		"bluef1":
			return "res://assests/Blue F1 Car.png"
		"orangef1":
			return "res://assests/Orange F1 Car.png"
		"greennascar":
			return "res://assests/Green Nascar.png"
		"yellownascar":
			return "res://assests/Yellow Nascar.png"
		_:
			return ""

func get_car_track_scale(car_id: Variant) -> Vector2:
	match str(car_id):
		"greennascar", "yellownascar":
			return Vector2(0.007, 0.007)
		"bluef1", "orangef1":
			return Vector2(0.01, 0.01)
		_:
			return Vector2.ONE

func get_car_photo_memory_scale(car_id: Variant) -> Vector2:
	match str(car_id):
		"greennascar", "yellownascar":
			return Vector2(0.07, 0.07)
		"bluef1", "orangef1":
			return Vector2(0.1, 0.1)
		_:
			return Vector2.ONE

func get_minigame_scene_path(minigame: String = pendingMinigame) -> String:
	match minigame:
		MINIGAME_PONG:
			return "res://assests/pong.tscn"
		MINIGAME_PHOTO_MEMORY:
			return "res://photo_memory/photo_memory.tscn"
		MINIGAME_ONE_UP:
			return "res://one_up/one_up.tscn"
		MINIGAME_DIZZY_DRIVING:
			return "res://dizzy_driving/dizzy_driving.tscn"
		_:
			return ""

func get_minigame_intro_texture_path(minigame: String = pendingMinigame) -> String:
	match minigame:
		MINIGAME_PONG:
			return "res://assests/Pong Introduction Screen.png"
		MINIGAME_PHOTO_MEMORY:
			return "res://assests/photo_memory_intro.png"
		MINIGAME_ONE_UP:
			return "res://assests/OneUp Introduction Screen.png"
		MINIGAME_DIZZY_DRIVING:
			return "res://assests/dizzy_driving_intro.png"
		_:
			return ""
