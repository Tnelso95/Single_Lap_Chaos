extends Node

const TRACK_OPTIONS_BY_SCENE := {
	"start_screen": ["res://sounds_assets/background_music.mp3"],
	"character_select": ["res://sounds_assets/background_music.mp3"],
	"leaderboard": ["res://sounds_assets/car_move.mp3", "res://sounds_assets/click_sound.mp3"],
	"main": ["res://sounds_assets/wheel_spin.mp3", "res://sounds_assets/button_press.mp3"],
	"wheel": ["res://sounds_assets/wheel_spin.mp3", "res://sounds_assets/button_press.mp3"],
	"minigame_intro": ["res://sounds_assets/intro_practice.mp3"],
	"pong": ["res://sounds_assets/pong_game_background.mp3"],
	"pong_practice": ["res://sounds_assets/intro_practice.mp3"],
	"photo_memory": ["res://sounds_assets/photo_memory.mp3"],
	"photo_memory_practice": ["res://sounds_assets/intro_practice.mp3"],
	"one_up": ["res://sounds_assets/one_up.mp3"],
	"one_up_practice": ["res://sounds_assets/intro_practice.mp3"],
	"dizzy_driving": ["res://sounds_assets/dizzy_driving.mp3"],
	"dizzy_practice": ["res://sounds_assets/intro_practice.mp3"],
}

const LOOP_BY_SCENE := {
	"start_screen": true,
	"character_select": true,
	"pong": true,
	"photo_memory": true,
	"photo_memory_practice": true,
	"one_up": true,
	"one_up_practice": true,
	"dizzy_driving": true,
	"leaderboard": false,
	"main": false,
	"wheel": false,
	"minigame_intro": true,
	"pong_practice": true,
	"dizzy_practice": true,
}

var _player := AudioStreamPlayer.new()
var _last_scene_path := ""
var _current_track_path := ""

func _ready() -> void:
	_player.bus = "Master"
	_player.autoplay = false
	_player.stream_paused = false
	_player.volume_db = -7.0
	add_child(_player)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var scene_path := scene.scene_file_path
	if scene_path == _last_scene_path:
		return
	_last_scene_path = scene_path
	_update_track_for_scene(scene_path)

func _update_track_for_scene(scene_path: String) -> void:
	var scene_key := scene_path.get_file().get_basename().to_lower()
	var track: Dictionary = _first_loadable_track(scene_key)
	var track_path: String = str(track.get("path", ""))
	var stream := track.get("stream", null) as AudioStream
	if track_path.is_empty() or stream == null:
		_player.stop()
		_current_track_path = ""
		return
	if track_path == _current_track_path and _player.playing:
		return
	stream.loop = bool(LOOP_BY_SCENE.get(scene_key, true))
	_player.stream = stream
	_player.play()
	_current_track_path = track_path

func _first_loadable_track(scene_key: String) -> Dictionary:
	var candidates: Array = TRACK_OPTIONS_BY_SCENE.get(scene_key, [])
	for raw_path in candidates:
		var path := str(raw_path)
		if not ResourceLoader.exists(path):
			continue
		var stream := load(path) as AudioStream
		if stream != null:
			return {"path": path, "stream": stream}
	return {}
