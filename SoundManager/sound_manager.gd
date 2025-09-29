extends Node

var sounds: Dictionary = {
	"button_press" = load("res://Resources/Sounds/button_press.mp3"),
	"mouse_press" = load("res://Resources/Sounds/mouse_press.mp3"),
	"transition" = load("res://Resources/Sounds/transition.mp3"),


	"alarm_soft" = load("res://Resources/Sounds/alarm_soft.mp3"),
	"alarm_bell" = load("res://Resources/Sounds/alarm_bell.mp3"),
	"alarm_drum" = load("res://Resources/Sounds/alarm_drum.mp3")
	
}

var alarm_sound: String = "soft"


func play_sound(sound_name: String) -> void:
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	audio.stream = sounds[sound_name]
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)

var alarm: AudioStreamPlayer = null
var alarm_vol: float = 0
func play_alarm() -> void:
	# Tween alarm volume
	alarm_vol = 0
	var t: Tween = create_tween()
	t.tween_property(self, "alarm_vol", 1, 15)
	

	# Erase previous alarm
	if alarm:
		alarm.queue_free()
	alarm = null

	# Create new alarm
	if alarm_sound != "none":
		var audio: AudioStreamPlayer = AudioStreamPlayer.new()
		alarm = audio
		audio.stream = sounds["alarm_" + alarm_sound]
		audio.stream.loop = true
		add_child(audio)
		audio.play()

func end_alarm() -> void:
	if alarm:
		alarm.queue_free()
	alarm = null

func _process(_delta: float) -> void:
	if alarm:
		alarm.volume_linear = alarm_vol
