extends CanvasLayer

@export var ui_layer : Control

var is_visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("debug_ui_toggle"):
		if (is_visible):
			ui_layer.visible = false
			is_visible = false
		else:
			ui_layer.visible = true
			is_visible = true
