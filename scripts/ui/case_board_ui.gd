extends Control
class_name CaseBoardUI

## Case Board UI System with proper zoom-to-cursor and pan
## Uses direct Control manipulation instead of ScrollContainer

# Signals
signal case_board_closed()

# UI References
@onready var background_blur: ColorRect = $BackgroundBlur
@onready var case_board_panel: Panel = $CaseBoardPanel
@onready var board_container: Control = $CaseBoardPanel/MainVBox/BoardContainer
@onready var board_viewport: Control = $CaseBoardPanel/MainVBox/BoardContainer/BoardViewport
@onready var board_content: Control = $CaseBoardPanel/MainVBox/BoardContainer/BoardViewport/BoardContent

# Toolbar references
@onready var case_tabs_control: TabContainer = $CaseBoardPanel/MainVBox/ToolbarContainer/CaseTabsContainer/CaseTabsControl
@onready var new_case_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/CaseTabsContainer/NewCaseButton
@onready var add_note_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/AddNoteButton
@onready var clear_board_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/ClearBoardButton
@onready var close_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/CloseButton

# Transform properties
var zoom_level: float = 1.0
var min_zoom: float = 0.3
var max_zoom: float = 2.0
var zoom_step: float = 0.1
var board_offset: Vector2 = Vector2.ZERO

# Interaction state
var is_panning: bool = false
var last_mouse_position: Vector2

# Board properties
var board_size: Vector2 = Vector2(4000, 3000)  # Fixed large canvas for all resolutions
var border_size: float = 50.0  # Small border edge
var border_color: Color = Color(0.15, 0.15, 0.15)
var canvas_color: Color = Color.WHITE

# Board state
var sticky_notes: Array = []
var current_case_index: int = 0
var case_boards: Array = []

# Case management
class CaseData:
	var name: String
	var notes: Array = []
	var board_data: Dictionary = {}
	
	func _init(case_name: String):
		name = case_name

func _ready():
	# Set up the case board UI
	_setup_ui()
	_setup_board()
	_connect_signals()
	
	# Initialize with first case
	_initialize_cases()

func _setup_ui():
	"""Set up the main UI layout"""
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Set up background blur
	background_blur.color = Color(0, 0, 0, 0.7)
	
	# Set up case board panel (85% of screen)
	case_board_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var screen_size = get_viewport().get_visible_rect().size
	var panel_size = screen_size * 0.85
	case_board_panel.size = panel_size
	case_board_panel.position = (screen_size - panel_size) / 2

func _setup_board():
	"""Initialize the board content area with proper clipping"""
	# Set up viewport for clipping
	board_viewport.clip_contents = true
	
	# Calculate total content size including border
	var total_size = board_size + Vector2(border_size * 2, border_size * 2)
	
	# Set up board content size
	board_content.custom_minimum_size = total_size
	board_content.size = total_size
	
	# Create visual background
	_create_board_background()
	
	# Calculate zoom limits and center board
	call_deferred("_calculate_zoom_limits")

func _create_board_background():
	"""Create the visual board background with borders"""
	# Remove existing background
	for child in board_content.get_children():
		if child.name == "BoardBackground":
			child.queue_free()
	
	# Create border background
	var background = ColorRect.new()
	background.name = "BoardBackground"
	background.color = border_color
	background.size = board_content.size
	background.position = Vector2.ZERO
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_content.add_child(background)
	board_content.move_child(background, 0)
	
	# Create white canvas area
	var canvas = ColorRect.new()
	canvas.name = "BoardCanvas"
	canvas.color = canvas_color
	canvas.size = board_size
	canvas.position = Vector2(border_size, border_size)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(canvas)

func _is_position_in_canvas(pos: Vector2) -> bool:
	"""Check if a position is within the white canvas area"""
	var canvas_rect = Rect2(Vector2.ZERO, board_size)
	return canvas_rect.has_point(pos)

func _clamp_position_to_canvas(pos: Vector2, note_size: Vector2 = Vector2(150, 150)) -> Vector2:
	"""Clamp position to keep note fully within canvas bounds"""
	var clamped_pos = pos
	clamped_pos.x = clamp(clamped_pos.x, 0, board_size.x - note_size.x)
	clamped_pos.y = clamp(clamped_pos.y, 0, board_size.y - note_size.y)
	return clamped_pos

