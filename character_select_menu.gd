extends Node2D

const BUTTON_CLICK_SFX: AudioStream = preload("res://sounds_assets/button_click.mp3")

var sprites = [
	preload("res://assests/Blue F1 Car.png"),
	preload("res://assests/Orange F1 Car.png"),
	preload("res://assests/Green Nascar.png"),
	preload("res://assests/Yellow Nascar.png")
]

var grayed_sprites = [
	preload("res://assests/gray_bluef1.png"),
	preload("res://assests/gray_orangef1.png"),
	preload("res://assests/gray_greennascar.png"),
	preload("res://assests/gray_yellownascar.png")
]

var p1Index = 0
var p2Index = 0
var p1_axis_dir := 0
var p2_axis_dir := 0
var p1_locked := false
var p2_locked := false

@onready var p1ColorDisplay = $PlayerOneCarsColor
@onready var p1GrayDisplay = $PlayerOneCarsGray
@onready var p2ColorDisplay = $PlayerTwoCarsColor
@onready var p2GrayDisplay = $PlayerTwoCarsGray

@onready var p1Next = $PlayerOneNext
@onready var p1Previous = $PlayerOnePrevious

@onready var p2Next = $PlayerTwoNext
@onready var p2Previous = $PlayerTwoPrevious

@onready var p1Select = $PlayerOneSelect
@onready var p2Select = $PlayerTwoSelect

var _click_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	GlobalData.p1Car = null
	GlobalData.p2Car = null
	_click_player.bus = "Master"
	_click_player.autoplay = false
	_click_player.volume_db = 1.5
	add_child(_click_player)
	
	p1Next.pressed.connect(p1NextButton)
	p1Previous.pressed.connect(p1PreviousButton)
	
	p2Next.pressed.connect(p2NextButton)
	p2Previous.pressed.connect(p2PreviousButton)
	
	p1Select.pressed.connect(p1Selection)
	p2Select.pressed.connect(p2Selection)
	
	
	p1ColorDisplay.stretch_mode = $PlayerOneCarsColor.STRETCH_KEEP_ASPECT_CENTERED
	p1ColorDisplay.expand = true
	p1GrayDisplay.stretch_mode = $PlayerOneCarsGray.STRETCH_KEEP_ASPECT_CENTERED
	p1GrayDisplay.expand = true
	
	p2ColorDisplay.stretch_mode = $PlayerTwoCarsColor.STRETCH_KEEP_ASPECT_CENTERED
	p2ColorDisplay.expand = true
	p2GrayDisplay.stretch_mode = $PlayerTwoCarsGray.STRETCH_KEEP_ASPECT_CENTERED
	p2GrayDisplay.expand = true
	
	updateP1()
	updateP2()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		var joy_event := event as InputEventJoypadButton
		var p1_device := GlobalData.get_player_device(1)
		var p2_device := GlobalData.get_player_device(2)
		if joy_event.device == p1_device and GlobalData.is_player_face_button_event(event, 1, "A"):
			p1Selection()
		elif joy_event.device == p2_device and GlobalData.is_player_face_button_event(event, 2, "A"):
			p2Selection()
		elif joy_event.device == p1_device and GlobalData.is_player_face_button_event(event, 1, "B"):
			_p1Deselect()
		elif joy_event.device == p2_device and GlobalData.is_player_face_button_event(event, 2, "B"):
			_p2Deselect()
		return
	if event is InputEventJoypadMotion:
		_handle_player_axis_input(1)
		_handle_player_axis_input(2)

func _handle_player_axis_input(player: int) -> void:
	var device := GlobalData.get_player_device(player)
	if device < 0:
		return
	var axis := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var dpad_right := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)
	var dpad_left := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)
	var dir := 0
	if axis >= 0.5 or dpad_right:
		dir = 1
	elif axis <= -0.5 or dpad_left:
		dir = -1
	if player == 1:
		if dir != 0 and p1_axis_dir == 0 and not p1_locked:
			if dir > 0:
				p1NextButton()
			else:
				p1PreviousButton()
		p1_axis_dir = dir
	else:
		if dir != 0 and p2_axis_dir == 0 and not p2_locked:
			if dir > 0:
				p2NextButton()
			else:
				p2PreviousButton()
		p2_axis_dir = dir
	
	

