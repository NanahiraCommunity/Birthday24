extends ItemData
class_name ItemDataEquip

@export var defence: int

func use(target) -> void:
	if defence != 0:
		target.increase_def(defence, name)
