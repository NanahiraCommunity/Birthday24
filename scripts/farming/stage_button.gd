extends Button

@export var stage_amount_on_press = 1.0
@export var interactables_map : GridMap


func _ready():
	connect("pressed", _on_pressed)

func _on_pressed():
	#var mesh_library = interactables_map.mesh_library
	#var item = mesh_library.find_item_by_name("crops_cornStageA2")
	#var item2 = mesh_library.find_item_by_name("crops_cornStageB2")
	#var used_cells = interactables_map.get_used_cells_by_item(item)
	#for cell_mesh in used_cells:
		#interactables_map.set_cell_item(cell_mesh, item2)
	
	for stage_component in get_tree().get_nodes_in_group(StageComponent.group_name):
		if (stage_component is StageComponent):
			stage_component.increase_stage(stage_amount_on_press)

