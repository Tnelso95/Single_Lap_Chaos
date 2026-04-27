extends Node

const POINTS_TO_WIN := 100.0
const MINIGAME_WIN_POINTS := POINTS_TO_WIN * 0.25
const MINIGAME_PONG := "pong"
const MINIGAME_PHOTO_MEMORY := "photo_memory"
const MINIGAME_ONE_UP := "one_up"
const MINIGAME_DIZZY_DRIVING := "dizzy_driving"

var p1Car = null
var p2Car = null
var winner = null

var p1Points = 0.0
var p2Points = 0.0
var p1DisplayedPoints = 0.0
var p2DisplayedPoints = 0.0
var pendingMinigame = ""
var practiceRoundActive := false
var demoWheelSpinIndex := 0
var p1ControllerDevice := -1
var p2ControllerDevice := -1
var _rumble_request_id_by_device: Dictionary = {}

func reset_race(reset_cars: bool = false) -> void:
	p1Points = 0.0
	p2Points = 0.0
	p1DisplayedPoints = 0.0
	p2DisplayedPoints = 0.0
	pendingMinigame = ""
	practiceRoundActive = false
	demoWheelSpinIndex = 0
	if reset_cars:
		p1Car = null
		p2Car = null

func set_pending_minigame(minigame: String) -> void:
	pendingMinigame = minigame
	practiceRoundActive = true

func is_practice_round() -> bool:
	return practiceRoundActive

func complete_practice_round() -> void:
	practiceRoundActive = false

func get_next_demo_minigame() -> String:
	var demo_order: Array[String] = [
		MINIGAME_PONG,
		MINIGAME_PHOTO_MEMORY,
		MINIGAME_DIZZY_DRIVING,
		MINIGAME_ONE_UP,
	]
	var minigame: String = demo_order[demoWheelSpinIndex % demo_order.size()]
	demoWheelSpinIndex += 1
	return minigame

func get_actual_minigame_scene_path(minigame: String = pendingMinigame) -> String:
	match minigame:
		MINIGAME_PONG:
			return "res://pong/pong.tscn"
		MINIGAME_PHOTO_MEMORY:
			return "res://photo_memory/photo_memory.tscn"
		MINIGAME_ONE_UP:
			return "res://one_up/one_up.tscn"
		MINIGAME_DIZZY_DRIVING:
			return "res://dizzy_driving/dizzy_driving.tscn"
		_:
			return ""

func award_win(player: int, points: float = MINIGAME_WIN_POINTS) -> void:
	if player == 1:
		p1Points += points
	elif player == 2:
		p2Points += points

func has_race_winner() -> bool:
	if p1Points >= POINTS_TO_WIN:
		winner = "player1"
	if p2Points >= POINTS_TO_WIN:
		winner = "player2"
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
	if practiceRoundActive and minigame == MINIGAME_DIZZY_DRIVING:
		return "res://dizzy_driving/dizzy_practice.tscn"
	if practiceRoundActive and minigame == MINIGAME_PONG:
		return "res://pong/pong_practice.tscn"
	if practiceRoundActive and minigame == MINIGAME_PHOTO_MEMORY:
		return "res://photo_memory/photo_memory_practice.tscn"
	if practiceRoundActive and minigame == MINIGAME_ONE_UP:
		return "res://one_up/one_up_practice.tscn"
	match minigame:
		MINIGAME_PONG:
			return "res://pong/pong.tscn"
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

func _ready() -> void:
	refresh_controller_assignments()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	refresh_controller_assignments()

func refresh_controller_assignments() -> void:
	var joypads: Array = Input.get_connected_joypads()
	p1ControllerDevice = -1
	p2ControllerDevice = -1
	var xbox_device := -1
	var switch_device := -1
	for raw_device in joypads:
		var device: int = int(raw_device)
		var joy_name := Input.get_joy_name(device).to_lower()
		if xbox_device < 0 and joy_name.contains("xbox"):
			xbox_device = device
		if switch_device < 0 and (joy_name.contains("switch") or joy_name.contains("joy-con") or joy_name.contains("nintendo")):
			switch_device = device
	if xbox_device >= 0:
		p1ControllerDevice = xbox_device
	elif joypads.size() > 0:
		p1ControllerDevice = int(joypads[0])
	if switch_device >= 0 and switch_device != p1ControllerDevice:
		p2ControllerDevice = switch_device
	else:
		for raw_device in joypads:
			var candidate: int = int(raw_device)
			if candidate != p1ControllerDevice:
				p2ControllerDevice = candidate
				break

func get_player_device(player: int) -> int:
	if player == 1:
		return p1ControllerDevice
	if player == 2:
		return p2ControllerDevice
	return -1

func is_player_confirm_event(event: InputEvent, player: int) -> bool:
	return is_player_face_button_event(event, player, "A")

func _is_switch_layout_device(device: int) -> bool:
	if device < 0:
		return false
	var joy_name := Input.get_joy_name(device).to_lower()
	return joy_name.contains("switch") or joy_name.contains("joy-con") or joy_name.contains("nintendo")

func get_player_face_button_index(player: int, button_name: String) -> int:
	var device := get_player_device(player)
	var is_switch := _is_switch_layout_device(device)
	match button_name:
		"A":
			return JOY_BUTTON_B if is_switch else JOY_BUTTON_A
		"B":
			return JOY_BUTTON_A if is_switch else JOY_BUTTON_B
		"X":
			return JOY_BUTTON_Y if is_switch else JOY_BUTTON_X
		"Y":
			return JOY_BUTTON_X if is_switch else JOY_BUTTON_Y
		_:
			return -1

func is_player_face_button_event(event: InputEvent, player: int, button_name: String) -> bool:
	if not (event is InputEventJoypadButton):
		return false
	var button_event := event as InputEventJoypadButton
	if not button_event.pressed:
		return false
	var device := get_player_device(player)
	if device < 0 or button_event.device != device:
		return false
	var target_button := get_player_face_button_index(player, button_name)
	return target_button >= 0 and button_event.button_index == target_button

func is_player_face_button_pressed(player: int, button_name: String) -> bool:
	var device := get_player_device(player)
	if device < 0:
		return false
	var target_button := get_player_face_button_index(player, button_name)
	if target_button < 0:
		return false
	return Input.is_joy_button_pressed(device, target_button)

func rumble_player(player: int, weak: float = 0.45, strong: float = 0.75, duration: float = 0.12) -> void:
	var device := get_player_device(player)
	if device < 0:
		return
	var clamped_duration := maxf(duration, 0.01)
	var request_id := int(_rumble_request_id_by_device.get(device, 0)) + 1
	_rumble_request_id_by_device[device] = request_id
	Input.start_joy_vibration(
		device,
		clampf(weak, 0.0, 1.0),
		clampf(strong, 0.0, 1.0),
		clamped_duration
	)
	_stop_rumble_after(device, request_id, clamped_duration)

func _stop_rumble_after(device: int, request_id: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if int(_rumble_request_id_by_device.get(device, 0)) != request_id:
		return
	Input.stop_joy_vibration(device)
