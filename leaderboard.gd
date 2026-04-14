extends Node2D


@onready var p1_path_follow = $P1Path2D/P1PathFollow2D
@onready var p1car = p1_path_follow.get_node("P1Car")
@onready var p2_path_follow = $P2Path2D/P2PathFollow2D
@onready var p2car = p2_path_follow.get_node("P2Car")


func _ready():
	var blue_f1 = preload("res://assests/Blue F1 Car.png")
	var orange_f1 = preload("res://assests/Orange F1 Car.png")
	var green_nascar = preload("res://assests/Green Nascar.png")
	var yellow_nascar = preload("res://assests/Yellow Nascar.png")
	print(blue_f1)
	print(orange_f1)
	print(green_nascar)
	print(yellow_nascar)
	if GlobalData.p1Car == "bluef1":
		$P1Path2D/P1PathFollow2D/P1Car.texture = blue_f1
		$P1Path2D/P1PathFollow2D/P1Car.scale = Vector2(.01,.01)
	if GlobalData.p2Car == "bluef1":
		$P2Path2D/P2PathFollow2D/P2Car.texture = blue_f1
		$P2Path2D/P2PathFollow2D/P2Car.scale = Vector2(.01,.01)
	if GlobalData.p1Car == "orangef1":
		$P1Path2D/P1PathFollow2D/P1Car.texture = orange_f1
		$P1Path2D/P1PathFollow2D/P1Car.scale = Vector2(.01,.01)
	if GlobalData.p2Car == "orangef1":
		$P2Path2D/P2PathFollow2D/P2Car.texture = orange_f1
		$P2Path2D/P2PathFollow2D/P2Car.scale = Vector2(.01,.01)
	if GlobalData.p1Car == "greennascar":
		$P1Path2D/P1PathFollow2D/P1Car.texture = green_nascar
		$P1Path2D/P1PathFollow2D/P1Car.scale = Vector2(.007,.007)
	if GlobalData.p2Car == "greennascar":
		$P2Path2D/P2PathFollow2D/P2Car.texture = green_nascar
		$P2Path2D/P2PathFollow2D/P2Car.scale = Vector2(.007,.007)
	if GlobalData.p1Car == "yellownascar":
		$P1Path2D/P1PathFollow2D/P1Car.texture = yellow_nascar
		$P1Path2D/P1PathFollow2D/P1Car.scale = Vector2(.007,.007)
	if GlobalData.p2Car == "yellownascar":
		$P2Path2D/P2PathFollow2D/P2Car.texture = yellow_nascar
		$P2Path2D/P2PathFollow2D/P2Car.scale = Vector2(.007,.007)
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
