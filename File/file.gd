extends Node

# Save to file
var first_practice_date: int = -1
var total_practiced_days: int = 0
var current_streak: int = 0
var longest_streak: int = 0
var last_completed_date: int = -1

var current_day: int = -1
var day_finished: bool = false

var update_stats: bool = false

var first_open: bool = true

# Save data to file
func save_data() -> void:
	var data: Dictionary = {}
	for variable: StringName in ["first_practice_date", "total_practiced_days", "current_streak", "longest_streak", "last_completed_date"]:
		data[variable] = get(variable)

	var file: FileAccess = FileAccess.open("user://data", FileAccess.WRITE)
	var jstr: String = JSON.stringify(data)
	file.store_line(jstr)

	update_stats = true

# Load data from file
func load_data() -> void:
	if !FileAccess.file_exists("user://data"):
		save_data()

	var file: FileAccess = FileAccess.open("user://data", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_line())

	for variable: StringName in data.keys():
		set(variable, data[variable])

	update_stats = true

var t: float = 0
func _process(delta: float) -> void:
	t += delta
	if t > 1:
		t = 0
		check_today()


var d: int = 0
func check_today() -> void:
	var today: int = get_date()
	var days_since_practice: int = roundi(float(today - last_completed_date) / 86400)
	if days_since_practice == 0:
		day_finished = true
	else:
		day_finished = false
	if days_since_practice > 1:
		current_streak = 0

	if d != today:
		update_stats = true
		d = today


func game_start() -> void:
	current_day = get_date()

func get_date() -> int:
	var today: Dictionary = Time.get_datetime_dict_from_system()
	today.hour = 0
	today.minute = 0
	today.second = 0
	today.dst = false
	return Time.get_unix_time_from_datetime_dict(today)


func practice_finished() -> void:
	if first_practice_date == -1:
		first_practice_date = current_day
	total_practiced_days += 1
	current_streak += 1
	if current_streak > longest_streak:
		longest_streak = current_streak
	last_completed_date = current_day
	check_today()
	save_data()


func _ready() -> void:
	load_data()
	check_today()
	var white: ColorRect = ColorRect.new()
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	white.size = Vector2(720, 720)
	add_child(white)
