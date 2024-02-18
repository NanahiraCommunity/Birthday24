extends Node

const weekdays = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"]
const seasons = ["Spring", "Summer", "Fall", "Winter"]
const am_pm = ["AM", "PM"]
const minute_intervals = ["00", "10", "20", "30", "40", "50"]

var weekdayIndex = 0
var second = 25200
var minute = 0
var hour = 0
var day = 1
var month = 1
var year = 1
var season = "Spring"
var timeFormat = "AM"
var minuteInterval = "00"

@export var time_speed = 80

func _process(delta):
	
	if (hour == 0 && time_speed > 0):
		change_day()
	
	second += int(floor(delta * time_speed))
	minute = (int(second) / 60 % 60)
	hour = (int(second) / 3600) % 24
	timeFormat = am_pm[hour / 12]
	minuteInterval = minute_intervals[minute / 10]

func change_day():
	second = 0
	minute = 0
	hour = 0
	day += 1
	
	weekdayIndex = int(day) % 7 - 1
	print_debug(weekdayIndex)
	
