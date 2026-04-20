extends Node2D


func _ready() -> void:
	winner_text()
	confetti()
	
	
func winner_text():
	if GlobalData.winner == "player1":
		$WinnerText.text = "Congratulations player 1!"
	if GlobalData.winner == "player2":
		$WinnerText.text = "Congratulations player 2!"
		
		
func confetti():
	var confetti_textures = [
		load("res://assests/blueconfetti.png"),
		load("res://assests/pinkconfetti.png"),
		load("res://assests/yellowconfetti.png")
	]
	
	var count = 200
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var screen_size = get_viewport_rect().size
	
	for i in range(count):
		var sprite = Sprite2D.new()
		sprite.texture = confetti_textures[rng.randi_range(0, confetti_textures.size()-1)]
		sprite.position = Vector2(
			rng.randf_range(0, screen_size.x),
			-20
		)
		
		sprite.scale = Vector2(0.1, 0.1)
		add_child(sprite)
		
		var tween = create_tween()
		var velocity = Vector2(rng.randf_range(-150,150), rng.randf_range(300,800))
		tween.tween_property(
			sprite,
			"position",
			sprite.position + velocity,
			12.0
		)
		tween.parallel().tween_property(
			sprite,
			"modulate:a",
			0.0,
			10.0
		).set_delay(2.0)
