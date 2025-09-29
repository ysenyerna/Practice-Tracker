extends Area2D

var queue_press: bool = false
var pressed: bool = false
var hovered: bool = false

var tweening: bool = false

func _ready() -> void:
	connect("mouse_entered", _mouse_entered)
	connect("mouse_exited", _mouse_exited)


func _mouse_entered() -> void:
	hovered = true

func _mouse_exited() -> void:
	hovered = false

const SCALE_SPEED: float = 16
func _process(delta: float) -> void:
	# Press
	if pressed:
		pressed = false
		play_press_anim()

	if queue_press:
		pressed = true
		queue_press = false

	if !tweening:
		if (hovered):
			scale = scale.lerp(Vector2(1.2, 1.2), SCALE_SPEED * delta)
		else:
			scale = scale.lerp(Vector2(1, 1), SCALE_SPEED * delta)


# Get pressed
func _input(event: InputEvent) -> void:
	if !hovered:
		return
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if (e.button_index == 1) && (e.pressed):
			queue_press = true
			SoundManager.play_sound("button_press")

			get_tree().current_scene.button_pressed = true

func play_press_anim() -> void:
	var t: Tween = create_tween()
	tweening = true
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	t.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	t.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	t.tween_property(self, "tweening", false, 0.1)
