extends Node2D

@onready var main: Node2D = get_parent()
@onready var rename: LineEdit = $Info/Rename
var piece_button_scene: PackedScene = preload("res://Pieces/piece_button.tscn")

# Array containing dictionaries for each of the pieces
# Dictionaries contain:
# name
# first_practiced: Date in unix time of the first practice (no hours, minutes, seconds)
# last_practiced: Date in unix time of last practice (no hours, minutes, seconds)
# date_interacted: Date in unix time of when the piece was either created or last practiced with hours, minutes and seconds. used for ordering 
var piece_data: Array[Dictionary] = []

# Array containing all piece names
# Do not update this array, update piece_data and then call "update_piece_names"
var piece_names: Array[String] = []

var selected_piece: String = ""

func _ready() -> void:
	load_pieces()
	update_piece_names()
	update_scroll()
	if (!piece_names.is_empty()):
		new_piece_selected(piece_names[0])

func update_piece_names() -> void:
	piece_names = []
	# Store pieces by their dates
	var interacted_dates: Array[int] = []
	var interacted_to_name_dict: Dictionary = {}
	for p: Dictionary in piece_data:
		var interacted_date: int = p["date_interacted"]
		# Make sure no duplicate interated dates
		while (interacted_dates.has(interacted_date)):
			interacted_date += 1
		interacted_to_name_dict[str(interacted_date)] = p["name"]
		interacted_dates.append(interacted_date)

	# Sort dates
	interacted_dates.sort()
	interacted_dates.reverse()

	# Add pieces names to array (in order of interacted)
	for d: int in interacted_dates:
		piece_names.append(interacted_to_name_dict[str(d)])

	update_piece_select_buttons()
	save_pieces()

func get_dict_from_name(piece_name: String) -> Dictionary:
	for p: Dictionary in piece_data:
		if p["name"] == piece_name:
			return p

	return {}

func update_piece_select_buttons() -> void:
	for child: Node in $Select/PieceButtons.get_children():
		child.set_meta("free", true)
		child.queue_free()

	const POS_INCREMENT: int = 52
	var current_pos: int = 293
	for n: String in piece_names:
		var b: Area2D = piece_button_scene.instantiate()
		b.position.x = 176
		b.position.y = current_pos
		current_pos += POS_INCREMENT
		$Select/PieceButtons.add_child(b)
		b.get_node("Label").text = n
		b.set_meta("name", n)
		b.set_meta("free", false)


func _process(_delta: float) -> void:
	if (main.game_state == main.GAME_STATE.PIECES || (main.game_state == main.GAME_STATE.RUN && main.in_piece_select)):
		# Selecting pieces
		for button: Area2D in $Select/PieceButtons.get_children():
			if button.pressed:
				new_piece_selected(button.get_node("Label").text)

		handle_renaming()
		handle_adding_pieces()
		handle_scrolling()

		$Back.visible = !(main.game_state == main.GAME_STATE.RUN && main.in_piece_select && piece_names.size() == 0)

	else:
		rename.unedit()
		rename.text = ""
		$Select/NewPiece.unedit()
		$Select/NewPiece.text = ""

func handle_renaming() -> void:
	var confirm_rename: Area2D = $Info/ConfirmRename
	var new_name: String = rename.text
	var new_name_valid: bool = new_name != "" && !piece_names.has(new_name)
	confirm_rename.visible = new_name_valid
	rename.visible = !piece_names.is_empty()

	# Update name
	if (confirm_rename.pressed && new_name_valid):
		get_dict_from_name(selected_piece)["name"] = new_name
		update_piece_names()
		new_piece_selected(new_name)
		rename.unedit()
		update_scroll()


func handle_adding_pieces() -> void:
	var confirm_new_piece: Area2D = $Select/ConfirmNewPiece
	var new_piece: String = $Select/NewPiece.text
	var new_piece_valid: bool = new_piece != "" && !piece_names.has(new_piece)
	confirm_new_piece.visible = new_piece_valid
	# Add new piece
	if (confirm_new_piece.pressed && new_piece_valid):
		var new_piece_dict: Dictionary = {
			"name" = new_piece, 
			"first_practiced" = -1,
			"last_practiced" = -1,
			"times_practiced" = 0,
			"date_interacted" = roundi(Time.get_unix_time_from_system()),
		}
		piece_data.append(new_piece_dict)
		update_piece_names()
		new_piece_selected(new_piece)
		$Select/NewPiece.text = ""
		$Select/NewPiece.unedit()
		current_scroll = 0
		update_scroll()

var current_scroll: int = 0
func handle_scrolling() -> void:
	var up: Area2D = $Select/Up
	var down: Area2D = $Select/Down

	up.visible = current_scroll > 0
	down.visible = current_scroll < piece_names.size() - 6

	if (up.pressed):
		current_scroll -= 1
		update_scroll()
	if (down.pressed):
		current_scroll += 1
		update_scroll()


func update_scroll() -> void:
	$Select/PieceButtons.position.y = -52 * current_scroll

	var idx: int = 0
	for child: Node in $Select/PieceButtons.get_children():
		if (child.get_meta("free")):
			continue
		if (idx < current_scroll + 1) && !(current_scroll == 0 && idx == 0):
			child.hide() 
		elif (idx > 5 + current_scroll) || (current_scroll + 5 == idx) && !(current_scroll == piece_names.size() - 6):
			child.hide()
		else:
			child.show()

		idx += 1


func new_piece_selected(piece_name: String) -> void:
	selected_piece = piece_name
	# Highlight button
	for b: Area2D in $Select/PieceButtons.get_children():
		if (b.get_meta("name") == piece_name):
			b.get_node("Highlight").visible = true
		else:
			b.get_node("Highlight").visible = false

	rename.text = ""

	# Update info
	var piece_dict: Dictionary = get_dict_from_name(piece_name)
	$Info/Name.text = piece_name
	$Info/FirstPractice.text = "First Practice: " + main.get_date_from_unix(piece_dict["first_practiced"])
	$Info/LastPractice.text = "Last Practice: " + main.get_date_from_unix(piece_dict["last_practiced"])
	$Info/TimesPracticed.text = "Times Practiced: " + str(piece_dict["times_practiced"])


func save_pieces() -> void:
	var file: FileAccess = FileAccess.open("user://pieces", FileAccess.WRITE)
	for data: Dictionary in piece_data:
		var jstr: String = JSON.stringify(data)
		file.store_line(jstr)

func load_pieces() -> void:
	if !FileAccess.file_exists("user://pieces"):
		return

	piece_data = []
	var file: FileAccess = FileAccess.open("user://pieces", FileAccess.READ)
	while (!file.eof_reached()):
		var json: JSON = JSON.new()
		if (json.parse(file.get_line()) == OK):
			var content: Variant = json.data
			if (content is Dictionary):
				for k: String in content.keys():
					if content[k] is float:
						content[k] = int(content[k])
				piece_data.append(content)

func practice_finished() -> void:
	var date: int = File.get_date()
	var data: Dictionary = get_dict_from_name(selected_piece)
	if (data["first_practiced"] < 0):
		data["first_practiced"] = date
	data["last_practiced"] = date
	data["times_practiced"] += 1
	data["date_interacted"] = roundi(Time.get_unix_time_from_system())

	update_piece_names()
