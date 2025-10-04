extends Control
class_name SleepDialog

## Sleep Dialog UI for selecting sleep duration

# Signals
signal sleep_confirmed(hours: float)
signal dialog_closed()

# UI References
@onready var current_time_label: Label = $Panel/VBox/CurrentTimeLabel
@onready var sleep_slider: HSlider = $Panel/VBox/SliderContainer/SleepSlider
@onready var target_time_label: Label = $Panel/VBox/TargetTimeLabel
@onready var sleep_button: Button = $Panel/VBox/ButtonContainer/SleepButton
@onready var cancel_button: Button = $Panel/VBox/ButtonContainer/CancelButton

# Game manager reference
var game_manager

# Sleep duration settings
const MIN_SLEEP_HOURS: float = 0.5  # 30 minutes
const MAX_SLEEP_HOURS: float = 24.0  # 24 hours
const SLEEP_INCREMENT: float = 0.5   # 30 minute increments

func _ready():
	# Get game manager reference
	game_manager = get_node("/root/GameManagerUI")
	
	# Set up the dialog
	_setup_dialog()
	_update_display()

func _setup_dialog():
	"""Configure the sleep dialog"""
	# Center the dialog
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# Set up slider
	sleep_slider.min_value = MIN_SLEEP_HOURS
	sleep_slider.max_value = MAX_SLEEP_HOURS
	sleep_slider.step = SLEEP_INCREMENT
	sleep_slider.value = 8.0  # Default 8 hours
	
	# Configure slider ticks (48 ticks total for 30-min increments)
	sleep_slider.tick_count = int((MAX_SLEEP_HOURS - MIN_SLEEP_HOURS) / SLEEP_INCREMENT) + 1
	sleep_slider.ticks_on_borders = true
	
	# Connect signals
	sleep_slider.connect("value_changed", _on_slider_changed)
	sleep_button.connect("pressed", _on_sleep_button_pressed)
	cancel_button.connect("pressed", _on_cancel_button_pressed)
	
	# Handle escape key
	set_process_unhandled_input(true)

func _unhandled_input(event):
	"""Handle escape key to close dialog"""
	if event.is_action_pressed("ui_cancel"):
		_close_dialog()

func _update_display():
	"""Update the time displays"""
	if not game_manager:
		return
	
	# Show current time
	current_time_label.text = "Current Time: %s" % game_manager.get_full_time_string()
	
	# Calculate and show target time
	var target_time = _calculate_target_time(sleep_slider.value)
	target_time_label.text = "Wake up at: %s" % target_time

func _calculate_target_time(hours: float) -> String:
	"""Calculate what time the player will wake up"""
	if not game_manager:
		return ""
	
	# Get current time values
	var current_day = game_manager.current_day
	var current_hour = game_manager.current_hour
	var current_minute = game_manager.current_minute
	
	# Add sleep duration
	var total_minutes = current_hour * 60 + current_minute + (hours * 60)
	var target_day = current_day
	var target_hour = int(total_minutes / 60)
	var target_minute = int(total_minutes) % 60
	
	# Handle day overflow
	while target_hour >= 24:
		target_hour -= 24
		target_day += 1
	
	# Format time string
	var period = "AM"
	var display_hour = target_hour
	
	if target_hour == 0:
		display_hour = 12
	elif target_hour > 12:
		display_hour = target_hour - 12
		period = "PM"
	elif target_hour == 12:
		period = "PM"
	
	return "Day %d - %d:%02d %s" % [target_day, display_hour, target_minute, period]

func _on_slider_changed(value: float):
	"""Called when sleep duration slider changes"""
	_update_display()
	
	# Update sleep button text
	if value == 0.5:
		sleep_button.text = "Sleep (30 min)"
	elif value == 1.0:
		sleep_button.text = "Sleep (1 hour)"
	elif value < 2.0:
		sleep_button.text = "Sleep (%.1f hours)" % value
	else:
		sleep_button.text = "Sleep (%d hours)" % int(value)

func _on_sleep_button_pressed():
	"""Called when sleep button is pressed"""
	var sleep_hours = sleep_slider.value
	emit_signal("sleep_confirmed", sleep_hours)

func _on_cancel_button_pressed():
	"""Called when cancel button is pressed"""
	_close_dialog()

func _close_dialog():
	"""Close the dialog"""
	emit_signal("dialog_closed")

# Fast-forward effect (called from bed script after dialog closes)
func start_fast_forward_effect(_hours: float):
	"""Start the 5-second fast-forward visualization"""
	# This will be called by the bed script to show time advancing quickly
	# For now, just a placeholder - could add visual effects later
	pass
