extends WorldEnvironment

@onready var directional_light_3d = $DirectionalLight3D
@onready var animation_player = $AnimationPlayer

func _process(delta):
	if TimeSystem.minute_interval == "00":
		if TimeSystem.hour == 6:
			animation_player.play("Day")
		if TimeSystem.hour == 15:
			animation_player.play("Evening")
		if TimeSystem.hour == 22:
			animation_player.play("Night")
