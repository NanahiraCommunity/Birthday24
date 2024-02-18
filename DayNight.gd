#@tool
extends WorldEnvironment

@export_range(0, 2400, 0.01) var timeOfDay : float = 1200.0
@export var simulateTime : bool = false
@export_range(0, 10, 0.01) var rateOfTime : float = 0.1
@export_range(0, 360, 0.1) var skyRotation : float = 0.0

@onready var directional_light_3d = $DirectionalLight3D
@onready var weekday_label = $"../CanvasLayer/WeekdayLabel"
@onready var time_label = $"../CanvasLayer/TimeLabel"

const weekdays = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"]
const seasons = ["Spring", "Summer", "Fall", "Winter"]
const am_pm = ["AM", "PM"]
var weekdayIndex = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timeOfDay += rateOfTime
	
	
	if (timeOfDay >= 2400.0):
		timeOfDay = 0.0
		updateDay()
		
	update_rotation()
	time_label.set_text(str(floor(timeOfDay)))

func update_rotation():
	var hourMapped = remap(timeOfDay, 0.0, 2400.0, 0.0, 1.0)
	directional_light_3d.rotation_degrees.y = skyRotation
	directional_light_3d.rotation_degrees.x = hourMapped * 360.0

func updateDay():
	if (weekdayIndex >= 6):
		weekdayIndex = 0
	
	weekdayIndex += 1
	weekday_label.set_text(weekdays[weekdayIndex])

