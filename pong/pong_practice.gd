extends Node2D

@onready var banner: Sprite2D = $PracticeBanner
@onready var background: Sprite2D = $PongGame/Background
@onready var ball: Area2D = $PongGame/Ball

func _ready() -> void:
	# Keep practice banner above background but below gameplay ball.
	if background:
		background.z_index = -10
	if banner:
		banner.z_index = -1
	if ball:
		ball.z_index = 1
