extends Control

@export var debug_ui : Control

var is_visible = false

func _process(delta):
	if Input.is_action_just_pressed("debug_ui_toggle"):
		if (is_visible):
			debug_ui.visible = false
			is_visible = false
		else:
			debug_ui.visible = true
			is_visible = true
