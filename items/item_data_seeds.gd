extends ItemData
class_name ItemDataSeeds

enum CropType {
	CORN,
}

@export var crop_type: CropType

func use(target) -> void:
	target.place_crop()
