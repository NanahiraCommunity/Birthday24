extends Button

@export var stage_amount_on_press = 1.0


func _ready():
	connect("pressed", _on_pressed)

func _on_pressed():
	for stage_component in get_tree().get_nodes_in_group(StageComponent.group_name):
		if (stage_component is StageComponent):
			stage_component.increase_stage(stage_amount_on_press)

