extends StaticBody3D

var crop_corn = preload("res://interactables/crops/corn/corn_stage_a.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func place_crop(interactables_map : GridMap, crop_type: PlayerManager.CropType) -> void:
	#var map_pos = interactables_map.local_to_map(self.position)
	#var cell_pos = interactables_map.map_to_local(map_pos)
	var crop = null
	if crop_type == PlayerManager.CropType.CORN:
		crop = crop_corn.instantiate()
	if crop_type == PlayerManager.CropType.CARROT:
		print("CARROT")
		return
	#crop.global_position = interactables_map.to_global(cell_pos * interactables_map.cell_size)
	crop.global_position = interactables_map.to_global(self.position)
	interactables_map.add_child(crop)
	
	queue_free()