func _center_board():
	"""Center the white canvas in the viewport"""
	var viewport_size = board_viewport.size
	var canvas_size_scaled = board_size * zoom_level
	var border_offset_scaled = Vector2(border_size, border_size) * zoom_level
	
	# Center the white canvas, not the entire board content
	var canvas_center_offset = (viewport_size - canvas_size_scaled) / 2
	board_offset = canvas_center_offset - border_offset_scaled
	_update_board_transform()

func _calculate_zoom_limits():
	"""Calculate proper zoom limits"""
	var viewport_size = board_viewport.size
	
	if viewport_size.x > 0 and viewport_size.y > 0:
		# Calculate zoom to fit canvas (not total) in viewport with some padding
		var fit_zoom_x = viewport_size.x / board_size.x
		var fit_zoom_y = viewport_size.y / board_size.y
		min_zoom = min(fit_zoom_x, fit_zoom_y) * 0.8  # Leave 20% padding
		
		# Set initial zoom to fit canvas nicely
		zoom_level = min_zoom * 1.2  # Slightly zoomed in from min
		zoom_level = clamp(zoom_level, min_zoom, max_zoom)
		
		# Re-center after zoom adjustment
		_center_board()

func _connect_signals():
	"""Connect UI signals"""
	close_button.connect("pressed", _on_close_button_pressed)
	add_note_button.connect("pressed", _on_add_note_pressed)
	clear_board_button.connect("pressed", _on_clear_board_pressed)
	new_case_button.connect("pressed", _on_new_case_pressed)
	case_tabs_control.connect("tab_changed", _on_case_tab_changed)
	
	# Handle input
	set_process_unhandled_input(true)

