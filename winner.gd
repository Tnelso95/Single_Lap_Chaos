extends Node2D

var sprites = [
	preload("res://assests/Blue F1 Car.png"),
	preload("res://assests/Orange F1 Car.png"),
	preload("res://assests/Green Nascar.png"),
	preload("res://assests/Yellow Nascar.png")
]
const START_SCENE_PATH := "res://start_screen.tscn"
const TRIGGER_THRESHOLD := 0.65
const WINNER_SOUND: AudioStream = preload("res://sounds_assets/winner.mp3")
var _returning := false
var _winner_audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	_winner_audio_player.bus = "Master"
	_winner_audio_player.autoplay = false
	_winner_audio_player.volume_db = 0.0
	add_child(_winner_audio_player)
	winner_text()
	confetti()
	set_car()
	_play_winner_sound()
	
func _process(delta):
	while ($WinnerCar.position != Vector2(570,525)):
		$WinnerCar.position.x += 1
		#$WinnerCar.position.y += 1
		await get_tree().create_timer(1).timeout
	_check_return_combo()
	
	
func winner_text():
	var winner_player := GlobalData.get_race_winner()
	if winner_player == 1:
		$WinnerText.text = "Congratulations player 1!"
	if winner_player == 2:
		$WinnerText.text = "Congratulations player 2!"
		
		
func confetti():
	var confetti_textures = [
		load("res://assests/blueconfetti.png"),
		load("res://assests/pinkconfetti.png"),
		load("res://assests/yellowconfetti.png")
	]
	
	var count = 200
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var screen_size = get_viewport_rect().size
	
	for i in range(count):
		var sprite = Sprite2D.new()
		sprite.texture = confetti_textures[rng.randi_range(0, confetti_textures.size()-1)]
		sprite.position = Vector2(
			rng.randf_range(0, screen_size.x),
			-20
		)
		
		sprite.scale = Vector2(0.1, 0.1)
		add_child(sprite)
		
		var tween = create_tween()
		var velocity = Vector2(rng.randf_range(-150,150), rng.randf_range(300,800))
		tween.tween_property(
			sprite,
			"position",
			sprite.position + velocity,
			12.0
		)
		tween.parallel().tween_property(
			sprite,
			"modulate:a",
			0.0,
			10.0
		).set_delay(2.0)
		
func set_car():
	var winner_player := GlobalData.get_race_winner()
	var winner_car_id: Variant = GlobalData.p1Car if winner_player == 1 else GlobalData.p2Car
	var texture_path := GlobalData.get_car_texture_path(winner_car_id)
	if texture_path.is_empty():
		return
	$WinnerCar.texture = load(texture_path)
	if str(winner_car_id) == "greennascar" or str(winner_car_id) == "yellownascar":
		$WinnerCar.scale = Vector2(0.05, 0.05)
	else:
		$WinnerCar.scale = Vector2(0.07, 0.07)

func _check_return_combo() -> void:
	if _returning:
		return
	if _player_combo_pressed(1) or _player_combo_pressed(2):
		_returning = true
		GlobalData.reset_race(false)
		get_tree().change_scene_to_file(START_SCENE_PATH)

func _player_combo_pressed(player: int) -> bool:
	var device := GlobalData.get_player_device(player)
	if device < 0:
		return false
	var rt := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT)
	var lt := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)
	var a_pressed := GlobalData.is_player_face_button_pressed(player, "A")
	return rt >= TRIGGER_THRESHOLD and lt >= TRIGGER_THRESHOLD and a_pressed

func _play_winner_sound() -> void:
	if WINNER_SOUND == null:
		return
	_winner_audio_player.stream = WINNER_SOUND
	_winner_audio_player.play()
