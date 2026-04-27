extends Control

const LEADERBOARD_SCENE_PATH := "res://leaderboard.tscn"
const RETURN_DELAY := 2.0
const TURN_SWAP_DELAY := 1.0

enum ChainButton { A, X, Y, B, RT, LT }

const PLAYER_ONE_KEYS := {
	KEY_J: ChainButton.A,
	KEY_U: ChainButton.X,
	KEY_I: ChainButton.Y,
	KEY_K: ChainButton.B,
	KEY_O: ChainButton.RT,
	KEY_L: ChainButton.LT,
}

const PLAYER_TWO_KEYS := {
	KEY_KP_2: ChainButton.A,
	KEY_KP_4: ChainButton.X,
	KEY_KP_8: ChainButton.Y,
	KEY_KP_6: ChainButton.B,
	KEY_KP_9: ChainButton.RT,
	KEY_KP_7: ChainButton.LT,
}

const BUTTON_TEXT := {
	ChainButton.A: "A",
	ChainButton.X: "X",
	ChainButton.Y: "Y",
	ChainButton.B: "B",
	ChainButton.RT: "RT",
	ChainButton.LT: "LT",
}

const BUTTON_ROTATION_DEGREES := {
	ChainButton.RT: 60.0,
	ChainButton.B: 90.0,
	ChainButton.A: 120.0,
	ChainButton.X: 240.0,
	ChainButton.Y: 270.0,
	ChainButton.LT: 300.0,
}

const BUTTON_SFX := {
	ChainButton.A: preload("res://sounds_assets/A.mp3"),
	ChainButton.B: preload("res://sounds_assets/B.mp3"),
	ChainButton.X: preload("res://sounds_assets/X.mp3"),
	ChainButton.Y: preload("res://sounds_assets/Y.mp3"),
	ChainButton.RT: preload("res://sounds_assets/RT.mp3"),
	ChainButton.LT: preload("res://sounds_assets/LT.mp3"),
}

const TRIGGER_THRESHOLD := 0.65
const BUTTON_PULSE_SCALE := 1.35
const BUTTON_PULSE_TIME := 0.09

@onready var p1_score_label: Label = get_node_or_null("UI/PlayerOneScoreLabel") as Label
@onready var p2_score_label: Label = get_node_or_null("UI/PlayerTwoScoreLabel") as Label
@onready var result_label: Label = get_node_or_null("UI/ResultLabel") as Label
@onready var prompt_label: Label = get_node_or_null("UI/PromptLabel") as Label
@onready var chain_guide_label: Label = get_node_or_null("UI/ChainGuideLabel") as Label
@onready var icon: TextureRect = get_node_or_null("Icon") as TextureRect
@onready var button_a_icon: Sprite2D = get_node_or_null("Buttons/AButton") as Sprite2D
@onready var button_x_icon: Sprite2D = get_node_or_null("Buttons/XButton") as Sprite2D
@onready var button_y_icon: Sprite2D = get_node_or_null("Buttons/YButton") as Sprite2D
@onready var button_b_icon: Sprite2D = get_node_or_null("Buttons/BButton") as Sprite2D
@onready var button_rt_icon: Sprite2D = get_node_or_null("Buttons/RTButton") as Sprite2D
@onready var button_lt_icon: Sprite2D = get_node_or_null("Buttons/LTButton") as Sprite2D

var game_over := false
var transitioning := false
var active_player := 1
var chain: Array[int] = []
var replay_index := 0
var waiting_for_new_step := true
var input_locked := false
var practice_mode := false
var _last_rt_down_by_device: Dictionary = {}
var _last_lt_down_by_device: Dictionary = {}
var _button_icon_base_scales: Dictionary = {}
var _button_sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	_button_sfx_player.bus = "Master"
	_button_sfx_player.autoplay = false
	_button_sfx_player.volume_db = 2.0
	add_child(_button_sfx_player)
	if result_label:
		result_label.visible = false
	if icon:
		icon.pivot_offset = icon.size / 2.0
	practice_mode = GlobalData.is_practice_round()
	_cache_button_icon_scales()
	_start_new_round()

