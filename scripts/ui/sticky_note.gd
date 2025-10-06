extends Control
class_name StickyNote

## Sticky Note component for the Case Board
## Draggable note with editable text

# Signals
signal note_moved(note: StickyNote, new_position: Vector2)
signal note_deleted(note: StickyNote)
signal note_edited(note: StickyNote, new_text: String)
signal connection_requested(note: StickyNote)
signal connection_target_selected(note: StickyNote)
signal text_edit_started()
signal text_edit_finished()

# UI References
@onready var background: Panel = $Background
@onready var text_edit: TextEdit = $Background/TextEdit
@onready var delete_button: Button = $Background/DeleteButton

# Context menu
var context_menu: PopupMenu

# Properties
var note_id: String = ""
var is_dragging: bool = false
var drag_offset: Vector2

# Connection system
var connected_notes: Array[StickyNote] = []
var anchor_points: Array[Vector2] = []

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
	_setup_context_menu()
	_connect_signals()
	_calculate_anchor_points()

func _setup_note():
	"""Initialize the sticky note appearance and behavior"""
	# Generate unique ID
	note_id = "note_" + str(Time.get_time_dict_from_system().hash())
	
	# Set initial size
	custom_minimum_size = Vector2(150, 150)
	size = Vector2(150, 150)
	
	# Set initial color
	_update_note_color()

func _setup_context_menu():
	"""Set up the right-click context menu"""
	context_menu = PopupMenu.new()
	context_menu.add_item("Delete Note", 0)
	context_menu.add_item("Clear Note", 1)
	context_menu.add_item("Create Connection", 2)
	context_menu.connect("id_pressed", _on_context_menu_selected)
	add_child(context_menu)

func _calculate_anchor_points():
	"""Calculate anchor points on the middle of each side"""
	anchor_points.clear()
	var note_size = size
	var half_width = note_size.x / 2.0
	var half_height = note_size.y / 2.0
	
	# Top, Right, Bottom, Left
	anchor_points.append(Vector2(half_width, 0))  # Top
	anchor_points.append(Vector2(note_size.x, half_height))  # Right
	anchor_points.append(Vector2(half_width, note_size.y))  # Bottom
	anchor_points.append(Vector2(0, half_height))  # Left

func _connect_signals():
	"""Connect internal signals"""
	text_edit.connect("text_changed", _on_text_changed)
	text_edit.connect("focus_entered", _on_text_edit_focus_entered)
	text_edit.connect("focus_exited", _on_text_edit_focus_exited)
	delete_button.connect("pressed", _on_delete_pressed)
	
	# Connect background input for dragging
	background.connect("gui_input", _on_background_input)

func _on_context_menu_selected(id: int):
	"""Handle context menu selection"""
	match id:
		0:  # Delete Note
			emit_signal("note_deleted", self)
		1:  # Clear Note
			set_note_text("")
		2:  # Create Connection
			emit_signal("connection_requested", self)

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
				# Check if this is a connection target selection
				var case_board = _find_case_board()
				if case_board and case_board.has_method("is_connecting") and case_board.is_connecting():
					emit_signal("connection_target_selected", self)
					return
				
				# Start dragging - store the offset from mouse to note position
				is_dragging = true
				drag_offset = event.position  # Local offset within the note
				move_to_front()  # Bring to front when clicked
			else:
				# Stop dragging
				if is_dragging:
					is_dragging = false
					emit_signal("note_moved", self, position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Show context menu
			context_menu.position = get_global_mouse_position()
			context_menu.popup()
	
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
	# Save position relative to canvas (subtract border offset)
	var canvas_position = position - Vector2(50, 50)  # border_size = 50
	return {
		"id": note_id,
		"text": get_note_text(),
		"position": {"x": canvas_position.x, "y": canvas_position.y},  # Save as dictionary for JSON compatibility
		"color_index": current_color_index
	}

func get_closest_anchor_point(target_position: Vector2) -> Vector2:
	"""Get the anchor point closest to the target position"""
	var note_pos = position
	var best_anchor = anchor_points[0]
	var best_distance = INF
	
	for anchor in anchor_points:
		var world_anchor = note_pos + anchor
		var distance = world_anchor.distance_to(target_position)
		if distance < best_distance:
			best_distance = distance
			best_anchor = anchor
	
	return note_pos + best_anchor

func get_global_anchor_points() -> Array[Vector2]:
	"""Get all anchor points in global coordinates"""
	var global_anchors: Array[Vector2] = []
	var note_pos = position
	
	for anchor in anchor_points:
		global_anchors.append(note_pos + anchor)
	
	return global_anchors

func add_connection(target_note: StickyNote):
	"""Add a connection to another note"""
	if target_note not in connected_notes:
		connected_notes.append(target_note)

func _find_case_board() -> Control:
	"""Find the case board UI in the parent hierarchy"""
	var parent = get_parent()
	while parent:
		if parent.has_method("is_connecting"):
			return parent
		parent = parent.get_parent()
	return null

func _on_text_edit_focus_entered():
	"""Handle text edit gaining focus"""
	emit_signal("text_edit_started")

func _on_text_edit_focus_exited():
	"""Handle text edit losing focus"""
	emit_signal("text_edit_finished")

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
