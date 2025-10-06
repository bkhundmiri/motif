extends Control
class_name StickyNote

## Sticky Note component for the Case Board
## Draggable note with editable text

# Signals
signal note_moved(note: StickyNote, new_position: Vector2)
signal note_deleted(note: StickyNote)
signal note_edited(note: StickyNote, new_text: String)

# UI References
@onready var background: Panel = $Background
@onready var text_edit: TextEdit = $Background/TextEdit
@onready var delete_button: Button = $Background/DeleteButton

# Properties
var note_id: String = ""
var is_dragging: bool = false
var drag_offset: Vector2

# Note styling
var note_colors: Array[Color] = [
	Color.YELLOW,
	Color.LIGHT_BLUE,
	Color.LIGHT_GREEN,
	Color.PINK,
	Color.ORANGE
]
var current_color_index: int = 0

func _ready():
	# Set up the sticky note
	_setup_note()
	_connect_signals()

func _setup_note():
	"""Initialize the sticky note appearance and behavior"""
	# Generate unique ID
	note_id = "note_" + str(Time.get_time_dict_from_system().hash())
	
	# Set initial size
	custom_minimum_size = Vector2(150, 150)
	size = Vector2(150, 150)
	
	# Set initial color
	_update_note_color()

func _connect_signals():
	"""Connect internal signals"""
	text_edit.connect("text_changed", _on_text_changed)
	delete_button.connect("pressed", _on_delete_pressed)
	
	# Connect background input for dragging
	background.connect("gui_input", _on_background_input)

func _update_note_color():
	"""Update the note's background color"""
	if background:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = note_colors[current_color_index]
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.GRAY
		style_box.corner_radius_top_left = 5
		style_box.corner_radius_top_right = 5
		style_box.corner_radius_bottom_left = 5
		style_box.corner_radius_bottom_right = 5
		background.add_theme_stylebox_override("panel", style_box)

func _gui_input(event):
	"""Handle mouse input for dragging from anywhere on the note"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging - store the offset from mouse to note position
				is_dragging = true
				drag_offset = event.position  # Local offset within the note
				move_to_front()  # Bring to front when clicked
			else:
				# Stop dragging
				if is_dragging:
					is_dragging = false
					emit_signal("note_moved", self, position)
	
	elif event is InputEventMouseMotion and is_dragging:
		# Handle dragging using global mouse position and coordinate transformation
		var global_mouse_pos = get_global_mouse_position()
		var parent_node = get_parent()
		
		if parent_node:
			# Convert global mouse position to parent's local coordinate space
			# For Control nodes, we transform through the parent's global transform
			var parent_transform = parent_node.get_global_transform()
			var local_mouse_pos = parent_transform.affine_inverse() * global_mouse_pos
			
			# Calculate desired position relative to where we clicked on the note
			var desired_position = local_mouse_pos - drag_offset
			
			# Constrain position to stay within white canvas bounds
			var constrained_position = _constrain_to_canvas(desired_position)
			position = constrained_position

func _constrain_to_canvas(desired_pos: Vector2) -> Vector2:
	"""Constrain sticky note position to stay within white canvas bounds"""
	# Canvas parameters (matching case_board_ui.gd)
	var border_size = 50.0
	var board_size = Vector2(4000, 3000)
	
	# Calculate canvas boundaries in parent coordinate space
	var canvas_start = Vector2(border_size, border_size)
	var canvas_end = canvas_start + board_size
	
	# Note size
	var note_size = size
	
	# Constrain position to keep note completely within canvas
	var constrained_pos = desired_pos
	constrained_pos.x = clamp(constrained_pos.x, canvas_start.x, canvas_end.x - note_size.x)
	constrained_pos.y = clamp(constrained_pos.y, canvas_start.y, canvas_end.y - note_size.y)
	
	return constrained_pos

func _on_background_input(event):
	"""Handle input from the background panel for dragging"""
	# Forward input to the main drag handler
	_gui_input(event)

func _on_text_changed():
	"""Handle text changes"""
	emit_signal("note_edited", self, text_edit.text)

func _on_delete_pressed():
	"""Handle delete button press"""
	emit_signal("note_deleted", self)

# Public methods
func set_note_text(text: String):
	"""Set the note's text content"""
	if text_edit:
		text_edit.text = text

func get_note_text() -> String:
	"""Get the note's text content"""
	if text_edit:
		return text_edit.text
	return ""

func set_note_color(color_index: int):
	"""Set the note's color by index"""
	if color_index >= 0 and color_index < note_colors.size():
		current_color_index = color_index
		_update_note_color()

func cycle_note_color():
	"""Cycle to the next color"""
	current_color_index = (current_color_index + 1) % note_colors.size()
	_update_note_color()

func get_save_data() -> Dictionary:
	"""Get data for saving this note"""
	return {
		"id": note_id,
		"text": get_note_text(),
		"position": global_position,
		"color_index": current_color_index
	}

func load_from_data(data: Dictionary):
	"""Load note from saved data"""
	if data.has("id"):
		note_id = data["id"]
	if data.has("text"):
		set_note_text(data["text"])
	if data.has("position"):
		global_position = data["position"]
	if data.has("color_index"):
		set_note_color(data["color_index"])