func _unhandled_input(event: InputEvent) -> void:
	if game_over or input_locked:
		return
	var input_button := _button_for_active_player_event(event)
	if input_button == -1:
		return
	_show_input_button(input_button)
	if waiting_for_new_step:
		_add_step_and_pass_turn(input_button)
		return
	var expected_button := chain[replay_index]
	if input_button != expected_button:
		GlobalData.rumble_player(active_player, 0.7, 1.0, 0.2)
		var winner := 2 if active_player == 1 else 1
		_end_game(winner, "Player %d broke the chain." % active_player)
		return
	replay_index += 1
	if replay_index >= chain.size():
		waiting_for_new_step = true
		_set_chain_guide("Add to Chain")
		if prompt_label:
			prompt_label.text = "Correct. Player %d add one new button." % active_player
	else:
		_set_chain_guide("Repeat Chain")
		if prompt_label:
			prompt_label.text = "Player %d: replaying chain (%d/%d)." % [active_player, replay_index, chain.size()]

func _end_game(winner: int, text: String) -> void:
	game_over = true
	var missed_player := 2 if winner == 1 else 1
	if not practice_mode:
		GlobalData.award_win(winner)
	if prompt_label:
		prompt_label.text = "Player %d Missed, Starting Game" % missed_player
	await get_tree().create_timer(2.0).timeout
	if practice_mode:
		_start_actual_minigame()
		return
	if result_label:
		result_label.text = "Player %d wins One Up!\n%s" % [winner, text]
		result_label.visible = true
	if prompt_label:
		prompt_label.text = "Returning to leaderboard..."
	_queue_return()

func _queue_return() -> void:
	await get_tree().create_timer(RETURN_DELAY).timeout
	_return_to_leaderboard()

func _return_to_leaderboard() -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().change_scene_to_file(LEADERBOARD_SCENE_PATH)

func _start_new_round() -> void:
	chain.clear()
	active_player = 1
	replay_index = 0
	waiting_for_new_step = true
	input_locked = false
	_set_chain_guide("Start Chain")
	_prepare_active_player_turn("Player 1 starts: add the first button.")

func _add_step_and_pass_turn(input_button: int) -> void:
	GlobalData.rumble_player(active_player, 0.45, 0.75, 0.12)
	chain.append(input_button)
	input_locked = true
	if prompt_label:
		prompt_label.text = "Chain extended. Switching turns..."
	await get_tree().create_timer(TURN_SWAP_DELAY).timeout
	if game_over:
		return
	active_player = 2 if active_player == 1 else 1
	replay_index = 0
	waiting_for_new_step = false
	input_locked = false
	_set_chain_guide("Repeat Chain")
	_prepare_active_player_turn("Player %d replay the chain (%d step%s), then add one." % [
		active_player,
		chain.size(),
		"" if chain.size() == 1 else "s"
	])

func _update_turn_labels() -> void:
	if p1_score_label:
		p1_score_label.text = "Player 1%s" % (" <- Turn" if active_player == 1 else "")
	if p2_score_label:
		p2_score_label.text = "Player 2%s" % (" <- Turn" if active_player == 2 else "")

