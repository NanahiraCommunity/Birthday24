class_name StageComponent
extends Node
## Track objects stage and can replace target scene
## into a new scene after reacing a stage_threshold

signal stage_changed(new_stage: float, last_stage: float)
signal stage_threshold_reached(new_scene: Node3D)

## When set, is the scene that will be replaced with next_scene.
## Otherwise the direct parent will be used
@export var target: Node3D
@export var last_stage : bool = false
var _current_stage = 0.0:
	set(value):
		if (_current_stage != value):
			var last_stage = _current_stage
			_current_stage = value
			emit_signal("stage_changed", _current_stage, last_stage)
			
			if (_current_stage >= stage_threshold && _threshold_reached != true):
				if last_stage:
					target.queue_free()
					
				var new_scene : Node3D
				
				if (next_scene != null):
					new_scene = _create_next_scene()
				
				emit_signal("stage_threshold", new_scene)
				_threshold_reached = true
				target.queue_free()

@export var stage_threshold = 1.0
@export var next_scene : PackedScene
@export var next_stage = ""

var _threshold_reached = false

static var group_name = "StageComponent"

@onready var water_component = $"../WaterComponent"

func _ready():
	if (target == null):
		target = get_parent()
	
	add_to_group(group_name)

func _create_next_scene() -> Node3D:
	var instance : Node3D = next_scene.instantiate()
	target.get_parent().add_child(instance)
	instance.global_transform = target.global_transform
	return instance

func increase_stage(value: float):
	if (last_stage or water_component.is_watered()):
		_current_stage += value
