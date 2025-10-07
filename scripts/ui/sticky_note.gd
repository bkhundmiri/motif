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
# Delete button removed - using context menu instead

# Context menu
var context_menu: PopupMenu

# Hover tooltip
var hover_tooltip: Label
var hover_timer: Timer
var is_hovering: bool = false

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
	_setup_hover_tooltip()
	_connect_signals()
	_calculate_anchor_points()

func _setup_note():
	"""Initialize the sticky note appearance and behavior"""
	# Generate unique ID using timestamp + random component for better uniqueness
	var timestamp = Time.get_time_dict_from_system()
	var unique_part = str(timestamp.hour) + str(timestamp.minute) + str(timestamp.second)
	var random_part = str(randi() % 1000000)  # Add random component
	var microsecond_part = str(Time.get_ticks_usec() % 1000000)  # Use microseconds for additional uniqueness
	note_id = "note_" + unique_part + "_" + microsecond_part + "_" + random_part
	print("Generated new note ID: %s" % note_id)
	
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
	"""Calculate anchor points on sides and corners for better connection positioning"""
	anchor_points.clear()
	var note_size = size
	var half_width = note_size.x / 2.0
	var half_height = note_size.y / 2.0
	var quarter_width = note_size.x / 4.0
	var quarter_height = note_size.y / 4.0
	var three_quarter_width = note_size.x * 3.0 / 4.0
	var three_quarter_height = note_size.y * 3.0 / 4.0
	
	# Side centers (primary anchors)
	anchor_points.append(Vector2(half_width, 0))  # Top center
	anchor_points.append(Vector2(note_size.x, half_height))  # Right center
	anchor_points.append(Vector2(half_width, note_size.y))  # Bottom center
	anchor_points.append(Vector2(0, half_height))  # Left center
	
	# Quarter points on each side for better positioning
	anchor_points.append(Vector2(quarter_width, 0))  # Top left quarter
	anchor_points.append(Vector2(three_quarter_width, 0))  # Top right quarter
	anchor_points.append(Vector2(note_size.x, quarter_height))  # Right top quarter
	anchor_points.append(Vector2(note_size.x, three_quarter_height))  # Right bottom quarter
	anchor_points.append(Vector2(three_quarter_width, note_size.y))  # Bottom right quarter
	anchor_points.append(Vector2(quarter_width, note_size.y))  # Bottom left quarter
	anchor_points.append(Vector2(0, three_quarter_height))  # Left bottom quarter
	anchor_points.append(Vector2(0, quarter_height))  # Left top quarter

func _setup_hover_tooltip():
	"""Set up hover tooltip for right-click hint"""
	hover_tooltip = _create_dark_tooltip("Right click for options")
	hover_tooltip.position = Vector2(10, -30)
	add_child(hover_tooltip)
	
	# Setup hover timer with reduced delay
	hover_timer = Timer.new()
	hover_timer.wait_time = 1.0  # Reduced from 2.0 seconds
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timeout)
	add_child(hover_timer)

func _create_dark_tooltip(text: String) -> Label:
	"""Create a dark tooltip with consistent styling"""
	var tooltip = Label.new()
	tooltip.text = text
	tooltip.visible = false
	tooltip.z_index = 1000
	
	# Create dark background style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.9)  # Dark semi-transparent
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.4, 0.4, 0.4, 1.0)
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	style_box.content_margin_left = 8
	style_box.content_margin_right = 8
	style_box.content_margin_top = 4
	style_box.content_margin_bottom = 4
	
	tooltip.add_theme_stylebox_override("normal", style_box)
	tooltip.add_theme_color_override("font_color", Color.WHITE)
	tooltip.add_theme_color_override("font_shadow_color", Color.BLACK)
	tooltip.add_theme_constant_override("shadow_offset_x", 1)
	tooltip.add_theme_constant_override("shadow_offset_y", 1)
	
	return tooltip

func _connect_signals():
	"""Connect internal signals"""
	text_edit.connect("text_changed", _on_text_changed)
	text_edit.connect("focus_entered", _on_text_edit_focus_entered)
	text_edit.connect("focus_exited", _on_text_edit_focus_exited)
	# Delete button removed - using context menu
	
	# Connect background input for dragging and hover
	background.connect("gui_input", _on_background_input)
	background.connect("mouse_entered", _on_mouse_entered)
	background.connect("mouse_exited", _on_mouse_exited)

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
					print("Note clicked during connection mode: ", note_id)
					emit_signal("connection_target_selected", self)
					get_viewport().set_input_as_handled()  # Prevent further processing
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
			
			# Update connections in real-time during dragging
			_update_connections_during_drag()

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

func _update_connections_during_drag():
	"""Update all connections that involve this note during dragging"""
	# Find all connection strings in the parent and update them
	var parent_node = get_parent()
	if parent_node:
		for child in parent_node.get_children():
			if child is ConnectionString:
				var connection = child as ConnectionString
				if connection.source_note == self or connection.target_note == self:
					connection._update_connection_points()

func _on_mouse_entered():
	"""Handle mouse entering the note area"""
	is_hovering = true
	hover_timer.start()

func _on_mouse_exited():
	"""Handle mouse leaving the note area"""
	is_hovering = false
	hover_timer.stop()
	hover_tooltip.visible = false

func _on_hover_timeout():
	"""Show tooltip after hover delay"""
	if is_hovering and not text_edit.has_focus():
		hover_tooltip.visible = true

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
	var old_id = note_id
	if data.has("id"):
		note_id = data["id"]
		print("Note ID changed from %s to %s" % [old_id, note_id])
	else:
		print("No ID in save data, keeping generated ID: %s" % note_id)
	if data.has("text"):
		set_note_text(data["text"])
	if data.has("position"):
		# Handle different position data formats
		var pos_data = data["position"]
		var note_position: Vector2
		
		if pos_data is Vector2:
			note_position = pos_data
		elif pos_data is Dictionary and pos_data.has("x") and pos_data.has("y"):
			# Handle dictionary format (from JSON serialization)
			note_position = Vector2(pos_data["x"], pos_data["y"])
		elif pos_data is String:
			# Handle string representation like "(200, 150)"
			var cleaned = pos_data.strip_edges().replace("(", "").replace(")", "")
			var parts = cleaned.split(",")
			if parts.size() >= 2:
				note_position = Vector2(float(parts[0].strip_edges()), float(parts[1].strip_edges()))
			else:
				note_position = Vector2.ZERO
		else:
			print("Warning: Invalid position data type for note %s: %s" % [note_id, typeof(pos_data)])
			note_position = Vector2.ZERO
		
		position = note_position + Vector2(50, 50)  # Add border offset that was subtracted during save
	if data.has("color_index"):
		set_note_color(data["color_index"])
