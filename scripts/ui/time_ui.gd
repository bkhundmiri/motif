extends Control
class_name TimeUI

## Time UI Display for Motif Detective Game
## Shows current game time in the top right corner

@onready var time_label: Label = $TimeLabel

# Reference to game manager
var game_manager

func _ready():
	# Get reference to GameManager singleton
	game_manager = get_node("/root/GameManagerUI")
	
	# Connect to time change signal
	if game_manager:
		game_manager.connect("time_changed", _on_time_changed)
		# Update initial display
		_update_time_display()
	
	# Set up UI positioning and styling
	_setup_ui()

func _setup_ui():
	"""Configure the UI appearance and positioning"""
	# Set anchoring to top-right
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	
	# Adjust position slightly inward from edge
	position.x -= 20
	position.y += 10
	
	# Set size
	custom_minimum_size = Vector2(150, 30)

func _on_time_changed(_day: int, _hour: int, _minute: int):
	"""Update the time display when game time changes"""
	_update_time_display()

func _update_time_display():
	"""Update the time label text"""
	if game_manager and time_label:
		time_label.text = game_manager.get_full_time_string()

func _notification(what):
	# Handle theme changes or resizing
	if what == NOTIFICATION_THEME_CHANGED:
		_setup_ui()
