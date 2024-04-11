extends ItemData
class_name ItemDataTool

enum ToolType {
	HOE,
	PAIL,
	AXE,
}

@export var tool_type: ToolType

func use(target) -> void:
	if tool_type == ToolType.PAIL:
		target.water_crop()
	if tool_type == ToolType.HOE:
		target.till_land()
