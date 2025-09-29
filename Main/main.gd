extends Node2D

@onready var transition: Sprite2D = $Transition
@onready var run_time: Timer = $Run/RunTime

enum GAME_STATE { TITLE, RUN, TRANSITION, STATS, SETTINGS, PIECES}
var game_state: GAME_STATE = GAME_STATE.TITLE

const MENU_SPEED: float = 6
var menu_position: float = 0

var trans_amount: float = 0
var trans_alpha: float = 1

var pausing_enabled: bool = false
var time_paused: bool = false
var practice_stage: int = 0

var button_pressed: bool = false


func _ready() -> void:
	load_settings()
	update_stats()

	var loading: bool = load_session()

	if (!loading):
		clear_session()

	$Run.visible = loading
	$Title.visible = !loading

	$Transition.visible = true

	$Stats.visible = true
	$Stats.position.x = 720

	$Settings.visible = true
	$Settings.position.x = -720

	$Pieces.visible = true
	$Pieces.position.x = 1440

	if (File.first_open):
		File.first_open = false
	else:
		trans_amount = 1
		trans_alpha = 1
		transition.material.set("shader_parameter/pos", Vector2(0.5, 0.5))
		transition.material.set("shader_parameter/rad", trans_amount)
		transition.material.set("shader_parameter/alpha", trans_alpha)
		var t: Tween = create_tween()
		t.tween_interval(0.1)
		t.tween_property(self, "trans_alpha", 0, 1)
		t.tween_callback(reset_trans)

func reset_trans() -> void:
	trans_amount = 0
	trans_alpha = 1

var in_piece_select: bool = false

var save_time: float = 0
func _process(delta: float) -> void:

	# Transition
	transition.material.set("shader_parameter/rad", trans_amount)
	transition.material.set("shader_parameter/alpha", trans_alpha)

	# Stats
	if File.update_stats:
		update_stats()
		File.update_stats = false

	match game_state:
		GAME_STATE.TITLE:
			menu_position = lerp(menu_position, 0.0, delta * MENU_SPEED)
			for button: Node in $Title/Buttons.get_children():
				if button.pressed:
					handle_title_buttons(button)

			$Title/End.visible = File.day_finished
			$Title/Buttons/Start.visible = !File.day_finished
			$Title/Streak.text = "Daily Streak: " + str(File.current_streak)

		GAME_STATE.RUN:
			# Save every 10 seconds
			if save_time < 10:
				save_time += delta
			else:
				save_time = 0
				save_session()

			if (!in_piece_select):
				menu_position = lerp(menu_position, 0.0, delta * MENU_SPEED)
				handle_time_label()
				handle_pausing()
			else:
				menu_position = lerp(menu_position, -720.0, delta * MENU_SPEED)
				$Stats.visible = false
				$Pieces.position.x = 720
				$Pieces/Back/Label.text = "Select this one"
				$Pieces/Back/Collision.shape.size.x = 234

				if ($Pieces/Back.pressed):
					$Run/PieceName.text = "Currently practicing: " + $Pieces.selected_piece
					in_piece_select = false
					progress_run(2)

		GAME_STATE.STATS:
			menu_position = lerp(menu_position, -720.0, delta * MENU_SPEED)
			if $Stats/Back.pressed:
				game_state = GAME_STATE.TITLE
			if $Stats/Pieces.pressed:
				game_state = GAME_STATE.PIECES

		GAME_STATE.SETTINGS:
			handle_settings()
			menu_position = lerp(menu_position, 720.0, delta * MENU_SPEED)
			if $Settings/Back.pressed:
				game_state = GAME_STATE.TITLE
				$Settings/Buttons/Sound/SoundPreview.stop()

		GAME_STATE.PIECES:
			menu_position = lerp(menu_position, -1440.0, delta * MENU_SPEED)
			if $Pieces/Back.pressed:
				game_state = GAME_STATE.STATS


	# Menu positions
	$Run.position.x = menu_position
	$Title.position.x = menu_position
	$Stats.position.x = menu_position + 720
	$Settings.position.x = menu_position - 720
	$Pieces.position.x = menu_position + (720 if game_state == GAME_STATE.RUN else 1440)

func handle_title_buttons(button: Node) -> void:
	match button.name:
		"Start":
			File.game_start()
			game_state = GAME_STATE.TRANSITION
			transition.material.set("shader_parameter/pos", get_global_mouse_position() / 720)
			SoundManager.play_sound("transition")
			var t: Tween = create_tween()
			t.set_trans(Tween.TRANS_QUINT)
			t.tween_property(self, "trans_amount", 1, 1.0)
			t.tween_callback(start_run)

		"Settings":
			game_state = GAME_STATE.SETTINGS

		"Stats":
			game_state = GAME_STATE.STATS

		"Close":
			get_tree().quit()


