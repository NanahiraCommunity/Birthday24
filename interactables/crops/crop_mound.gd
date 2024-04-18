extends StaticBody3D

var crop_corn = preload("res://interactables/crops/corn/corn_stage_a.tscn")

func place_crop(interactables_map : GridMap, crop_type: PlayerManager.CropType) -> void:
	var crop = null
	if crop_type == PlayerManager.CropType.CORN:
		crop = crop_corn.instantiate()
	if crop_type == PlayerManager.CropType.CARROT:
		print("CARROT")
		return
	crop.global_position = interactables_map.to_global(self.position)
	interactables_map.add_child(crop)
	queue_free()