func p1NextButton():
	var n := maxi(1, sprites.size())
	p1Index = (p1Index + 1) % n
	updateP1()
	
func p1PreviousButton():
	var n := maxi(1, sprites.size())
	p1Index = (p1Index - 1 + n) % n
	updateP1()
	
func p2NextButton():
	p2Index = (p2Index + 1) % sprites.size()
	updateP2()
	
func p2PreviousButton():
	p2Index = (p2Index - 1 + sprites.size()) % sprites.size()
	updateP2()
	
func p1Selection():
	if p1_locked or sprites.is_empty():
		return
	var car_id := _car_id_for_texture(sprites[p1Index])
	if car_id == "":
		return
	if p2_locked and GlobalData.p2Car == car_id:
		return
	GlobalData.p1Car = car_id
	p1_locked = true
	_play_click_sound()
	$PlayerOneNext.disabled = true
	$PlayerOnePrevious.disabled = true
	p1GrayDisplay.texture = grayed_sprites[p1Index]
	_sync_display_mode()
	if p2_locked:
		#get_tree().change_scene_to_file("res://wheel.tscn")
		get_tree().change_scene_to_file("res://leaderboard.tscn")
		
func p2Selection():
	if p2_locked or sprites.is_empty():
		return
	var car_id := _car_id_for_texture(sprites[p2Index])
	if car_id == "":
		return
	if p1_locked and GlobalData.p1Car == car_id:
		return
	GlobalData.p2Car = car_id
	p2_locked = true
	_play_click_sound()
	$PlayerTwoNext.disabled = true
	$PlayerTwoPrevious.disabled = true
	p2GrayDisplay.texture = grayed_sprites[p2Index]
	_sync_display_mode()
	if p1_locked:
		#get_tree().change_scene_to_file("res://wheel.tscn")
		get_tree().change_scene_to_file("res://leaderboard.tscn")
	
	
func updateP1():
	if sprites.is_empty():
		return
	p1Index = clampi(p1Index, 0, sprites.size() - 1)
	if not p1_locked and p2_locked and _car_id_for_texture(sprites[p1Index]) == GlobalData.p2Car:
		p1Index = (p1Index + 1) % sprites.size()
	p1ColorDisplay.texture = sprites[p1Index % sprites.size()]
	p1GrayDisplay.texture = grayed_sprites[p1Index % grayed_sprites.size()]
	_sync_display_mode()

func updateP2():
	if sprites.is_empty():
		return
	p2Index = clampi(p2Index, 0, sprites.size() - 1)
	if not p2_locked and p1_locked and _car_id_for_texture(sprites[p2Index]) == GlobalData.p1Car:
		p2Index = (p2Index + 1) % sprites.size()
	p2ColorDisplay.texture = sprites[p2Index % sprites.size()]
	p2GrayDisplay.texture = grayed_sprites[p2Index % grayed_sprites.size()]
	_sync_display_mode()

func _p1Deselect() -> void:
	if not p1_locked:
		return
	p1_locked = false
	GlobalData.p1Car = null
	$PlayerOneNext.disabled = false
	$PlayerOnePrevious.disabled = false
	updateP1()

func _p2Deselect() -> void:
	if not p2_locked:
		return
	p2_locked = false
	GlobalData.p2Car = null
	$PlayerTwoNext.disabled = false
	$PlayerTwoPrevious.disabled = false
	updateP2()

func _car_id_for_texture(texture: Texture2D) -> String:
	if texture == preload("res://assests/Blue F1 Car.png"):
		return "bluef1"
	if texture == preload("res://assests/Orange F1 Car.png"):
		return "orangef1"
	if texture == preload("res://assests/Green Nascar.png"):
		return "greennascar"
	if texture == preload("res://assests/Yellow Nascar.png"):
		return "yellownascar"
	return ""

func _sync_display_mode() -> void:
	p1ColorDisplay.visible = not p1_locked
	p1GrayDisplay.visible = p1_locked
	p2ColorDisplay.visible = not p2_locked
	p2GrayDisplay.visible = p2_locked

func _play_click_sound() -> void:
	if BUTTON_CLICK_SFX == null:
		return
	_click_player.stream = BUTTON_CLICK_SFX
	_click_player.play()