#region RUN
func handle_time_label() -> void:
	var t: float = roundf(run_time.time_left)
	var m: int = floori(t / 60)
	var s: int = roundi(t - m * 60)
	var s_string: String = str(s)
	if s_string.length() == 1:
		s_string = "0" + s_string
	var m_string: String = str(m)

	var time_left: String = m_string + ":" + s_string
	$Run/Timer.text = time_left

func handle_pausing() -> void:
	# Timer ended
	var time_ended: bool = $Run/RunTime.is_stopped()
	if time_ended:
		time_paused = false
		run_time.paused = false
		$Run/Pause/Label.text = "Finish" if practice_stage == 2 else "Next"
		# Progress
		if $Run/Pause.pressed:
			SoundManager.end_alarm()
			if practice_stage == 0:
				progress_run(1)

			elif practice_stage == 1:
				in_piece_select = true


			elif practice_stage == 2:
				$Pieces.practice_finished()
				File.practice_finished()
				clear_session()

				# Back to title transition
				game_state = GAME_STATE.TRANSITION
				transition.material.set("shader_parameter/pos", get_global_mouse_position() / 720)
				trans_alpha = 1
				trans_amount = 0
				SoundManager.play_sound("transition")
				var t: Tween = create_tween()
				t.set_trans(Tween.TRANS_QUINT)
				t.tween_property(self, "trans_amount", 1, 1.0)
				t.tween_callback(get_tree().reload_current_scene)



			var t2: Tween = create_tween()
			t2.set_trans(Tween.TRANS_QUAD)
			t2.tween_property($Run/Activity, "scale", Vector2(0.9, 1.1), 0.1)
			t2.tween_property($Run/Activity, "scale", Vector2(1.1, 0.9), 0.1)
			t2.tween_property($Run/Activity, "scale", Vector2(1, 1), 0.1)
			$Run/Pause/Label.text = "Pause"


	# Pausing
	elif pausing_enabled:
		if $Run/Pause.pressed:
			time_paused = !time_paused
	
			run_time.paused = time_paused
			$Run/Pause/Label.text = "Pause" if !time_paused else "Resume"


	# Timer Blinking
	if time_paused || time_ended:
		if $Run/TimerBlink.is_stopped():
			$Run/TimerBlink.start()
		$Run/Timer.visible = true if $Run/TimerBlink.time_left < $Run/TimerBlink.wait_time / 2 else false
	else:
		$Run/Timer.visible = true

func start_run() -> void:
	$Title.visible = false
	$Run.visible = true
	game_state = GAME_STATE.RUN
	progress_run(0)

	# Transition
	var t: Tween = create_tween()
	t.tween_interval(0.1)
	t.tween_property(self, "trans_alpha", 0, 1)
	t.tween_property(self, "pausing_enabled", true, 0.1)


func progress_run(stage: int, time_left: int = -1) -> void:
	practice_stage = stage
	var full_time: int = -1

	if (stage == 0):
		$Run/Activity/Label.text = "Scales"
		full_time = 900
	elif (stage == 1):
		$Run/Activity/Label.text = "Free Practice"
		full_time = 900
	elif (stage == 2):
		$Run/Activity/Label.text = "Piece Practice"
		full_time = 1800

	run_time.start(full_time if time_left < 0 else time_left)


func run_time_ended() -> void:
	SoundManager.play_alarm()
	$Run/Pause.play_press_anim()

#endregion

#region STATS 
func update_stats() -> void:
	$Stats/FirstPractice.text = "First Practice Date: " + get_date_from_unix(File.first_practice_date)
	$Stats/LastPractice.text = "Last Practice Date: " + get_date_from_unix(File.last_completed_date)
	$Stats/TotalPractice.text = "Total Practice Days: " + str(File.total_practiced_days)
	var missed_days: int = 0
	if (File.first_practice_date > 0):
		missed_days = roundi(float(File.get_date() - File.first_practice_date) / 86400) - File.total_practiced_days
		if File.day_finished: missed_days += 1
	$Stats/TotalMissed.text = "Total Missed Days: " + str(missed_days)
	$Stats/CurrentStreak.text = "Current Streak: " + str(File.current_streak)
	$Stats/LongestStreak.text = "Longest Streak: " + str(File.longest_streak)

func get_date_from_unix(unix: int) -> String:
	var date: String = "N/A"
	if unix >= 0:
		date = Time.get_datetime_string_from_unix_time(unix, true)
		date = date.split(" ")[0]
	return date

#endregion

#region SETTINGS STUFFS
const VOLUME: Array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
var volume: int = 10
const SOUND: Array = ["Soft", "Bell", "Drum", "None"]
var sound: String = "Soft"
const BACKGROUND: Array = ["Night", "Mint", "Ember"]
var background: String = "Night"
const WINDOW_SIZE: Array = [480, 720, 1080, 1440]
var window_size: int = 720