func _button_for_active_player_event(event: InputEvent) -> int:
	var player: int = active_player
	var device: int = GlobalData.get_player_device(player)
	if event is InputEventJoypadButton:
		var joy_button_event := event as InputEventJoypadButton
		if joy_button_event.device != device:
			return -1
		if not joy_button_event.pressed:
			return -1
		if GlobalData.is_player_face_button_event(event, player, "A"):
			return ChainButton.A
		if GlobalData.is_player_face_button_event(event, player, "X"):
			return ChainButton.X
		if GlobalData.is_player_face_button_event(event, player, "Y"):
			return ChainButton.Y
		if GlobalData.is_player_face_button_event(event, player, "B"):
			return ChainButton.B
		return -1
	if event is InputEventJoypadMotion:
		var joy_motion_event := event as InputEventJoypadMotion
		if joy_motion_event.device != device:
			return -1
		if joy_motion_event.axis == JOY_AXIS_TRIGGER_RIGHT:
			var now_rt := joy_motion_event.axis_value >= TRIGGER_THRESHOLD
			var prev_rt := bool(_last_rt_down_by_device.get(device, false))
			_last_rt_down_by_device[device] = now_rt
			if now_rt and not prev_rt:
				return ChainButton.RT
		elif joy_motion_event.axis == JOY_AXIS_TRIGGER_LEFT:
			var now_lt := joy_motion_event.axis_value >= TRIGGER_THRESHOLD
			var prev_lt := bool(_last_lt_down_by_device.get(device, false))
			_last_lt_down_by_device[device] = now_lt
			if now_lt and not prev_lt:
				return ChainButton.LT
		return -1
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var key_map: Dictionary = PLAYER_ONE_KEYS if player == 1 else PLAYER_TWO_KEYS
		if key_map.has(key_event.keycode):
			return int(key_map[key_event.keycode])
	return -1

func _show_input_button(button_id: int) -> void:
	var button_name: String = str(BUTTON_TEXT.get(button_id, "?"))
	if prompt_label:
		prompt_label.text = "Player %d input: %s" % [active_player, button_name]
	_play_button_sound(button_id)
	_pulse_button_icon(button_id)
	if icon:
		var rotation_degrees_for_input: float = float(BUTTON_ROTATION_DEGREES.get(button_id, 0.0))
		icon.rotation_degrees = rotation_degrees_for_input

func _prepare_active_player_turn(prompt_text: String) -> void:
	_update_turn_labels()
	_set_active_player_car()
	if icon:
		icon.rotation_degrees = 0.0
	if prompt_label:
		prompt_label.text = prompt_text

func _set_active_player_car() -> void:
	var car_id = GlobalData.p1Car if active_player == 1 else GlobalData.p2Car
	var texture_path := GlobalData.get_car_texture_path(car_id)
	if texture_path.is_empty():
		return
	if icon:
		icon.texture = load(texture_path)

func _cache_button_icon_scales() -> void:
	var icons := [button_a_icon, button_x_icon, button_y_icon, button_b_icon, button_rt_icon, button_lt_icon]
	for item in icons:
		var icon_node := item as Sprite2D
		if icon_node != null:
			_button_icon_base_scales[icon_node] = icon_node.scale

func _icon_for_button(button_id: int) -> Sprite2D:
	match button_id:
		ChainButton.A:
			return button_a_icon
		ChainButton.X:
			return button_x_icon
		ChainButton.Y:
			return button_y_icon
		ChainButton.B:
			return button_b_icon
		ChainButton.RT:
			return button_rt_icon
		ChainButton.LT:
			return button_lt_icon
		_:
			return null

func _pulse_button_icon(button_id: int) -> void:
	var icon_node: Sprite2D = _icon_for_button(button_id)
	if icon_node == null:
		return
	var typed_base_scale: Vector2 = _button_icon_base_scales.get(icon_node, icon_node.scale) as Vector2
	icon_node.scale = typed_base_scale * BUTTON_PULSE_SCALE
	var tween := create_tween()
	tween.tween_property(icon_node, "scale", typed_base_scale, BUTTON_PULSE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_actual_minigame() -> void:
	if transitioning:
		return
	transitioning = true
	GlobalData.complete_practice_round()
	get_tree().change_scene_to_file(GlobalData.get_actual_minigame_scene_path())

func _play_button_sound(button_id: int) -> void:
	var stream: AudioStream = BUTTON_SFX.get(button_id, null) as AudioStream
	if stream == null:
		return
	_button_sfx_player.stream = stream
	_button_sfx_player.play()

func _set_chain_guide(text: String) -> void:
	if chain_guide_label:
		chain_guide_label.text = text
