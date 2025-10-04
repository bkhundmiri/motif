extends Control
class_name CaseBoardUI

## Case Board UI System
## Provides whiteboard-style investigation interface with zoom and pan

# Signals
signal case_board_closed()

# UI References
@onready var background_blur: ColorRect = $BackgroundBlur
@onready var case_board_panel: Panel = $CaseBoardPanel
@onready var board_scroll_container: ScrollContainer = $CaseBoardPanel/MainVBox/BoardContainer/BoardScrollContainer
@onready var board_content: Control = $CaseBoardPanel/MainVBox/BoardContainer/BoardScrollContainer/BoardContent

# Toolbar references
@onready var case_tabs_control: TabContainer = $CaseBoardPanel/MainVBox/ToolbarContainer/CaseTabsContainer/CaseTabsControl
@onready var new_case_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/CaseTabsContainer/NewCaseButton
@onready var add_note_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/AddNoteButton
@onready var clear_board_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/ClearBoardButton
@onready var close_button: Button = $CaseBoardPanel/MainVBox/ToolbarContainer/ToolbarButtons/CloseButton

# Zoom and Pan properties
var zoom_level: float = 1.0
var min_zoom: float = 0.3
var max_zoom: float = 3.0
var zoom_step: float = 0.2

var pan_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var last_mouse_position: Vector2

# Board state
var board_size: Vector2 = Vector2(2000, 1500)  # Large whiteboard space
var sticky_notes: Array = []
var current_case_index: int = 0
var case_boards: Array = []  # Array to store multiple case boards

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
	_setup_default_case()

func _setup_ui():
	"""Configure the case board UI layout"""
	# Fill the entire screen
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
	"""Initialize the board content area"""
	print("=== Setting up board ===")
	print("Board size: ", board_size)
	
	# Set up board content size
	board_content.custom_minimum_size = board_size
	board_content.size = board_size
	
	print("Board content size set to: ", board_content.size)
	print("Board content position: ", board_content.position)
	print("Board content visible: ", board_content.visible)
	print("Board scroll container size: ", board_scroll_container.size)
	
	# Apply initial zoom and pan
	_update_board_transform()
	print("=== Board setup complete ===")

func _connect_signals():
	"""Connect UI signals"""
	close_button.connect("pressed", _on_close_button_pressed)
	
	# Toolbar signals
	add_note_button.connect("pressed", _on_add_note_pressed)
	clear_board_button.connect("pressed", _on_clear_board_pressed)
	new_case_button.connect("pressed", _on_new_case_pressed)
	case_tabs_control.connect("tab_changed", _on_case_tab_changed)
	
	# Handle escape key
	set_process_unhandled_input(true)

