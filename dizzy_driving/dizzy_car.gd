extends CharacterBody2D

const INTENT_THROTTLE := 0
const INTENT_BRAKE := 1
const INTENT_LEFT := 2
const INTENT_RIGHT := 3

@export var move_speed: float = 700.0
@export var turn_speed: float = 4.2
@export var use_player_one_controls: bool = false
@export var randomize_inputs: bool = true
@export var remap_min_seconds: float = 3.0
@export var remap_max_seconds: float = 5.0

var _throttle: float = 0.0
var _seconds_until_remap: float = 0.0
var _key_to_intent: Dictionary = {}
var _control_keys: Array[int] = []
var _rng := RandomNumberGenerator.new()
var _using_random_mapping := false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_rng.randomize()
	_control_keys = _default_keys()
	_apply_default_mapping()
	_using_random_mapping = false
	_schedule_next_remap()

func _physics_process(delta: float) -> void:
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

func _intent_pressed(intent: int) -> bool:
	for key in _key_to_intent.keys():
		if _key_to_intent[key] == intent and _is_control_key_pressed(key):
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
			break

func _toggle_mapping_phase() -> void:
	if _using_random_mapping:
		_apply_default_mapping()
	else:
		_shuffle_mapping()
	_using_random_mapping = not _using_random_mapping
