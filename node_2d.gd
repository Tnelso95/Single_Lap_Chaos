extends Node2D

func _ready():
	randomize()
	spin_the_wheel()
	

@export var revolutions: int = 10
@export var spin_time: float = 12.0 # seconds the wheel spins
@export var game_count: int = 4 # number of possible mini games

var chosen_game: int = 1
 
func spin_the_wheel():
	# change next line to chosen_game = 0 to make it land on pong every spin
	#chosen_game = randi() % game_count # randomly selects a game within the scope
	chosen_game = 0
	# TAU is equal to 2 pi (a full circle/360 degrees)
	var angle = TAU / game_count
	var target_rotation = chosen_game * angle
	var final_rotation = target_rotation + (revolutions * TAU)
	var tween = create_tween()
	tween.tween_property(
		self,
		"rotation",
		final_rotation,
		spin_time
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.finished.connect(spin_finished)
	
func spin_finished():
	print("Game chosen: ", chosen_game)
