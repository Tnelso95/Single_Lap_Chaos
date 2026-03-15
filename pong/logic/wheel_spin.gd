extends Node2D

@export var revolutions: int = 10
@export var spin_time: float = 5.0
@export var game_count: int = 4

var chosen_game: int = 0


func _ready() -> void:
	randomize()
	spin_the_wheel()


func spin_the_wheel() -> void:
	chosen_game = randi() % game_count
	var angle := TAU / game_count
	var target_rotation := chosen_game * angle
	var final_rotation := target_rotation + (revolutions * TAU)
	var tween := create_tween()
	tween.tween_property(self, "rotation", final_rotation, spin_time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_spin_finished)


func _on_spin_finished() -> void:
	# Always go to pong after the wheel lands
	get_tree().change_scene_to_file("res://assests/pong.tscn")