func _unhandled_input(event):
	"""Handle zoom, pan, and other input"""
	# Handle escape key
	if event.is_action_pressed("ui_cancel"):
		_close_case_board()
		return
	
	# Only handle board input if mouse is over viewport
	if not _is_mouse_over_viewport():
		return
	
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_cursor(zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_cursor(-zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				last_mouse_position = event.position
			else:
				is_panning = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_create_sticky_note_at_cursor(event.position)
	
	# Handle panning
	if event is InputEventMouseMotion and is_panning:
		var delta = event.position - last_mouse_position
		
		# Scale pan speed based on zoom level for more responsive feel
		var pan_speed = 1.0 / zoom_level
		board_offset += delta * pan_speed
		
		# Enforce canvas bounds
		_enforce_canvas_bounds()
		_update_board_transform()
		last_mouse_position = event.position

func _is_mouse_over_viewport() -> bool:
	"""Check if mouse is over the board viewport"""
	var mouse_pos = get_global_mouse_position()
	var viewport_rect = board_viewport.get_global_rect()
	return viewport_rect.has_point(mouse_pos)

func _zoom_at_cursor(delta: float, cursor_pos: Vector2):
	"""Zoom at cursor position with strict canvas boundary constraints"""
	var old_zoom = zoom_level
	zoom_level = clamp(zoom_level + delta, min_zoom, max_zoom)
	
	if old_zoom != zoom_level:
		# Get cursor position relative to viewport
		var viewport_rect = board_viewport.get_global_rect()
		var local_cursor = cursor_pos - viewport_rect.position
		
		# Calculate point in board space under cursor
		var board_point = (local_cursor - board_offset) / old_zoom
		
		# Update transform
		_update_board_transform()
		
		# Adjust offset to keep same point under cursor
		var new_local_cursor = board_point * zoom_level + board_offset
		var offset_correction = local_cursor - new_local_cursor
		board_offset += offset_correction
		
		# Strictly enforce canvas visibility
		_enforce_canvas_bounds()
		_update_board_transform()

func _enforce_canvas_bounds():
	"""Strictly enforce that white canvas stays visible and centered"""
	var viewport_size = board_viewport.size
	var canvas_start_local = Vector2(border_size, border_size) * zoom_level
	var canvas_size_scaled = board_size * zoom_level
	
	# Calculate where canvas appears in viewport
	var canvas_screen_start = board_offset + canvas_start_local
	var canvas_screen_end = canvas_screen_start + canvas_size_scaled
	
	# If canvas is smaller than viewport, center it
	if canvas_size_scaled.x <= viewport_size.x:
		board_offset.x = (viewport_size.x - canvas_size_scaled.x) / 2 - canvas_start_local.x
	else:
		# Canvas is larger, ensure it doesn't go too far off screen
		var max_offset = canvas_size_scaled.x * 0.2  # Allow 20% to go off screen
		if canvas_screen_start.x > max_offset:
			board_offset.x = max_offset - canvas_start_local.x
		elif canvas_screen_end.x < viewport_size.x - max_offset:
			board_offset.x = viewport_size.x - max_offset - canvas_size_scaled.x - canvas_start_local.x
	
	if canvas_size_scaled.y <= viewport_size.y:
		board_offset.y = (viewport_size.y - canvas_size_scaled.y) / 2 - canvas_start_local.y
	else:
		# Canvas is larger, ensure it doesn't go too far off screen
		var max_offset = canvas_size_scaled.y * 0.2  # Allow 20% to go off screen
		if canvas_screen_start.y > max_offset:
			board_offset.y = max_offset - canvas_start_local.y
		elif canvas_screen_end.y < viewport_size.y - max_offset:
			board_offset.y = viewport_size.y - max_offset - canvas_size_scaled.y - canvas_start_local.y

func _constrain_pan_to_canvas():
	"""Strictly constrain panning to keep white canvas centered and visible"""
	var viewport_size = board_viewport.size
	var canvas_start_local = Vector2(border_size, border_size) * zoom_level
	var canvas_size_scaled = board_size * zoom_level
	
	# Calculate current canvas position in viewport coordinates
	var canvas_screen_start = board_offset + canvas_start_local
	var canvas_screen_end = canvas_screen_start + canvas_size_scaled
	
	# Enforce strict bounds - never let canvas go completely outside viewport
	var min_visible = min(canvas_size_scaled.x, canvas_size_scaled.y) * 0.3  # 30% must be visible
	
	# Horizontal constraints
	if canvas_screen_end.x < min_visible:
		# Canvas going too far left
		board_offset.x = min_visible - canvas_size_scaled.x - canvas_start_local.x
	elif canvas_screen_start.x > viewport_size.x - min_visible:
		# Canvas going too far right
		board_offset.x = viewport_size.x - min_visible - canvas_start_local.x
	
	# Vertical constraints
	if canvas_screen_end.y < min_visible:
		# Canvas going too far up
		board_offset.y = min_visible - canvas_size_scaled.y - canvas_start_local.y
	elif canvas_screen_start.y > viewport_size.y - min_visible:
		# Canvas going too far down
		board_offset.y = viewport_size.y - min_visible - canvas_start_local.y

func _update_board_transform():
	"""Update board position and scale"""
	board_content.scale = Vector2(zoom_level, zoom_level)
	board_content.position = board_offset

func _create_sticky_note_at_cursor(cursor_pos: Vector2):
	"""Create sticky note at cursor position - only within white canvas"""
	# Convert global cursor position to viewport local coordinates
	var viewport_rect = board_viewport.get_global_rect()
	var local_cursor = cursor_pos - viewport_rect.position
	
	# Convert to board content coordinates
	var content_pos = (local_cursor - board_offset) / zoom_level
	
	# Convert to canvas coordinates (subtract border offset)
	var canvas_pos = content_pos - Vector2(border_size, border_size)
	
	# Check if cursor is within white canvas bounds
	var note_size = Vector2(150, 150)
	
	# Ensure note will be completely within canvas
	if (canvas_pos.x >= 0 and canvas_pos.y >= 0 and 
		canvas_pos.x + note_size.x <= board_size.x and 
		canvas_pos.y + note_size.y <= board_size.y):
		add_sticky_note(canvas_pos, "New Note")
	else:
		print("Note must be placed completely within the white canvas area")

func add_sticky_note(board_position: Vector2, note_text: String = "New Note"):
	"""Add a sticky note to the board"""
	# Check for existing notes and find available position
	var final_position = _find_available_position(board_position)
	
	# Load sticky note scene
	var sticky_note_scene = load("res://scenes/ui/sticky_note.tscn")
	if sticky_note_scene == null:
		print("ERROR: Could not load sticky note scene!")
		return
		
	var sticky_note = sticky_note_scene.instantiate()
	if sticky_note == null:
		print("ERROR: Could not instantiate sticky note!")
		return
	
	# Set position (add border offset)
	sticky_note.position = final_position + Vector2(border_size, border_size)
	sticky_note.z_index = 50
	sticky_note.set_note_text(note_text)
	
	# Connect signals
	sticky_note.connect("note_moved", _on_sticky_note_moved)
	sticky_note.connect("note_deleted", _on_sticky_note_deleted)
	sticky_note.connect("note_edited", _on_sticky_note_edited)
	
	# Add to board
	board_content.add_child(sticky_note)
	sticky_notes.append(sticky_note)

func _find_available_position(desired_position: Vector2) -> Vector2:
	"""Find available position for new note, avoiding overlaps and staying in canvas"""
	var note_size = Vector2(150, 150)
	var final_position = _clamp_position_to_canvas(desired_position, note_size)
	var offset_step = 20
	var max_attempts = 20
	var attempts = 0
	
	while attempts < max_attempts:
		var collision_found = false
		
		for note in sticky_notes:
			if note == null:
				continue
			var note_rect = Rect2(note.position - Vector2(border_size, border_size), note.size)
			var test_rect = Rect2(final_position, note_size)
			
			if note_rect.intersects(test_rect):
				collision_found = true
				break
		
		if not collision_found:
			break
			
		# Spiral outward to find space, but keep within canvas
		var angle = attempts * 0.5
		var radius = attempts * offset_step
		var test_pos = desired_position + Vector2(cos(angle), sin(angle)) * radius
		final_position = _clamp_position_to_canvas(test_pos, note_size)
		attempts += 1
	
	return final_position

# Case management functions
func _initialize_cases():
	"""Initialize the case system"""
	if case_boards.is_empty():
		var first_case = CaseData.new("Case 1")
		case_boards.append(first_case)
		_update_case_tabs()

func _update_case_tabs():
	"""Update case tab display"""
	# Clear existing tabs by removing children
	for child in case_tabs_control.get_children():
		child.queue_free()
	
	# Add tabs for each case
	for i in range(case_boards.size()):
		var tab = Control.new()
		tab.name = case_boards[i].name
		case_tabs_control.add_child(tab)
	
	# Set current tab
	if current_case_index < case_tabs_control.get_tab_count():
		case_tabs_control.current_tab = current_case_index

# Signal handlers
func _on_close_button_pressed():
	_close_case_board()

func _close_case_board():
	_save_current_case_state()
	emit_signal("case_board_closed")

func _on_add_note_pressed():
	# Place note at center of white canvas (not total board)
	var center_pos = board_size / 2
	add_sticky_note(center_pos, "New Note")

func _on_clear_board_pressed():
	_clear_all_notes()

func _on_new_case_pressed():
	_create_new_case()

func _on_case_tab_changed(tab_index: int):
	_switch_to_case(tab_index)

func _on_sticky_note_moved(_note: StickyNote, _new_position: Vector2):
	pass  # Auto-saved through case state

func _on_sticky_note_deleted(note: StickyNote):
	if note in sticky_notes:
		sticky_notes.erase(note)
	note.queue_free()

func _on_sticky_note_edited(_note: StickyNote, _new_text: String):
	pass  # Auto-saved through case state

# Case management implementation
func _create_new_case():
	var case_name = "Case " + str(case_boards.size() + 1)
	_save_current_case_state()
	
	var new_case = CaseData.new(case_name)
	case_boards.append(new_case)
	current_case_index = case_boards.size() - 1
	
	_clear_all_notes()
	_update_case_tabs()

func _switch_to_case(case_index: int):
	if case_index >= 0 and case_index < case_boards.size():
		_save_current_case_state()
		current_case_index = case_index
		_load_case_state(case_boards[current_case_index])

func _save_current_case_state():
	if current_case_index >= 0 and current_case_index < case_boards.size():
		var case_data = case_boards[current_case_index]
		case_data.notes.clear()
		
		for note in sticky_notes:
			if note and is_instance_valid(note):
				case_data.notes.append(note.get_save_data())

func _load_case_state(case_data: CaseData):
	_clear_all_notes()
	
	for note_data in case_data.notes:
		var note_pos = note_data.get("position", Vector2.ZERO)
		note_pos -= Vector2(border_size, border_size)  # Adjust for border
		
		var note_text = note_data.get("text", "")
		add_sticky_note(note_pos, note_text)
		
		if not sticky_notes.is_empty():
			var last_note = sticky_notes[-1]
			if note_data.has("color_index"):
				last_note.set_note_color(note_data["color_index"])

func _clear_all_notes():
	for note in sticky_notes:
		if note and is_instance_valid(note):
			note.queue_free()
	sticky_notes.clear()
