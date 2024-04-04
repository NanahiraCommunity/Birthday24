extends Control
@onready var weekday_label = $"../Panel/weekdayLabel"
@onready var time_label = $"../Panel/timeLabel"
@onready var day_label = $"../Panel/dayLabel"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if TimeSystem.hour < 10:
		time_label.set_text("0" + str(TimeSystem.hour) + ":" + str(TimeSystem.minute_interval))
	else:
		time_label.set_text(str(TimeSystem.hour) + ":" + str(TimeSystem.minute_interval))
	
	if TimeSystem.day < 10:
		day_label.set_text("0" + str(TimeSystem.day))
	else:
		day_label.set_text(str(TimeSystem.day))
	weekday_label.set_text(TimeSystem.weekday)
