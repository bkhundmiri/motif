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
@onready var board_control: Control = $CaseBoardPanel/MainVBox/BoardContainer/BoardViewport/BoardContent

# Toolbar references
@onready var case_tabs_control: HBoxContainer = $CaseBoardPanel/MainVBox/ToolbarContainer/CaseTabsContainer/CaseTabsControl
@onready var new_case_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/CaseTabsContainer/NewCaseButton
@onready var add_note_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/AddNoteButton
@onready var clear_board_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/ClearBoardButton
@onready var close_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/CloseButton

# Transform properties
var zoom_level: float = 1.0

# Keyboard panning state
var keyboard_pan_keys_pressed: Dictionary = {
	"w": false, "a": false, "s": false, "d": false,
	"up": false, "left": false, "down": false, "right": false
}
var keyboard_pan_timer: Timer
var min_zoom: float = 0.3
var max_zoom: float = 2.0
var zoom_step: float = 0.05
var board_offset: Vector2 = Vector2.ZERO

# Interaction state
var is_panning: bool = false
var last_mouse_position: Vector2

# Connection system
var connections: Array[ConnectionString] = []
var is_creating_connection: bool = false
var connection_source: StickyNote = null
var active_connection_line: Line2D = null

# Input blocking for text editing
var is_text_editing: bool = false

# Board properties
var board_size: Vector2 = Vector2(4000, 3000)  # Fixed large canvas for all resolutions
var border_size: float = 50.0  # Small border edge
var border_color: Color = Color(0.15, 0.15, 0.15)
var canvas_color: Color = Color.WHITE

# Board state
var sticky_notes: Array = []
var current_case_index: int = 0
var case_boards: Array = []
var is_loading: bool = false  # Prevent auto-save during loading

# Auto-save system
var auto_save_timer: Timer
var auto_save_interval: float = 300.0  # 5 minutes in seconds
var needs_save: bool = false  # Track if changes need saving

# Save file path
# File paths
var save_file_path: String = "user://case_board_data.json"

# Session state variables (for within-instance persistence)
# Using static variables to persist across UI instances
static var session_case_boards: Array[CaseData] = []
static var session_current_case_index: int = 0
static var has_session_data: bool = false

# Case management
class CaseData:
	var name: String
	var notes: Array = []
	var connections: Array = []  # Connection string data
	var board_data: Dictionary = {}
	
	func _init(case_name: String):
		name = case_name

func _ready():
	"""Initialize the case board UI"""
	
	# Clear legacy save data (uncomment for testing new save system)
	# _clear_legacy_save_data()
	
	_setup_ui()
	_connect_signals()
	_setup_auto_save_timer()
	_load_case_board_data()
	_setup_board()

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
	
	# Set up board content with transform and background
	board_control.custom_minimum_size = total_size
	board_control.size = total_size	# Create visual background
	_create_board_background()
	
	# Calculate zoom limits and center board immediately
	_calculate_zoom_limits()

func _create_board_background():
	"""Create the visual board background with borders"""
	# Remove existing background
	for child in board_control.get_children():
		if child.name == "BoardBackground":
			child.queue_free()
	
	# Create border background
	var background = ColorRect.new()
	background.name = "BoardBackground"
	background.color = border_color
	background.size = board_control.size
	background.position = Vector2.ZERO
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_control.add_child(background)
	board_control.move_child(background, 0)
	
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

func is_connecting() -> bool:
	"""Check if currently in connection creation mode"""
	return is_creating_connection

func _connect_signals():
	"""Connect UI signals"""
	close_button.connect("pressed", _on_close_button_pressed)
	add_note_button.connect("pressed", _on_add_note_pressed)
	clear_board_button.connect("pressed", _on_clear_board_pressed)
	new_case_button.connect("pressed", _on_new_case_pressed)
	# Note: Tab signals are now connected individually in _update_case_tabs()
	
	# Handle input
	set_process_unhandled_input(true)

func _setup_auto_save_timer():
	"""Set up the 5-minute auto-save timer"""
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	auto_save_timer.autostart = true
	add_child(auto_save_timer)

