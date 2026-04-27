extends Node2D

const PRACTICE_DURATION := 10.0
const SHUFFLE_MIN_SECONDS := 3.0
const SHUFFLE_MAX_SECONDS := 5.0
const SHUFFLE_COUNTDOWN_TEXTURES: Array[Texture2D] = [
	preload("res://assests/1.png"),
	preload("res://assests/2.png"),
	preload("res://assests/3.png"),
	preload("res://assests/4.png"),
	preload("res://assests/5.png"),
]

@onready var player_one_car: CharacterBody2D = $PlayerOneCar
@onready var player_two_car: CharacterBody2D = $PlayerTwoCar
@onready var banner_label: Label = get_node_or_null("UI/PracticeLabel") as Label
@onready var banner_sprite: Sprite2D = get_node_or_null("practice_label") as Sprite2D
@onready var countdown_label: Label = get_node_or_null("UI/CountdownLabel") as Label
@onready var shuffle_countdown_sprite: Sprite2D = get_node_or_null("ShuffleCountdown") as Sprite2D

var transitioning := false
var _shuffle_rng := RandomNumberGenerator.new()
var _seconds_until_shuffle := 0.0

func _ready() -> void:
	player_one_car.set_car_visual(GlobalData.p1Car)
	player_two_car.set_car_visual(GlobalData.p2Car)
	player_one_car.randomize_inputs = false
	player_two_car.randomize_inputs = false
	if banner_label:
		banner_label.text = "Practice Round - Learn controls (%ds)" % int(PRACTICE_DURATION)
	if banner_sprite:
		banner_sprite.visible = true
	_shuffle_rng.randomize()
	_schedule_next_shuffle()
	_start_timer()

func _physics_process(delta: float) -> void:
	if transitioning:
		return
	_seconds_until_shuffle -= delta
	if _seconds_until_shuffle <= 0.0:
		player_one_car.force_shuffle_now()
		player_two_car.force_shuffle_now()
		_schedule_next_shuffle()
	_update_shuffle_countdown()

func _start_timer() -> void:
	var seconds_left := int(PRACTICE_DURATION)
	while seconds_left > 0:
		if countdown_label:
			countdown_label.text = str(seconds_left)
		await get_tree().create_timer(1.0).timeout
		seconds_left -= 1
	if countdown_label:
		countdown_label.text = "GO!"
		await get_tree().create_timer(0.35).timeout
	_start_actual_minigame()

func _start_actual_minigame() -> void:
	if transitioning:
		return
	transitioning = true
	GlobalData.complete_practice_round()
	get_tree().change_scene_to_file(GlobalData.get_actual_minigame_scene_path())

func _schedule_next_shuffle() -> void:
	var min_seconds := minf(SHUFFLE_MIN_SECONDS, SHUFFLE_MAX_SECONDS)
	var max_seconds := maxf(SHUFFLE_MIN_SECONDS, SHUFFLE_MAX_SECONDS)
	_seconds_until_shuffle = _shuffle_rng.randf_range(min_seconds, max_seconds)

func _update_shuffle_countdown() -> void:
	if shuffle_countdown_sprite == null:
		return
	var seconds_to_show: int = clampi(int(ceili(_seconds_until_shuffle)), 1, 5)
	var texture_index := clampi(seconds_to_show - 1, 0, SHUFFLE_COUNTDOWN_TEXTURES.size() - 1)
	shuffle_countdown_sprite.texture = SHUFFLE_COUNTDOWN_TEXTURES[texture_index]
	shuffle_countdown_sprite.visible = true
