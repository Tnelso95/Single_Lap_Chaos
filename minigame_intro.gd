extends Control

const FALLBACK_SCENE_PATH := "res://leaderboard.tscn"
const BUTTON_CLICK_SFX: AudioStream = preload("res://sounds_assets/button_click.mp3")

const PLAYER_ONE_READY_KEYS := [KEY_W, KEY_A, KEY_S, KEY_D]
const PLAYER_TWO_READY_KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]

@onready var background: ColorRect = get_node_or_null("Background") as ColorRect
@onready var art: TextureRect = get_node_or_null("Background/Art") as TextureRect
@onready var p1_ready_label: CanvasItem = get_node_or_null("P1ReadyLabel") as CanvasItem
@onready var p2_ready_label: CanvasItem = get_node_or_null("P2ReadyLabel") as CanvasItem

var transitioning := false
var p1_ready := false
var p2_ready := false
var _click_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	_click_player.bus = "Master"
	_click_player.autoplay = false
	_click_player.volume_db = 1.5
	add_child(_click_player)
	var texture_path := GlobalData.get_minigame_intro_texture_path()
	if texture_path.is_empty():
		_go_to_minigame()
		return
	if art == null:
		_go_to_minigame()
		return
	art.texture = load(texture_path) as Texture2D
	_fit_art_to_viewport()
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if transitioning:
		return
	if event is InputEventJoypadButton:
		if GlobalData.is_player_confirm_event(event, 1):
			if not p1_ready:
				_play_click_sound()
			p1_ready = true
		if GlobalData.is_player_confirm_event(event, 2):
			if not p2_ready:
				_play_click_sound()
			p2_ready = true
		_update_prompt()
		if p1_ready and p2_ready:
			_go_to_minigame()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in PLAYER_ONE_READY_KEYS:
			if not p1_ready:
				_play_click_sound()
			p1_ready = true
		if event.keycode in PLAYER_TWO_READY_KEYS:
			if not p2_ready:
				_play_click_sound()
			p2_ready = true
		_update_prompt()
		if p1_ready and p2_ready:
			_go_to_minigame()

func _go_to_minigame() -> void:
	if transitioning:
		return
	transitioning = true
	var scene_path := GlobalData.get_minigame_scene_path()
	if scene_path.is_empty():
		get_tree().change_scene_to_file(FALLBACK_SCENE_PATH)
		return
	get_tree().change_scene_to_file(scene_path)

func _update_prompt() -> void:
	if p1_ready_label:
		p1_ready_label.modulate = Color(0.55, 1.0, 0.55, 1.0) if p1_ready else Color(1, 1, 1, 1)
	if p2_ready_label:
		p2_ready_label.modulate = Color(0.55, 1.0, 0.55, 1.0) if p2_ready else Color(1, 1, 1, 1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_art_to_viewport()

func _fit_art_to_viewport() -> void:
	if art == null:
		return
	var texture := art.texture
	if texture == null:
		return
	var view_size := get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	# Cover mode: preserve aspect ratio while filling the entire scene.
	var scale_factor := maxf(view_size.x / tex_size.x, view_size.y / tex_size.y) * 0.75
	var target_width := tex_size.x * scale_factor
	var target_height := tex_size.y * scale_factor
	art.size = Vector2(target_width, target_height)
	var y_offset := -100.0 if GlobalData.pendingMinigame == GlobalData.MINIGAME_PONG else 0.0
	art.position = Vector2((view_size.x - target_width) * 0.5, (view_size.y - target_height) * 0.5 + y_offset)

func _play_click_sound() -> void:
	if BUTTON_CLICK_SFX == null:
		return
	_click_player.stream = BUTTON_CLICK_SFX
	_click_player.play()
