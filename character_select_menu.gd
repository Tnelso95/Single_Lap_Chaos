extends Node2D

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

@onready var p1Display = $PlayerOneCars
@onready var p2Display = $PlayerTwoCars

@onready var p1Next = $PlayerOneNext
@onready var p1Previous = $PlayerOnePrevious

@onready var p2Next = $PlayerTwoNext
@onready var p2Previous = $PlayerTwoPrevious

@onready var p1Select = $PlayerOneSelect
@onready var p2Select = $PlayerTwoSelect

func _ready():
	
	p1Next.pressed.connect(p1NextButton)
	p1Previous.pressed.connect(p1PreviousButton)
	
	p2Next.pressed.connect(p2NextButton)
	p2Previous.pressed.connect(p2PreviousButton)
	
	p1Select.pressed.connect(p1Selection)
	p2Select.pressed.connect(p2Selection)
	
	
	p1Display.stretch_mode = $PlayerOneCars.STRETCH_KEEP_ASPECT_CENTERED
	p1Display.expand = true
	
	p2Display.stretch_mode = $PlayerTwoCars.STRETCH_KEEP_ASPECT_CENTERED
	p2Display.expand = true
	
	updateP1()
	updateP2()
	
	

func p1NextButton():
	p1Index = (p1Index + 1) % 4
	updateP1()
	
func p1PreviousButton():
	p1Index = (p1Index - 1 + 4) % 4
	updateP1()
	
func p2NextButton():
	p2Index = (p2Index + 1) % sprites.size()
	updateP2()
	
func p2PreviousButton():
	p2Index = (p2Index - 1 + sprites.size()) % sprites.size()
	updateP2()
	
func p1Selection():
	GlobalData.p1Car = sprites[p1Index]
	$PlayerOneNext.disabled = true
	$PlayerOnePrevious.disabled = true
	p1Display.texture = grayed_sprites[p1Index]
	sprites.pop_at(p1Index)
	if GlobalData.p2Car != null:
		get_tree().change_scene_to_file("res://wheel.tscn")
		
func p2Selection():
	GlobalData.p2Car = sprites[p2Index]
	$PlayerTwoNext.disabled = true
	$PlayerTwoPrevious.disabled = true
	p1Display.texture = grayed_sprites[p1Index]
	sprites.pop_at(p2Index)
	if GlobalData.p1Car != null:
		get_tree().change_scene_to_file("res://wheel.tscn")
	
	
func updateP1():
	if (GlobalData.p2Car == null):
		p1Display.texture = sprites[p1Index]
	else:
		p1Display.texture = sprites[p1Index % 3]

func updateP2():
	if (GlobalData.p1Car == null):
		p2Display.texture = sprites[p2Index]
	else:
		p2Display.texture = sprites[p2Index % 3]


#func _on_player_one_select_pressed() -> void:
#	GlobalData.p1Car = sprites[p1Index]
#	print(GlobalData.plCar)
#	if GlobalData.p2Car != "":
#		get_tree().change_scene_to_file("res://wheel.tscn")
