extends CharacterBody2D

const INTENT_THROTTLE := 0
const INTENT_BRAKE := 1
const INTENT_LEFT := 2
const INTENT_RIGHT := 3

@export var move_speed: float = 1150.0
@export var turn_speed: float = 5.0
@export var use_player_one_controls: bool = false
@export var randomize_inputs: bool = true
@export var remap_min_seconds: float = 3.0
@export var remap_max_seconds: float = 5.0

var _throttle: float = 0.0
var _seconds_until_remap: float = 0.0
var _key_to_intent: Dictionary = {}
var _control_keys: Array[int] = []
var _controller_channel_to_intent: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _using_random_mapping := false
var _wall_rumble_cooldown := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_rng.randomize()
	_control_keys = _default_keys()
	_apply_default_mapping()
	_using_random_mapping = false
	_schedule_next_remap()

func _physics_process(delta: float) -> void:
	_wall_rumble_cooldown = maxf(0.0, _wall_rumble_cooldown - delta)
	if randomize_inputs:
		_seconds_until_remap -= delta
		if _seconds_until_remap <= 0.0:
			_toggle_mapping_phase()
			_schedule_next_remap()

	_throttle = _axis(_intent_pressed(INTENT_BRAKE), _intent_pressed(INTENT_THROTTLE))
	var steer := _axis(_intent_pressed(INTENT_LEFT), _intent_pressed(INTENT_RIGHT))

	rotation += steer * turn_speed * delta
	velocity = transform.x * move_speed * _throttle
	move_and_slide()
	if _wall_rumble_cooldown <= 0.0 and get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision := get_slide_collision(i)
			if collision and collision.get_collider() is StaticBody2D:
				var player := 1 if use_player_one_controls else 2
				GlobalData.rumble_player(player, 0.5, 0.95, 0.1)
				_wall_rumble_cooldown = 0.18
				break

func set_car_visual(car_id: Variant) -> void:
	var texture_path := GlobalData.get_car_texture_path(car_id)
	if texture_path.is_empty():
		return
	sprite.texture = load(texture_path)
	if car_id == "greennascar" or car_id == "yellownascar":
		sprite.scale = Vector2(0.08, 0.08)
	else:
		sprite.scale = Vector2(0.1, 0.1)

func _axis(negative_pressed: bool, positive_pressed: bool) -> float:
	return float(positive_pressed) - float(negative_pressed)

func _default_keys() -> Array[int]:
	if use_player_one_controls:
		return [KEY_W, KEY_A, KEY_S, KEY_D]
	return [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]

func _apply_default_mapping() -> void:
	_key_to_intent.clear()
	_key_to_intent[_control_keys[0]] = INTENT_THROTTLE
	_key_to_intent[_control_keys[1]] = INTENT_LEFT
	_key_to_intent[_control_keys[2]] = INTENT_BRAKE
	_key_to_intent[_control_keys[3]] = INTENT_RIGHT
	_controller_channel_to_intent = [
		INTENT_THROTTLE, # channel 0
		INTENT_LEFT,     # channel 1
		INTENT_BRAKE,    # channel 2
		INTENT_RIGHT,    # channel 3
	]

func _intent_pressed(intent: int) -> bool:
	for key in _key_to_intent.keys():
		if _key_to_intent[key] == intent and _is_control_key_pressed(key):
			return true
	if _controller_pressed(intent):
		return true
	return false

func _is_control_key_pressed(key: int) -> bool:
	return Input.is_physical_key_pressed(key) or Input.is_key_pressed(key)

func _schedule_next_remap() -> void:
	var min_seconds := minf(remap_min_seconds, remap_max_seconds)
	var max_seconds := maxf(remap_min_seconds, remap_max_seconds)
	_seconds_until_remap = _rng.randf_range(min_seconds, max_seconds)

func _shuffle_mapping() -> void:
	var previous: Dictionary = _key_to_intent.duplicate()
	var intents := [INTENT_THROTTLE, INTENT_LEFT, INTENT_BRAKE, INTENT_RIGHT]
	var attempts := 0

	while attempts < 8:
		attempts += 1
		intents.shuffle()
		for i in range(_control_keys.size()):
			_key_to_intent[_control_keys[i]] = intents[i]
		if _key_to_intent != previous:
			_controller_channel_to_intent.clear()
			for value in intents:
				_controller_channel_to_intent.append(int(value))
			break

func _toggle_mapping_phase() -> void:
	if _using_random_mapping:
		_apply_default_mapping()
	else:
		_shuffle_mapping()
	_using_random_mapping = not _using_random_mapping

func _controller_pressed(intent: int) -> bool:
	var player := 1 if use_player_one_controls else 2
	var device: int = GlobalData.get_player_device(player)
	if device < 0:
		return false

	var left_x := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var left_y := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	var rt := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT)
	var lt := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)

	var channel_pressed := [
		# Channel 0: throttle
		GlobalData.is_player_face_button_pressed(player, "A")
			or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)
			or left_y <= -0.5
			or rt >= 0.3,
		# Channel 1: left
		Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)
			or left_x <= -0.5,
		# Channel 2: reverse
		GlobalData.is_player_face_button_pressed(player, "B")
			or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)
			or left_y >= 0.5
			or lt >= 0.3,
		# Channel 3: right
		Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)
			or left_x >= 0.5,
	]
	for i in range(_controller_channel_to_intent.size()):
		if _controller_channel_to_intent[i] == intent and channel_pressed[i]:
			return true
	return false

func get_seconds_until_remap() -> int:
	if not randomize_inputs:
		return 0
	return clampi(int(ceili(_seconds_until_remap)), 1, 5)

func force_shuffle_now() -> void:
	_toggle_mapping_phase()