func handle_settings() -> void:
	for button: Node in $Settings/Buttons.get_children():
		if button.pressed:
			$Settings/Buttons/Sound/SoundPreview.stop()
			# Get values
			var left: bool = (get_global_mouse_position().x - button.global_position.x) < 0
			var setting_name: StringName = button.name.to_snake_case()
			var setting_array: Array = get(setting_name.to_upper())
			var setting_value: Variant = get(setting_name)
			var value_position: int = setting_array.find(setting_value)
			var array_size: int = setting_array.size() - 1
			var new_value_position: int = 0

			# Find new value
			if (left):
				if (value_position == 0):
					new_value_position = array_size
				else:
					new_value_position = value_position - 1
			else:
				if (value_position == array_size):
					new_value_position = 0
				else:
					new_value_position = value_position + 1

			var new_value: Variant = setting_array[new_value_position]
			set(setting_name, new_value)

			# Update Settings
			update_setting(setting_name, new_value, true)

func update_setting(setting_name: StringName, setting_value: Variant, play_new_alarm: bool = false) -> void:
	# Update settings
	if (setting_name == "volume"):
		AudioServer.set_bus_volume_linear(0, float(setting_value) / 10.0)
	if (setting_name == "sound"):
		SoundManager.alarm_sound = setting_value.to_lower()
		if play_new_alarm && setting_value != "None":
			var sound_preview: AudioStreamPlayer = $Settings/Buttons/Sound/SoundPreview
			sound_preview.stop()
			sound_preview.stream = SoundManager.sounds["alarm_" + setting_value.to_lower()]
			sound_preview.play()

	elif (setting_name == "background"):
		$BG.texture = load("res://Resources/Backgrounds/bg_" + str(setting_value).to_lower() + ".png")
	elif (setting_name == "window_size"):
		DisplayServer.window_set_size(Vector2i(setting_value, setting_value))

	# Save settings
	save_settings()

	# Update labels
	var new_text: String = ""
	match setting_name:
		"volume": new_text = "Volume: " + str(setting_value)
		"sound": new_text = "Alarm Sound: " + setting_value
		"background": new_text = "Background: " + setting_value
		"window_size": new_text = "Window Size: " + str(setting_value)
	get_node("Settings/Buttons/" + setting_name.to_pascal_case() + "/Label").text = new_text

func save_settings() -> void:
	var data: Dictionary = {}
	for setting: StringName in ["volume", "sound", "background", "window_size"]:
		data[setting] = get(setting)

	var file: FileAccess = FileAccess.open("user://settings", FileAccess.WRITE)
	var jstr: String = JSON.stringify(data)
	file.store_line(jstr)

func load_settings() -> void:
	if !FileAccess.file_exists("user://settings"):
		save_settings()

	var file: FileAccess = FileAccess.open("user://settings", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_line())

	for setting: StringName in data.keys():
		set(setting, data[setting])
		update_setting(setting, get(setting))

#endregion

# Mouse particles
var mouse_particles: PackedScene = load("res://Particles/button_particles.tscn")
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if (e.button_index == 1) && (e.pressed):
			var p: GPUParticles2D = mouse_particles.instantiate()
			p.global_position = get_global_mouse_position()
			
			add_child(p)
			p.connect("finished", p.queue_free)
			p.emitting = true

			if (!button_pressed):
				SoundManager.play_sound("mouse_press")
			button_pressed = false

#region SAVING SESSION

func save_session() -> void:
	var data: Dictionary = {
		"date" = File.current_day,
		"stage" = practice_stage,
		"time_left" = $Run/RunTime.time_left,
		"piece" = $Pieces.selected_piece
	}

	var file: FileAccess = FileAccess.open("user://session", FileAccess.WRITE)
	var jstr: String = JSON.stringify(data)
	file.store_line(jstr)

func clear_session() -> void:
	FileAccess.open("user://session", FileAccess.WRITE)

func load_session() -> bool:
	if !FileAccess.file_exists("user://session"):
		return false

	var file: FileAccess = FileAccess.open("user://session", FileAccess.READ)
	var json: JSON = JSON.new()
	if (json.parse(file.get_line()) != OK):
		return false

	var content: Variant = json.data

	# Check if it's not the same day
	if (int(content["date"]) != File.get_date()):
		return false

	# Resume the run
	game_state = GAME_STATE.RUN
	$Pieces.selected_piece = content["piece"]
	if (content["stage"] == 2):
		$Run/PieceName.text = "Currently Practicing: " + content["piece"]

	File.game_start()
	pausing_enabled = true
	run_time.paused = true
	$Run/Pause/Label.text = "Resume"
	time_paused = true
	progress_run(int(content["stage"]), content["time_left"])

	return true

#endregion
