extends Control

const FALLBACK_SCENE_PATH := "res://leaderboard.tscn"

const PLAYER_ONE_READY_KEYS := [KEY_W, KEY_A, KEY_S, KEY_D]
const PLAYER_TWO_READY_KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]

@onready var background: TextureRect = $Background
@onready var prompt_label: Label = $PromptLabel

var transitioning := false
var p1_ready := false
var p2_ready := false

func _ready() -> void:
	var texture_path := GlobalData.get_minigame_intro_texture_path()
	if texture_path.is_empty():
		_go_to_minigame()
		return
	background.texture = load(texture_path)
	background.position.y = -40.0 if GlobalData.pendingMinigame == GlobalData.MINIGAME_PONG else 0.0
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in PLAYER_ONE_READY_KEYS:
			p1_ready = true
		if event.keycode in PLAYER_TWO_READY_KEYS:
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
	if p1_ready and p2_ready:
		prompt_label.text = "Loading minigame..."
	elif p1_ready:
		prompt_label.text = "Player 1 ready. Waiting for Player 2..."
	elif p2_ready:
		prompt_label.text = "Player 2 ready. Waiting for Player 1..."
	else:
		prompt_label.text = "Both players press a control to continue"
