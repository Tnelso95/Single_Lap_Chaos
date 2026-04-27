extends Node2D

const WHEEL_SCENE_PATH := "res://main.tscn"
const START_SCREEN_SCENE_PATH := "res://start_screen.tscn"
const WINNER_SCENE_PATH := "res://winner.tscn"
const CAR_MOVE_DURATION := 6.25
const POST_MOVE_PAUSE := 1.0
const RACE_FINISH_DELAY := 3.0


@onready var p1_path_follow = $P1Path2D/P1PathFollow2D
@onready var p1car = p1_path_follow.get_node("P1Car")
@onready var p2_path_follow = $P2Path2D/P2PathFollow2D
@onready var p2car = p2_path_follow.get_node("P2Car")
@onready var prompt_label: Label = $PromptLabel

var transitioning := false
var race_finished := false


func _ready():
	_apply_car_visuals(p1car, GlobalData.p1Car)
	_apply_car_visuals(p2car, GlobalData.p2Car)
	update_position()
	if GlobalData.has_race_winner():
		queue_race_finish_transition()
	else:
		prompt_label.text = "Next minigame loading..."
		queue_wheel_transition()

func _unhandled_input(event: InputEvent) -> void:
	var should_advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		should_advance = true
	elif event is InputEventJoypadButton and event.pressed:
		if GlobalData.is_player_confirm_event(event, 1) or GlobalData.is_player_confirm_event(event, 2):
			should_advance = true
	if should_advance:
		if race_finished:
			return_to_start_screen()
		else:
			advance_to_wheel()

func update_position():
	var p1start_progress = GlobalData.p1DisplayedPoints / GlobalData.POINTS_TO_WIN
	var p2start_progress = GlobalData.p2DisplayedPoints / GlobalData.POINTS_TO_WIN
	var p1progress = GlobalData.p1Points / GlobalData.POINTS_TO_WIN
	var p2progress = GlobalData.p2Points / GlobalData.POINTS_TO_WIN
	var p1seconds = CAR_MOVE_DURATION if not is_equal_approx(GlobalData.p1Points, GlobalData.p1DisplayedPoints) else 0.0
	var p2seconds = CAR_MOVE_DURATION if not is_equal_approx(GlobalData.p2Points, GlobalData.p2DisplayedPoints) else 0.0
	
	$ProgressBarP1.max_value = GlobalData.POINTS_TO_WIN
	$ProgressBarP2.max_value = GlobalData.POINTS_TO_WIN
	$ProgressBarP1.value = GlobalData.p1Points
	$ProgressBarP2.value = GlobalData.p2Points
	p1_path_follow.progress_ratio = p1start_progress
	p2_path_follow.progress_ratio = p2start_progress
	
	var p1tween = create_tween()
	p1tween.tween_property(
		p1_path_follow,
		"progress_ratio",
		p1progress,
		p1seconds
	)
	
	var p2tween = create_tween()
	p2tween.tween_property(
		p2_path_follow,
		"progress_ratio",
		p2progress,
		p2seconds
	)

func queue_wheel_transition() -> void:
	var p1_moved = not is_equal_approx(GlobalData.p1Points, GlobalData.p1DisplayedPoints)
	var p2_moved = not is_equal_approx(GlobalData.p2Points, GlobalData.p2DisplayedPoints)
	var wait_time = POST_MOVE_PAUSE
	if p1_moved or p2_moved:
		wait_time += CAR_MOVE_DURATION
	await get_tree().create_timer(wait_time).timeout
	advance_to_wheel()

func queue_race_finish_transition() -> void:
	race_finished = true
	var winner := GlobalData.get_race_winner()
	if winner == 1:
		prompt_label.text = "Player 1 wins the race!"
	elif winner == 2:
		prompt_label.text = "Player 2 wins the race!"
	else:
		prompt_label.text = "Race complete!"
	await get_tree().create_timer(RACE_FINISH_DELAY).timeout
	go_to_winner_scene()

func advance_to_wheel() -> void:
	if transitioning:
		return
	transitioning = true
	GlobalData.sync_displayed_points()
	get_tree().change_scene_to_file(WHEEL_SCENE_PATH)

func return_to_start_screen() -> void:
	if transitioning:
		return
	transitioning = true
	GlobalData.reset_race(true)
	get_tree().change_scene_to_file(START_SCREEN_SCENE_PATH)

func go_to_winner_scene() -> void:
	if transitioning:
		return
	transitioning = true
	GlobalData.sync_displayed_points()
	get_tree().change_scene_to_file(WINNER_SCENE_PATH)

func _apply_car_visuals(car_sprite: Sprite2D, car_id: Variant) -> void:
	var texture_path := GlobalData.get_car_texture_path(car_id)
	if texture_path.is_empty():
		return
	car_sprite.texture = load(texture_path)
	car_sprite.scale = GlobalData.get_car_track_scale(car_id)
