extends Control
class_name EscMenu

## ESC Menu Overlay
## Handles pause menu functionality including save deletion

var background_overlay: ColorRect
var menu_panel: Panel
var delete_save_button: Button
var cancel_button: Button
var confirm_dialog: AcceptDialog

var game_manager: GameManager
var is_setup_complete: bool = false

func _ready():
	# Setup the UI
	_setup_ui()
	
	# Find the game manager
	game_manager = get_node("/root/GameManagerUI") if has_node("/root/GameManagerUI") else null
	if game_manager:
		print("ESC Menu: Successfully connected to GameManagerUI")
	else:
		print("ESC Menu: WARNING - Could not find GameManagerUI!")
	
	# Hide by default
	visible = false
	
	# Connect signals
	_connect_signals()
	
	# Mark setup as complete
	is_setup_complete = true

func _setup_ui():
	"""Setup the ESC menu UI elements"""
	# Set up as full screen overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create dark background overlay
	background_overlay = ColorRect.new()
	background_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_overlay.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	add_child(background_overlay)
	
	# Create centered menu panel
	menu_panel = Panel.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_panel.size = Vector2(400, 300)
	menu_panel.position = Vector2(-200, -150)  # Center it
	add_child(menu_panel)
	
	# Create VBox for menu items
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	menu_panel.add_child(vbox)
	
	# Add padding
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size.y = 40
	vbox.add_child(top_spacer)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Game Menu"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	# Delete save button
	delete_save_button = Button.new()
	delete_save_button.text = "Delete Save & Restart"
	delete_save_button.custom_minimum_size.y = 50
	vbox.add_child(delete_save_button)
	
	# Cancel button
	cancel_button = Button.new()
	cancel_button.text = "Cancel (ESC)"
	cancel_button.custom_minimum_size.y = 50
	vbox.add_child(cancel_button)
	
	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size.y = 40
	vbox.add_child(bottom_spacer)
	
	# Create confirmation dialog
	confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to delete your save file and restart?\nThis cannot be undone!"
	confirm_dialog.title = "Confirm Delete Save"
	confirm_dialog.get_ok_button().text = "Yes, Delete"
	confirm_dialog.add_cancel_button("Cancel")
	add_child(confirm_dialog)

func _connect_signals():
	"""Connect button signals"""
	delete_save_button.pressed.connect(_on_delete_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_dialog.confirmed.connect(_on_delete_confirmed)
	
	# Close menu when clicking background
	background_overlay.gui_input.connect(_on_background_clicked)

func _input(event):
	"""Handle ESC key to close menu"""
	if visible and event.is_action_pressed("ui_cancel"):
		_close_menu()
		get_viewport().set_input_as_handled()

func open_menu():
	"""Open the ESC menu and pause the game"""
	# Ensure UI is setup before opening
	if not is_setup_complete:
		print("ESC menu not ready yet, skipping open")
		return
	
	if game_manager:
		print("Calling game_manager.pause_game() and open_ui()")
		game_manager.pause_game()
		game_manager.open_ui()
		print("Game paused state: %s, UI open state: %s" % [game_manager.game_paused, game_manager.ui_open])
	else:
		print("No game manager found - cannot pause game!")
	
	visible = true
	# Grab focus for keyboard navigation (with null check)
	if cancel_button and is_instance_valid(cancel_button):
		cancel_button.grab_focus()
	
	print("ESC menu opened - Game paused")

func _close_menu():
	"""Close the ESC menu and resume the game"""
	if game_manager:
		print("Calling game_manager.resume_game() and close_ui()")
		game_manager.resume_game()
		game_manager.close_ui()
		print("Game paused state: %s, UI open state: %s" % [game_manager.game_paused, game_manager.ui_open])
	else:
		print("No game manager found - cannot resume game!")
	
	visible = false
	
	# Restore mouse capture for first-person view
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	print("ESC menu closed - Game resumed")

func _on_delete_save_pressed():
	"""Show confirmation dialog for save deletion"""
	confirm_dialog.popup_centered()

func _on_cancel_pressed():
	"""Cancel and close the menu"""
	_close_menu()

func _on_delete_confirmed():
	"""Actually delete the save file"""
	if game_manager:
		game_manager.delete_save_and_restart()

func _on_background_clicked(event):
	"""Close menu when clicking on background"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_menu()