func _unhandled_input(event):
	"""Handle input for zoom, pan, and closing"""
	# Handle escape key to close
	if event.is_action_pressed("ui_cancel"):
		_close_case_board()
		return
	
	# Handle mouse wheel for zooming
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_point(zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_point(-zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				last_mouse_position = event.position
			else:
				is_panning = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right-click to add sticky note
			_create_sticky_note_at_mouse(event.position)
	
	# Handle middle mouse drag for panning
	if event is InputEventMouseMotion and is_panning:
		var delta = event.position - last_mouse_position
		# Update scroll position directly
		board_scroll_container.scroll_horizontal -= int(delta.x)
		board_scroll_container.scroll_vertical -= int(delta.y)
		last_mouse_position = event.position

func _zoom_at_point(delta: float, point: Vector2):
	"""Zoom in/out at a specific point"""
	var old_zoom = zoom_level
	zoom_level = clamp(zoom_level + delta, min_zoom, max_zoom)
	
	if old_zoom != zoom_level:
		# Adjust pan to zoom at mouse position
		var zoom_ratio = zoom_level / old_zoom
		var scroll_rect = board_scroll_container.get_rect()
		var local_point = point - scroll_rect.position
		pan_offset = (pan_offset + local_point / old_zoom) * zoom_ratio - local_point / zoom_level
		
		_update_board_transform()

func _update_board_transform():
	"""Update the board content transform based on zoom and pan"""
	# With ScrollContainer, we handle zoom differently
	board_content.scale = Vector2(zoom_level, zoom_level)
	# Pan is handled by the ScrollContainer's scroll position
	board_scroll_container.scroll_horizontal = int(-pan_offset.x)
	board_scroll_container.scroll_vertical = int(-pan_offset.y)
	
	print("Board transform updated - scale: ", board_content.scale)
	print("Scroll position: ", Vector2(board_scroll_container.scroll_horizontal, board_scroll_container.scroll_vertical))
	print("Board content size after transform: ", board_content.size * board_content.scale)

func _on_close_button_pressed():
	"""Handle close button press"""
	_close_case_board()

func _close_case_board():
	"""Close the case board and emit signal"""
	emit_signal("case_board_closed")

# Board content management
func _create_sticky_note_at_mouse(mouse_position: Vector2):
	"""Create a sticky note at the mouse position"""
	# Convert mouse position to board space
	var scroll_rect = board_scroll_container.get_rect()
	var local_mouse = mouse_position - scroll_rect.position
	var board_position = (local_mouse - pan_offset) / zoom_level
	
	add_sticky_note(board_position, "New Note")

func add_sticky_note(board_position: Vector2, note_text: String = "New Note"):
	"""Add a sticky note to the board"""
	print("=== Adding sticky note ===")
	print("Board position: ", board_position)
	print("Board content size: ", board_content.size)
	print("Board content children before: ", board_content.get_child_count())
	
	# Try creating a simple colored control first
	var simple_note = ColorRect.new()
	simple_note.size = Vector2(150, 150)
	simple_note.position = board_position
	simple_note.color = Color.YELLOW
	simple_note.z_index = 75
	board_content.add_child(simple_note)
	print("Added simple yellow rect")
	
	# Load sticky note scene
	var sticky_note_scene = load("res://scenes/ui/sticky_note.tscn")
	if sticky_note_scene == null:
		print("ERROR: Could not load sticky note scene!")
		return
		
	var sticky_note = sticky_note_scene.instantiate()
	if sticky_note == null:
		print("ERROR: Could not instantiate sticky note!")
		return
	
	print("Sticky note created successfully")
	
	# Set position and text
	sticky_note.position = board_position + Vector2(200, 0)  # Offset from simple rect
	sticky_note.z_index = 50  # Make sure it's above background
	print("Position set to: ", sticky_note.position)
	print("Z-index set to: ", sticky_note.z_index)
	
	sticky_note.set_note_text(note_text)
	print("Text set to: ", note_text)
	
	# Connect signals
	sticky_note.connect("note_moved", _on_sticky_note_moved)
	sticky_note.connect("note_deleted", _on_sticky_note_deleted)
	sticky_note.connect("note_edited", _on_sticky_note_edited)
	print("Signals connected")
	
	# Add to board and tracking array
	board_content.add_child(sticky_note)
	sticky_notes.append(sticky_note)
	
	print("Added to board_content, child count now: ", board_content.get_child_count())
	print("Sticky notes array size: ", sticky_notes.size())
	print("Sticky note visible: ", sticky_note.visible)
	print("Sticky note size: ", sticky_note.size)
	print("=== End adding sticky note ===")
	print("Added sticky note at ", board_position, " with text: ", note_text)

func _on_sticky_note_moved(_note, new_position: Vector2):
	"""Handle sticky note movement"""
	print("Sticky note moved to: ", new_position)
	# Auto-save could be triggered here

func _on_sticky_note_deleted(note):
	"""Handle sticky note deletion"""
	if note in sticky_notes:
		sticky_notes.erase(note)
	note.queue_free()
	print("Sticky note deleted")

func _on_sticky_note_edited(_note, new_text: String):
	"""Handle sticky note text changes"""
	print("Sticky note edited: ", new_text)
	# Auto-save could be triggered here

func add_person_profile(board_position: Vector2, person_name: String = "Unknown Person"):
	"""Add a person profile card to the board"""
	# TODO: Implement person profile creation
	print("Adding person profile at ", board_position, " for: ", person_name)

func save_board_state():
	"""Save the current board state to file"""
	# TODO: Implement save functionality
	print("Saving board state...")

func load_board_state():
	"""Load board state from file"""
	# TODO: Implement load functionality
	print("Loading board state...")

# Case Management Functions
func _setup_default_case():
	"""Set up the first default case"""
	var default_case = CaseData.new("Case 1")
	case_boards.append(default_case)
	current_case_index = 0

func _on_add_note_pressed():
	"""Handle add note button press"""
	print("Add Note button pressed!")
	
	# Reset transforms temporarily to test
	board_content.scale = Vector2.ONE
	board_content.position = Vector2.ZERO
	zoom_level = 1.0
	pan_offset = Vector2.ZERO
	
	var center_position = Vector2(400, 300)  # Use a simple position instead of calculated center
	print("Creating note at position: ", center_position)
	print("Current zoom level: ", zoom_level)
	print("Current pan offset: ", pan_offset)
	print("Board content transform - scale: ", board_content.scale, " position: ", board_content.position)
	
	# First, try adding a simple test rectangle to see if that works
	var test_rect = ColorRect.new()
	test_rect.size = Vector2(100, 100)
	test_rect.position = center_position
	test_rect.color = Color.RED
	test_rect.z_index = 100  # Make sure it's on top
	board_content.add_child(test_rect)
	print("Added test rectangle at: ", test_rect.position, " size: ", test_rect.size)
	print("Test rectangle visible: ", test_rect.visible)
	print("Test rectangle z_index: ", test_rect.z_index)
	
	# Then try adding the sticky note
	add_sticky_note(center_position + Vector2(200, 0), "New Note")

func _on_clear_board_pressed():
	"""Handle clear board button press"""
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to clear all notes from this case board?"
	add_child(dialog)
	dialog.connect("confirmed", _clear_current_board)
	dialog.popup_centered()

func _clear_current_board():
	"""Clear all notes from the current board"""
	for note in sticky_notes:
		if is_instance_valid(note):
			note.queue_free()
	sticky_notes.clear()
	print("Board cleared")

func _on_new_case_pressed():
	"""Handle new case button press"""
	var case_number = case_boards.size() + 1
	var new_case = CaseData.new("Case " + str(case_number))
	case_boards.append(new_case)
	
	# Add new tab to the tab container
	var new_tab = Control.new()
	new_tab.name = new_case.name
	case_tabs_control.add_child(new_tab)
	
	# Switch to the new case
	case_tabs_control.current_tab = case_boards.size() - 1
	_switch_to_case(case_boards.size() - 1)

func _on_case_tab_changed(tab_index: int):
	"""Handle case tab change"""
	if tab_index >= 0 and tab_index < case_boards.size():
		_switch_to_case(tab_index)

func _switch_to_case(case_index: int):
	"""Switch to a different case board"""
	if case_index < 0 or case_index >= case_boards.size():
		return
	
	# Save current case state
	_save_current_case_state()
	
	# Clear current board
	for note in sticky_notes:
		if is_instance_valid(note):
			note.queue_free()
	sticky_notes.clear()
	
	# Load new case state
	current_case_index = case_index
	_load_case_state(case_index)

func _save_current_case_state():
	"""Save the current case state to the case data"""
	if current_case_index >= 0 and current_case_index < case_boards.size():
		var current_case = case_boards[current_case_index]
		current_case.notes.clear()
		
		# Save sticky note data using the proper methods
		for note in sticky_notes:
			if is_instance_valid(note):
				var note_data = note.get_save_data()
				current_case.notes.append(note_data)

func _load_case_state(case_index: int):
	"""Load a case state from case data"""
	if case_index < 0 or case_index >= case_boards.size():
		return
	
	var case_data = case_boards[case_index]
	
	# Recreate sticky notes using the proper methods
	for note_data in case_data.notes:
		var sticky_note_scene = preload("res://scenes/ui/sticky_note.tscn")
		var sticky_note = sticky_note_scene.instantiate()
		
		# Load the note data
		sticky_note.load_from_data(note_data)
		
		# Connect signals
		sticky_note.connect("note_moved", _on_sticky_note_moved)
		sticky_note.connect("note_deleted", _on_sticky_note_deleted)
		sticky_note.connect("note_edited", _on_sticky_note_edited)
		
		# Add to board and tracking array
		board_content.add_child(sticky_note)
		sticky_notes.append(sticky_note)

func _create_sticky_note_at_position(note_position: Vector2, text: String = "", _color: Color = Color.YELLOW):
	"""Create a sticky note at a specific position"""
	var sticky_note_scene = preload("res://scenes/ui/sticky_note.tscn")
	var sticky_note = sticky_note_scene.instantiate()
	
	# Configure the note
	sticky_note.position = note_position
	sticky_note.set_note_text(text)
	# Note: Color will be handled by color index, not direct Color value
	
	# Connect signals
	sticky_note.connect("note_moved", _on_sticky_note_moved)
	sticky_note.connect("note_deleted", _on_sticky_note_deleted)
	sticky_note.connect("note_edited", _on_sticky_note_edited)
	
	# Add to board and tracking array
	board_content.add_child(sticky_note)
	sticky_notes.append(sticky_note)
