extends Node

var second = 25200
var minute = 0
var hour = 7
var day = 1
var month = 1
var year = 1
var weekday = "Sun"
var weekday_index = 0
var season = "Spring"
var time_format = "AM"
var minute_interval = "00"

const weekdays = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"]
const seasons = ["Spring", "Summer", "Fall", "Winter"]
const am_pm = ["AM", "PM"]
const minute_intervals = ["00", "10", "20", "30", "40", "50"]

const stage_amount_on_press = 1.0

const default_time_speed = 500
var day_processed = false

var time_speed = 80

func _ready() -> void:
	time_speed = default_time_speed

func _process(delta: float) -> void:
	if hour == 0 and day_processed == false and time_speed > 0:
		change_day()
	
	if hour > 0:
		day_processed = false
	
	if time_speed > 0:
		second += int(floor(delta * time_speed))
		minute = (int(second) / 60) % 60
		hour = (int(second) / (3600)) % 24
		time_format = am_pm[hour / 12]
		minute_interval = minute_intervals[minute / 10]

func change_day() -> void:
	second = 0
	minute = 0
	hour = 0
	day += 1
	day_processed = true
	# Current month should end below
	if day == 29:
		month += 1
		day = 1
		second = 0
		minute = 0
		hour = 0
		# Last month of the year, start new year
		if month == 5:
			year += 1
			month = 1
			day = 1
			second = 0
			minute = 0
			hour = 0
		season = seasons[month - 1]
	weekday_index = int(day) % 7 - 1
	weekday = weekdays[weekday_index]
	
	for stage_component in get_tree().get_nodes_in_group(StageComponent.group_name):
		if (stage_component is StageComponent):
			stage_component.increase_stage(stage_amount_on_press)
	
