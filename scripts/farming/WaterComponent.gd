class_name WaterComponent
extends Node
## Track if the object has been watered

signal value_changed(new_value: bool, last_value: bool)

var _current_value = false:
	set(value):
		if (_current_value != value):
			var last_value = _current_value
			_current_value = value
			emit_signal("value_changed", _current_value, last_value)

static var group_name = "WaterComponent"

func _ready():
	add_to_group(group_name)

func water():
	_current_value = !_current_value
	print_debug("watered")

func is_watered():
	return _current_value
