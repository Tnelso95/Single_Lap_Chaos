extends TextureButton

@export var hover_scale: Vector2 = Vector2(1.1, 1.1)
@export var pressed_scale: Vector2 = Vector2(0.9, 0.9)

func _ready() -> void:
	mouse_entered.connect(_button_enter)
	mouse_exited.connect(_button_exit)
	call_deferred("_init_pivot")
	
func _init_pivot() -> void:
	pivot_offset = size/2.0

func _on_pressed() -> void:
	var button_press_tween: Tween = create_tween()
	button_press_tween.tween_property(self,"scale", pressed_scale, 0.06).set_trans(Tween.TRANS_SINE)
	button_press_tween.tween_property(self,"scale", hover_scale, 0.12).set_trans(Tween.TRANS_SINE)
	GlobalData.reset_race(true)
	get_tree().change_scene_to_file("res://character_select.tscn")
	#get_tree().change_scene_to_file("res://leaderboard.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if GlobalData.is_player_confirm_event(event, 1) or GlobalData.is_player_confirm_event(event, 2):
			_on_pressed()

func _button_enter() -> void:
	create_tween().tween_property(self, "scale", hover_scale, 0.25).set_trans(Tween.TRANS_SINE)
	
func _button_exit() -> void:
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE)
