extends Area2D


const BASE_MOVE_SPEED = 330.0
const MAX_SPEED_MULTIPLIER = 2.8
const PONG_HIT_SOUND_PATHS := [
	"res://assests/sounds/pong_hit.mp3",
	"res://sounds_assets/click_sound.mp3",
]

var _ball_dir: int
var _up: String
var _down: String
var _hit_player: AudioStreamPlayer
var _is_left_paddle := true
var _player := 1
var _free_movement := false
var _play_bounds := Rect2()
var _midline_x := 0.0

@onready var _screen_size_y: float = get_viewport_rect().size.y
@onready var _ball: Area2D = get_parent().get_node("Ball") as Area2D


func _ready() -> void:
	var n := str(name).to_lower()
	_up = n + "_move_up"
	_down = n + "_move_down"
	_is_left_paddle = n == "left"
	_player = 1 if _is_left_paddle else 2
	_ball_dir = 1 if n == "left" else -1
	_hit_player = AudioStreamPlayer.new()
	var hit_stream := _load_first_existing_sound(PONG_HIT_SOUND_PATHS)
	if hit_stream:
		_hit_player.stream = hit_stream
	_hit_player.bus = "Master"
	add_child(_hit_player)


func _process(delta: float) -> void:
	var vertical_input := _vertical_input()
	var move_speed := BASE_MOVE_SPEED * _ball_speed_multiplier()
	position.y += vertical_input * move_speed * delta
	if _free_movement:
		position.x += _horizontal_input() * move_speed * delta
		_apply_free_movement_bounds()
	else:
		position.y = clamp(position.y, 50.0, _screen_size_y - 50.0)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("pong_ball"):
		var bounced := true
		if area.has_method("bounce_from_paddle"):
			bounced = bool(area.call("bounce_from_paddle", float(_ball_dir)))
		else:
			area.direction = Vector2(_ball_dir, area.direction.y).normalized()
		if not bounced:
			return
		if area.has_method("add_speed"):
			area.call("add_speed", 50.0)
		area.direction.y = clampf(area.direction.y + randf_range(-0.18, 0.18), -0.92, 0.92)
		area.direction = area.direction.normalized()
		GlobalData.rumble_player(_player, 0.5, 0.9, 0.12)
		if _hit_player.stream:
			_hit_player.play()

func _load_first_existing_sound(paths: Array) -> AudioStream:
	for raw_path in paths:
		var path := str(raw_path)
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null

func _ball_speed_multiplier() -> float:
	var tracked_ball_speed := 0.0
	if _ball != null and _ball.has_method("get_current_speed"):
		tracked_ball_speed = maxf(tracked_ball_speed, float(_ball.call("get_current_speed")))
	var parent := get_parent()
	if parent != null and parent.has_method("get_max_ball_speed"):
		tracked_ball_speed = maxf(tracked_ball_speed, float(parent.call("get_max_ball_speed")))
	if tracked_ball_speed <= 0.0:
		return 1.0
	# Slightly stronger response so speed-up is obvious in gameplay.
	var multiplier := tracked_ball_speed / 330.0
	return clampf(multiplier, 1.0, MAX_SPEED_MULTIPLIER)

func set_free_movement(enabled: bool, bounds: Rect2, midline_x: float) -> void:
	_free_movement = enabled
	_play_bounds = bounds
	_midline_x = midline_x

func _horizontal_input() -> float:
	var keyboard_input := 0.0
	if _is_left_paddle:
		# Player 1 free movement: WASD
		keyboard_input = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	else:
		# Player 2 free movement: Arrow keys
		keyboard_input = float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT))

	var controller_input := 0.0
	var device: int = GlobalData.get_player_device(_player)
	if device >= 0:
		var axis := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var dpad_right := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)
		var dpad_left := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)
		var dpad_input := float(dpad_right) - float(dpad_left)
		var axis_input := axis if absf(axis) >= 0.25 else 0.0
		controller_input = dpad_input if absf(dpad_input) > absf(axis_input) else axis_input

	return controller_input if absf(controller_input) > absf(keyboard_input) else keyboard_input

func _vertical_input() -> float:
	var keyboard_input := Input.get_action_strength(_down) - Input.get_action_strength(_up)
	var controller_input := 0.0
	var device: int = GlobalData.get_player_device(_player)
	if device >= 0:
		var axis := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		var dpad_down := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)
		var dpad_up := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)
		var dpad_input := float(dpad_down) - float(dpad_up)
		var axis_input := axis if absf(axis) >= 0.25 else 0.0
		controller_input = dpad_input if absf(dpad_input) > absf(axis_input) else axis_input
	return controller_input if absf(controller_input) > absf(keyboard_input) else keyboard_input

func _apply_free_movement_bounds() -> void:
	position.y = clamp(position.y, _play_bounds.position.y, _play_bounds.end.y)
	if _is_left_paddle:
		position.x = clamp(position.x, _play_bounds.position.x, _midline_x)
	else:
		position.x = clamp(position.x, _midline_x, _play_bounds.end.x)
