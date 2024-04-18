extends Button

func _ready() -> void:
	connect("pressed", _on_pressed)

func _on_pressed() -> void:
	print("pressed")
	for water_component in get_tree().get_nodes_in_group(WaterComponent.group_name):
		if (water_component is WaterComponent):
			water_component.water()

