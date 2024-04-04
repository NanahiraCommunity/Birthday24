extends ItemData
class_name ItemDataSeeds

@export var crop_type: PlayerManager.CropType

func use(target) -> void:
	target.place_crop(crop_type)
