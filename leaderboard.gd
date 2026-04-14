extends Node2D


@onready var p1_path_follow = $P1Path2D/P1PathFollow2D
@onready var p1car = p1_path_follow.get_node("P1Car")
@onready var p2_path_follow = $P2Path2D/P2PathFollow2D
@onready var p2car = p2_path_follow.get_node("P2Car")
#@onready var trail = $Trail1

var last_trail : Vector2 = Vector2.ZERO
var spacing = 4.0


func _ready():
	#last_trail = to_local(car.global_position)
	#trail.add_point(last_trail)
	update_position()

func update_position():
	var p1progress = GlobalData.p1Points / 1000.0
	var p2progress = GlobalData.p2Points / 1000.0
	var p1seconds = GlobalData.p1Points / 40.0
	var p2seconds = GlobalData.p2Points / 40.0
	
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
	#path_follow.progress_ratio = progress
	
#func _process(_delta):
#	if car == null or trail == null:
#		return
#	var pos = to_local(car.global_position)
#	if last_trail == Vector2.ZERO:
#		last_trail = pos
#		trail.add_point(pos)
		#last_trail = pos
		#		return
	#if last_trail.distance_to(pos) >= spacing:
	#	trail.add_point(pos)
	#	last_trail = pos
	#trail.add_point(trail.to_local(car.global_position))
	

	
	