func _input(event):
	"""Handle zoom, pan, and tab input"""
	# Handle escape key
	if event.is_action_pressed("ui_cancel"):
		if is_creating_connection:
			_cancel_connection_creation()
		else:
			_close_case_board()
		# Prevent ESC from propagating to the game state menu
		get_viewport().set_input_as_handled()
		return
	
	# Handle keyboard panning (alternative to mouse panning) - but not during text editing
	if event is InputEventKey and not is_text_editing:
		_handle_keyboard_panning(event)
	
	# Handle tab input for renaming
	if _handle_tab_input(event):
		return  # Tab input was handled
	
	# Handle tab tooltips on mouse motion
	if event is InputEventMouseMotion:
		_handle_tab_tooltips(event)
		# Update connection preview line if in connection mode
		if is_creating_connection:
			_update_preview_line()
	
	# Handle zoom and panning
	if not _is_mouse_over_viewport():
		return
	
	# Handle click to defocus text editing (only on the board area)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_text_editing:
			_defocus_all_text_editing()
	
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_cursor(zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_cursor(-zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_creating_connection:
			# If creating connection, we need to handle this more carefully
			# Let the note handle target selection first, then cancel if no target was selected
			await get_tree().process_frame  # Wait one frame for note input to process
			if is_creating_connection:  # If still creating connection after frame, cancel it
				print("Cancelling connection - clicked on empty space")
				_cancel_connection_creation()

func _is_mouse_over_viewport() -> bool:
	"""Check if mouse is over the board viewport"""
	var mouse_pos = get_global_mouse_position()
	var viewport_rect = board_viewport.get_global_rect()
	return viewport_rect.has_point(mouse_pos)

func _handle_keyboard_panning(event: InputEventKey):
	"""Handle WASD/Arrow key panning with diagonal support"""
	var key_name = ""
	var is_pressed = event.pressed
	
	# Determine which key was pressed/released
	match event.keycode:
		KEY_W, KEY_UP:
			key_name = "w" if event.keycode == KEY_W else "up"
		KEY_A, KEY_LEFT:
			key_name = "a" if event.keycode == KEY_A else "left"
		KEY_S, KEY_DOWN:
			key_name = "s" if event.keycode == KEY_S else "down"
		KEY_D, KEY_RIGHT:
			key_name = "d" if event.keycode == KEY_D else "right"
		_:
			return  # Not a movement key
	
	# Update key state
	keyboard_pan_keys_pressed[key_name] = is_pressed
	
	# Start/stop continuous panning
	_update_keyboard_panning()

func _update_keyboard_panning():
	"""Update continuous keyboard panning based on currently pressed keys"""
	var pan_delta = Vector2.ZERO
	var pan_speed = 120.0  # Increased speed for smoother movement
	
	# Check for vertical movement
	if keyboard_pan_keys_pressed["w"] or keyboard_pan_keys_pressed["up"]:
		pan_delta.y += pan_speed
	if keyboard_pan_keys_pressed["s"] or keyboard_pan_keys_pressed["down"]:
		pan_delta.y -= pan_speed
	
	# Check for horizontal movement
	if keyboard_pan_keys_pressed["a"] or keyboard_pan_keys_pressed["left"]:
		pan_delta.x += pan_speed
	if keyboard_pan_keys_pressed["d"] or keyboard_pan_keys_pressed["right"]:
		pan_delta.x -= pan_speed
	
	# Apply movement if any keys are pressed
	if pan_delta != Vector2.ZERO:
		# Normalize diagonal movement to prevent faster diagonal panning
		if abs(pan_delta.x) > 0 and abs(pan_delta.y) > 0:
			pan_delta = pan_delta.normalized() * pan_speed
		
		board_offset += pan_delta * get_process_delta_time() * 60.0  # Frame-rate independent
		_enforce_canvas_bounds()
		_update_board_transform()
		
		# Start continuous panning timer if not already running
		if not keyboard_pan_timer or keyboard_pan_timer.is_stopped():
			_start_keyboard_pan_timer()
	else:
		# Stop panning timer when no keys are pressed
		if keyboard_pan_timer and not keyboard_pan_timer.is_stopped():
			keyboard_pan_timer.stop()

func _start_keyboard_pan_timer():
	"""Start the keyboard panning timer for continuous movement"""
	if not keyboard_pan_timer:
		keyboard_pan_timer = Timer.new()
		keyboard_pan_timer.wait_time = 0.016  # ~60 FPS
		keyboard_pan_timer.timeout.connect(_update_keyboard_panning)
		add_child(keyboard_pan_timer)
	keyboard_pan_timer.start()



func _handle_tab_input(_event) -> bool:
	"""Handle input for tab renaming. Returns true if event was handled."""
	# Tab input is now handled by individual tab buttons with signals
	# This function is kept for compatibility but no longer needed
	return false

func _handle_tab_tooltips(_event: InputEventMouseMotion):
	"""Handle tooltip display for tabs"""
	# Tooltips are now handled by individual tab buttons
	# This function is kept for compatibility but no longer needed
	pass

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
	board_control.scale = Vector2(zoom_level, zoom_level)
	board_control.position = board_offset

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
	
	# Connect signals
	sticky_note.connect("note_moved", _on_sticky_note_moved)
	sticky_note.connect("note_deleted", _on_sticky_note_deleted)
	sticky_note.connect("note_edited", _on_sticky_note_edited)
	sticky_note.connect("connection_requested", _on_connection_requested)
	sticky_note.connect("connection_target_selected", _on_connection_target_selected)
	sticky_note.connect("text_edit_started", _on_text_edit_started)
	sticky_note.connect("text_edit_finished", _on_text_edit_finished)
	
	# Add to board
	board_control.add_child(sticky_note)
	sticky_notes.append(sticky_note)
	
	# Set text after the node is ready
	await sticky_note.ready
	sticky_note.set_note_text(note_text)
	
	# Mark that changes need saving (but not during loading)
	if not is_loading:
		needs_save = true

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
func _initialize_clean_board():
	"""Initialize a clean board with just one empty case"""
	case_boards.clear()
	current_case_index = 0
	
	# Clear session data when starting fresh (only if we don't already have session data)
	if not CaseBoardUI.has_session_data:
		_clear_session_data()
	
	# Create one clean case
	var initial_case = CaseData.new("Case 1")
	case_boards.append(initial_case)
	
	# Update UI
	_update_case_tabs()
	_setup_board()
	print("Initialized clean case board with 1 empty case")

func _clear_session_data():
	"""Clear session state data"""
	CaseBoardUI.session_case_boards.clear()
	CaseBoardUI.session_current_case_index = 0
	CaseBoardUI.has_session_data = false
	print("Session data cleared")

func _initialize_cases():
	"""Initialize the case system"""
	if case_boards.is_empty():
		var first_case = CaseData.new("Case 1")
		case_boards.append(first_case)
		_update_case_tabs()

func _update_case_tabs():
	"""Update the tabs display with custom buttons"""
	# Clear existing tab buttons
	for child in case_tabs_control.get_children():
		child.queue_free()
	
	# Wait for frame to ensure cleanup
	await get_tree().process_frame
	
	# Create tab buttons for each case
	for i in range(case_boards.size()):
		var tab_button = Button.new()
		tab_button.text = case_boards[i].name
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.custom_minimum_size = Vector2(120, 40)
		tab_button.tooltip_text = "%s\n(Right-click or double-click to rename)" % case_boards[i].name
		
		# Style the button to look like a tab
		if i == current_case_index:
			# Active tab style
			tab_button.modulate = Color.WHITE
			tab_button.add_theme_color_override("font_color", Color.BLACK)
		else:
			# Inactive tab style
			tab_button.modulate = Color(0.8, 0.8, 0.8, 1.0)
			tab_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		
		# Connect signals for tab functionality
		tab_button.connect("pressed", _on_tab_button_pressed.bind(i))
		tab_button.connect("gui_input", _on_tab_button_input.bind(i))
		
		case_tabs_control.add_child(tab_button)
		print("Created tab button %d: '%s'" % [i, case_boards[i].name])

func _setup_tab_rename(_tab_index: int):
	"""Set up double-click to rename functionality for a tab"""
	# Tab rename functionality is handled by _unhandled_input and _handle_tab_input
	# This function exists for consistency but the actual implementation
	# is in the input handling system since TabContainer doesn't expose
	# individual tab button signals properly
	pass

# Signal handlers
func _on_close_button_pressed():
	_close_case_board()

func _on_tab_button_pressed(tab_index: int):
	"""Handle tab button press to switch cases"""
	print("Tab button %d pressed, switching to case '%s'" % [tab_index, case_boards[tab_index].name])
	_switch_to_case(tab_index)

func _on_tab_button_input(event: InputEvent, tab_index: int):
	"""Handle right-click and double-click on tab buttons"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			print("Right-click detected on tab %d" % tab_index)
			_show_rename_dialog(tab_index)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			print("Double-click detected on tab %d" % tab_index)
			_show_rename_dialog(tab_index)

func _close_case_board():
	print("Closing case board...")
	_save_current_case_state()
	
	# Reset cursor if we're currently panning
	if is_panning:
		is_panning = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	# Save current state to session for within-instance persistence
	_save_session_state()
	
	print("Case board closed (session state saved, file persistence via autosave)")
	emit_signal("case_board_closed")

func _on_add_note_pressed():
	# Place note at center of white canvas (not total board)
	var center_pos = board_size / 2
	add_sticky_note(center_pos, "New Note")

func _on_clear_board_pressed():
	_clear_all_notes()

func _on_new_case_pressed():
	_create_new_case()

# Note: _on_case_tab_changed removed since we now use individual tab buttons

func _on_tab_renamed(tab_index: int, new_name: String):
	"""Handle tab rename event"""
	if tab_index >= 0 and tab_index < case_boards.size():
		case_boards[tab_index].name = new_name
		needs_save = true  # Mark for auto-save
		_update_case_tabs()  # Refresh the tab display
		print("Renamed case %d to: '%s'" % [tab_index, new_name])

# Note: _get_tab_at_position removed since we now use individual tab buttons

func _show_rename_dialog(tab_index: int):
	"""Show dialog to rename a case tab"""
	if tab_index < 0 or tab_index >= case_boards.size():
		print("Invalid tab index for rename: %d" % tab_index)
		return
	
	print("Showing rename dialog for tab %d ('%s')" % [tab_index, case_boards[tab_index].name])
	
	# Create a simple input dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Rename Case"
	dialog.size = Vector2(300, 150)
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var label = Label.new()
	label.text = "Enter new name for case:"
	vbox.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.text = case_boards[tab_index].name
	line_edit.select_all()
	vbox.add_child(line_edit)
	
	# Position dialog in center
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	line_edit.grab_focus()  # Ensure the input field is focused
	
	print("Rename dialog should now be visible")
	
	# Handle dialog result
	dialog.connect("confirmed", func(): 
		var new_name = line_edit.text.strip_edges()
		if new_name != "":
			print("Dialog confirmed with new name: '%s'" % new_name)
			_on_tab_renamed(tab_index, new_name)
			# Note: _update_case_tabs() is called by _on_tab_renamed()
		else:
			print("Dialog confirmed but name was empty")
		dialog.queue_free()
	)
	
	# Clean up dialog when cancelled
	dialog.connect("cancelled", func():
		print("Rename dialog was cancelled")
		dialog.queue_free()
	)

func _on_sticky_note_moved(_note: StickyNote, _new_position: Vector2):
	# Update all connections involving this note
	for child in board_control.get_children():
		if child is ConnectionString:
			var connection = child as ConnectionString
			if connection.source_note == _note or connection.target_note == _note:
				connection.update_on_note_movement()
	
	needs_save = true  # Mark for next auto-save

func _on_sticky_note_deleted(note: StickyNote):
	if note in sticky_notes:
		sticky_notes.erase(note)
	note.queue_free()
	needs_save = true  # Mark for next auto-save

func _on_sticky_note_edited(_note: StickyNote, _new_text: String):
	needs_save = true  # Mark for next auto-save

# Case management implementation
func _create_new_case():
	var case_name = "Case " + str(case_boards.size() + 1)
	_save_current_case_state()
	
	var new_case = CaseData.new(case_name)
	case_boards.append(new_case)
	current_case_index = case_boards.size() - 1
	
	# Clear both notes and connections for the new case
	_clear_all_notes()
	_clear_all_connections()
	_update_case_tabs()
	needs_save = true  # Mark for save
	
	# Show hint about renaming for new users
	print("New case created: '%s' (Right-click or double-click tab to rename)" % case_name)

func _switch_to_case(case_index: int):
	if case_index >= 0 and case_index < case_boards.size():
		_save_current_case_state()
		current_case_index = case_index
		_load_case_state(case_boards[current_case_index])
		needs_save = true  # Mark for save

func _save_current_case_state():
	if current_case_index >= 0 and current_case_index < case_boards.size():
		var case_data = case_boards[current_case_index]
		print("Saving to case %d ('%s'): %d notes, %d connections found" % [current_case_index, case_data.name, sticky_notes.size(), _count_connections()])
		case_data.notes.clear()
		case_data.connections.clear()
		
		# Save notes
		for note in sticky_notes:
			if note and is_instance_valid(note):
				var note_data = note.get_save_data()
				case_data.notes.append(note_data)
				print("Saved note: '%s' (ID: %s) at %s" % [note_data.text, note_data.id, note_data.position])
		
		# Save connections
		for child in board_control.get_children():
			if child is ConnectionString:
				var connection = child as ConnectionString
				var connection_data = connection.get_save_data()
				if connection_data:  # Only save valid connections
					case_data.connections.append(connection_data)
					print("Saved connection between notes %s and %s" % [connection_data.source_id, connection_data.target_id])
	else:
		print("ERROR: Cannot save case state - invalid case index %d" % current_case_index)

func _load_case_state(case_data: CaseData):
	is_loading = true  # Prevent auto-save during loading
	_clear_all_notes()
	_clear_all_connections()
	
	print("Loading case '%s': %d notes, %d connections to restore" % [case_data.name, case_data.notes.size(), case_data.connections.size()])
	
	# First load all notes
	var notes_by_id: Dictionary = {}
	for note_data in case_data.notes:
		# Create note at default position first
		add_sticky_note(Vector2.ZERO, "")
		# Get the note that was just created and load its data (including position)
		if not sticky_notes.is_empty():
			var note = sticky_notes[-1]
			note.load_from_data(note_data)
			notes_by_id[note.note_id] = note  # Map for connection loading
			print("Loaded note: '%s' with ID %s" % [note_data.get("text", ""), note.note_id])
	
	# Debug: Print the notes_by_id mapping
	print("Note ID mapping for connections:")
	for id in notes_by_id.keys():
		print("  ID: %s -> Note with text: '%s'" % [id, notes_by_id[id].get_note_text()])
	
	# Then load all connections with deduplication
	var loaded_connections: Array[String] = []  # Track loaded connection pairs
	
	for connection_data in case_data.connections:
		print("Loading connection data: source=%s, target=%s" % [connection_data.source_id, connection_data.target_id])
		
		# Create a normalized connection key (smaller ID first to detect bidirectional duplicates)
		var connection_key = ""
		if connection_data.source_id < connection_data.target_id:
			connection_key = connection_data.source_id + "->" + connection_data.target_id
		else:
			connection_key = connection_data.target_id + "->" + connection_data.source_id
		
		# Skip if we've already loaded this connection pair
		if loaded_connections.has(connection_key):
			print("Skipping duplicate connection: %s" % connection_key)
			continue
		
		loaded_connections.append(connection_key)
		
		# Verify both notes exist
		if not notes_by_id.has(connection_data.source_id):
			print("ERROR: Source note ID %s not found in notes_by_id" % connection_data.source_id)
			continue
		if not notes_by_id.has(connection_data.target_id):
			print("ERROR: Target note ID %s not found in notes_by_id" % connection_data.target_id)
			continue
			
		var connection_string = preload("res://scripts/ui/connection_string.gd").new()
		board_control.add_child(connection_string)
		connection_string.load_from_data(connection_data, notes_by_id)
		print("Loaded connection between %s and %s" % [connection_data.source_id, connection_data.target_id])
	
	print("Case '%s' loaded: %d notes, %d connections restored" % [case_data.name, sticky_notes.size(), _count_connections()])
	is_loading = false  # Re-enable auto-save

func _count_connections() -> int:
	"""Count the number of connection strings in the current case"""
	var count = 0
	for child in board_control.get_children():
		if child is ConnectionString:
			count += 1
	return count

func _clear_all_connections():
	"""Clear all connection strings from the board"""
	for child in board_control.get_children():
		if child is ConnectionString:
			child.queue_free()

func _clear_all_notes():
	for note in sticky_notes:
		if note and is_instance_valid(note):
			note.queue_free()
	sticky_notes.clear()

func _copy_case_data_to(source_case: CaseData, target_case: CaseData):
	"""Shared method to copy all case data including notes and connections"""
	target_case.notes = source_case.notes.duplicate(true)
	target_case.connections = source_case.connections.duplicate(true)
	target_case.board_data = source_case.board_data.duplicate(true)

func _create_case_save_dict(case_data: CaseData) -> Dictionary:
	"""Shared method to create save dictionary including all case data"""
	return {
		"name": case_data.name,
		"notes": case_data.notes.duplicate(),
		"connections": case_data.connections.duplicate(),
		"board_data": case_data.board_data.duplicate()
	}

func _load_case_from_dict(case_info: Dictionary) -> CaseData:
	"""Shared method to load case data from dictionary including all data"""
	var case_data = CaseData.new(case_info["name"])
	case_data.notes = case_info.get("notes", []).duplicate()
	case_data.connections = case_info.get("connections", []).duplicate()
	case_data.board_data = case_info.get("board_data", {}).duplicate()
	return case_data

# Save/Load functionality
func _save_session_state():
	"""Save current case board state to session variables"""
	CaseBoardUI.session_case_boards.clear()
	
	print("=== Saving session state ===")
	print("Current cases to save: %d" % case_boards.size())
	
	# Deep copy current case boards to session
	for i in range(case_boards.size()):
		var case_data = case_boards[i]
		var session_case = CaseData.new(case_data.name)
		_copy_case_data_to(case_data, session_case)
		CaseBoardUI.session_case_boards.append(session_case)
		print("Saved session case %d: '%s' with %d notes, %d connections" % [i, case_data.name, case_data.notes.size(), case_data.connections.size()])
	
	CaseBoardUI.session_current_case_index = current_case_index
	CaseBoardUI.has_session_data = true
	print("Session state saved: %d cases, current index: %d" % [CaseBoardUI.session_case_boards.size(), current_case_index])

func _load_from_session_state():
	"""Load case board state from session variables"""
	case_boards.clear()
	
	# Deep copy session data back to current state
	for session_case in CaseBoardUI.session_case_boards:
		var case_data = CaseData.new(session_case.name)
		_copy_case_data_to(session_case, case_data)
		case_boards.append(case_data)
	
	current_case_index = CaseBoardUI.session_current_case_index
	if current_case_index >= case_boards.size():
		current_case_index = 0
	
	print("Loaded from session state: %d cases (within-instance persistence)" % case_boards.size())
	
	# Update UI and load current case
	_update_case_tabs()
	if not case_boards.is_empty():
		_load_case_state(case_boards[current_case_index])
		print("Session case '%s' restored" % case_boards[current_case_index].name)

func _clear_legacy_save_data():
	"""Clear old save data that doesn't match the new smart save system"""
	if FileAccess.file_exists(save_file_path):
		print("Clearing legacy save data...")
		DirAccess.remove_absolute(save_file_path)
		print("Legacy save data cleared")

func _case_has_content(case_data: CaseData) -> bool:
	"""Check if a case has meaningful content worth saving"""
	# Save if case has been renamed from default
	if not case_data.name.begins_with("Case "):
		return true
	
	# Save if case has any notes/components
	if case_data.notes.size() > 0:
		return true
	
	# Save if case has any connections
	if case_data.connections.size() > 0:
		return true
	
	# Save if case has any board data
	if case_data.board_data.size() > 0:
		return true
	
	return false

func _save_case_board_data():
	"""Save only meaningful case board data to disk"""
	_save_current_case_state()  # Ensure current state is saved
	
	# Filter cases with meaningful content
	var meaningful_cases = []
	var meaningful_current_index = -1
	
	for i in range(case_boards.size()):
		var case_data = case_boards[i]
		if _case_has_content(case_data):
			meaningful_cases.append(case_data)
			if i == current_case_index:
				meaningful_current_index = meaningful_cases.size() - 1
	
	# Don't save if no meaningful cases exist
	if meaningful_cases.is_empty():
		print("No meaningful cases to save - skipping save")
		# Remove existing save file if it exists
		if FileAccess.file_exists(save_file_path):
			DirAccess.remove_absolute(save_file_path)
			print("Removed empty case board save file")
		return
	
	var save_data = {
		"cases": [],
		"current_case_index": meaningful_current_index,
		"version": 1
	}
	
	# Save meaningful cases
	print("Saving %d meaningful cases to disk:" % meaningful_cases.size())
	for i in range(meaningful_cases.size()):
		var case_data = meaningful_cases[i]
		var case_save_data = _create_case_save_dict(case_data)
		save_data["cases"].append(case_save_data)
		print("  Case %d: '%s' with %d notes, %d connections" % [i, case_data.name, case_data.notes.size(), case_data.connections.size()])
	
	# Write to file
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Case board data saved successfully to: %s" % save_file_path)
	else:
		print("Error: Could not save case board data")

func _load_case_board_data():
	"""Load case board data - prioritize session state, fallback to file"""
	print("=== Loading case board data ===")
	print("Session data status: has_data=%s, cases=%d" % [CaseBoardUI.has_session_data, CaseBoardUI.session_case_boards.size()])
	
	# First, try to load from session (within same game instance)
	if CaseBoardUI.has_session_data and not CaseBoardUI.session_case_boards.is_empty():
		print("Loading from session state (within-instance persistence)")
		_load_from_session_state()
		return
	
	# No session data, try loading from file (between game restarts)
	if not FileAccess.file_exists(save_file_path):
		print("No case board save file found - starting with clean slate")
		_initialize_clean_board()
		return
	
	print("Loading from file (between-instance persistence)")
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		print("Error: Could not open save file, starting with clean slate")
		_initialize_clean_board()
		return
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	
	if parse_result != OK:
		print("Error: Could not parse save file, starting with clean slate")
		_initialize_clean_board()
		return
	
	var save_data = json.data
	
	# Validate save data
	if not save_data.has("cases") or not save_data.has("current_case_index"):
		print("Error: Invalid save file format, starting with clean slate")
		_initialize_clean_board()
		return
	
	# Load cases from file
	case_boards.clear()
	for i in range(save_data["cases"].size()):
		var case_info = save_data["cases"][i]
		var case_data = _load_case_from_dict(case_info)
		case_boards.append(case_data)
		print("Loaded case %d: '%s' with %d notes, %d connections" % [i, case_data.name, case_data.notes.size(), case_data.connections.size()])
	
	# Set current case index
	current_case_index = save_data["current_case_index"]
	if current_case_index >= case_boards.size():
		current_case_index = 0
	print("Setting current case index to: %d" % current_case_index)
	
	# Handle empty case boards (shouldn't happen with new save system)
	if case_boards.is_empty():
		print("Warning: Loaded empty case board, starting with clean slate")
		_initialize_clean_board()
		return
	
	# Update UI
	_update_case_tabs()
	
	# Load current case state
	if not case_boards.is_empty():
		print("About to load case %d ('%s')" % [current_case_index, case_boards[current_case_index].name])
		_load_case_state(case_boards[current_case_index])
		print("Case board data loaded successfully: %d cases" % case_boards.size())
	else:
		print("No cases found in save file, starting with clean slate")
		_initialize_clean_board()

func _save_all_game_data():
	"""Save all game data including case board and game clock"""
	_save_case_board_data()
	# GameManager handles its own save automatically

func _auto_save_case_state():
	"""Auto-save case state after changes"""
	if is_loading or not needs_save:
		return  # Don't auto-save during loading or if no changes
	
	_save_current_case_state()  # Save current case including connections
	_save_case_board_data()  # Save to disk
	needs_save = false
	print("Auto-save completed with connections")

func _on_auto_save_timer_timeout():
	"""Called every 5 minutes to auto-save"""
	if needs_save:
		print("5-minute auto-save triggered")
		_auto_save_case_state()
	else:
		print("5-minute timer: no changes to save")

# Connection System Methods
func _on_connection_requested(source_note: StickyNote):
	"""Handle connection creation request from a note"""
	print("Connection requested from note: ", source_note.note_id)
	if is_creating_connection:
		print("Already creating connection - cancelling previous")
		# Cancel existing connection
		_cancel_connection_creation()
	
	is_creating_connection = true
	connection_source = source_note
	print("Connection mode enabled, source set to: ", source_note.note_id)
	
	# Create visual feedback line that follows mouse
	_create_preview_line()

func _on_connection_target_selected(target_note: StickyNote):
	"""Handle connection target selection"""
	print("Connection target selected: ", target_note.note_id)
	if not is_creating_connection or not connection_source:
		print("Not in connection mode or no source")
		return
	
	if target_note == connection_source:
		print("Cannot connect to self - cancelling")
		# Can't connect to self
		_cancel_connection_creation()
		return
	
	print("Creating connection between: ", connection_source.note_id, " and ", target_note.note_id)
	# Create the connection
	_create_connection(connection_source, target_note)
	_cancel_connection_creation()

func _create_preview_line():
	"""Create preview line that follows mouse cursor"""
	active_connection_line = Line2D.new()
	active_connection_line.width = 5.0  # Thicker line
	active_connection_line.default_color = Color.RED
	active_connection_line.z_index = 100
	# Add some curve to the line
	active_connection_line.joint_mode = Line2D.LINE_JOINT_ROUND
	active_connection_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	active_connection_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	board_control.add_child(active_connection_line)

func _update_preview_line():
	"""Update preview line to follow mouse cursor with curvature"""
	if not active_connection_line or not connection_source:
		return
	
	var mouse_pos = board_control.get_local_mouse_position()
	var source_center = connection_source.position + (connection_source.size / 2.0)
	
	# Calculate curve for preview line
	var distance = source_center.distance_to(mouse_pos)
	var curve_strength = min(distance * 0.3, 100.0)
	
	# Calculate perpendicular direction for curve
	var direction = (mouse_pos - source_center).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Add curve control point in the middle, offset perpendicular
	var mid_point = (source_center + mouse_pos) / 2.0
	var control_point = mid_point + perpendicular * curve_strength * 0.5
	
	# Create curved line with multiple points
	active_connection_line.clear_points()
	var segments = 15
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var curve_point = _bezier_quadratic(source_center, control_point, mouse_pos, t)
		active_connection_line.add_point(curve_point)

func _bezier_quadratic(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	"""Calculate point on quadratic bezier curve"""
	var u = 1.0 - t
	return u * u * p0 + 2 * u * t * p1 + t * t * p2

func _create_connection(source: StickyNote, target: StickyNote):
	"""Create a visual connection between two notes"""
	print("Creating connection between notes: ", source.note_id, " -> ", target.note_id)
	
	# Check if connection already exists in either direction
	for existing_connection in connections:
		if (existing_connection.source_note == source and existing_connection.target_note == target) or \
		   (existing_connection.source_note == target and existing_connection.target_note == source):
			print("Connection already exists between these notes, skipping duplicate")
			return
	
	var connection = ConnectionString.new()
	connection.setup_connection(source, target)
	# Connect to deletion signal to clean up from connections array
	connection.connect("tree_exiting", _on_connection_deleted.bind(connection))
	board_control.add_child(connection)
	connections.append(connection)
	print("Connection added. Total connections: ", connections.size())
	
	# Add connection to both notes (for tracking purposes)
	source.add_connection(target)
	target.add_connection(source)
	
	# Mark that we need to save the updated state
	needs_save = true

func _cancel_connection_creation():
	"""Cancel connection creation mode"""
	print("Cancelling connection creation")
	is_creating_connection = false
	connection_source = null
	
	if active_connection_line:
		active_connection_line.queue_free()
		active_connection_line = null

# Text editing state management
func _on_text_edit_started():
	"""Handle when a note starts text editing"""
	is_text_editing = true

func _on_text_edit_finished():
	"""Handle when a note finishes text editing"""
	is_text_editing = false

func _defocus_all_text_editing():
	"""Remove focus from all text editing fields"""
	for note in sticky_notes:
		if note and is_instance_valid(note) and note.text_edit and note.text_edit.has_focus():
			note.text_edit.release_focus()

func _on_connection_deleted(connection: ConnectionString):
	"""Handle when a connection is deleted"""
	if connection in connections:
		connections.erase(connection)
		needs_save = true  # Mark that we need to save the updated state
		print("Connection deleted. Total connections: ", connections.size())
